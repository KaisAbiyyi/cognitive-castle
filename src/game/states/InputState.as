package game.states {
    
    import core.Constants;
    import core.GameEvent;
    import game.GameController;
    
    /**
     * InputState - Waits for user to recall and input the sequence.
     * Tracks user inputs and enforces timeout.
     */
    public class InputState extends BaseState {
        
        /** Callback for state transitions */
        public var onTransition:Function;
        /** Callback when user makes input */
        public var onUserInput:Function;
        
        private var _expectedSequence:Array;
        private var _userInputs:Array;
        private var _timeout:Number;
        private var _mode:String;
        private var _inputStartTime:Number;
        
        public function InputState(controller:GameController) {
            super(controller, Constants.STATE_INPUT);
            _timeout = Constants.INPUT_TIMEOUT_DEFAULT;
            _mode = Constants.MODE_FORWARD;
        }
        
        override public function enter(data:Object = null):void {
            super.enter(data);
            
            _expectedSequence = data ? data.sequence : [];
            _userInputs = [];
            _mode = data && data.mode ? data.mode : Constants.MODE_FORWARD;
            _inputStartTime = new Date().time;
            
            // Calculate timeout based on sequence length
            _timeout = Constants.INPUT_TIMEOUT_DEFAULT + 
                       (_expectedSequence.length * Constants.INPUT_TIMEOUT_PER_ITEM);
            
            _eventBus.dispatch(GameEvent.INPUT_START, {
                sequenceLength: _expectedSequence.length,
                mode: _mode,
                timeout: _timeout
            });
        }
        
        override public function update(deltaTime:Number):void {
            super.update(deltaTime);
            
            // Check for timeout
            if (_stateTime >= _timeout) {
                trace("[InputState] Timeout reached");
                submitInput(true); // Force submit on timeout
            }
        }
        
        override public function handleInput(action:String, data:Object = null):void {
            if (action == "BUTTON_PRESS" || action == "button_press") {
                var buttonIndex:int = data ? int(data.index) : -1;
                if (buttonIndex >= 0) {
                    addInput(buttonIndex);
                }
            } else if (action == "SUBMIT" || action == "submit") {
                submitInput(false);
            } else if (action == "CLEAR" || action == "clear") {
                clearInputs();
            } else if (action == "UNDO" || action == "undo") {
                undoLastInput();
            }
        }
        
        /**
         * Add a user input
         */
        public function addInput(value:int):void {
            _userInputs.push(value);
            
            _eventBus.dispatch(GameEvent.INPUT_RECEIVED, {
                value: value,
                index: _userInputs.length - 1,
                total: _userInputs.length,
                expected: _expectedSequence.length
            });
            
            if (onUserInput != null) {
                onUserInput(value, _userInputs.length);
            }
            
            // Auto-submit when input count matches expected
            if (_userInputs.length >= _expectedSequence.length) {
                submitInput(false);
            }
        }
        
        /**
         * Submit the input for validation
         */
        private function submitInput(timedOut:Boolean):void {
            var reactionTime:Number = new Date().time - _inputStartTime;
            
            _eventBus.dispatch(GameEvent.INPUT_COMPLETE, {
                inputs: _userInputs,
                expected: _expectedSequence,
                mode: _mode,
                timedOut: timedOut,
                reactionTime: reactionTime
            });
            
            if (onTransition != null) {
                onTransition(Constants.STATE_RESULT, {
                    expected: _expectedSequence,
                    actual: _userInputs,
                    mode: _mode,
                    timedOut: timedOut,
                    reactionTime: reactionTime
                });
            }
        }
        
        /**
         * Clear all inputs
         */
        private function clearInputs():void {
            _userInputs = [];
            _eventBus.dispatch(GameEvent.INPUT_CLEARED, {});
        }
        
        /**
         * Undo the last input
         */
        private function undoLastInput():void {
            if (_userInputs.length > 0) {
                _userInputs.pop();
                _eventBus.dispatch(GameEvent.INPUT_RECEIVED, {
                    value: -1, // Indicates undo
                    index: _userInputs.length,
                    total: _userInputs.length,
                    expected: _expectedSequence.length
                });
            }
        }
        
        /**
         * Get current user inputs
         */
        public function get userInputs():Array {
            return _userInputs.slice();
        }
        
        /**
         * Get remaining time in ms
         */
        public function get remainingTime():Number {
            return Math.max(0, _timeout - _stateTime);
        }
        
        override public function canTransitionTo(targetState:String):Boolean {
            return targetState == Constants.STATE_RESULT || 
                   targetState == Constants.STATE_PAUSED;
        }
    }
}
