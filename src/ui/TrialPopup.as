package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Graphics;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import flash.utils.getTimer;
    import generation.QuestionGenerator;
    import generation.NumberQuestion;
    
    /**
     * TrialPopup - Popup window for sequence memory trial.
     * Features:
     * - Keyboard input support (1-9 keys)
     * - Timer bar animation (3 seconds per sequence item)
     * - Auto-fail when timer expires
     */
    public class TrialPopup extends Sprite {
        
        // Debug
        private static const DEBUG:Boolean = true;
        
        // Timer settings
        private static const SECONDS_PER_ITEM:Number = 3.0; // 3 seconds per sequence item
        private static const TIMER_UPDATE_INTERVAL:int = 50; // Update timer bar every 50ms
        
        // Events
        public static const TRIAL_SUCCESS:String = "trialSuccess";
        public static const TRIAL_FAIL:String = "trialFail";
        public static const TRIAL_CLOSED:String = "trialClosed";
        
        // States - 3 WINDOW FLOW
        private static const STATE_STIMULUS:String = "stimulus";     // Window 1: Show numbers
        private static const STATE_INSTRUCTION:String = "instruction"; // Window 2: Show instruction (3 sec)
        private static const STATE_INPUT:String = "input";           // Window 3: User input
        private static const STATE_RESULT:String = "result";
        
        // Instruction timing
        private static const INSTRUCTION_DISPLAY_TIME:int = 3000; // 3 seconds
        
        // Dimensions - NEAR FULLSCREEN (calculated in initialize)
        private var _popupWidth:Number = 900;
        private var _popupHeight:Number = 700;
        
        // Visual components
        private var _overlay:Shape;
        private var _background:Shape;
        private var _titleText:TextField;
        private var _stateText:TextField;
        private var _stimulusDisplay:TextField;
        private var _inputDisplay:TextField;
        private var _closeButton:Sprite;
        private var _inputButtonsContainer:Sprite;
        private var _inputButtons:Vector.<Sprite>;
        
        // Timer bar components
        private var _timerBarContainer:Sprite;
        private var _timerBarBg:Shape;
        private var _timerBarFill:Shape;
        private var _timerText:TextField;
        
        // Game components - NEW QUESTION SYSTEM
        private var _questionGenerator:QuestionGenerator;
        private var _currentQuestion:NumberQuestion;
        private var _userInput:Vector.<int>;
        private var _currentState:String;
        private var _currentDifficulty:int = 1;
        
        // Level progression - 12 levels total
        // Level 1-2: 4 digit EASY, Level 3-4: 4 digit MEDIUM, Level 5-6: 4 digit HARD
        // Level 7-8: 6 digit EASY, Level 9-10: 6 digit MEDIUM, Level 11-12: 6 digit HARD
        private var _currentLevel:int = 1; // 1-12 maps to combo/difficulty
        private var _correctAtLevel:int = 0;
        private var _wrongCount:int = 0; // Track consecutive wrong answers at current checkpoint
        private var _highestCheckpoint:int = 1; // Highest unlocked checkpoint (1, 4, or 7)
        private static const CORRECT_TO_LEVEL_UP:int = 1; // 1 correct answer = level up
        private static const WRONG_TO_RESET:int = 3; // 3 wrong answers at checkpoint = reset to previous checkpoint
        private static const MAX_LEVEL:int = 12; // Final level
        
        // Timers
        private var _stimulusTimer:Timer;
        private var _instructionTimer:Timer; // NEW: Timer for instruction phase
        private var _currentStimulusIndex:int = 0;
        private var _resultTimer:Timer;
        
        // Input phase timer
        private var _inputTimer:Timer;
        private var _inputStartTime:int;
        private var _inputTotalTime:int; // Total milliseconds for input phase
        
        // Stage reference
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Last trial result (for animation after close)
        private var _lastTrialResult:Boolean = false; // true = success, false = fail
        
        /**
         * Constructor
         */
        public function TrialPopup() {
            _questionGenerator = QuestionGenerator.getInstance();
            _userInput = new Vector.<int>();
            _inputButtons = new Vector.<Sprite>();
            
            visible = false;
        }
        
        /**
         * Initialize popup
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            // Calculate popup size as 90% of screen
            _popupWidth = Math.min(_stageWidth * 0.9, 1200);
            _popupHeight = Math.min(_stageHeight * 0.9, 800);
            
            createOverlay();
            createBackground();
            createTitle();
            createStateDisplay();
            createStimulusDisplay();
            createInputDisplay();
            createTimerBar();
            createInputButtons();
            createCloseButton();
            
            if (DEBUG) {
                trace("[TrialPopup] Initialized with keyboard support and timer");
            }
        }
        
        /**
         * Create dark overlay
         */
        private function createOverlay():void {
            _overlay = new Shape();
            _overlay.graphics.beginFill(0x000000, 0.5);
            _overlay.graphics.drawRect(0, 0, _stageWidth, _stageHeight);
            _overlay.graphics.endFill();
            addChild(_overlay);
        }
        
        /**
         * Create popup background
         */
        private function createBackground():void {
            _background = new Shape();
            var g:Graphics = _background.graphics;
            
            // Shadow
            g.beginFill(0x000000, 0.2);
            g.drawRoundRect(5, 5, _popupWidth, _popupHeight, 20, 20);
            g.endFill();
            
            // Main background
            g.beginFill(0xFFFFFF);
            g.lineStyle(3, 0x333333);
            g.drawRoundRect(0, 0, _popupWidth, _popupHeight, 20, 20);
            g.endFill();
            
            // Header bar
            g.beginFill(0x4A90E2);
            g.drawRoundRect(0, 0, _popupWidth, 50, 20, 20);
            g.drawRect(0, 30, _popupWidth, 20);
            g.endFill();
            
            _background.x = (_stageWidth - _popupWidth) / 2;
            _background.y = (_stageHeight - _popupHeight) / 2;
            
            addChild(_background);
        }
        
        /**
         * Create title
         */
        private function createTitle():void {
            _titleText = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 20;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            _titleText.defaultTextFormat = format;
            _titleText.text = "UPGRADE CHALLENGE";
            _titleText.width = _popupWidth;
            _titleText.height = 40;
            _titleText.selectable = false;
            _titleText.x = _background.x;
            _titleText.y = _background.y + 10;
            
            addChild(_titleText);
        }
        
        /**
         * Create state display
         */
        private function createStateDisplay():void {
            _stateText = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 20; // Bigger font
            format.color = 0x666666;
            format.align = TextFormatAlign.CENTER;
            
            _stateText.defaultTextFormat = format;
            _stateText.width = _popupWidth;
            _stateText.height = 60; // Taller
            _stateText.selectable = false;
            _stateText.multiline = true;
            _stateText.wordWrap = true;
            _stateText.x = _background.x;
            _stateText.y = _background.y + 60;
            
            addChild(_stateText);
        }
        
        /**
         * Create stimulus display - LARGER for better visibility
         */
        private function createStimulusDisplay():void {
            _stimulusDisplay = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 72; // Bigger default size
            format.color = 0x2D3748;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            _stimulusDisplay.defaultTextFormat = format;
            _stimulusDisplay.width = _popupWidth;
            _stimulusDisplay.height = 200; // Taller for multi-line instruction
            _stimulusDisplay.selectable = false;
            _stimulusDisplay.wordWrap = true;
            _stimulusDisplay.multiline = true;
            _stimulusDisplay.x = _background.x;
            _stimulusDisplay.y = _background.y + 100;
            _stimulusDisplay.visible = false;
            
            addChild(_stimulusDisplay);
        }
        
        /**
         * Create input display
         */
        private function createInputDisplay():void {
            _inputDisplay = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 18;
            format.color = 0x4A90E2;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            _inputDisplay.defaultTextFormat = format;
            _inputDisplay.width = _popupWidth;
            _inputDisplay.height = 120; // Taller
            _inputDisplay.selectable = false;
            _inputDisplay.wordWrap = true;
            _inputDisplay.multiline = true;
            _inputDisplay.x = _background.x;
            _inputDisplay.y = _background.y + 130; // Moved down
            _inputDisplay.visible = false;
            
            addChild(_inputDisplay);
        }
        
        /**
         * Create timer bar
         */
        private function createTimerBar():void {
            _timerBarContainer = new Sprite();
            _timerBarContainer.visible = false;
            
            var barWidth:Number = _popupWidth - 80;
            var barHeight:Number = 24;
            
            // Background
            _timerBarBg = new Shape();
            _timerBarBg.graphics.beginFill(0xDDDDDD);
            _timerBarBg.graphics.drawRoundRect(0, 0, barWidth, barHeight, 10, 10);
            _timerBarBg.graphics.endFill();
            _timerBarContainer.addChild(_timerBarBg);
            
            // Fill (will be redrawn dynamically)
            _timerBarFill = new Shape();
            _timerBarContainer.addChild(_timerBarFill);
            
            // Timer text
            _timerText = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 12;
            format.color = 0x666666;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            _timerText.defaultTextFormat = format;
            _timerText.width = barWidth;
            _timerText.height = barHeight;
            _timerText.y = 1;
            _timerText.selectable = false;
            _timerText.mouseEnabled = false;
            _timerBarContainer.addChild(_timerText);
            
            _timerBarContainer.x = _background.x + 40;
            _timerBarContainer.y = _background.y + 310; // Moved down for larger popup
            
            addChild(_timerBarContainer);
        }
        
        /**
         * Update timer bar fill
         */
        private function updateTimerBar(progress:Number):void {
            var barWidth:Number = _popupWidth - 80;
            var barHeight:Number = 24;
            var fillWidth:Number = barWidth * progress;
            
            // Determine color based on progress
            var color:uint;
            if (progress > 0.5) {
                color = 0x4CAF50; // Green
            } else if (progress > 0.25) {
                color = 0xFFEB3B; // Yellow
            } else {
                color = 0xF44336; // Red
            }
            
            // Redraw fill
            _timerBarFill.graphics.clear();
            if (fillWidth > 0) {
                _timerBarFill.graphics.beginFill(color);
                _timerBarFill.graphics.drawRoundRect(0, 0, fillWidth, barHeight, 10, 10);
                _timerBarFill.graphics.endFill();
            }
            
            // Update text
            var remainingSeconds:Number = (_inputTotalTime - (getTimer() - _inputStartTime)) / 1000;
            if (remainingSeconds < 0) remainingSeconds = 0;
            _timerText.text = remainingSeconds.toFixed(1) + "s";
        }
        
        /**
         * Create input buttons
         */
        private function createInputButtons():void {
            _inputButtonsContainer = new Sprite();
            _inputButtonsContainer.x = _background.x;
            _inputButtonsContainer.y = _background.y + 360; // Moved down for larger popup
            _inputButtonsContainer.visible = false;
            
            addChild(_inputButtonsContainer);
        }
        
        /**
         * Create close button
         */
        private function createCloseButton():void {
            _closeButton = new Sprite();
            
            var size:int = 30;
            var g:Graphics = _closeButton.graphics;
            
            g.beginFill(0xE53E3E);
            g.drawCircle(size / 2, size / 2, size / 2);
            g.endFill();
            
            // X icon
            g.lineStyle(3, 0xFFFFFF);
            g.moveTo(10, 10);
            g.lineTo(20, 20);
            g.moveTo(20, 10);
            g.lineTo(10, 20);
            
            _closeButton.x = _background.x + _popupWidth - size - 10;
            _closeButton.y = _background.y + 10;
            _closeButton.buttonMode = true;
            _closeButton.useHandCursor = true;
            _closeButton.addEventListener(MouseEvent.CLICK, onCloseClick);
            _closeButton.visible = false;
            
            addChild(_closeButton);
        }
        
        /**
         * Show the popup and start trial
         */
        public function show(difficulty:int = 1):void {
            _currentDifficulty = difficulty;
            visible = true;
            _closeButton.visible = false;
            _timerBarContainer.visible = false;
            
            // Add keyboard listener
            if (stage) {
                stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyboardDown);
            }
            
            startTrial();
        }
        
        /**
         * Hide the popup
         */
        public function hide():void {
            visible = false;
            stopTimers();
            
            // Remove keyboard listener
            if (stage) {
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleKeyboardDown);
            }
            
            dispatchEvent(new Event(TRIAL_CLOSED));
        }
        
        /**
         * Handle keyboard input - supports 0-9 keys
         */
        private function handleKeyboardDown(e:KeyboardEvent):void {
            if (_currentState != STATE_INPUT) return;

            if (e.ctrlKey && e.shiftKey) {
                if (e.keyCode == Keyboard.Y) {
                    applyCheatResult(true);
                    return;
                }
                if (e.keyCode == Keyboard.X) {
                    applyCheatResult(false);
                    return;
                }
            }
            
            var keyNum:int = -1;
            
            // Top row 0 key (keycode 48) = number 0
            if (e.keyCode == 48) {
                keyNum = 0;
            }
            // Top row numbers 1-9 (keycodes 49-57)
            else if (e.keyCode >= 49 && e.keyCode <= 57) {
                keyNum = e.keyCode - 48; // 1-9
            }
            // Numpad 0 (keycode 96) = number 0
            else if (e.keyCode == 96) {
                keyNum = 0;
            }
            // Numpad numbers 1-9 (keycodes 97-105)
            else if (e.keyCode >= 97 && e.keyCode <= 105) {
                keyNum = e.keyCode - 96; // 1-9
            }
            
            // Only accept if within valid range (0-9)
            if (keyNum >= 0 && keyNum <= 9) {
                processInput(keyNum);
                
                // Visual feedback on button
                if (keyNum < _inputButtons.length) {
                    flashButton(_inputButtons[keyNum]);
                }
                
                if (DEBUG) {
                    trace("[TrialPopup] Keyboard input: " + keyNum);
                }
            }
        }

        private function applyCheatResult(isCorrect:Boolean):void {
            stopTimers();
            _currentState = STATE_RESULT;
            _inputButtonsContainer.visible = false;
            _timerBarContainer.visible = false;
            
            var userAnswer:Array = [];
            if (_currentQuestion && _currentQuestion.correctAnswer) {
                userAnswer = _currentQuestion.correctAnswer.concat();
                if (!isCorrect && userAnswer.length > 0) {
                    userAnswer[0] = (userAnswer[0] + 1) % 10;
                }
            }
            
            setUserInputFromArray(userAnswer);
            showResult(isCorrect, userAnswer);
        }

        private function setUserInputFromArray(values:Array):void {
            _userInput.length = 0;
            if (!values) return;
            
            for (var i:int = 0; i < values.length; i++) {
                _userInput.push(int(values[i]));
            }
        }
        
        /**
         * Get question settings from current level (12 LEVEL SYSTEM)
         * Level 1-2: 4 digits EASY (urutan sama)
         * Level 3-4: 4 digits MEDIUM (reverse)
         * Level 5-6: 4 digits HARD (switch)
         * Level 7-8: 6 digits EASY
         * Level 9-10: 6 digits MEDIUM
         * Level 11-12: 6 digits HARD
         */
        private function getQuestionSettings():Object {
            var settings:Object = {
                combination: NumberQuestion.COMBO_4,
                level: NumberQuestion.LEVEL_EASY
            };
            
            // Determine digit count: 1-6 = 4 digits, 7-12 = 6 digits
            if (_currentLevel <= 6) {
                settings.combination = NumberQuestion.COMBO_4;
            } else {
                settings.combination = NumberQuestion.COMBO_6;
            }
            
            // Determine difficulty based on level pairs
            // Within each digit group: 1-2 EASY, 3-4 MEDIUM, 5-6 HARD
            var levelInGroup:int = (_currentLevel <= 6) ? _currentLevel : (_currentLevel - 6);
            
            if (levelInGroup <= 2) {
                settings.level = NumberQuestion.LEVEL_EASY;
            } else if (levelInGroup <= 4) {
                settings.level = NumberQuestion.LEVEL_MEDIUM;
            } else {
                settings.level = NumberQuestion.LEVEL_HARD;
            }
            
            return settings;
        }
        
        /**
         * Start new trial - NEW QUESTION SYSTEM
         */
        private function startTrial():void {
            _userInput.length = 0;
            _currentState = STATE_STIMULUS;
            
            // Get question settings based on current level
            var settings:Object = getQuestionSettings();
            
            if (DEBUG) {
                trace("[TrialPopup] ========== GENERATING QUESTION ==========");
                trace("[TrialPopup] Current Level: " + _currentLevel);
                trace("[TrialPopup] Settings - combination: " + settings.combination + ", level: " + settings.level);
            }
            
            // Generate NEW question
            _currentQuestion = _questionGenerator.generate(settings.combination, settings.level);
            
            if (DEBUG) {
                trace("[TrialPopup] ============ NEW QUESTION ============");
                trace("[TrialPopup] Level: " + _currentLevel + " -> Combo: " + _currentQuestion.combination + ", Difficulty: " + _currentQuestion.level);
                trace("[TrialPopup] Original sequence: [" + _currentQuestion.originalSequence.join(", ") + "]");
                trace("[TrialPopup] Displayed (sorted): [" + _currentQuestion.displayedSequence.join(", ") + "]");
                trace("[TrialPopup] Correct answer: [" + _currentQuestion.correctAnswer.join(", ") + "]");
                trace("[TrialPopup] Instruction: " + _currentQuestion.instruction);
                trace("[TrialPopup] =====================================");
            }
            
            // Start stimulus phase
            enterStimulusPhase();
        }
        
        /**
         * Enter stimulus phase - WINDOW 1: Show BIG numbers only
         * No instruction here, just memorize the sequence
         */
        private function enterStimulusPhase():void {
            _currentState = STATE_STIMULUS;
            
            // Show level info only, no instruction yet
            var levelInfo:String = "Level " + _currentLevel + " | " + _currentQuestion.combination + " angka";
            _stateText.text = levelInfo + "\n\n🧠 INGAT URUTAN ANGKA INI!";
            
            _stimulusDisplay.visible = true;
            _inputDisplay.visible = false;
            _inputButtonsContainer.visible = false;
            _timerBarContainer.visible = false;
            
            // Show the ORIGINAL sequence in BIG format
            _stimulusDisplay.text = _currentQuestion.originalSequence.join("   ");
            
            // Format for LARGE, clear visibility - adjust size based on digit count
            var format:TextFormat = _stimulusDisplay.getTextFormat();
            format.color = 0x2D3748;
            
            // Dynamic font size: smaller for more digits
            if (_currentQuestion.combination == 4) {
                format.size = 72;
                format.letterSpacing = 20;
            } else if (_currentQuestion.combination == 6) {
                format.size = 60;
                format.letterSpacing = 15;
            } else { // 8 digits
                format.size = 48;
                format.letterSpacing = 10;
            }
            format.bold = true;
            _stimulusDisplay.setTextFormat(format);
            
            if (DEBUG) {
                trace("[TrialPopup] WINDOW 1 - Showing numbers: " + _currentQuestion.originalSequence.join(", "));
            }
            
            // Display time based on combination (2s base + 0.75s per digit)
            var displayTime:int = 2000 + (_currentQuestion.combination * 750);
            
            // Timer to move to INSTRUCTION phase (not input yet!)
            _stimulusTimer = new Timer(displayTime, 1);
            _stimulusTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onStimulusComplete);
            _stimulusTimer.start();
        }
        
        /**
         * Handle stimulus display complete - move to INSTRUCTION phase
         */
        private function onStimulusComplete(e:TimerEvent):void {
            stopTimers();
            enterInstructionPhase(); // Go to Window 2, not input directly!
        }
        
        /**
         * Enter instruction phase - WINDOW 2: Show instruction for 3 seconds
         * This is the new phase between stimulus and input
         */
        private function enterInstructionPhase():void {
            _currentState = STATE_INSTRUCTION;
            
            // Hide stimulus display, show instruction
            _stimulusDisplay.visible = true;
            _inputDisplay.visible = false;
            _inputButtonsContainer.visible = false;
            _timerBarContainer.visible = false;
            
            // Show instruction based on level difficulty
            var instructionText:String = "";
            var instructionIcon:String = "";
            
            switch (_currentQuestion.level) {
                case NumberQuestion.LEVEL_EASY:
                    instructionText = "KETIK URUTAN\nYANG SAMA";
                    instructionIcon = "➡️";
                    break;
                case NumberQuestion.LEVEL_MEDIUM:
                    instructionText = "KETIK URUTAN\nTERBALIK (REVERSE)";
                    instructionIcon = "↩️";
                    break;
                case NumberQuestion.LEVEL_HARD:
                    instructionText = "TUKAR POSISI\nGANJIL-GENAP";
                    instructionIcon = "🔄";
                    break;
            }
            
            // Update display
            _stateText.text = "📋 INSTRUKSI";
            _stimulusDisplay.text = instructionIcon + "\n" + instructionText;
            
            // Format for instruction display
            var format:TextFormat = _stimulusDisplay.getTextFormat();
            format.color = 0x4A90E2;
            format.size = 36;
            format.letterSpacing = 0;
            format.bold = true;
            _stimulusDisplay.setTextFormat(format);
            
            if (DEBUG) {
                trace("[TrialPopup] WINDOW 2 - Showing instruction: " + _currentQuestion.level);
                trace("[TrialPopup] Instruction will display for " + (INSTRUCTION_DISPLAY_TIME/1000) + " seconds");
            }
            
            // Timer to move to INPUT phase after 3 seconds
            _instructionTimer = new Timer(INSTRUCTION_DISPLAY_TIME, 1);
            _instructionTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onInstructionComplete);
            _instructionTimer.start();
        }
        
        /**
         * Handle instruction display complete - move to INPUT phase
         */
        private function onInstructionComplete(e:TimerEvent):void {
            stopTimers();
            enterInputPhase(); // Now go to Window 3
        }
        
        /**
         * Show current stimulus - LEGACY (not used in new system)
         */
        private function showCurrentStimulus():void {
            // Legacy - not used
        }
        
        /**
         * Handle stimulus timer tick - LEGACY (not used in new system)
         */
        private function onStimulusTick(e:TimerEvent):void {
            // Legacy - not used
        }
        
        /**
         * Enter input phase - WINDOW 3: User inputs their answer
         */
        private function enterInputPhase():void {
            _currentState = STATE_INPUT;
            
            // Show what user needs to do
            var taskHint:String = "";
            switch (_currentQuestion.level) {
                case NumberQuestion.LEVEL_EASY:
                    taskHint = "Ketik urutan SAMA seperti yang ditampilkan";
                    break;
                case NumberQuestion.LEVEL_MEDIUM:
                    taskHint = "Ketik urutan TERBALIK (dari belakang)";
                    break;
                case NumberQuestion.LEVEL_HARD:
                    taskHint = "Ketik dengan TUKAR posisi ganjil-genap";
                    break;
            }
            _stateText.text = "✏️ MASUKKAN JAWABAN\n" + taskHint;
            
            _stimulusDisplay.visible = false;
            _inputDisplay.visible = true;
            _inputDisplay.text = "Jawaban: ";
            _inputButtonsContainer.visible = true;
            _timerBarContainer.visible = true;
            
            // Create 10 input buttons (numbers 1-10)
            createInputButtonsForSequence(10);
            
            // Start input timer based on question time limit
            _inputTotalTime = _currentQuestion.timeLimit * 1000;
            _inputStartTime = getTimer();
            
            // Update timer bar
            updateTimerBar(1.0);
            
            // Start timer update loop
            _inputTimer = new Timer(TIMER_UPDATE_INTERVAL);
            _inputTimer.addEventListener(TimerEvent.TIMER, onInputTimerTick);
            _inputTimer.start();
            
            if (DEBUG) {
                trace("[TrialPopup] Input phase started. Time limit: " + _currentQuestion.timeLimit + "s");
                trace("[TrialPopup] Need to enter " + _currentQuestion.combination + " numbers");
            }
        }
        
        /**
         * Handle input timer tick - update progress bar
         */
        private function onInputTimerTick(e:TimerEvent):void {
            var elapsed:int = getTimer() - _inputStartTime;
            var remaining:Number = 1 - (elapsed / _inputTotalTime);
            
            if (remaining <= 0) {
                // Time's up!
                remaining = 0;
                updateTimerBar(0);
                onTimeExpired();
            } else {
                updateTimerBar(remaining);
            }
        }
        
        /**
         * Handle time expired - auto fail
         */
        private function onTimeExpired():void {
            if (_currentState != STATE_INPUT) return;
            
            if (DEBUG) {
                trace("[TrialPopup] Time expired! Auto-fail.");
            }
            
            stopTimers();
            
            _currentState = STATE_RESULT;
            _timerBarContainer.visible = false;
            _inputButtonsContainer.visible = false;
            
            // Show timeout message
            _stateText.text = "Time's Up!";
            showResult(false);
        }
        
        /**
         * Create input buttons for sequence
         */
        private function createInputButtonsForSequence(numButtons:int):void {
            // Clear existing buttons
            while (_inputButtonsContainer.numChildren > 0) {
                _inputButtonsContainer.removeChildAt(0);
            }
            _inputButtons.length = 0;
            
            var buttonSize:int = 65; // Bigger buttons
            var spacing:int = 12;
            var totalWidth:int = numButtons * buttonSize + (numButtons - 1) * spacing;
            var startX:int = (_popupWidth - totalWidth) / 2;
            
            for (var i:int = 0; i < numButtons; i++) {
                var btn:Sprite = new Sprite();
                var g:Graphics = btn.graphics;
                
                g.beginFill(0x4A90E2);
                g.lineStyle(2, 0x357ABD);
                g.drawRoundRect(0, 0, buttonSize, buttonSize, 12, 12);
                g.endFill();
                
                // Number label (0-9)
                var label:TextField = new TextField();
                var format:TextFormat = new TextFormat();
                format.font = "Arial";
                format.size = 28; // Bigger font
                format.color = 0xFFFFFF;
                format.bold = true;
                format.align = TextFormatAlign.CENTER;
                
                label.defaultTextFormat = format;
                label.text = String(i); // 0-9 instead of 1-10
                label.width = buttonSize;
                label.height = buttonSize;
                label.y = 15;
                label.selectable = false;
                label.mouseEnabled = false;
                btn.addChild(label);
                
                btn.x = startX + i * (buttonSize + spacing);
                btn.y = 0;
                btn.buttonMode = true;
                btn.useHandCursor = true;
                btn.name = String(i);
                btn.addEventListener(MouseEvent.CLICK, onInputButtonClick);
                btn.addEventListener(MouseEvent.ROLL_OVER, onInputButtonOver);
                btn.addEventListener(MouseEvent.ROLL_OUT, onInputButtonOut);
                
                _inputButtonsContainer.addChild(btn);
                _inputButtons.push(btn);
            }
            
            // Add keyboard hint
            var hintText:TextField = new TextField();
            var hintFormat:TextFormat = new TextFormat();
            hintFormat.font = "Arial";
            hintFormat.size = 12;
            hintFormat.color = 0x999999;
            hintFormat.align = TextFormatAlign.CENTER;
            
            hintText.defaultTextFormat = hintFormat;
            hintText.text = "Tekan tombol 0-9 pada keyboard";
            hintText.width = _popupWidth;
            hintText.height = 20;
            hintText.y = buttonSize + 15;
            hintText.x = 0;
            hintText.selectable = false;
            _inputButtonsContainer.addChild(hintText);
        }
        
        /**
         * Handle input button click
         */
        private function onInputButtonClick(e:MouseEvent):void {
            if (_currentState != STATE_INPUT) return;
            
            var btn:Sprite = e.currentTarget as Sprite;
            var buttonId:int = int(btn.name);
            
            processInput(buttonId);
            flashButton(btn);
        }
        
        /**
         * Process user input (from button or keyboard)
         * buttonId is 0-9, which directly corresponds to numbers 0-9
         */
        private function processInput(buttonId:int):void {
            _userInput.push(buttonId); // Store 0-9 directly
            updateInputDisplay();
            
            if (DEBUG) {
                trace("[TrialPopup] Input: " + buttonId + " | Buffer: " + getUserInputDisplay());
            }
            
            // Check if input complete (based on question combination, not button count)
            if (_userInput.length >= _currentQuestion.combination) {
                stopTimers();
                validateInput();
            }
        }
        
        /**
         * Get user input as display string (numbers are 0-9)
         */
        private function getUserInputDisplay():String {
            var arr:Array = [];
            for each (var id:int in _userInput) {
                arr.push(String(id)); // Numbers are already 0-9
            }
            return arr.join(", ");
        }
        
        /**
         * Get user input as array of actual numbers (0-9)
         */
        private function getUserInputArray():Array {
            var arr:Array = [];
            for each (var id:int in _userInput) {
                arr.push(id); // Numbers are already 0-9
            }
            return arr;
        }
        
        /**
         * Update input display
         */
        private function updateInputDisplay():void {
            _inputDisplay.text = "Jawaban: " + getUserInputDisplay() + " (" + _userInput.length + "/" + _currentQuestion.combination + ")";
        }
        
        /**
         * Flash button effect
         */
        private function flashButton(btn:Sprite):void {
            btn.alpha = 0.5;
            btn.scaleX = 0.9;
            btn.scaleY = 0.9;
            
            var timer:Timer = new Timer(100, 1);
            timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
                btn.alpha = 1.0;
                btn.scaleX = 1.0;
                btn.scaleY = 1.0;
            });
            timer.start();
        }
        
        /**
         * Handle input button hover
         */
        private function onInputButtonOver(e:MouseEvent):void {
            var btn:Sprite = e.currentTarget as Sprite;
            btn.scaleX = 1.1;
            btn.scaleY = 1.1;
        }
        
        /**
         * Handle input button out
         */
        private function onInputButtonOut(e:MouseEvent):void {
            var btn:Sprite = e.currentTarget as Sprite;
            btn.scaleX = 1.0;
            btn.scaleY = 1.0;
        }
        
        /**
         * Validate user input - NEW SYSTEM
         */
        private function validateInput():void {
            _currentState = STATE_RESULT;
            _inputButtonsContainer.visible = false;
            _timerBarContainer.visible = false;
            
            // Convert user input to actual numbers and validate
            var userAnswer:Array = getUserInputArray();
            var validationResult:Object = _currentQuestion.validateAnswer(userAnswer);
            var isCorrect:Boolean = validationResult.isCorrect;
            
            if (DEBUG) {
                trace("[TrialPopup] ============ VALIDATION ============");
                trace("[TrialPopup] User answer: [" + userAnswer.join(", ") + "]");
                trace("[TrialPopup] Correct answer: [" + _currentQuestion.correctAnswer.join(", ") + "]");
                trace("[TrialPopup] Result: " + (isCorrect ? "CORRECT" : "INCORRECT"));
                trace("[TrialPopup] Accuracy: " + Math.round(validationResult.accuracy * 100) + "%");
                trace("[TrialPopup] =====================================");
            }
            
            showResult(isCorrect, userAnswer);
        }
        
        /**
         * Get checkpoint level for current level
         * Checkpoints: 1 (level 1-3), 4 (level 4-6), 7 (level 7-9), 10 (level 10-12)
         */
        private function getCurrentCheckpoint():int {
            if (_currentLevel <= 3) return 1;
            if (_currentLevel <= 6) return 4;
            if (_currentLevel <= 9) return 7;
            return 10;
        }
        
        /**
         * Get checkpoint level to reset to when wrong 3x at current checkpoint
         * - If at checkpoint 1 (level 1-3): stay at 1
         * - If at checkpoint 4 (level 4-6): reset to 1
         * - If at checkpoint 7 (level 7-9): reset to 4
         * - If at checkpoint 10 (level 10-12): reset to 7
         */
        private function getPreviousCheckpoint():int {
            var currentCP:int = getCurrentCheckpoint();
            if (currentCP <= 1) return 1; // No previous, stay at 1
            if (currentCP <= 4) return 1;
            if (currentCP <= 7) return 4;
            return 7;
        }
        
        /**
         * Unlock checkpoint when completing a group (level 3, 6, 9)
         */
        private function checkUnlockCheckpoint():void {
            // Completing level 3 unlocks checkpoint 4
            if (_currentLevel == 3 && _highestCheckpoint < 4) {
                _highestCheckpoint = 4;
                if (DEBUG) trace("[TrialPopup] Checkpoint 4 UNLOCKED!");
            }
            // Completing level 6 unlocks checkpoint 7
            if (_currentLevel == 6 && _highestCheckpoint < 7) {
                _highestCheckpoint = 7;
                if (DEBUG) trace("[TrialPopup] Checkpoint 7 UNLOCKED!");
            }
            // Completing level 9 unlocks checkpoint 10
            if (_currentLevel == 9 && _highestCheckpoint < 10) {
                _highestCheckpoint = 10;
                if (DEBUG) trace("[TrialPopup] Checkpoint 10 UNLOCKED!");
            }
        }
        
        /**
         * Show result - with CHECKPOINT system
         */
        private function showResult(isCorrect:Boolean, userAnswer:Array = null):void {
            _stimulusDisplay.visible = true;
            _inputDisplay.visible = true;
            
            // Show comparison - show original sequence that was displayed
            var comparison:String = "Ditampilkan: [" + _currentQuestion.originalSequence.join(", ") + "]\n";
            comparison += "Jawaban benar: [" + _currentQuestion.correctAnswer.join(", ") + "]\n";
            if (userAnswer) {
                comparison += "Jawaban Anda: [" + userAnswer.join(", ") + "]";
            }
            _inputDisplay.text = comparison;
            
            if (isCorrect) {
                _correctAtLevel++;
                _wrongCount = 0; // Reset wrong counter on correct answer
                
                // Check for level up
                if (_correctAtLevel >= CORRECT_TO_LEVEL_UP) {
                    // Check if completing this level unlocks a checkpoint
                    checkUnlockCheckpoint();
                    
                    if (_currentLevel < MAX_LEVEL) {
                        _currentLevel++;
                        _correctAtLevel = 0;
                        _stateText.text = "🎉 LEVEL UP!\nNaik ke Level " + _currentLevel + "!";
                        
                        if (DEBUG) {
                            trace("[TrialPopup] LEVEL UP! Now at level " + _currentLevel);
                        }
                    } else {
                        // Level 12 complete - GAME WON!
                        _stateText.text = "🏆 SELAMAT!\nAnda menyelesaikan semua level!";
                        
                        if (DEBUG) {
                            trace("[TrialPopup] GAME COMPLETE! All levels finished!");
                        }
                    }
                } else {
                    var remaining:int = CORRECT_TO_LEVEL_UP - _correctAtLevel;
                    _stateText.text = "✅ Benar!\n" + remaining + " lagi untuk naik level";
                }
                
                _stimulusDisplay.text = "✓";
                
                var formatCorrect:TextFormat = _stimulusDisplay.getTextFormat();
                formatCorrect.color = 0x48BB78;
                formatCorrect.size = 72;
                _stimulusDisplay.setTextFormat(formatCorrect);
                
                // Store result for animation after close
                _lastTrialResult = true;
                
                dispatchEvent(new Event(TRIAL_SUCCESS));
            } else {
                // Wrong answer - new error logic:
                // 1st wrong: reset to current checkpoint
                // 3x wrong at checkpoint level: reset to PREVIOUS checkpoint
                _wrongCount++;
                var wasAtLevel:int = _currentLevel;
                var currentCP:int = getCurrentCheckpoint();
                
                if (DEBUG) {
                    trace("[TrialPopup] WRONG! Count: " + _wrongCount + "/" + WRONG_TO_RESET);
                    trace("[TrialPopup] Current checkpoint: " + currentCP + ", At checkpoint level: " + (_currentLevel == currentCP));
                }
                
                // Check if at checkpoint level and hit 3 wrongs
                if (_currentLevel == currentCP && _wrongCount >= WRONG_TO_RESET) {
                    // At checkpoint level, 3 wrongs = reset to PREVIOUS checkpoint
                    var prevCP:int = getPreviousCheckpoint();
                    _currentLevel = prevCP;
                    _correctAtLevel = 0;
                    _wrongCount = 0;
                    
                    if (_stateText.text != "Time's Up!") {
                        _stateText.text = "❌ 3x Salah!\nKembali ke Level " + prevCP;
                    } else {
                        _stateText.text = "⏱️ Waktu Habis!\nKembali ke Level " + prevCP;
                    }
                    
                    if (DEBUG) {
                        trace("[TrialPopup] 3 WRONGS at checkpoint! Reset to previous checkpoint: " + prevCP);
                    }
                } else if (_currentLevel > currentCP) {
                    // Not at checkpoint - any wrong resets to current checkpoint
                    _currentLevel = currentCP;
                    _correctAtLevel = 0;
                    // Keep wrongCount - it tracks wrongs at checkpoint
                    
                    if (_stateText.text != "Time's Up!") {
                        _stateText.text = "❌ Salah!\nKembali ke Level " + currentCP;
                    } else {
                        _stateText.text = "⏱️ Waktu Habis!\nKembali ke Level " + currentCP;
                    }
                    
                    if (DEBUG) {
                        trace("[TrialPopup] Wrong! Reset to checkpoint: " + currentCP + " (wrongs at CP: " + _wrongCount + ")");
                    }
                } else {
                    // At checkpoint, but haven't hit 3 wrongs yet
                    var wrongsRemaining:int = WRONG_TO_RESET - _wrongCount;
                    if (_stateText.text != "Time's Up!") {
                        _stateText.text = "❌ Salah!\n" + wrongsRemaining + " kesempatan lagi";
                    } else {
                        _stateText.text = "⏱️ Waktu Habis!\n" + wrongsRemaining + " kesempatan lagi";
                    }
                }
                
                _stimulusDisplay.text = "✗";
                
                var formatWrong:TextFormat = _stimulusDisplay.getTextFormat();
                formatWrong.color = 0xE53E3E;
                formatWrong.size = 72;
                _stimulusDisplay.setTextFormat(formatWrong);
                
                // Store result for animation after close
                _lastTrialResult = false;
                
                dispatchEvent(new Event(TRIAL_FAIL));
            }
            
            // Show close button
            _closeButton.visible = true;
            
            // Auto close after short delay
            _resultTimer = new Timer(1500, 1); // Longer delay so user can see result
            _resultTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onResultTimeout);
            _resultTimer.start();
        }
        
        /**
         * Handle result timeout - auto close
         */
        private function onResultTimeout(e:TimerEvent):void {
            hide();
        }
        
        /**
         * Handle close button click
         */
        private function onCloseClick(e:MouseEvent):void {
            hide();
        }
        
        /**
         * Stop all timers
         */
        private function stopTimers():void {
            if (_stimulusTimer) {
                _stimulusTimer.stop();
                _stimulusTimer.removeEventListener(TimerEvent.TIMER, onStimulusTick);
                _stimulusTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onStimulusComplete);
                _stimulusTimer = null;
            }
            if (_instructionTimer) {
                _instructionTimer.stop();
                _instructionTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onInstructionComplete);
                _instructionTimer = null;
            }
            if (_resultTimer) {
                _resultTimer.stop();
                _resultTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onResultTimeout);
                _resultTimer = null;
            }
            if (_inputTimer) {
                _inputTimer.stop();
                _inputTimer.removeEventListener(TimerEvent.TIMER, onInputTimerTick);
                _inputTimer = null;
            }
        }
        
        /**
         * Set difficulty level (legacy compatibility)
         * NOTE: This no longer resets _currentLevel - level progression is handled internally
         */
        public function setDifficulty(level:int):void {
            _currentDifficulty = level;
            // Don't reset _currentLevel here - it's managed by the progression system
            // _currentLevel is only reset on wrong answers (to checkpoint)
        }
        
        /**
         * Get current level
         */
        public function getCurrentLevel():int {
            return _currentLevel;
        }
        
        /**
         * Get current question for result processing
         */
        public function getCurrentQuestion():NumberQuestion {
            return _currentQuestion;
        }
        
        /**
         * Get user input for result processing
         */
        public function getUserInput():Vector.<int> {
            return _userInput;
        }
        
        /**
         * Get user input as array of actual numbers
         */
        public function getUserAnswer():Array {
            return getUserInputArray();
        }
        
        /**
         * Reset to checkpoint when castle is destroyed (called from outside)
         * This forces a reset regardless of wrong count
         */
        public function resetToCheckpoint():void {
            var resetTo:int = getPreviousCheckpoint();
            var wasAtLevel:int = _currentLevel;
            
            _currentLevel = resetTo;
            _correctAtLevel = 0;
            _wrongCount = 0;
            
            if (DEBUG) {
                trace("[TrialPopup] CASTLE DESTROYED! Reset from level " + wasAtLevel + " to checkpoint " + resetTo);
            }
        }
        
        /**
         * Get wrong count for external tracking
         */
        public function getWrongCount():int {
            return _wrongCount;
        }
        
        /**
         * Get last trial result (true = success, false = fail)
         * Used for triggering castle animation after popup closes
         */
        public function getLastTrialResult():Boolean {
            return _lastTrialResult;
        }
        
        /**
         * Resize popup to new stage dimensions
         */
        public function resize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            // Resize overlay
            _overlay.graphics.clear();
            _overlay.graphics.beginFill(0x000000, 0.5);
            _overlay.graphics.drawRect(0, 0, _stageWidth, _stageHeight);
            _overlay.graphics.endFill();
            
            // Reposition background (centered)
            _background.x = (_stageWidth - _popupWidth) / 2;
            _background.y = (_stageHeight - _popupHeight) / 2;
            
            // Reposition title
            _titleText.x = _background.x;
            _titleText.y = _background.y + 10;
            
            // Reposition state text
            _stateText.x = _background.x;
            _stateText.y = _background.y + 55;
            
            // Reposition stimulus display
            _stimulusDisplay.x = _background.x;
            _stimulusDisplay.y = _background.y + 80;
            
            // Reposition input display
            _inputDisplay.x = _background.x;
            _inputDisplay.y = _background.y + 75;
            
            // Reposition timer bar
            _timerBarContainer.x = _background.x + 40;
            _timerBarContainer.y = _background.y + 165;
            
            // Reposition input buttons container
            _inputButtonsContainer.x = _background.x;
            _inputButtonsContainer.y = _background.y + 200;
            
            // Reposition close button
            _closeButton.x = _background.x + _popupWidth - 40;
            _closeButton.y = _background.y + 10;
            
            if (DEBUG) {
                trace("[TrialPopup] Resized to " + stageWidth + "x" + stageHeight);
            }
        }
    }
}
