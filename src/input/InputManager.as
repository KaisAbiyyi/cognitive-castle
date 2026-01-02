package input {

    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.MouseEvent;
    import flash.events.TouchEvent;
    import flash.events.KeyboardEvent;
    import flash.events.TimerEvent;
    import flash.events.Event;
    import flash.utils.Timer;
    import flash.utils.getTimer;
    import flash.geom.Point;
    import flash.ui.Keyboard;
    import core.EventBus;
    import core.GameEvent;
    import core.Constants;

    /**
     * InputManager - Handles cross-platform input (Touch, Mouse, Keyboard) with unified event model.
     * Manages input collection, visual feedback, timeout handling, and undo functionality.
     *
     * Features:
     * - Mouse click (Desktop)
     * - Touch tap (Mobile)
     * - Keyboard shortcuts (1-6 for buttons, Backspace for undo, Enter for submit, Escape for clear)
     * - Visual input grid (2x3, 3x3, 4x3 layouts)
     * - Input buffer with real-time display
     * - Timeout with countdown
     * - Undo last input
     *
     * SOLID Principles:
     * - Single Responsibility: Only manages input handling and collection
     * - Open/Closed: Can be extended with new input types without changing existing code
     * - Dependency Inversion: Depends on abstractions (InputAction) rather than concrete events
     */
    public class InputManager extends Sprite {

        // Debug flag for conditional logging
        private static const DEBUG:Boolean = true;

        // ============ GRID LAYOUTS ============
        public static const LAYOUT_2x3:String = "2x3";  // 6 buttons
        public static const LAYOUT_3x3:String = "3x3";  // 9 buttons
        public static const LAYOUT_4x3:String = "4x3";  // 12 buttons

        // Singleton instance
        private static var _instance:InputManager;

        // Input buffer - collects stimulus IDs during answer phase
        private var _inputBuffer:Vector.<int>;
        
        // Action history for undo
        private var _actionHistory:Vector.<InputAction>;

        // Timeout timer
        private var _timeoutTimer:Timer;
        private var _timeoutDuration:int = 10000;
        private var _countdownTimer:Timer;

        // Callback functions
        private var _onInputReceived:Function;
        private var _onTimeout:Function;
        private var _onButtonClick:Function;
        private var _onBufferChanged:Function;

        // Input state
        private var _isInputEnabled:Boolean = false;
        private var _inputStartTime:uint;
        private var _expectedInputLength:int = -1;
        private var _currentLayout:String = LAYOUT_2x3;

        // Visual feedback
        private var _buttonStates:Object;
        
        // Input buttons
        private var _inputButtons:Vector.<Sprite>;
        private var _buttonSize:int = 80;
        private var _buttonSpacing:int = 15;
        
        // Countdown display
        private var _countdownDisplay:TextField;
        
        // EventBus reference
        private var _eventBus:EventBus;
        
        // Stage reference for keyboard events
        private var _stageRef:Stage;

        /**
         * Get singleton instance
         */
        public static function getInstance():InputManager {
            if (!_instance) {
                _instance = new InputManager();
            }
            return _instance;
        }

        /**
         * Constructor
         */
        public function InputManager() {
            _inputBuffer = new Vector.<int>();
            _actionHistory = new Vector.<InputAction>();
            _buttonStates = {};
            _inputButtons = new Vector.<Sprite>();
            _eventBus = EventBus.getInstance();

            // Initialize timers
            _timeoutTimer = new Timer(_timeoutDuration, 1);
            _timeoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimeoutComplete);
            
            _countdownTimer = new Timer(100); // Update every 100ms
            _countdownTimer.addEventListener(TimerEvent.TIMER, onCountdownTick);
            
            // Create buttons when added to stage
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        /**
         * Handle added to stage - setup keyboard listeners
         */
        private function onAddedToStage(event:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            _stageRef = stage;
            
            // Setup keyboard listeners
            stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyboardDown);
            
            // Create input buttons
            createInputButtons(_currentLayout);
            
            // Create countdown display
            createCountdownDisplay();
        }

        /**
         * Create input buttons based on layout
         */
        private function createInputButtons(layout:String):void {
            // Clear existing buttons
            for each (var oldButton:Sprite in _inputButtons) {
                if (contains(oldButton)) removeChild(oldButton);
            }
            _inputButtons.length = 0;
            _buttonStates = {};
            
            // Determine grid size
            var cols:int, rows:int, numButtons:int;
            switch (layout) {
                case LAYOUT_3x3:
                    cols = 3; rows = 3; numButtons = 9;
                    break;
                case LAYOUT_4x3:
                    cols = 4; rows = 3; numButtons = 12;
                    break;
                case LAYOUT_2x3:
                default:
                    cols = 3; rows = 2; numButtons = 6;
                    break;
            }
            
            _currentLayout = layout;
            
            // Calculate positioning
            var stageW:int = stage ? stage.stageWidth : 480;
            var stageH:int = stage ? stage.stageHeight : 300;
            
            var gridWidth:int = cols * _buttonSize + (cols - 1) * _buttonSpacing;
            var gridHeight:int = rows * _buttonSize + (rows - 1) * _buttonSpacing;
            
            var startX:int = (stageW - gridWidth) / 2;
            var startY:int = stageH - gridHeight - 30;

            // Button colors (colorblind-friendly)
            var buttonColors:Array = Constants.STIMULUS_COLORS;

            for (var i:int = 0; i < numButtons; i++) {
                var col:int = i % cols;
                var row:int = Math.floor(i / cols);

                var button:Sprite = createButton(i, buttonColors[i % buttonColors.length]);
                button.x = startX + col * (_buttonSize + _buttonSpacing);
                button.y = startY + row * (_buttonSize + _buttonSpacing);
                button.name = "button_" + i;
                button.visible = false;

                // Register event listeners
                button.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
                button.addEventListener(MouseEvent.CLICK, onMouseClick);
                button.buttonMode = true;
                button.useHandCursor = true;

                addChild(button);
                _inputButtons.push(button);
                registerButton(button, i);
            }
            
            if (DEBUG) {
                trace("[InputManager] Created " + numButtons + " buttons with layout " + layout);
            }
        }
        
        /**
         * Create a single button
         */
        private function createButton(index:int, color:uint):Sprite {
            var button:Sprite = new Sprite();
            
            // Background
            button.graphics.beginFill(color, 1);
            button.graphics.lineStyle(3, 0xFFFFFF, 1);
            button.graphics.drawRoundRect(0, 0, _buttonSize, _buttonSize, 12, 12);
            button.graphics.endFill();

            // Label
            var label:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 28;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            label.defaultTextFormat = format;
            label.text = String(index + 1);
            label.width = _buttonSize;
            label.height = 40;
            label.selectable = false;
            label.mouseEnabled = false;
            label.y = (_buttonSize - 32) / 2;
            button.addChild(label);

            return button;
        }
        
        /**
         * Create countdown display
         */
        private function createCountdownDisplay():void {
            _countdownDisplay = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 18;
            format.color = 0xFFFFFF;
            format.align = TextFormatAlign.CENTER;
            _countdownDisplay.defaultTextFormat = format;
            _countdownDisplay.width = 100;
            _countdownDisplay.height = 25;
            _countdownDisplay.selectable = false;
            _countdownDisplay.visible = false;
            
            // Position above buttons
            if (stage) {
                _countdownDisplay.x = (stage.stageWidth - 100) / 2;
                _countdownDisplay.y = 10;
            }
            addChild(_countdownDisplay);
        }

        /**
         * Handle keyboard input
         */
        private function handleKeyboardDown(event:KeyboardEvent):void {
            if (!_isInputEnabled) return;
            
            var action:InputAction = null;
            
            // Number keys 1-9 (and 0 for 10) map to buttons
            if (event.keyCode >= Keyboard.NUMBER_1 && event.keyCode <= Keyboard.NUMBER_9) {
                var buttonIndex:int = event.keyCode - Keyboard.NUMBER_1;
                if (buttonIndex < _inputButtons.length && _inputButtons[buttonIndex].visible) {
                    action = InputAction.fromKeyboard(InputAction.KEY, buttonIndex, event.keyCode);
                    handleInputAction(action);
                }
            }
            // Numpad 1-9
            else if (event.keyCode >= Keyboard.NUMPAD_1 && event.keyCode <= Keyboard.NUMPAD_9) {
                var numpadIndex:int = event.keyCode - Keyboard.NUMPAD_1;
                if (numpadIndex < _inputButtons.length && _inputButtons[numpadIndex].visible) {
                    action = InputAction.fromKeyboard(InputAction.KEY, numpadIndex, event.keyCode);
                    handleInputAction(action);
                }
            }
            // Backspace - Undo last input
            else if (event.keyCode == Keyboard.BACKSPACE || event.keyCode == Keyboard.DELETE) {
                undoLastInput();
            }
            // Enter - Submit
            else if (event.keyCode == Keyboard.ENTER) {
                submitInput();
            }
            // Escape - Clear all
            else if (event.keyCode == Keyboard.ESCAPE) {
                clearBuffer();
                _eventBus.dispatch(GameEvent.INPUT_CLEARED, {});
            }
        }

        /**
         * Set the grid layout
         */
        public function setLayout(layout:String):void {
            if (_currentLayout != layout) {
                createInputButtons(layout);
            }
        }
        
        /**
         * Get current layout
         */
        public function get currentLayout():String {
            return _currentLayout;
        }
        
        /**
         * Undo the last input action
         */
        public function undoLastInput():void {
            if (_inputBuffer.length > 0) {
                var removed:int = _inputBuffer.pop();
                if (DEBUG) {
                    trace("[InputManager] Undo last input: " + removed + " - Buffer now: " + _inputBuffer.join(","));
                }
                _eventBus.dispatch(GameEvent.INPUT_CLEARED, { removedId: removed, buffer: _inputBuffer.slice() });
                
                // Callback to update UI
                if (_onButtonClick != null) {
                    _onButtonClick(_inputBuffer);
                }
            }
        }
        
        /**
         * Handle countdown timer tick
         */
        private function onCountdownTick(event:TimerEvent):void {
            if (!_isInputEnabled) return;
            
            var remaining:int = getTimeRemaining();
            var seconds:Number = Math.ceil(remaining / 1000);
            
            if (_countdownDisplay) {
                _countdownDisplay.text = String(seconds) + "s";
                _countdownDisplay.visible = true;
                
                // Color change when low on time
                var format:TextFormat = _countdownDisplay.getTextFormat();
                if (seconds <= 3) {
                    format.color = 0xFF4444; // Red
                } else if (seconds <= 5) {
                    format.color = 0xFFAA00; // Orange  
                } else {
                    format.color = 0xFFFFFF; // White
                }
                _countdownDisplay.setTextFormat(format);
            }
            
            // Dispatch tick event
            _eventBus.dispatch(GameEvent.COUNTDOWN_TICK, { remaining: remaining, seconds: seconds });
        }
        
        /**
         * Enable input collection phase
         * @param onInputReceived Callback when input is received (function(buffer:Vector.<int>):void)
         * @param onTimeout Callback when timeout occurs (function():void)
         * @param timeoutMs Timeout duration in milliseconds
         * @param onButtonClick Optional callback for each button click (function(buffer:Vector.<int>):void)
         * @param numButtonsToShow Number of buttons to show (defaults to all 6)
         */
        public function startInputPhase(onInputReceived:Function, onTimeout:Function = null, timeoutMs:int = 10000, onButtonClick:Function = null, numButtonsToShow:int = -1):void {
            _inputBuffer.length = 0; // Clear buffer
            _onInputReceived = onInputReceived;
            _onTimeout = onTimeout;
            _onButtonClick = onButtonClick;
            _timeoutDuration = timeoutMs;
            _isInputEnabled = true;
            _inputStartTime = getTimer();
            _expectedInputLength = numButtonsToShow; // Store expected length for auto-submit

            // Show input buttons (only show as many as needed)
            showButtons(numButtonsToShow);

            // Reset and start timeout timer
            _timeoutTimer.reset();
            _timeoutTimer.delay = _timeoutDuration;
            _timeoutTimer.start();

            // Reset all button states to normal
            for each (var stateObj:Object in _buttonStates) {
                if (stateObj.normal) {
                    setButtonState(stateObj.button, "normal");
                }
            }

            if (DEBUG) {
                trace("Input phase started - timeout in " + _timeoutDuration + "ms");
            }
        }

        /**
         * Disable input collection
         */
        public function stopInputPhase():void {
            _isInputEnabled = false;
            _timeoutTimer.stop();
            _onInputReceived = null;
            _onTimeout = null;
            
            // Hide input buttons
            hideButtons();
        }

        /**
         * Show input buttons
         * @param numToShow Number of buttons to show (-1 for all)
         */
        private function showButtons(numToShow:int = -1):void {
            var count:int = (numToShow > 0 && numToShow <= _inputButtons.length) ? numToShow : _inputButtons.length;
            
            for (var i:int = 0; i < _inputButtons.length; i++) {
                _inputButtons[i].visible = (i < count);
            }
            
            if (DEBUG) {
                trace("Input buttons shown: " + count + " of " + _inputButtons.length);
            }
        }

        /**
         * Hide all input buttons
         */
        private function hideButtons():void {
            for each (var button:Sprite in _inputButtons) {
                button.visible = false;
            }
            if (DEBUG) {
                trace("Input buttons hidden");
            }
        }

        /**
         * Register an input button/display object
         * @param button Display object that represents an input option
         * @param stimulusId Logical stimulus ID this button represents
         * @param normalState Normal appearance (optional)
         * @param pressedState Pressed appearance (optional)
         * @param disabledState Disabled appearance (optional)
         */
        public function registerButton(button:DisplayObject, stimulusId:int,
                                     normalState:* = null, pressedState:* = null, disabledState:* = null):void {
            // Store state information
            _buttonStates[stimulusId] = {
                button: button,
                normal: normalState,
                pressed: pressedState,
                disabled: disabledState
            };

            // Add event listeners for cross-platform input
            if (button.stage && button.stage.hasEventListener) {
                // Check if touch is supported (simplified check)
                var supportsTouch:Boolean = false;
                try {
                    supportsTouch = TouchEvent.TOUCH_BEGIN != null;
                } catch (e:Error) {}

                if (supportsTouch) {
                    button.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
                    button.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
                } else {
                    button.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
                    button.addEventListener(MouseEvent.CLICK, onMouseClick);
                }
            }

            // Set initial state
            setButtonState(button, "normal");
        }

        /**
         * Set visual state of a button
         * @param button Display object
         * @param state State name ("normal", "pressed", "disabled")
         */
        private function setButtonState(button:DisplayObject, state:String):void {
            // Basic visual feedback - could be enhanced with actual graphics
            switch (state) {
                case "pressed":
                    button.alpha = 0.7;
                    button.scaleX = button.scaleY = 0.95;
                    break;
                case "disabled":
                    button.alpha = 0.3;
                    button.scaleX = button.scaleY = 1.0;
                    break;
                case "normal":
                default:
                    button.alpha = 1.0;
                    button.scaleX = button.scaleY = 1.0;
                    break;
            }
        }

        /**
         * Handle mouse down event
         * @param event Mouse event
         */
        private function onMouseDown(event:MouseEvent):void {
            if (!_isInputEnabled) return;

            var stimulusId:int = getStimulusIdFromButton(event.currentTarget as DisplayObject);
            if (stimulusId >= 0) {
                setButtonState(event.currentTarget as DisplayObject, "pressed");
            }
        }

        /**
         * Handle mouse click event
         * @param event Mouse event
         */
        private function onMouseClick(event:MouseEvent):void {
            if (!_isInputEnabled) return;

            var stimulusId:int = getStimulusIdFromButton(event.currentTarget as DisplayObject);
            if (stimulusId >= 0) {
                var action:InputAction = InputAction.fromMouse(InputAction.CLICK, stimulusId, event.stageX, event.stageY);
                handleInputAction(action);
                setButtonState(event.currentTarget as DisplayObject, "normal");
            }
        }

        /**
         * Handle touch begin event
         * @param event Touch event
         */
        private function onTouchBegin(event:TouchEvent):void {
            if (!_isInputEnabled) return;

            var stimulusId:int = getStimulusIdFromButton(event.currentTarget as DisplayObject);
            if (stimulusId >= 0) {
                var action:InputAction = InputAction.fromTouch(InputAction.PRESS, stimulusId, event.stageX, event.stageY);
                handleInputAction(action);
                setButtonState(event.currentTarget as DisplayObject, "pressed");
            }
        }

        /**
         * Handle touch end event
         * @param event Touch event
         */
        private function onTouchEnd(event:TouchEvent):void {
            if (!_isInputEnabled) return;

            var stimulusId:int = getStimulusIdFromButton(event.currentTarget as DisplayObject);
            if (stimulusId >= 0) {
                var action:InputAction = InputAction.fromTouch(InputAction.RELEASE, stimulusId, event.stageX, event.stageY);
                handleInputAction(action);
                setButtonState(event.currentTarget as DisplayObject, "normal");
            }
        }

        /**
         * Handle input action (unified processing)
         * @param action InputAction object
         */
        private function handleInputAction(action:InputAction):void {
            // For click/press/key actions, add to buffer
            if (action.type == InputAction.CLICK || action.type == InputAction.PRESS || action.type == InputAction.KEY) {
                _inputBuffer.push(action.targetId);
                if (DEBUG) {
                    trace("Input received: " + action.toString() + " - Buffer: " + _inputBuffer.join(","));
                }

                // Call button click callback if provided
                if (_onButtonClick != null) {
                    _onButtonClick(_inputBuffer);
                }

                // Auto-submit when buffer reaches expected length
                if (_expectedInputLength > 0 && _inputBuffer.length >= _expectedInputLength) {
                    if (DEBUG) {
                        trace("Buffer full (" + _inputBuffer.length + "/" + _expectedInputLength + "), auto-submitting...");
                    }
                    submitInput();
                }
            }
        }

        /**
         * Get stimulus ID from button display object
         * Maps using name, custom data, or other properties
         * @param button Display object
         * @return Stimulus ID or -1 if not found
         */
        private function getStimulusIdFromButton(button:DisplayObject):int {
            // Try different mapping strategies

            // 1. By name (e.g., "button_0", "button_1")
            if (button.name && button.name.indexOf("button_") == 0) {
                var idStr:String = button.name.split("_")[1];
                return parseInt(idStr);
            }

            // 2. By custom data property
            if (button.hasOwnProperty("stimulusId")) {
                return button["stimulusId"];
            }

            // 3. By display list index (fallback)
            if (button.parent) {
                return button.parent.getChildIndex(button);
            }

            return -1;
        }

        /**
         * Submit current input buffer
         */
        public function submitInput():void {
            if (!_isInputEnabled) return;

            _timeoutTimer.stop();
            _isInputEnabled = false;

            if (_onInputReceived != null) {
                _onInputReceived(_inputBuffer.slice()); // Pass copy
            }

            if (DEBUG) {
                trace("Input submitted: " + _inputBuffer.join(","));
            }
        }
        
        /**
         * Force submit current input buffer (called externally)
         * Used for auto-submit after enough inputs received
         */
        public function forceSubmit():void {
            submitInput();
        }

        /**
         * Get current input buffer (read-only)
         * @return Copy of input buffer
         */
        public function getInputBuffer():Vector.<int> {
            return _inputBuffer.slice();
        }

        /**
         * Clear input buffer
         */
        public function clearBuffer():void {
            _inputBuffer.length = 0;
        }

        /**
         * Set timeout duration
         * @param ms Timeout in milliseconds
         */
        public function setTimeoutDuration(ms:int):void {
            _timeoutDuration = ms;
        }

        /**
         * Handle timeout completion
         * @param event Timer event
         */
        private function onTimeoutComplete(event:TimerEvent):void {
            if (!_isInputEnabled) return;

            _isInputEnabled = false;
            if (DEBUG) {
                trace("Input timeout occurred");
            }

            if (_onTimeout != null) {
                _onTimeout();
            } else if (_onInputReceived != null) {
                // Default behavior: submit empty buffer on timeout
                _onInputReceived(new Vector.<int>());
            }
        }

        /**
         * Check if input is currently enabled
         * @return True if accepting input
         */
        public function isInputEnabled():Boolean {
            return _isInputEnabled;
        }

        /**
         * Get remaining time before timeout
         * @return Milliseconds remaining
         */
        public function getTimeRemaining():int {
            if (!_isInputEnabled) return 0;
            var elapsed:int = getTimer() - _inputStartTime;
            return Math.max(0, _timeoutDuration - elapsed);
        }
    }
}