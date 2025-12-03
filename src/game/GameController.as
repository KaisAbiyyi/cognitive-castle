package game {

    import flash.display.Sprite;
    import flash.display.SimpleButton;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.MouseEvent;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import ui.HUD;
    import generation.QuestionGenerator;
    import generation.QuestionManager;
    import generation.NumberQuestion;
    import generation.QuestionEvent;
    import input.InputManager;
    import domain.StimulusItem;
    import domain.TrialResult;
    import castle.CastleArchitect;
    import castle.CastleView;
    import castle.CastlePanel;
    import castle.CastleConfig;
    import castle.BuildEvent;
    import castle.EffectsManager;
    import castle.MetricsManager;

    /**
     * GameController - Manages the game loop finite state machine and orchestrates all game components.
     * Handles phase transitions: IDLE -> STIMULUS -> INPUT -> RESULT -> NEXT
     *
     * NEW QUESTION SYSTEM:
     * - Uses NumberQuestion with 3 combinations (4, 6, 8 digits)
     * - 3 difficulty levels: EASY (recall), MEDIUM (reverse), HARD (swap odd/even)
     * - Numbers displayed sorted descending, player must recall original order
     *
     * SOLID Principles:
     * - Single Responsibility: Only orchestrates game flow and state management
     * - Open/Closed: Can be extended with new game states without changing existing code
     * - Dependency Inversion: Depends on abstractions (HUD, QuestionGenerator, InputManager)
     */
    public class GameController {

        // Debug flag for conditional logging (set to false for release builds)
        private static const DEBUG:Boolean = true;

        // FSM States
        public static const STATE_IDLE:String = "idle";
        public static const STATE_STIMULUS:String = "stimulus";
        public static const STATE_INPUT:String = "input";
        public static const STATE_RESULT:String = "result";
        public static const STATE_NEXT:String = "next";

        // Singleton instance
        private static var _instance:GameController;

        // Current FSM state
        private var _currentState:String = STATE_IDLE;

        // Game components
        private var _hud:HUD;
        private var _questionGenerator:QuestionGenerator;
        private var _questionManager:QuestionManager;
        private var _inputManager:InputManager;
        // private var _stimulusView:StimulusView; // Stub - implemented in Area 2
        // private var _validator:Validator; // Stub - implemented in Area 4
        
        // Castle components
        private var _castleArchitect:CastleArchitect;
        private var _castleView:CastleView;
        private var _castlePanel:CastlePanel;
        private var _effectsManager:EffectsManager;
        private var _metricsManager:MetricsManager;
        
        // Streak tracking
        private var _currentStreak:int = 0;
        private var _trialStartTime:Number = 0;
        private var _inputStartTime:Number = 0;
        
        // Level progression tracking
        private var _correctAnswersAtCurrentLevel:int = 0;
        private static const CORRECT_ANSWERS_TO_LEVEL_UP:int = 3;

        // NEW Question System Data
        private var _currentQuestion:NumberQuestion;
        private var _userAnswerArray:Array;
        
        // Legacy (keep for compatibility)
        private var _currentSequence:Vector.<StimulusItem>;
        private var _userInput:Vector.<int>;
        private var _isCorrect:Boolean;
        private var _trialCount:int = 0;
        private var _currentStimulusIndex:int = 0; // Track which stimulus is being shown
        private var _stimulusTimer:Timer; // Timer for stimulus presentation

        // UI Components
        private var _nextTrialButton:SimpleButton;
        private var _autoAdvanceTimer:Timer;
        private var _stimulusDisplay:TextField; // Week 1 placeholder for stimulus
        private var _userInputDisplay:TextField; // Show user's input as they click

        // Timing constants
        private const RESULT_DISPLAY_TIME:int = 3000; // 3 seconds

        /**
         * Get singleton instance
         * @return GameController instance
         */
        public static function getInstance():GameController {
            if (!_instance) {
                _instance = new GameController();
            }
            return _instance;
        }

        /**
         * Constructor (private for singleton)
         */
        public function GameController() {
            // Initialize NEW question system
            _questionGenerator = QuestionGenerator.getInstance();
            _questionManager = QuestionManager.getInstance();
            
            _inputManager = InputManager.getInstance();
            _autoAdvanceTimer = new Timer(RESULT_DISPLAY_TIME, 1);
            _autoAdvanceTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAutoAdvance);
            
            // Initialize castle system
            _castleArchitect = new CastleArchitect();
            _metricsManager = MetricsManager.getInstance();
            
            // Initialize user answer array
            _userAnswerArray = [];
        }

        /**
         * Initialize the game controller with HUD
         * @param hud HUD component
         */
        public function initialize(hud:HUD):void {
            _hud = hud;
            createStimulusDisplay();
            createUserInputDisplay();
            initializeCastleUI();
            enterState(STATE_IDLE);
            
            // Start metrics session
            _metricsManager.startSession();
        }
        
        /**
         * Initialize castle view and panel
         */
        private function initializeCastleUI():void {
            if (!_hud.parent) return;
            
            var stage:* = _hud.parent.stage || _hud.parent;
            
            // Create castle view (left side)
            _castleView = new CastleView(200, 180);
            _castleView.x = 10;
            _castleView.y = 60;
            _hud.parent.addChild(_castleView);
            
            // Create castle panel (right side)
            _castlePanel = new CastlePanel(180, 140);
            _castlePanel.x = stage.stageWidth - 190;
            _castlePanel.y = 60;
            _hud.parent.addChild(_castlePanel);
            
            // Create effects manager with parent
            _effectsManager = EffectsManager.getInstance();
            _effectsManager.setParent(_hud.parent as Sprite);
            
            // Initial render
            _castleView.render(_castleArchitect.state);
            _castlePanel.updateFromState(_castleArchitect.state, _currentStreak);
            
            if (DEBUG) {
                trace("Castle UI initialized");
            }
        }

        /**
         * Create stimulus display TextField (Week 1 placeholder)
         */
        private function createStimulusDisplay():void {
            _stimulusDisplay = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 80;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = "center";
            
            _stimulusDisplay.defaultTextFormat = format;
            _stimulusDisplay.width = 400;
            _stimulusDisplay.height = 100;
            
            // Position at center of actual stage
            if (_hud.parent && _hud.parent.stage) {
                _stimulusDisplay.x = (_hud.parent.stage.stageWidth - 400) / 2;
                _stimulusDisplay.y = (_hud.parent.stage.stageHeight - 100) / 2;
            } else {
                // Fallback positioning
                _stimulusDisplay.x = 40;
                _stimulusDisplay.y = 100;
            }
            
            _stimulusDisplay.selectable = false;
            _stimulusDisplay.visible = false;
            
            // Add to HUD's parent (stage)
            if (_hud.parent) {
                _hud.parent.addChild(_stimulusDisplay);
            }
        }

        /**
         * Create user input display TextField (shows input as user clicks)
         */
        private function createUserInputDisplay():void {
            _userInputDisplay = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 40;
            format.color = 0x00FF00; // Green color
            format.bold = true;
            format.align = "center";
            
            _userInputDisplay.defaultTextFormat = format;
            _userInputDisplay.width = 600;
            _userInputDisplay.height = 60;
            
            // Position below center
            if (_hud.parent && _hud.parent.stage) {
                _userInputDisplay.x = (_hud.parent.stage.stageWidth - 600) / 2;
                _userInputDisplay.y = (_hud.parent.stage.stageHeight / 2) + 80;
            } else {
                _userInputDisplay.x = 40;
                _userInputDisplay.y = 180;
            }
            
            _userInputDisplay.selectable = false;
            _userInputDisplay.visible = false;
            _userInputDisplay.text = "Your input: ";
            
            // Add to HUD's parent (stage)
            if (_hud.parent) {
                _hud.parent.addChild(_userInputDisplay);
            }
        }

        /**
         * Start next trial (public method called from HUD START button or NEXT button)
         */
        public function startNextTrial():void {
            createNextTrialButton();
            startNewTrial();
        }

        /**
         * Create the Next Trial button (only if not already created)
         */
        private function createNextTrialButton():void {
            // Only create once
            if (_nextTrialButton) {
                return;
            }

            // Create button graphics
            var upState:Sprite = createButtonState("Next Trial", 0x4CAF50);
            var overState:Sprite = createButtonState("Next Trial", 0x66BB6A);
            var downState:Sprite = createButtonState("Next Trial", 0x388E3C);

            _nextTrialButton = new SimpleButton(upState, overState, downState, upState);
            
            // Position using actual stage dimensions
            if (_hud.parent && _hud.parent.stage) {
                _nextTrialButton.x = (_hud.parent.stage.stageWidth - _nextTrialButton.width) / 2;
                _nextTrialButton.y = _hud.parent.stage.stageHeight - 100;
            } else {
                _nextTrialButton.x = 175;
                _nextTrialButton.y = 200;
            }
            
            _nextTrialButton.addEventListener(MouseEvent.CLICK, onNextTrialClick);
            _nextTrialButton.visible = false;

            // Add to HUD's parent (stage)
            if (_hud.parent) {
                _hud.parent.addChild(_nextTrialButton);
            }
        }

        /**
         * Create button state sprite
         * @param text Button text
         * @param color Background color
         * @return Sprite for button state
         */
        private function createButtonState(text:String, color:uint):Sprite {
            var sprite:Sprite = new Sprite();

            // Background
            sprite.graphics.beginFill(color);
            sprite.graphics.drawRoundRect(0, 0, 150, 40, 10);
            sprite.graphics.endFill();

            // Text
            var tf:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 16;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = "center";

            tf.defaultTextFormat = format;
            tf.text = text;
            tf.width = 150;
            tf.height = 40;
            tf.selectable = false;
            tf.x = 0;
            tf.y = 10;

            sprite.addChild(tf);
            return sprite;
        }

        /**
         * Enter a new FSM state
         * @param newState State to enter
         */
        private function enterState(newState:String):void {
            if (DEBUG) {
                trace("Entering state: " + newState);
            }
            _currentState = newState;

            switch (newState) {
                case STATE_IDLE:
                    onEnterIdle();
                    break;
                case STATE_STIMULUS:
                    onEnterStimulus();
                    break;
                case STATE_INPUT:
                    onEnterInput();
                    break;
                case STATE_RESULT:
                    onEnterResult();
                    break;
                case STATE_NEXT:
                    onEnterNext();
                    break;
            }
        }

        /**
         * Handle IDLE state entry
         */
        private function onEnterIdle():void {
            _hud.setStateText("Ready");
            _hud.setInstructionText("Tekan tombol apapun atau tap untuk memulai tantangan!");
            // Don't show next trial button in IDLE state - it's shown via HUD START button
        }

        /**
         * Map HUD level to question combination and level
         * Level 1-3: 4 digits (Easy, Medium, Hard)
         * Level 4-6: 6 digits (Easy, Medium, Hard)
         * Level 7-9: 8 digits (Easy, Medium, Hard)
         */
        private function getQuestionSettingsFromLevel(hudLevel:int):Object {
            var settings:Object = {
                combination: NumberQuestion.COMBO_4,
                level: NumberQuestion.LEVEL_EASY
            };
            
            if (hudLevel <= 3) {
                settings.combination = NumberQuestion.COMBO_4;
            } else if (hudLevel <= 6) {
                settings.combination = NumberQuestion.COMBO_6;
            } else {
                settings.combination = NumberQuestion.COMBO_8;
            }
            
            var levelMod:int = (hudLevel - 1) % 3;
            if (levelMod == 0) {
                settings.level = NumberQuestion.LEVEL_EASY;
            } else if (levelMod == 1) {
                settings.level = NumberQuestion.LEVEL_MEDIUM;
            } else {
                settings.level = NumberQuestion.LEVEL_HARD;
            }
            
            return settings;
        }

        /**
         * Handle STIMULUS state entry - NEW QUESTION SYSTEM
         */
        private function onEnterStimulus():void {
            _hud.setStateText("Ingat!");
            if (_nextTrialButton) {
                _nextTrialButton.visible = false;
            }
            
            // Record trial start time
            _trialStartTime = new Date().getTime();

            // Get question settings based on HUD level
            var settings:Object = getQuestionSettingsFromLevel(_hud.getLevel());
            
            // Generate NEW question using QuestionGenerator
            _currentQuestion = _questionGenerator.generate(settings.combination, settings.level);
            _hud.setSpan(_currentQuestion.combination);

            if (DEBUG) {
                trace("========== STIMULUS PHASE (NEW SYSTEM) ==========");
                trace("HUD Level: " + _hud.getLevel() + " -> Combo: " + settings.combination + ", Difficulty: " + settings.level);
                trace("Combination: " + _currentQuestion.combination + " angka");
                trace("Level: " + _currentQuestion.getLevelName());
                trace("Original sequence: [" + _currentQuestion.originalSequence.join(", ") + "]");
                trace("Displayed (sorted): [" + _currentQuestion.displayedSequence.join(", ") + "]");
                trace("Correct answer: [" + _currentQuestion.correctAnswer.join(", ") + "]");
                trace("Instruction: " + _currentQuestion.instruction);
                trace("================================================");
            }

            // Show instruction based on level
            var levelProgress:String = "Level " + _hud.getLevel() + " | " + _currentQuestion.combination + " angka | " + _currentQuestion.getLevelName();
            _hud.setInstructionText(levelProgress + "\nINGAT URUTAN angka-angka ini!");

            // Show the ORIGINAL sequence (what user needs to remember)
            _stimulusDisplay.text = _currentQuestion.originalSequence.join("  ");
            _stimulusDisplay.visible = true;
            
            // Format stimulus display
            formatStimulusDisplay();

            // Show numbers for time based on combination
            var displayTime:int = 2000 + (_currentQuestion.combination * 500); // 4s for 4 digits, 5s for 6, 6s for 8
            
            _stimulusTimer = new Timer(displayTime, 1);
            _stimulusTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onStimulusComplete);
            _stimulusTimer.start();
            
            if (DEBUG) {
                trace("Display time: " + displayTime + "ms");
            }
        }
        
        /**
         * Format the stimulus display for better visibility
         */
        private function formatStimulusDisplay():void {
            var format:TextFormat = new TextFormat();
            format.size = 36;
            format.bold = true;
            format.color = 0xFFFFFF;
            format.align = TextFormatAlign.CENTER;
            format.letterSpacing = 8;
            _stimulusDisplay.setTextFormat(format);
        }
        
        /**
         * Handle stimulus display complete - move to input phase
         */
        private function onStimulusComplete(event:TimerEvent):void {
            if (_stimulusTimer) {
                _stimulusTimer.stop();
                _stimulusTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onStimulusComplete);
                _stimulusTimer = null;
            }
            _stimulusDisplay.visible = false;
            
            if (DEBUG) {
                trace("Stimulus display complete, moving to INPUT phase");
            }
            
            enterState(STATE_INPUT);
        }

        // Legacy methods kept for compatibility (not used in new system)
        private function showCurrentStimulus():void {
            // Legacy - not used in new question system
        }

        private function onStimulusTick(event:TimerEvent):void {
            // Legacy - not used in new question system
        }

        /**
         * Handle INPUT state entry - NEW QUESTION SYSTEM
         */
        private function onEnterInput():void {
            _hud.setStateText("Jawab! [" + _currentQuestion.getLevelName() + "]");
            
            // Show instruction based on level with more detail
            var levelInfo:String = "Level " + _hud.getLevel() + " (" + _currentQuestion.combination + " angka - " + _currentQuestion.getLevelName() + ")\n";
            _hud.setInstructionText(levelInfo + _currentQuestion.instruction);
            
            // Record input start time
            _inputStartTime = new Date().getTime();

            // Reset user answer array
            _userAnswerArray = [];

            // Show user input display
            _userInputDisplay.text = "Jawaban: ";
            _userInputDisplay.visible = true;

            if (DEBUG) {
                trace("onEnterInput - Question combination: " + _currentQuestion.combination);
                trace("Showing 10 input buttons (numbers 0-9)");
            }

            // Start input collection with 10 buttons (numbers 0-9)
            // Timeout based on question timeLimit
            var timeout:int = _currentQuestion.timeLimit * 1000;
            _inputManager.startInputPhase(onInputReceived, onInputTimeout, timeout, onButtonClicked, 10);
        }

        /**
         * Handle each button click (update display) - NEW SYSTEM
         * Numbers are 0-9, no conversion needed
         */
        private function onButtonClicked(buffer:Vector.<int>):void {
            _userAnswerArray = [];
            var displayArray:Array = [];
            for each (var id:int in buffer) {
                _userAnswerArray.push(id); // Numbers are already 0-9
                displayArray.push(String(id));
            }
            _userInputDisplay.text = "Jawaban: " + displayArray.join(", ");
            
            if (DEBUG) {
                trace("Current answer buffer: " + displayArray.join(", "));
            }
            
            // Auto-submit when enough numbers entered
            if (_userAnswerArray.length >= _currentQuestion.combination) {
                if (DEBUG) {
                    trace("Auto-submitting - answer complete");
                }
                // Small delay before auto-submit
                var submitTimer:Timer = new Timer(300, 1);
                submitTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
                    submitTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, arguments.callee);
                    _inputManager.forceSubmit();
                });
                submitTimer.start();
            }
        }

        /**
         * Handle input received - NEW SYSTEM
         * @param input User input buffer (numbers 0-9)
         */
        private function onInputReceived(input:Vector.<int>):void {
            // Copy to array - numbers are already 0-9
            _userAnswerArray = [];
            for each (var id:int in input) {
                _userAnswerArray.push(id); // Numbers are already 0-9
            }
            
            // Hide user input display
            _userInputDisplay.visible = false;
            
            if (DEBUG) {
                trace("========== VALIDATION (NEW SYSTEM) ==========");
                trace("User answer: [" + _userAnswerArray.join(", ") + "]");
                trace("Correct answer: [" + _currentQuestion.correctAnswer.join(", ") + "]");
            }

            // Validate using new question system
            var validationResult:Object = _currentQuestion.validateAnswer(_userAnswerArray);
            _isCorrect = validationResult.isCorrect;
            
            if (DEBUG) {
                trace("Validation result: " + (_isCorrect ? "CORRECT" : "INCORRECT"));
                trace("Correct count: " + validationResult.correctCount + "/" + validationResult.totalCount);
                trace("Accuracy: " + Math.round(validationResult.accuracy * 100) + "%");
                if (validationResult.errors.length > 0) {
                    trace("Errors: " + validationResult.errors.join("; "));
                }
                trace("=============================================");
            }

            enterState(STATE_RESULT);
        }

        /**
         * Handle input timeout
         */
        private function onInputTimeout():void {
            _userAnswerArray = [];
            _isCorrect = false;
            if (DEBUG) {
                trace("Input timeout - incorrect");
            }
            enterState(STATE_RESULT);
        }

        /**
         * Handle RESULT state entry - NEW SYSTEM
         */
        private function onEnterResult():void {
            _trialCount++;
            var now:Number = new Date().getTime();
            
            // Calculate reaction time
            var reactionTime:Number = now - _inputStartTime;
            var totalTime:Number = now - _trialStartTime;
            
            // Update streak
            if (_isCorrect) {
                _currentStreak++;
            } else {
                _currentStreak = 0;
            }

            // Build comparison text using NEW question system
            var expectedIds:Array = [];
            for each (var num:* in _currentQuestion.correctAnswer) {
                expectedIds.push(String(num));
            }
            var userIds:Array = [];
            for each (var userNum:* in _userAnswerArray) {
                userIds.push(String(userNum));
            }
            
            // Create TrialResult for castle system
            var trialResult:TrialResult = new TrialResult();
            trialResult.isCorrect = _isCorrect;
            trialResult.reactionTime = reactionTime;
            trialResult.totalTime = totalTime;
            trialResult.sequenceLength = _currentQuestion.combination;
            trialResult.difficulty = _hud.getLevel();
            trialResult.expected = expectedIds;
            trialResult.actual = userIds;
            trialResult.streakAfter = _currentStreak;
            trialResult.totalItems = _currentQuestion.combination;
            trialResult.correctItems = _isCorrect ? _currentQuestion.combination : countCorrectItemsNew();
            trialResult.accuracy = trialResult.totalItems > 0 ? trialResult.correctItems / trialResult.totalItems : 0;
            
            // Calculate score using difficulty multiplier from question
            var baseScore:int = CastleConfig.calculateTrialPoints(_isCorrect, _currentStreak, _hud.getLevel());
            trialResult.scoreEarned = Math.floor(baseScore * _currentQuestion.getDifficultyMultiplier());
            
            // Apply to castle system
            var buildEvents:Vector.<BuildEvent> = _castleArchitect.applyTrialResult(trialResult);
            
            // Record in metrics
            _metricsManager.recordTrial(trialResult);
            
            // Process build events for effects
            processBuildEvents(buildEvents, trialResult.scoreEarned);
            
            // Update castle view and panel
            updateCastleDisplay();
            
            // Build comparison text for display - show original sequence that was displayed
            var comparisonText:String = "\nDitampilkan: [" + _currentQuestion.originalSequence.join(", ") + "]" +
                                       "\nJawaban benar: [" + expectedIds.join(", ") + "]" + 
                                       "\nJawaban Anda: [" + userIds.join(", ") + "]";

            if (_isCorrect) {
                _hud.setScore(_hud.getScore() + 1);
                _correctAnswersAtCurrentLevel++;
                
                // Check for level up
                if (_correctAnswersAtCurrentLevel >= CORRECT_ANSWERS_TO_LEVEL_UP) {
                    var currentLevel:int = _hud.getLevel();
                    if (currentLevel < 9) { // Max level is 9 (8 digits HARD)
                        _hud.setLevel(currentLevel + 1);
                        _correctAnswersAtCurrentLevel = 0;
                        _hud.setStateText("LEVEL UP! +" + trialResult.scoreEarned + " pts");
                        _hud.setInstructionText("Luar biasa! Naik ke Level " + (currentLevel + 1) + "!" + comparisonText);
                        if (DEBUG) {
                            trace("=== LEVEL UP! Now at level " + (currentLevel + 1) + " ===");
                        }
                    } else {
                        _hud.setStateText("Benar! +" + trialResult.scoreEarned + " pts");
                        _hud.setInstructionText("SEMPURNA! Level maksimum tercapai!" + comparisonText);
                    }
                } else {
                    var remaining:int = CORRECT_ANSWERS_TO_LEVEL_UP - _correctAnswersAtCurrentLevel;
                    _hud.setStateText("Benar! +" + trialResult.scoreEarned + " pts");
                    _hud.setInstructionText("Bagus! " + remaining + " jawaban benar lagi untuk naik level." + comparisonText);
                }
                
                if (DEBUG) {
                    trace("Trial " + _trialCount + ": CORRECT - +" + trialResult.scoreEarned + " pts, Streak: " + _currentStreak);
                    trace("Correct at this level: " + _correctAnswersAtCurrentLevel + "/" + CORRECT_ANSWERS_TO_LEVEL_UP);
                }
            } else {
                // Reset progress at current level on wrong answer
                _correctAnswersAtCurrentLevel = 0;
                _hud.setStateText("Salah");
                _hud.setInstructionText("Coba lagi! Progress level direset." + comparisonText);
                if (DEBUG) {
                    trace("Trial " + _trialCount + ": INCORRECT - Streak reset, level progress reset");
                }
            }

            // Auto-advance to next state after delay
            _autoAdvanceTimer.start();
        }
        
        /**
         * Count correct items for partial accuracy - NEW SYSTEM
         */
        private function countCorrectItemsNew():int {
            var count:int = 0;
            var correctAnswer:Array = _currentQuestion.correctAnswer;
            var minLen:int = Math.min(correctAnswer.length, _userAnswerArray.length);
            for (var i:int = 0; i < minLen; i++) {
                if (correctAnswer[i] == _userAnswerArray[i]) {
                    count++;
                }
            }
            return count;
        }
        
        /**
         * Process build events and show effects
         */
        private function processBuildEvents(events:Vector.<BuildEvent>, score:int):void {
            if (!_effectsManager || !_castleView) return;
            
            var centerPos:* = _castleView.getCenter();
            var cx:Number = _castleView.x + centerPos.x;
            var cy:Number = _castleView.y + centerPos.y;
            
            for each (var event:BuildEvent in events) {
                switch (event.type) {
                    case BuildEvent.TYPE_PART_ADDED:
                        _effectsManager.playConstructionEffect(cx, cy, event.part.type);
                        _metricsManager.recordPartBuilt();
                        break;
                        
                    case BuildEvent.TYPE_PART_UPGRADED:
                        _effectsManager.playUpgradeEffect(cx, cy, event.part.tier);
                        _metricsManager.recordPartUpgraded();
                        break;
                        
                    case BuildEvent.TYPE_PART_DAMAGED:
                        _effectsManager.playDamageEffect(cx, cy, event.scoreDelta);
                        break;
                        
                    case BuildEvent.TYPE_MILESTONE_REACHED:
                        _effectsManager.showMilestoneNotification(event.milestoneId, cx, cy - 40);
                        if (_castlePanel) {
                            _castlePanel.showMilestoneReached(event.milestoneId);
                        }
                        break;
                }
            }
            
            // Show score popup for correct answers
            if (score > 0) {
                _effectsManager.playCorrectEffect(cx, cy - 20, score);
                
                // Show streak effect for streaks of 3+
                if (_currentStreak >= 3) {
                    _effectsManager.playStreakEffect(cx, cy - 60, _currentStreak);
                }
            }
        }
        
        /**
         * Update castle display
         */
        private function updateCastleDisplay():void {
            if (_castleView) {
                _castleView.render(_castleArchitect.state);
            }
            if (_castlePanel) {
                _castlePanel.updateFromState(_castleArchitect.state, _currentStreak);
            }
        }

        /**
         * Handle NEXT state entry
         */
        private function onEnterNext():void {
            _hud.setStateText("Next Trial");
            _hud.setInstructionText("Get ready for the next sequence...");
            if (_nextTrialButton) {
                _nextTrialButton.visible = true;
            }
        }

        /**
         * Handle next trial button click
         */
        private function onNextTrialClick(event:MouseEvent):void {
            if (_currentState == STATE_IDLE || _currentState == STATE_NEXT) {
                startNewTrial();
            }
        }

        /**
         * Handle auto-advance timer
         */
        private function onAutoAdvance(event:TimerEvent):void {
            if (_currentState == STATE_RESULT) {
                enterState(STATE_NEXT);
            }
        }

        /**
         * Start a new trial
         */
        private function startNewTrial():void {
            enterState(STATE_STIMULUS);
        }

        /**
         * Get current FSM state
         * @return Current state
         */
        public function getCurrentState():String {
            return _currentState;
        }

        /**
         * Force state transition (for debugging)
         * @param state State to enter
         */
        public function forceState(state:String):void {
            enterState(state);
        }
    }
}