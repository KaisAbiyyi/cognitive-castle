package ui {

    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.SimpleButton;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import core.Constants;
    import core.EventBus;
    import core.GameEvent;

    /**
     * HUD - Heads-Up Display component showing game state and instructions.
     * Displays score, level, phase instructions, input buffer, and countdown.
     *
     * SOLID Principles:
     * - Single Responsibility: Only handles UI display and updates
     * - Open/Closed: Can be extended with new display elements without changing existing code
     * - Interface Segregation: Provides focused UI update methods
     */
    public class HUD extends Sprite {

        // Text fields
        private var _scoreText:TextField;
        private var _levelText:TextField;
        private var _instructionText:TextField;
        private var _stateText:TextField;
        private var _startButton:flash.display.SimpleButton;
        
        // Input buffer display
        private var _inputBufferContainer:Sprite;
        private var _inputBufferSlots:Vector.<Sprite>;
        private var _inputBufferLabels:Vector.<TextField>;
        private var _maxBufferSlots:int = 12;
        
        // Countdown display
        private var _countdownContainer:Sprite;
        private var _countdownText:TextField;
        private var _countdownBar:Shape;
        private var _countdownBarBg:Shape;
        private var _totalTime:Number = 10000;
        
        // Feedback display
        private var _feedbackText:TextField;

        // Current values
        private var _currentScore:int = 0;
        private var _currentLevel:int = 1;
        private var _currentSpan:int = 2;

        // Stage dimensions
        private var _stageWidth:Number = 1920;
        private var _stageHeight:Number = 1080;

        // Layout constants
        private const PADDING:int = 20;
        private const FONT_SIZE:int = 24;
        private const SMALL_FONT_SIZE:int = 18;
        private const BUFFER_SLOT_SIZE:int = 40;
        private const BUFFER_SLOT_SPACING:int = 8;
        
        // Events
        public static const START_TRIAL:String = "startTrial";
        
        // Debug mode
        private static const DEBUG:Boolean = false;

        /**
         * Constructor
         */
        public function HUD() {
            _inputBufferSlots = new Vector.<Sprite>();
            _inputBufferLabels = new Vector.<TextField>();
            initializeTextFields();
            initializeInputBuffer();
            initializeCountdown();
            initializeFeedback();
        }

        /**
         * Initialize the HUD with stage dimensions
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            drawBackground(stageWidth, stageHeight);
            createStartButton(stageWidth, stageHeight);
            layoutComponents(stageWidth, stageHeight);
            updateDisplay();
        }

        /**
         * Initialize text field components
         */
        private function initializeTextFields():void {
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = FONT_SIZE;
            format.color = 0xFFFFFF;
            format.bold = true;

            var smallFormat:TextFormat = new TextFormat();
            smallFormat.font = "Arial";
            smallFormat.size = SMALL_FONT_SIZE;
            smallFormat.color = 0xFFFFFF;

            // Score display (top left)
            _scoreText = new TextField();
            _scoreText.defaultTextFormat = format;
            _scoreText.autoSize = TextFieldAutoSize.LEFT;
            _scoreText.selectable = false;
            addChild(_scoreText);

            // Level/Span display (top right)
            _levelText = new TextField();
            _levelText.defaultTextFormat = format;
            _levelText.autoSize = TextFieldAutoSize.RIGHT;
            _levelText.selectable = false;
            addChild(_levelText);

            // State text (center top)
            _stateText = new TextField();
            _stateText.defaultTextFormat = format;
            _stateText.autoSize = TextFieldAutoSize.CENTER;
            _stateText.selectable = false;
            addChild(_stateText);

            // Instruction text (bottom center)
            _instructionText = new TextField();
            _instructionText.defaultTextFormat = smallFormat;
            _instructionText.autoSize = TextFieldAutoSize.CENTER;
            _instructionText.multiline = true;
            _instructionText.wordWrap = true;
            _instructionText.selectable = false;
            addChild(_instructionText);
        }

        /**
         * Initialize input buffer display (shows user's entered sequence)
         */
        private function initializeInputBuffer():void {
            _inputBufferContainer = new Sprite();
            addChild(_inputBufferContainer);
            
            // Create slots for max buffer size
            for (var i:int = 0; i < _maxBufferSlots; i++) {
                // Slot background
                var slot:Sprite = new Sprite();
                slot.graphics.beginFill(0x333355, 0.6);
                slot.graphics.lineStyle(2, 0x555588, 1);
                slot.graphics.drawRoundRect(0, 0, BUFFER_SLOT_SIZE, BUFFER_SLOT_SIZE, 8, 8);
                slot.graphics.endFill();
                slot.visible = false;
                _inputBufferContainer.addChild(slot);
                _inputBufferSlots.push(slot);
                
                // Slot label (number)
                var label:TextField = new TextField();
                var format:TextFormat = new TextFormat();
                format.font = "Arial";
                format.size = 20;
                format.color = 0xFFFFFF;
                format.bold = true;
                format.align = TextFormatAlign.CENTER;
                label.defaultTextFormat = format;
                label.width = BUFFER_SLOT_SIZE;
                label.height = BUFFER_SLOT_SIZE;
                label.y = 8;
                label.selectable = false;
                label.mouseEnabled = false;
                label.visible = false;
                slot.addChild(label);
                _inputBufferLabels.push(label);
            }
        }
        
        /**
         * Initialize countdown display
         */
        private function initializeCountdown():void {
            _countdownContainer = new Sprite();
            _countdownContainer.visible = false;
            addChild(_countdownContainer);
            
            // Background bar
            _countdownBarBg = new Shape();
            _countdownBarBg.graphics.beginFill(0x333355, 0.6);
            _countdownBarBg.graphics.drawRoundRect(0, 0, 200, 20, 10, 10);
            _countdownBarBg.graphics.endFill();
            _countdownContainer.addChild(_countdownBarBg);
            
            // Progress bar
            _countdownBar = new Shape();
            _countdownContainer.addChild(_countdownBar);
            
            // Time text
            _countdownText = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 16;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            _countdownText.defaultTextFormat = format;
            _countdownText.width = 200;
            _countdownText.height = 25;
            _countdownText.y = 22;
            _countdownText.selectable = false;
            _countdownContainer.addChild(_countdownText);
        }
        
        /**
         * Initialize feedback text display
         */
        private function initializeFeedback():void {
            _feedbackText = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 32;
            format.color = 0x44FF44;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            _feedbackText.defaultTextFormat = format;
            _feedbackText.autoSize = TextFieldAutoSize.CENTER;
            _feedbackText.selectable = false;
            _feedbackText.visible = false;
            addChild(_feedbackText);
        }

        /**
         * Draw background
         */
        private function drawBackground(stageWidth:Number, stageHeight:Number):void {
            graphics.beginFill(0x1a1a2e, 1);
            graphics.drawRect(0, 0, stageWidth, stageHeight);
            graphics.endFill();
        }

        /**
         * Create start button
         */
        private function createStartButton(stageWidth:Number, stageHeight:Number):void {
            var upState:Sprite = createButtonState(0x4a90e2, "START");
            var overState:Sprite = createButtonState(0x357abd, "START");
            var downState:Sprite = createButtonState(0x1a4d7f, "START");

            _startButton = new SimpleButton(upState, overState, downState, upState);
            _startButton.x = (stageWidth - 200) / 2;
            _startButton.y = (stageHeight - 60) / 2;
            _startButton.addEventListener(MouseEvent.CLICK, onStartButtonClick);
            addChild(_startButton);
        }

        /**
         * Create a button state sprite
         */
        private function createButtonState(color:uint, label:String):Sprite {
            var sprite:Sprite = new Sprite();
            sprite.graphics.beginFill(color, 1);
            sprite.graphics.drawRect(0, 0, 200, 60);
            sprite.graphics.endFill();

            var textField:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 20;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;

            textField.defaultTextFormat = format;
            textField.text = label;
            textField.width = 200;
            textField.height = 60;
            textField.y = 15;
            textField.selectable = false;

            sprite.addChild(textField);
            return sprite;
        }

        /**
         * Start button click handler
         */
        private function onStartButtonClick(event:MouseEvent):void {
            dispatchEvent(new Event(START_TRIAL));
            _startButton.visible = false;
        }

        /**
         * Layout components on stage
         */
        private function layoutComponents(stageWidth:Number, stageHeight:Number):void {
            // Score - top left
            _scoreText.x = PADDING;
            _scoreText.y = PADDING;

            // Level - top right
            _levelText.x = stageWidth - _levelText.width - PADDING;
            _levelText.y = PADDING;

            // State text - center top
            _stateText.x = (stageWidth - _stateText.width) / 2;
            _stateText.y = PADDING * 2;

            // Instructions - bottom center
            _instructionText.x = (stageWidth - _instructionText.width) / 2;
            _instructionText.y = stageHeight - _instructionText.height - PADDING;
            _instructionText.width = stageWidth - PADDING * 2;
        }

        /**
         * Update all display text
         */
        private function updateDisplay():void {
            _scoreText.text = "Score: " + _currentScore;
            _levelText.text = "Level: " + _currentLevel + " (Span: " + _currentSpan + ")";
            layoutComponents(_stageWidth, _stageHeight);
        }

        /**
         * Set the current score
         * @param score New score value
         */
        public function setScore(score:int):void {
            _currentScore = score;
            updateDisplay();
        }

        /**
         * Set the current level
         * @param level New level value
         */
        public function setLevel(level:int):void {
            _currentLevel = level;
            updateDisplay();
        }

        /**
         * Set the current span length
         * @param span New span value
         */
        public function setSpan(span:int):void {
            _currentSpan = span;
            updateDisplay();
        }

        /**
         * Set the current game phase state text
         * @param stateText Text describing current phase (e.g., "Ready", "Observe", "Answer")
         */
        public function setStateText(stateText:String):void {
            _stateText.text = stateText;
            layoutComponents(_stageWidth, _stageHeight);
        }

        /**
         * Set instruction text
         * @param instruction Detailed instructions for the user
         */
        public function setInstructionText(instruction:String):void {
            _instructionText.text = instruction;
            layoutComponents(_stageWidth, _stageHeight);
        }

        /**
         * Handle stage resize
         */
        public function onResize():void {
            layoutComponents(_stageWidth, _stageHeight);
        }

        /**
         * Get current score
         * @return Current score
         */
        public function getScore():int {
            return _currentScore;
        }

        /**
         * Get current level
         * @return Current level
         */
        public function getLevel():int {
            return _currentLevel;
        }

        /**
         * Get current span
         * @return Current span
         */
        public function getSpan():int {
            return _currentSpan;
        }
        
        // ============ INPUT BUFFER DISPLAY ============
        
        /**
         * Show the input buffer display with given number of slots
         * @param numSlots Number of slots to show (expected input length)
         */
        public function showInputBuffer(numSlots:int):void {
            // Calculate total width
            var totalWidth:int = numSlots * BUFFER_SLOT_SIZE + (numSlots - 1) * BUFFER_SLOT_SPACING;
            var startX:int = (_stageWidth - totalWidth) / 2;
            var y:int = 100; // Below state text
            
            _inputBufferContainer.x = startX;
            _inputBufferContainer.y = y;
            
            // Position and show slots
            for (var i:int = 0; i < _maxBufferSlots; i++) {
                if (i < numSlots) {
                    _inputBufferSlots[i].x = i * (BUFFER_SLOT_SIZE + BUFFER_SLOT_SPACING);
                    _inputBufferSlots[i].y = 0;
                    _inputBufferSlots[i].visible = true;
                    _inputBufferLabels[i].text = "";
                    _inputBufferLabels[i].visible = true;
                    
                    // Reset slot appearance
                    updateSlotAppearance(i, false, false);
                } else {
                    _inputBufferSlots[i].visible = false;
                    _inputBufferLabels[i].visible = false;
                }
            }
            
            if (DEBUG) {
                trace("[HUD] Input buffer shown with " + numSlots + " slots");
            }
        }
        
        /**
         * Hide the input buffer display
         */
        public function hideInputBuffer():void {
            for (var i:int = 0; i < _maxBufferSlots; i++) {
                _inputBufferSlots[i].visible = false;
                _inputBufferLabels[i].visible = false;
            }
        }
        
        /**
         * Update the input buffer display with current buffer contents
         * @param buffer Array of stimulus IDs entered by user
         */
        public function updateInputBuffer(buffer:Vector.<int>):void {
            for (var i:int = 0; i < _maxBufferSlots; i++) {
                if (_inputBufferSlots[i].visible) {
                    if (i < buffer.length) {
                        // Show entered value (1-indexed for display)
                        _inputBufferLabels[i].text = String(buffer[i] + 1);
                        updateSlotAppearance(i, true, false);
                    } else {
                        // Empty slot
                        _inputBufferLabels[i].text = "";
                        updateSlotAppearance(i, false, false);
                    }
                }
            }
        }
        
        /**
         * Update slot visual appearance
         * @param index Slot index
         * @param filled Whether slot has a value
         * @param correct Whether slot value is correct (for result display)
         */
        private function updateSlotAppearance(index:int, filled:Boolean, correct:Boolean):void {
            var slot:Sprite = _inputBufferSlots[index];
            slot.graphics.clear();
            
            var fillColor:uint = 0x333355;
            var borderColor:uint = 0x555588;
            
            if (filled) {
                fillColor = 0x4a5568;
                borderColor = 0x718096;
            }
            
            slot.graphics.beginFill(fillColor, 0.8);
            slot.graphics.lineStyle(2, borderColor, 1);
            slot.graphics.drawRoundRect(0, 0, BUFFER_SLOT_SIZE, BUFFER_SLOT_SIZE, 8, 8);
            slot.graphics.endFill();
        }
        
        /**
         * Show result in input buffer (correct/incorrect highlighting)
         * @param expected Expected sequence
         * @param actual User's input sequence
         */
        public function showBufferResult(expected:Vector.<int>, actual:Vector.<int>):void {
            for (var i:int = 0; i < _maxBufferSlots; i++) {
                if (_inputBufferSlots[i].visible) {
                    var slot:Sprite = _inputBufferSlots[i];
                    slot.graphics.clear();
                    
                    var isCorrect:Boolean = (i < actual.length && i < expected.length && actual[i] == expected[i]);
                    var fillColor:uint = isCorrect ? 0x38a169 : 0xe53e3e; // Green or Red
                    var borderColor:uint = isCorrect ? 0x48bb78 : 0xfc8181;
                    
                    slot.graphics.beginFill(fillColor, 0.9);
                    slot.graphics.lineStyle(3, borderColor, 1);
                    slot.graphics.drawRoundRect(0, 0, BUFFER_SLOT_SIZE, BUFFER_SLOT_SIZE, 8, 8);
                    slot.graphics.endFill();
                }
            }
        }
        
        // ============ COUNTDOWN DISPLAY ============
        
        /**
         * Show countdown timer
         * @param totalTimeMs Total time in milliseconds
         */
        public function showCountdown(totalTimeMs:int):void {
            _totalTime = totalTimeMs;
            _countdownContainer.visible = true;
            _countdownContainer.x = (_stageWidth - 200) / 2;
            _countdownContainer.y = 150;
            updateCountdown(totalTimeMs);
        }
        
        /**
         * Hide countdown timer
         */
        public function hideCountdown():void {
            _countdownContainer.visible = false;
        }
        
        /**
         * Update countdown display
         * @param remainingMs Remaining time in milliseconds
         */
        public function updateCountdown(remainingMs:int):void {
            var seconds:Number = Math.ceil(remainingMs / 1000);
            var progress:Number = remainingMs / _totalTime;
            
            // Update text
            _countdownText.text = seconds + "s remaining";
            
            // Update bar
            var barWidth:int = int(196 * progress);
            var barColor:uint = 0x4299e1; // Blue
            
            if (seconds <= 3) {
                barColor = 0xe53e3e; // Red
            } else if (seconds <= 5) {
                barColor = 0xed8936; // Orange
            }
            
            _countdownBar.graphics.clear();
            _countdownBar.graphics.beginFill(barColor, 1);
            _countdownBar.graphics.drawRoundRect(2, 2, barWidth, 16, 8, 8);
            _countdownBar.graphics.endFill();
            
            // Update text color
            var format:TextFormat = _countdownText.getTextFormat();
            format.color = barColor;
            _countdownText.setTextFormat(format);
        }
        
        // ============ FEEDBACK DISPLAY ============
        
        /**
         * Show feedback text (Correct! / Incorrect!)
         * @param message Feedback message
         * @param isPositive True for positive (green), false for negative (red)
         */
        public function showFeedback(message:String, isPositive:Boolean):void {
            var format:TextFormat = _feedbackText.getTextFormat();
            format.color = isPositive ? 0x48bb78 : 0xfc8181;
            _feedbackText.setTextFormat(format);
            _feedbackText.defaultTextFormat = format;
            _feedbackText.text = message;
            _feedbackText.x = (_stageWidth - _feedbackText.width) / 2;
            _feedbackText.y = _stageHeight / 2 - 50;
            _feedbackText.visible = true;
        }
        
        /**
         * Hide feedback text
         */
        public function hideFeedback():void {
            _feedbackText.visible = false;
        }
        
        /**
         * Show start button
         */
        public function showStartButton():void {
            if (_startButton) {
                _startButton.visible = true;
            }
        }
        
        /**
         * Hide start button
         */
        public function hideStartButton():void {
            if (_startButton) {
                _startButton.visible = false;
            }
        }
    }
}