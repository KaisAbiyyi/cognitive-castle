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
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import flash.utils.getTimer;
    import domain.StimulusItem;
    import generation.SequenceGenerator;
    
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
        
        // States
        private static const STATE_STIMULUS:String = "stimulus";
        private static const STATE_INPUT:String = "input";
        private static const STATE_RESULT:String = "result";
        
        // Dimensions
        private var _popupWidth:Number = 400;
        private var _popupHeight:Number = 380;
        
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
        
        // Game components
        private var _sequenceGenerator:SequenceGenerator;
        private var _currentSequence:Vector.<StimulusItem>;
        private var _userInput:Vector.<int>;
        private var _currentState:String;
        private var _currentDifficulty:int = 1;
        
        // Timers
        private var _stimulusTimer:Timer;
        private var _currentStimulusIndex:int = 0;
        private var _resultTimer:Timer;
        
        // Input phase timer
        private var _inputTimer:Timer;
        private var _inputStartTime:int;
        private var _inputTotalTime:int; // Total milliseconds for input phase
        
        // Stage reference
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        /**
         * Constructor
         */
        public function TrialPopup() {
            _sequenceGenerator = new SequenceGenerator();
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
            format.size = 16;
            format.color = 0x666666;
            format.align = TextFormatAlign.CENTER;
            
            _stateText.defaultTextFormat = format;
            _stateText.width = _popupWidth;
            _stateText.height = 30;
            _stateText.selectable = false;
            _stateText.x = _background.x;
            _stateText.y = _background.y + 55;
            
            addChild(_stateText);
        }
        
        /**
         * Create stimulus display
         */
        private function createStimulusDisplay():void {
            _stimulusDisplay = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 72;
            format.color = 0x333333;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            _stimulusDisplay.defaultTextFormat = format;
            _stimulusDisplay.width = _popupWidth;
            _stimulusDisplay.height = 100;
            _stimulusDisplay.selectable = false;
            _stimulusDisplay.x = _background.x;
            _stimulusDisplay.y = _background.y + 90;
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
            format.size = 24;
            format.color = 0x4A90E2;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            _inputDisplay.defaultTextFormat = format;
            _inputDisplay.width = _popupWidth;
            _inputDisplay.height = 40;
            _inputDisplay.selectable = false;
            _inputDisplay.x = _background.x;
            _inputDisplay.y = _background.y + 85;
            _inputDisplay.visible = false;
            
            addChild(_inputDisplay);
        }
        
        /**
         * Create timer bar
         */
        private function createTimerBar():void {
            _timerBarContainer = new Sprite();
            _timerBarContainer.visible = false;
            
            var barWidth:Number = _popupWidth - 60;
            var barHeight:Number = 20;
            
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
            
            _timerBarContainer.x = _background.x + 30;
            _timerBarContainer.y = _background.y + 125;
            
            addChild(_timerBarContainer);
        }
        
        /**
         * Update timer bar fill
         */
        private function updateTimerBar(progress:Number):void {
            var barWidth:Number = _popupWidth - 60;
            var barHeight:Number = 20;
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
            _inputButtonsContainer.y = _background.y + 160;
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
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
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
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            }
            
            dispatchEvent(new Event(TRIAL_CLOSED));
        }
        
        /**
         * Handle keyboard input
         */
        private function onKeyDown(e:KeyboardEvent):void {
            if (_currentState != STATE_INPUT) return;
            
            // Check for number keys 1-9 (keycodes 49-57 for top row, 97-105 for numpad)
            var keyNum:int = -1;
            
            // Top row numbers (1-9)
            if (e.keyCode >= 49 && e.keyCode <= 57) {
                keyNum = e.keyCode - 49; // 0-8
            }
            // Numpad numbers (1-9)
            else if (e.keyCode >= 97 && e.keyCode <= 105) {
                keyNum = e.keyCode - 97; // 0-8
            }
            
            // Only accept if within valid button range
            if (keyNum >= 0 && keyNum < _currentSequence.length) {
                processInput(keyNum);
                
                // Visual feedback on button
                if (keyNum < _inputButtons.length) {
                    flashButton(_inputButtons[keyNum]);
                }
                
                if (DEBUG) {
                    trace("[TrialPopup] Keyboard input: " + (keyNum + 1));
                }
            }
        }
        
        /**
         * Start new trial
         */
        private function startTrial():void {
            _userInput.length = 0;
            _currentState = STATE_STIMULUS;
            
            // Generate sequence
            _currentSequence = _sequenceGenerator.generateSequence(_currentDifficulty);
            
            if (DEBUG) {
                var seqIds:Array = [];
                for each (var item:StimulusItem in _currentSequence) {
                    seqIds.push(item.id);
                }
                trace("[TrialPopup] Starting trial with sequence: " + seqIds.join(", "));
                trace("[TrialPopup] Timer will be: " + (_currentSequence.length * SECONDS_PER_ITEM) + " seconds");
            }
            
            // Start stimulus phase
            enterStimulusPhase();
        }
        
        /**
         * Enter stimulus phase
         */
        private function enterStimulusPhase():void {
            _currentState = STATE_STIMULUS;
            _stateText.text = "Watch carefully...";
            _stimulusDisplay.visible = true;
            _inputDisplay.visible = false;
            _inputButtonsContainer.visible = false;
            _timerBarContainer.visible = false;
            
            // Show first stimulus
            _currentStimulusIndex = 0;
            showCurrentStimulus();
            
            // Timer for next stimuli
            _stimulusTimer = new Timer(1200);
            _stimulusTimer.addEventListener(TimerEvent.TIMER, onStimulusTick);
            _stimulusTimer.start();
        }
        
        /**
         * Show current stimulus
         */
        private function showCurrentStimulus():void {
            if (_currentStimulusIndex < _currentSequence.length) {
                var item:StimulusItem = _currentSequence[_currentStimulusIndex];
                _stimulusDisplay.text = String(item.id + 1);
                
                // Reset text color
                var format:TextFormat = _stimulusDisplay.getTextFormat();
                format.color = 0x333333;
                _stimulusDisplay.setTextFormat(format);
                
                if (DEBUG) {
                    trace("[TrialPopup] Showing stimulus " + (_currentStimulusIndex + 1) + "/" + _currentSequence.length);
                }
            }
        }
        
        /**
         * Handle stimulus timer tick
         */
        private function onStimulusTick(e:TimerEvent):void {
            _currentStimulusIndex++;
            
            if (_currentStimulusIndex < _currentSequence.length) {
                showCurrentStimulus();
            } else {
                // Done showing stimuli
                stopTimers();
                enterInputPhase();
            }
        }
        
        /**
         * Enter input phase
         */
        private function enterInputPhase():void {
            _currentState = STATE_INPUT;
            _stateText.text = "Enter the sequence (use keyboard 1-" + _currentSequence.length + " or click):";
            _stimulusDisplay.visible = false;
            _inputDisplay.visible = true;
            _inputDisplay.text = "Your input: ";
            _inputButtonsContainer.visible = true;
            _timerBarContainer.visible = true;
            
            // Create input buttons matching sequence length
            createInputButtonsForSequence(_currentSequence.length);
            
            // Start input timer
            _inputTotalTime = _currentSequence.length * SECONDS_PER_ITEM * 1000; // Convert to milliseconds
            _inputStartTime = getTimer();
            
            // Update timer bar
            updateTimerBar(1.0);
            
            // Start timer update loop
            _inputTimer = new Timer(TIMER_UPDATE_INTERVAL);
            _inputTimer.addEventListener(TimerEvent.TIMER, onInputTimerTick);
            _inputTimer.start();
            
            if (DEBUG) {
                trace("[TrialPopup] Input phase started. Time limit: " + (_inputTotalTime / 1000) + "s");
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
            
            var buttonSize:int = 50;
            var spacing:int = 10;
            var totalWidth:int = numButtons * buttonSize + (numButtons - 1) * spacing;
            var startX:int = (_popupWidth - totalWidth) / 2;
            
            for (var i:int = 0; i < numButtons; i++) {
                var btn:Sprite = new Sprite();
                var g:Graphics = btn.graphics;
                
                g.beginFill(0x4A90E2);
                g.lineStyle(2, 0x357ABD);
                g.drawRoundRect(0, 0, buttonSize, buttonSize, 10, 10);
                g.endFill();
                
                // Number label
                var label:TextField = new TextField();
                var format:TextFormat = new TextFormat();
                format.font = "Arial";
                format.size = 24;
                format.color = 0xFFFFFF;
                format.bold = true;
                format.align = TextFormatAlign.CENTER;
                
                label.defaultTextFormat = format;
                label.text = String(i + 1);
                label.width = buttonSize;
                label.height = buttonSize;
                label.y = 10;
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
            hintText.text = "Press keys 1-" + numButtons + " on keyboard";
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
         */
        private function processInput(buttonId:int):void {
            _userInput.push(buttonId);
            updateInputDisplay();
            
            if (DEBUG) {
                trace("[TrialPopup] Input: " + (buttonId + 1) + " | Buffer: " + getUserInputDisplay());
            }
            
            // Check if input complete
            if (_userInput.length >= _currentSequence.length) {
                stopTimers();
                validateInput();
            }
        }
        
        /**
         * Get user input as display string
         */
        private function getUserInputDisplay():String {
            var arr:Array = [];
            for each (var id:int in _userInput) {
                arr.push(String(id + 1));
            }
            return arr.join(", ");
        }
        
        /**
         * Update input display
         */
        private function updateInputDisplay():void {
            _inputDisplay.text = "Your input: " + getUserInputDisplay();
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
         * Validate user input
         */
        private function validateInput():void {
            _currentState = STATE_RESULT;
            _inputButtonsContainer.visible = false;
            _timerBarContainer.visible = false;
            
            var isCorrect:Boolean = true;
            for (var i:int = 0; i < _currentSequence.length; i++) {
                if (i >= _userInput.length || _currentSequence[i].id != _userInput[i]) {
                    isCorrect = false;
                    break;
                }
            }
            
            if (DEBUG) {
                trace("[TrialPopup] Validation result: " + (isCorrect ? "CORRECT" : "INCORRECT"));
            }
            
            showResult(isCorrect);
        }
        
        /**
         * Show result
         */
        private function showResult(isCorrect:Boolean):void {
            _stimulusDisplay.visible = true;
            _inputDisplay.visible = false;
            
            if (isCorrect) {
                _stateText.text = "Correct!";
                _stimulusDisplay.text = "✓";
                
                var formatCorrect:TextFormat = _stimulusDisplay.getTextFormat();
                formatCorrect.color = 0x48BB78;
                _stimulusDisplay.setTextFormat(formatCorrect);
                
                dispatchEvent(new Event(TRIAL_SUCCESS));
            } else {
                if (_stateText.text != "Time's Up!") {
                    _stateText.text = "Incorrect!";
                }
                _stimulusDisplay.text = "✗";
                
                var formatWrong:TextFormat = _stimulusDisplay.getTextFormat();
                formatWrong.color = 0xE53E3E;
                _stimulusDisplay.setTextFormat(formatWrong);
                
                dispatchEvent(new Event(TRIAL_FAIL));
            }
            
            // Show close button
            _closeButton.visible = true;
            
            // Auto close after short delay
            _resultTimer = new Timer(500, 1);
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
                _stimulusTimer = null;
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
         * Set difficulty level
         */
        public function setDifficulty(level:int):void {
            _currentDifficulty = level;
        }
        
        /**
         * Get current sequence for result processing
         */
        public function getCurrentSequence():Vector.<StimulusItem> {
            return _currentSequence;
        }
        
        /**
         * Get user input for result processing
         */
        public function getUserInput():Vector.<int> {
            return _userInput;
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
            _stimulusDisplay.y = _background.y + 90;
            
            // Reposition input display
            _inputDisplay.x = _background.x;
            _inputDisplay.y = _background.y + 85;
            
            // Reposition timer bar
            _timerBarContainer.x = _background.x + 30;
            _timerBarContainer.y = _background.y + 125;
            
            // Reposition input buttons container
            _inputButtonsContainer.x = _background.x;
            _inputButtonsContainer.y = _background.y + 160;
            
            // Reposition close button
            _closeButton.x = _background.x + _popupWidth - 40;
            _closeButton.y = _background.y + 10;
            
            if (DEBUG) {
                trace("[TrialPopup] Resized to " + stageWidth + "x" + stageHeight);
            }
        }
    }
}
