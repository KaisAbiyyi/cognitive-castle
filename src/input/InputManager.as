package input {

    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.MouseEvent;
    import flash.events.TouchEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.utils.getTimer;

    /**
     * InputManager - Handles cross-platform input (Touch and Mouse) with unified event model.
     * Manages input collection, visual feedback, and timeout handling.
     *
     * SOLID Principles:
     * - Single Responsibility: Only manages input handling and collection
     * - Open/Closed: Can be extended with new input types without changing existing code
     * - Dependency Inversion: Depends on abstractions (InputAction) rather than concrete events
     */
    public class InputManager extends Sprite {

        // Debug flag for conditional logging (set to false for release builds)
        private static const DEBUG:Boolean = true;

        // Singleton instance
        private static var _instance:InputManager;

        // Input buffer - collects stimulus IDs during answer phase
        private var _inputBuffer:Vector.<int>;

        // Timeout timer
        private var _timeoutTimer:Timer;
        private var _timeoutDuration:int = 10000; // 10 seconds default

        // Callback functions
        private var _onInputReceived:Function;
        private var _onTimeout:Function;
        private var _onButtonClick:Function; // Callback for each button click

        // Input state
        private var _isInputEnabled:Boolean = false;
        private var _inputStartTime:uint;

        // Visual feedback - map of display objects to their states
        private var _buttonStates:Object; // stimulusId -> {normal, pressed, disabled}
        
        // Input buttons (Week 1 demo - 6 simple buttons)
        private var _inputButtons:Vector.<Sprite>;
        private const NUM_BUTTONS:int = 6;
        private const BUTTON_SIZE:int = 80;
        private const BUTTON_SPACING:int = 20;

        /**
         * Get singleton instance
         * @return InputManager instance
         */
        public static function getInstance():InputManager {
            if (!_instance) {
                _instance = new InputManager();
            }
            return _instance;
        }

        /**
         * Constructor (private for singleton)
         */
        public function InputManager() {
            _inputBuffer = new Vector.<int>();
            _buttonStates = {};
            _inputButtons = new Vector.<Sprite>();

            // Initialize timeout timer
            _timeoutTimer = new Timer(_timeoutDuration, 1);
            _timeoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimeoutComplete);
            
            // Create input buttons for Week 1
            createInputButtons();
        }

        /**
         * Create 6 input buttons for Week 1 demo
         */
        private function createInputButtons():void {
            // Calculate button grid (2x3 or 3x2)
            var cols:int = 3;
            var rows:int = 2;
            
            // Use actual stage dimensions if available, otherwise default
            var stageW:int = stage ? stage.stageWidth : 480;
            var stageH:int = stage ? stage.stageHeight : 300;
            
            var startX:int = (stageW - (cols * (BUTTON_SIZE + BUTTON_SPACING))) / 2;
            var startY:int = stageH - (rows * (BUTTON_SIZE + BUTTON_SPACING)) - 20; // 20px from bottom

            for (var i:int = 0; i < NUM_BUTTONS; i++) {
                var col:int = i % cols;
                var row:int = Math.floor(i / cols);

                var button:Sprite = new Sprite();
                button.graphics.beginFill(0x3498DB, 1);
                button.graphics.drawRect(0, 0, BUTTON_SIZE, BUTTON_SIZE);
                button.graphics.endFill();

                // Add border
                button.graphics.lineStyle(2, 0xFFFFFF, 1);
                button.graphics.drawRect(0, 0, BUTTON_SIZE, BUTTON_SIZE);

                // Add number label
                var label:TextField = new TextField();
                var format:TextFormat = new TextFormat();
                format.font = "Arial";
                format.size = 24;
                format.color = 0xFFFFFF;
                format.bold = true;
                format.align = "center";
                label.defaultTextFormat = format;
                label.text = String(i + 1);
                label.width = BUTTON_SIZE;
                label.height = BUTTON_SIZE;
                label.selectable = false;
                label.y = 18;
                button.addChild(label);

                // Position button
                button.x = startX + (col * (BUTTON_SIZE + BUTTON_SPACING));
                button.y = startY + (row * (BUTTON_SIZE + BUTTON_SPACING));
                // Use button name for stimulus ID mapping (getStimulusIdFromButton will parse it)
                button.name = "button_" + i;
                button.visible = false; // Hidden by default, shown when startInputPhase() called

                // Register event listeners
                button.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
                button.addEventListener(MouseEvent.CLICK, onMouseClick);

                // Add to manager
                addChild(button);
                _inputButtons.push(button);
                registerButton(button, i);

                if (DEBUG) {
                    trace("Created input button " + i);
                }
            }
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
                handleInputAction(InputAction.CLICK, stimulusId, event.stageX, event.stageY);
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
                handleInputAction(InputAction.PRESS, stimulusId, event.stageX, event.stageY);
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
                handleInputAction(InputAction.RELEASE, stimulusId, event.stageX, event.stageY);
                setButtonState(event.currentTarget as DisplayObject, "normal");
            }
        }

        /**
         * Handle input action (unified processing)
         * @param type Action type
         * @param stimulusId Stimulus identifier
         * @param x X position
         * @param y Y position
         */
        private function handleInputAction(type:String, stimulusId:int, x:Number, y:Number):void {
            var action:InputAction = new InputAction(type, stimulusId, x, y);

            // For click/press actions, add to buffer
            if (type == InputAction.CLICK || type == InputAction.PRESS) {
                _inputBuffer.push(stimulusId);
                if (DEBUG) {
                    trace("Input received: " + action.toString() + " - Buffer: " + _inputBuffer.join(","));
                }

                // Call button click callback if provided
                if (_onButtonClick != null) {
                    _onButtonClick(_inputBuffer);
                }

                // Auto-submit on buffer full or implement manual submit logic
                // For now, continue collecting until timeout or explicit submit
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