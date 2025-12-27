package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.geom.Matrix;
    import generation.NumberQuestion;
    import generation.QuestionGenerator;
    import game.ProgressionManager;
    import game.ProgressionResult;
    
    /**
     * UpgradePopup - Shows number sequence challenge with images
     */
    public class UpgradePopup extends Sprite {
        
        private static const DEBUG:Boolean = true;
        
        // Events
        public static const CHALLENGE_STARTED:String = "challengeStarted";
        public static const CHALLENGE_SUCCESS:String = "challengeSuccess";
        public static const CHALLENGE_FAIL:String = "challengeFail";
        public static const POPUP_CLOSED:String = "popupClosed";
        
        // State machine
        private static const STATE_SHOWING_NUMBERS:String = "showingNumbers";
        private static const STATE_SHOWING_INSTRUCTION:String = "showingInstruction";
        private static const STATE_INPUT:String = "input";
        private static const STATE_RESULT:String = "result";
        
        // Dimensions
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Visual components
        private var _overlay:Shape;
        private var _popupBitmap:Bitmap;
        private var _popupContainer:Sprite;
        private var _xButton:Sprite;
        private var _xButtonBitmap:Bitmap;
        private var _startButton:Sprite;
        private var _startButtonBitmap:Bitmap;
        private var _lastResult:Boolean = false;
        private var _correctPopup:Sprite;
        private var _correctPopupBitmap:Bitmap;
        private var _incorrectPopup:Sprite;
        private var _incorrectPopupBitmap:Bitmap;
        
        // Countdown timer
        private var _countdownTimer:Timer;
        private var _countdownSeconds:int;
        private var _countdownDisplay:Sprite;
        
        // Number display (images 1-9.png)
        private var _numberContainer:Sprite;
        private var _numberBitmaps:Vector.<Bitmap>;
        
        // Instruction display
        private var _instructionBitmap:Bitmap;
        
        // Input buttons (button1-9.png)
        private var _inputContainer:Sprite;
        private var _inputButtons:Vector.<Sprite>;
        
        // Question data
        private var _questionGenerator:QuestionGenerator;
        private var _progressionManager:ProgressionManager;
        private var _currentQuestion:NumberQuestion;
        private var _userInput:Vector.<int>;
        private var _currentState:String;
        private var _keyboardListenerAdded:Boolean = false;
        private var _currentLevel:int = 1;
        
        // Last progression result (for GameScreen to read)
        private var _lastProgressionResult:ProgressionResult;
        
        // Timers
        private var _displayTimer:Timer;
        private var _instructionTimer:Timer;
        
        // Result close timer (for showing notif after popup UI closes)
        private var _resultHideTimer:Timer;
        
        // Loaded assets cache
        private var _loadedNumbers:Object = {};
        private var _loadedButtons:Object = {};
        private var _loadedInstructions:Object = {};
        private var _loadedBackspace:Bitmap;
        private var _backspaceButton:Sprite;
        private var _assetsLoaded:Boolean = false;
        private var _assetsToLoad:int = 0;
        private var _assetsLoadedCount:int = 0;
        
        public function UpgradePopup() {
            _questionGenerator = QuestionGenerator.getInstance();
            _progressionManager = ProgressionManager.getInstance();
            _userInput = new Vector.<int>();
            _numberBitmaps = new Vector.<Bitmap>();
            _inputButtons = new Vector.<Sprite>();

            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
        }
        
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            createOverlay();
            createPopupContainer();
            loadAssets();
            
            visible = false;
        }
        
        private function createOverlay():void {
            _overlay = new Shape();
            var g:* = _overlay.graphics;
            g.beginFill(0x000000, 0.7);
            g.drawRect(0, 0, _stageWidth, _stageHeight);
            g.endFill();
            addChild(_overlay);
        }
        
        private function createPopupContainer():void {
            _popupContainer = new Sprite();
            addChild(_popupContainer);
            
            // Load popup background
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPopupLoaded);
            loader.load(new URLRequest("assets/images/Game/upgradePopup.png"));
        }
        
        private function onPopupLoaded(e:Event):void {
            _popupBitmap = Bitmap(e.target.content);
            _popupBitmap.smoothing = true;
            
            // Scale to fit (max 85% screen width)
            var maxWidth:Number = _stageWidth * 0.85;
            var maxHeight:Number = _stageHeight * 0.85;
            var scale:Number = Math.min(maxWidth / _popupBitmap.width, maxHeight / _popupBitmap.height);
            _popupBitmap.scaleX = scale;
            _popupBitmap.scaleY = scale;
            
            _popupContainer.addChildAt(_popupBitmap, 0);
            
            // Center popup
            _popupContainer.x = (_stageWidth - _popupBitmap.width) / 2;
            _popupContainer.y = (_stageHeight - _popupBitmap.height) / 2;
            
            // Create X button
            createXButton();
            
            // Create containers for numbers and inputs
            createNumberContainer();
            createInputContainer();
            
            // Create START button (after containers so we know popup size)
            createStartButton();
            
            // Position START button at popup center
            if (_startButton) {
                _startButton.x = _popupBitmap.width / 2;
                _startButton.y = _popupBitmap.height / 2;
            }
            
            // Create correct popup notification
            createCorrectPopup();
            createIncorrectPopup();
            
            // Create countdown timer display
            createCountdownDisplay();
            
            if (DEBUG) trace("[UpgradePopup] Popup loaded, size: " + _popupBitmap.width + "x" + _popupBitmap.height);
        }
        
        private function createXButton():void {
            _xButton = new Sprite();
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _xButtonBitmap = Bitmap(e.target.content);
                _xButtonBitmap.smoothing = true;
                
                // Scale X button to 120px (same as gear icon)
                var targetSize:Number = 120;
                var scale:Number = targetSize / _xButtonBitmap.width;
                _xButtonBitmap.scaleX = scale;
                _xButtonBitmap.scaleY = scale;
                
                // Center bitmap for proper scaling
                _xButtonBitmap.x = -_xButtonBitmap.width / 2;
                _xButtonBitmap.y = -_xButtonBitmap.height / 2;
                
                _xButton.addChild(_xButtonBitmap);
                
                // Position at top-right of popup (accounting for centered bitmap)
                _xButton.x = _popupBitmap.width - _xButtonBitmap.width / 2 - 20;
                _xButton.y = _xButtonBitmap.height / 2 + 20;
                
                _xButton.buttonMode = true;
                _xButton.addEventListener(MouseEvent.CLICK, onXButtonClick);
                addHoverEffect(_xButton);
                
                _popupContainer.addChild(_xButton);
            });
            loader.load(new URLRequest("assets/images/Game/xButton.png"));
        }
        
        private function createStartButton():void {
            _startButton = new Sprite();
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _startButtonBitmap = Bitmap(e.target.content);
                _startButtonBitmap.smoothing = true;
                
                // Scale START button - make it REALLY BIG (450px wide)
                var targetWidth:Number = 450;
                var scale:Number = targetWidth / _startButtonBitmap.width;
                _startButtonBitmap.scaleX = scale;
                _startButtonBitmap.scaleY = scale;
                
                // Center bitmap for proper scaling
                _startButtonBitmap.x = -_startButtonBitmap.width / 2;
                _startButtonBitmap.y = -_startButtonBitmap.height / 2;
                
                _startButton.addChild(_startButtonBitmap);
                
                _startButton.buttonMode = true;
                _startButton.addEventListener(MouseEvent.CLICK, onStartButtonClick);
                addHoverEffect(_startButton);
                
                _startButton.visible = false; // Hidden until show() is called
                
                if (DEBUG) trace("[UpgradePopup] START button loaded");
            });
            loader.load(new URLRequest("assets/images/Game/startButton.png"));
            
            _popupContainer.addChild(_startButton);
        }
        
        private function onStartButtonClick(e:MouseEvent):void {
            if (DEBUG) trace("[UpgradePopup] START button clicked");
            _startButton.visible = false;
            
            // Hide X button when challenge starts
            if (_xButton) {
                _xButton.visible = false;
            }
            
            dispatchEvent(new Event(CHALLENGE_STARTED));
            
            startChallenge();
        }
        
        private function createCorrectPopup():void {
            _correctPopup = new Sprite();
            _correctPopup.visible = false;
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _correctPopupBitmap = Bitmap(e.target.content);
                _correctPopupBitmap.smoothing = true;
                
                // Scale down to 30% for small notification
                _correctPopupBitmap.scaleX = 0.3;
                _correctPopupBitmap.scaleY = 0.3;
                
                _correctPopup.addChild(_correctPopupBitmap);
                
                if (DEBUG) trace("[UpgradePopup] Correct popup loaded");
            });
            loader.load(new URLRequest("assets/images/Game/correctPopup.png"));
            
            // Add to main container (not popup container) so it's outside the popup frame
            addChild(_correctPopup);
            
            // Position at top-left with margin
            _correctPopup.x = 20;
            _correctPopup.y = 20;
        }
        
        private function createIncorrectPopup():void {
            _incorrectPopup = new Sprite();
            _incorrectPopup.visible = false;
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _incorrectPopupBitmap = Bitmap(e.target.content);
                _incorrectPopupBitmap.smoothing = true;
                
                // Scale down to 30% for small notification
                _incorrectPopupBitmap.scaleX = 0.3;
                _incorrectPopupBitmap.scaleY = 0.3;
                
                _incorrectPopup.addChild(_incorrectPopupBitmap);
                
                if (DEBUG) trace("[UpgradePopup] Incorrect popup loaded");
            });
            loader.load(new URLRequest("assets/images/Game/incorrectPopup.png"));
            
            // Add to main container (not popup container) so it's outside the popup frame
            addChild(_incorrectPopup);
            
            // Position at top-left with margin
            _incorrectPopup.x = 20;
            _incorrectPopup.y = 20;
        }
        
        private function onXButtonClick(e:MouseEvent):void {
            hide();
        }
        
        private function createNumberContainer():void {
            _numberContainer = new Sprite();
            _numberContainer.y = 100; // Position below popup title
            _popupContainer.addChild(_numberContainer);
        }
        
        private function createInputContainer():void {
            _inputContainer = new Sprite();
            _inputContainer.y = _popupBitmap ? _popupBitmap.height - 200 : 400;
            _popupContainer.addChild(_inputContainer);
        }
        
        private function createCountdownDisplay():void {
            _countdownDisplay = new Sprite();
            _countdownDisplay.visible = false;
            _popupContainer.addChild(_countdownDisplay);
        }
        
        private function updateCountdownDisplay():void {
            // Clear previous display
            while (_countdownDisplay.numChildren > 0) {
                _countdownDisplay.removeChildAt(0);
            }
            
            // Get digits of countdown (e.g., 15 -> "1" "5")
            var timeStr:String = String(_countdownSeconds);
            var spacing:Number = 50;
            var totalWidth:Number = timeStr.length * spacing;
            
            for (var i:int = 0; i < timeStr.length; i++) {
                var digit:int = parseInt(timeStr.charAt(i));
                if (_loadedNumbers[digit]) {
                    var bitmap:Bitmap = new Bitmap(_loadedNumbers[digit].bitmapData);
                    bitmap.smoothing = true;
                    
                    // Scale to 50px height
                    var targetHeight:Number = 50;
                    var scale:Number = targetHeight / bitmap.height;
                    bitmap.scaleX = scale;
                    bitmap.scaleY = scale;
                    
                    bitmap.x = i * spacing;
                    bitmap.y = 0;
                    
                    _countdownDisplay.addChild(bitmap);
                }
            }
            
            // Position at top-right corner of popup frame
            _countdownDisplay.x = _popupBitmap.width - totalWidth - 40;
            _countdownDisplay.y = 30;
        }
        
        private function startCountdownTimer():void {
            // Calculate time based on sequence length (3 seconds per digit)
            _countdownSeconds = _currentQuestion.correctAnswer.length * 3;
            
            _countdownDisplay.visible = true;
            updateCountdownDisplay();
            
            // Update every second
            _countdownTimer = new Timer(1000);
            _countdownTimer.addEventListener(TimerEvent.TIMER, onCountdownTick);
            _countdownTimer.start();
        }
        
        private function onCountdownTick(e:TimerEvent):void {
            _countdownSeconds--;
            
            if (_countdownSeconds <= 0) {
                // Time's up - auto fail
                stopCountdownTimer();
                removeKeyboardListener();
                _countdownDisplay.visible = false;
                
                if (_currentState == STATE_INPUT) {
                    _currentState = STATE_RESULT;
                    _lastResult = false;
                    
                    // Process as wrong answer
                    _lastProgressionResult = _progressionManager.processWrong();
                    
                    dispatchEvent(new Event(CHALLENGE_FAIL));
                    
                    // Close popup UI immediately, then show fail notif
                    closePopupUIAndDispatchClosed();
                    if (_incorrectPopup) {
                        _incorrectPopup.visible = true;
                    }
                    
                    startResultHideTimer(1500);
                }
            } else {
                updateCountdownDisplay();
            }
        }
        
        private function stopCountdownTimer():void {
            if (_countdownTimer) {
                _countdownTimer.stop();
                _countdownTimer.removeEventListener(TimerEvent.TIMER, onCountdownTick);
                _countdownTimer = null;
            }
            if (_countdownDisplay) {
                _countdownDisplay.visible = false;
            }
        }
        
        private function loadAssets():void {
            // Preload all number images (0-9)
            for (var i:int = 0; i <= 9; i++) {
                _assetsToLoad++;
                loadNumberImage(i);
                _assetsToLoad++;
                loadButtonImage(i);
            }
            
            // Load instruction images
            var instructions:Array = ["inputSesuaiUrutan.png", "inputUrutanTerbalik.png", "inputTukarGenapGanjil.png"];
            for each (var inst:String in instructions) {
                _assetsToLoad++;
                loadInstructionImage(inst);
            }
            
            // Load backspace button
            _assetsToLoad++;
            loadBackspaceImage();
        }
        
        private function loadBackspaceImage():void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _loadedBackspace = Bitmap(e.target.content);
                onAssetLoaded();
            });
            loader.load(new URLRequest("assets/images/Game/buttonBackspace.png"));
        }
        
        private function loadNumberImage(num:int):void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _loadedNumbers[num] = Bitmap(e.target.content);
                onAssetLoaded();
            });
            loader.load(new URLRequest("assets/images/Game/" + num + ".png"));
        }
        
        private function loadButtonImage(num:int):void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _loadedButtons[num] = Bitmap(e.target.content);
                onAssetLoaded();
            });
            loader.load(new URLRequest("assets/images/Game/button" + num + ".png"));
        }
        
        private function loadInstructionImage(filename:String):void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _loadedInstructions[filename] = Bitmap(e.target.content);
                onAssetLoaded();
            });
            loader.load(new URLRequest("assets/images/Game/" + filename));
        }
        
        private function onAssetLoaded():void {
            _assetsLoadedCount++;
            if (_assetsLoadedCount >= _assetsToLoad) {
                _assetsLoaded = true;
                if (DEBUG) trace("[UpgradePopup] All assets loaded: " + _assetsLoadedCount);
            }
        }
        
        /**
         * Show popup with START button
         */
        public function show(level:int = 1):void {
            stopResultHideTimer();
            _currentLevel = level;
            visible = true;
            mouseEnabled = true;
            mouseChildren = true;
            
            // Ensure main popup UI is visible (it can be hidden during result notifications)
            if (_overlay) _overlay.visible = true;
            if (_popupContainer) _popupContainer.visible = true;
            clearDisplay();
            
            // Show START button and X button
            if (_startButton) {
                _startButton.visible = true;
            }
            if (_xButton) {
                _xButton.visible = true;
            }
            if (_correctPopup) {
                _correctPopup.visible = false;
            }
            if (_incorrectPopup) {
                _incorrectPopup.visible = false;
            }
        }
        
        public function hide(dispatchClosed:Boolean = true):void {
            stopResultHideTimer();
            visible = false;
            stopTimers();
            clearDisplay();
            removeKeyboardListener();
            
            if (_correctPopup) _correctPopup.visible = false;
            if (_incorrectPopup) _incorrectPopup.visible = false;
            
            if (dispatchClosed) {
                dispatchEvent(new Event(POPUP_CLOSED));
            }
        }
        
        private function stopResultHideTimer():void {
            if (_resultHideTimer) {
                _resultHideTimer.stop();
                _resultHideTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onResultHideTimerComplete);
                _resultHideTimer = null;
            }
        }
        
        private function closePopupUIAndDispatchClosed():void {
            stopTimers();
            clearDisplay();
            removeKeyboardListener();
            
            // Hide overlay + popup frame so the game immediately resumes
            if (_overlay) _overlay.visible = false;
            if (_popupContainer) _popupContainer.visible = false;
            
            // Don't block clicks while showing the small notif
            mouseEnabled = false;
            mouseChildren = false;
            
            dispatchEvent(new Event(POPUP_CLOSED));
        }
        
        private function startResultHideTimer(delayMs:int):void {
            stopResultHideTimer();
            _resultHideTimer = new Timer(delayMs, 1);
            _resultHideTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onResultHideTimerComplete);
            _resultHideTimer.start();
        }
        
        private function onResultHideTimerComplete(e:TimerEvent):void {
            if (_correctPopup) _correctPopup.visible = false;
            if (_incorrectPopup) _incorrectPopup.visible = false;
            hide(false);
        }
        
        private function startChallenge():void {
            _userInput.length = 0;
            
            // Get next question from ProgressionManager
            _currentQuestion = _progressionManager.getNextQuestion();
            
            if (DEBUG) {
                trace("[UpgradePopup] Question " + _progressionManager.currentQuestionNumber + 
                      " - Mode: " + _progressionManager.mode + 
                      ", Combo: " + _currentQuestion.combination + 
                      ", Difficulty: " + _currentQuestion.level);
                trace("[UpgradePopup] Sequence: " + _currentQuestion.originalSequence.join(", "));
                trace("[UpgradePopup] Answer: " + _currentQuestion.correctAnswer.join(", "));
            }
            
            // Show numbers first
            showNumbers();
        }
        
        private function getQuestionSettings():Object {
            // LEGACY - kept for backwards compatibility but not used anymore
            var settings:Object = { combination: 4, level: NumberQuestion.LEVEL_EASY };
            
            // Level 1-6: 4 digits, Level 7-12: 6 digits
            if (_currentLevel <= 6) {
                settings.combination = 4;
            } else {
                settings.combination = 6;
            }
            
            // Difficulty based on level mod
            var mod:int = (_currentLevel - 1) % 6;
            if (mod < 2) {
                settings.level = NumberQuestion.LEVEL_EASY;
            } else if (mod < 4) {
                settings.level = NumberQuestion.LEVEL_MEDIUM;
            } else {
                settings.level = NumberQuestion.LEVEL_HARD;
            }
            
            return settings;
        }
        
        private function showNumbers():void {
            _currentState = STATE_SHOWING_NUMBERS;
            clearDisplay();
            
            // Display number images - BIGGER and centered in frame
            var sequence:Array = _currentQuestion.originalSequence;
            var spacing:Number = 120;
            var totalWidth:Number = sequence.length * spacing;
            var startX:Number = (_popupBitmap.width - totalWidth) / 2;
            
            for (var i:int = 0; i < sequence.length; i++) {
                var num:int = sequence[i];
                if (_loadedNumbers[num]) {
                    var bitmap:Bitmap = new Bitmap(_loadedNumbers[num].bitmapData);
                    bitmap.smoothing = true;
                    
                    // Scale number - MUCH BIGGER (100px height)
                    var targetHeight:Number = 100;
                    var scale:Number = targetHeight / bitmap.height;
                    bitmap.scaleX = scale;
                    bitmap.scaleY = scale;
                    
                    bitmap.x = startX + i * spacing;
                    bitmap.y = 120;
                    
                    _numberContainer.addChild(bitmap);
                    _numberBitmaps.push(bitmap);
                }
            }
            
            // Timer to show instruction
            var displayTime:int = 2000 + sequence.length * 500;
            _displayTimer = new Timer(displayTime, 1);
            _displayTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onNumbersDisplayed);
            _displayTimer.start();
        }
        
        private function onNumbersDisplayed(e:TimerEvent):void {
            stopTimers();
            showInstruction();
        }
        
        private function showInstruction():void {
            _currentState = STATE_SHOWING_INSTRUCTION;
            clearDisplay();
            
            // Get instruction image based on level
            var instructionFile:String;
            switch (_currentQuestion.level) {
                case NumberQuestion.LEVEL_EASY:
                    instructionFile = "inputSesuaiUrutan.png";
                    break;
                case NumberQuestion.LEVEL_MEDIUM:
                    instructionFile = "inputUrutanTerbalik.png";
                    break;
                case NumberQuestion.LEVEL_HARD:
                    instructionFile = "inputTukarGenapGanjil.png";
                    break;
            }
            
            if (_loadedInstructions[instructionFile]) {
                _instructionBitmap = new Bitmap(_loadedInstructions[instructionFile].bitmapData);
                _instructionBitmap.smoothing = true;
                
                // Scale to fit nicely (not too big)
                var targetWidth:Number = _popupBitmap.width * 0.7;
                var scale:Number = targetWidth / _instructionBitmap.width;
                _instructionBitmap.scaleX = scale;
                _instructionBitmap.scaleY = scale;
                
                // Position in middle area of frame
                _instructionBitmap.x = (_popupBitmap.width - _instructionBitmap.width) / 2;
                _instructionBitmap.y = 160;
                
                _numberContainer.addChild(_instructionBitmap);
            }
            
            // Timer to show input
            _instructionTimer = new Timer(2000, 1);
            _instructionTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onInstructionDisplayed);
            _instructionTimer.start();
        }
        
        private function onInstructionDisplayed(e:TimerEvent):void {
            stopTimers();
            showInput();
        }
        
        private function showInput():void {
            _currentState = STATE_INPUT;
            clearDisplay();
            
            // Start countdown timer
            startCountdownTimer();
            
            // Create input buttons (0-9) - BIGGER and properly positioned
            var buttonSpacing:Number = 110;
            var buttonsPerRow:int = 5;
            var totalButtons:int = 10;
            
            for (var i:int = 0; i < totalButtons; i++) {
                var buttonNum:int = i; // 0-9
                var buttonSprite:Sprite = new Sprite();
                
                // Use button images for 0-9
                if (_loadedButtons[buttonNum]) {
                    var bitmap:Bitmap = new Bitmap(_loadedButtons[buttonNum].bitmapData);
                    bitmap.smoothing = true;
                    
                    // BIGGER buttons (100px)
                    var targetSize:Number = 100;
                    var scale:Number = targetSize / bitmap.width;
                    bitmap.scaleX = scale;
                    bitmap.scaleY = scale;
                    
                    // Center bitmap in sprite
                    bitmap.x = -bitmap.width / 2;
                    bitmap.y = -bitmap.height / 2;
                    
                    buttonSprite.addChild(bitmap);
                }
                
                // Position in grid - centered within frame
                var row:int = Math.floor(i / buttonsPerRow);
                var col:int = i % buttonsPerRow;
                var rowWidth:Number = Math.min(buttonsPerRow, totalButtons - row * buttonsPerRow) * buttonSpacing;
                var startX:Number = (_popupBitmap.width - rowWidth) / 2 + buttonSpacing / 2;
                
                buttonSprite.x = startX + col * buttonSpacing;
                buttonSprite.y = -150 + row * 110;
                
                buttonSprite.buttonMode = true;
                buttonSprite.name = String(buttonNum);
                buttonSprite.addEventListener(MouseEvent.CLICK, onInputButtonClick);
                addHoverEffect(buttonSprite);
                
                _inputContainer.addChild(buttonSprite);
                _inputButtons.push(buttonSprite);
            }
            
            // Create backspace button
            createBackspaceButton();
            
            // Add keyboard listener (stage-safe)
            addKeyboardListener();
            
            // Show current input display
            updateInputDisplay();
        }
        
        /**
         * Create backspace button
         */
        private function createBackspaceButton():void {
            _backspaceButton = new Sprite();
            
            if (_loadedBackspace) {
                var bitmap:Bitmap = new Bitmap(_loadedBackspace.bitmapData);
                bitmap.smoothing = true;
                
                // Same size as number buttons
                var targetSize:Number = 100;
                var scale:Number = targetSize / bitmap.width;
                bitmap.scaleX = scale;
                bitmap.scaleY = scale;
                
                bitmap.x = -bitmap.width / 2;
                bitmap.y = -bitmap.height / 2;
                
                _backspaceButton.addChild(bitmap);
            }
            
            // Position to the right of the second row - far right with more spacing
            _backspaceButton.x = (_popupBitmap.width / 2) + 350;
            _backspaceButton.y = -150 + 110; // Second row height
            
            _backspaceButton.buttonMode = true;
            _backspaceButton.name = "backspace";
            _backspaceButton.addEventListener(MouseEvent.CLICK, onBackspaceClick);
            addHoverEffect(_backspaceButton);
            
            _inputContainer.addChild(_backspaceButton);
        }
        
        /**
         * Handle backspace button click
         */
        private function onBackspaceClick(e:MouseEvent):void {
            deleteLastInput();
        }
        
        /**
         * Delete last input digit
         */
        private function deleteLastInput():void {
            if (_userInput.length > 0) {
                _userInput.pop();
                updateInputDisplay();
                
                if (DEBUG) {
                    trace("[UpgradePopup] Backspace - input now: " + _userInput.join(","));
                }
            }
        }
        
        /**
         * Handle keyboard input
         */
        private function onKeyDown(e:KeyboardEvent):void {
            if (_currentState != STATE_INPUT) return;
            
            var keyCode:int = e.keyCode;

            if (e.ctrlKey && e.shiftKey) {
                if (keyCode == Keyboard.Y) {
                    setUserInputFromArray(_currentQuestion ? _currentQuestion.correctAnswer : null);
                    updateInputDisplay();
                    checkAnswer();
                    return;
                }
                if (keyCode == Keyboard.X) {
                    var wrongInput:Array = _currentQuestion ? _currentQuestion.correctAnswer.concat() : [];
                    if (wrongInput.length > 0) {
                        wrongInput[0] = (wrongInput[0] + 1) % 10;
                    }
                    setUserInputFromArray(wrongInput);
                    updateInputDisplay();
                    checkAnswer();
                    return;
                }
            }
            
            // Number keys (0-9) - both regular and numpad
            if (keyCode >= Keyboard.NUMBER_0 && keyCode <= Keyboard.NUMBER_9) {
                // Regular number keys
                var num:int = keyCode - Keyboard.NUMBER_0;
                handleNumberInput(num);
            } else if (keyCode >= Keyboard.NUMPAD_0 && keyCode <= Keyboard.NUMPAD_9) {
                // Numpad keys
                var numpadNum:int = keyCode - Keyboard.NUMPAD_0;
                handleNumberInput(numpadNum);
            } else if (keyCode == Keyboard.BACKSPACE || keyCode == Keyboard.DELETE) {
                // Backspace or Delete
                deleteLastInput();
            } else if (keyCode == Keyboard.ENTER || keyCode == Keyboard.NUMPAD_ENTER) {
                // Enter to submit (if enough digits)
                if (_userInput.length >= _currentQuestion.correctAnswer.length) {
                    checkAnswer();
                }
            }
        }
        
        /**
         * Handle number input from keyboard
         */
        private function handleNumberInput(num:int):void {
            if (_currentState != STATE_INPUT) return;
            if (_userInput.length >= _currentQuestion.correctAnswer.length) return;
            
            _userInput.push(num);
            updateInputDisplay();
            
            // Check if input complete
            if (_userInput.length >= _currentQuestion.correctAnswer.length) {
                checkAnswer();
            }
        }

        private function setUserInputFromArray(values:Array):void {
            _userInput.length = 0;
            if (!values) return;
            
            for (var i:int = 0; i < values.length; i++) {
                _userInput.push(int(values[i]));
            }
        }
        
        /**
         * Add keyboard listener (AS3 requires explicit registration)
         */
        private function addKeyboardListener():void {
            if (stage && !_keyboardListenerAdded) {
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
                _keyboardListenerAdded = true;
            }
        }

        /**
         * Remove keyboard listener
         */
        private function removeKeyboardListener():void {
            if (stage && _keyboardListenerAdded) {
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
                _keyboardListenerAdded = false;
            }
        }

        private function onAddedToStage(event:Event):void {
            addKeyboardListener();
        }

        private function onRemovedFromStage(event:Event):void {
            removeKeyboardListener();
        }
        
        private function onInputButtonClick(e:MouseEvent):void {
            var num:int = int(e.currentTarget.name);
            _userInput.push(num);
            
            updateInputDisplay();
            
            // Check if input complete
            if (_userInput.length >= _currentQuestion.correctAnswer.length) {
                checkAnswer();
            }
        }
        
        private function updateInputDisplay():void {
            // Show what user has entered so far as number images
            // Clear previous input display
            while (_numberContainer.numChildren > 0) {
                _numberContainer.removeChildAt(0);
            }
            
            var spacing:Number = 80;
            var totalWidth:Number = _userInput.length * spacing;
            var startX:Number = (_popupBitmap.width - totalWidth) / 2;
            
            for (var i:int = 0; i < _userInput.length; i++) {
                var num:int = _userInput[i];
                if (_loadedNumbers[num]) {
                    var bitmap:Bitmap = new Bitmap(_loadedNumbers[num].bitmapData);
                    bitmap.smoothing = true;
                    
                    // Bigger input display (60px)
                    var targetHeight:Number = 60;
                    var scale:Number = targetHeight / bitmap.height;
                    bitmap.scaleX = scale;
                    bitmap.scaleY = scale;
                    
                    bitmap.x = startX + i * spacing;
                    bitmap.y = 100;
                    
                    _numberContainer.addChild(bitmap);
                }
            }
        }
        
        private function checkAnswer():void {
            _currentState = STATE_RESULT;
            
            // Stop countdown timer and remove keyboard listener
            stopCountdownTimer();
            removeKeyboardListener();
            
            var isCorrect:Boolean = true;
            var correctAnswer:Array = _currentQuestion.correctAnswer;
            
            for (var i:int = 0; i < correctAnswer.length; i++) {
                if (_userInput[i] != correctAnswer[i]) {
                    isCorrect = false;
                    break;
                }
            }
            
            if (DEBUG) {
                trace("[UpgradePopup] Answer check - User: " + _userInput.join(",") + " | Correct: " + correctAnswer.join(",") + " | Result: " + (isCorrect ? "CORRECT" : "WRONG"));
            }
            
            // Process result through ProgressionManager
            if (isCorrect) {
                _lastProgressionResult = _progressionManager.processCorrect();
            } else {
                _lastProgressionResult = _progressionManager.processWrong();
            }
            
            if (DEBUG) {
                trace("[UpgradePopup] Progression result: " + _lastProgressionResult.toString());
            }
            
            // Track and dispatch result
            _lastResult = isCorrect;
            if (isCorrect) {
                _currentLevel++;
                
                dispatchEvent(new Event(CHALLENGE_SUCCESS));
                
                // Close popup UI immediately, then show notif
                closePopupUIAndDispatchClosed();
                if (_correctPopup) {
                    _correctPopup.visible = true;
                }
                
                startResultHideTimer(1500);
            } else {
                dispatchEvent(new Event(CHALLENGE_FAIL));
                
                // Close popup UI immediately, then show notif
                closePopupUIAndDispatchClosed();
                if (_incorrectPopup) {
                    _incorrectPopup.visible = true;
                }
                
                startResultHideTimer(1500);
            }
        }
        
        /**
         * Get the last progression result (for GameScreen to read after CHALLENGE_SUCCESS/FAIL)
         */
        public function getLastProgressionResult():ProgressionResult {
            return _lastProgressionResult;
        }
        
        private function clearDisplay():void {
            while (_numberContainer.numChildren > 0) {
                _numberContainer.removeChildAt(0);
            }
            while (_inputContainer.numChildren > 0) {
                _inputContainer.removeChildAt(0);
            }
            _numberBitmaps.length = 0;
            _inputButtons.length = 0;
        }
        
        private function stopTimers():void {
            if (_displayTimer) {
                _displayTimer.stop();
                _displayTimer = null;
            }
            if (_instructionTimer) {
                _instructionTimer.stop();
                _instructionTimer = null;
            }
            stopCountdownTimer();
        }
        
        /**
         * Add smooth hover effect with center origin
         */
        private function addHoverEffect(target:Sprite):void {
            target.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
                // Scale from center
                var origX:Number = target.x;
                var origY:Number = target.y;
                target.scaleX = 1.15;
                target.scaleY = 1.15;
            });
            
            target.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
                target.scaleX = 1.0;
                target.scaleY = 1.0;
            });
        }
        
        /**
         * Get last trial result
         */
        public function getLastResult():Boolean {
            return _lastResult;
        }
        
        /**
         * Handle resize
         */
        public function onResize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            // Resize overlay
            if (_overlay) {
                _overlay.graphics.clear();
                _overlay.graphics.beginFill(0x000000, 0.7);
                _overlay.graphics.drawRect(0, 0, _stageWidth, _stageHeight);
                _overlay.graphics.endFill();
            }
            
            // Recenter popup
            if (_popupContainer && _popupBitmap) {
                _popupContainer.x = (_stageWidth - _popupBitmap.width) / 2;
                _popupContainer.y = (_stageHeight - _popupBitmap.height) / 2;
            }
        }
        
        // Getters
        public function get currentLevel():int { return _currentLevel; }
        public function set currentLevel(value:int):void { _currentLevel = value; }
    }
}
