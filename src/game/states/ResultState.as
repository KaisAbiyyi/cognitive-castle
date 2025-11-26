package game.states {
    
    import core.Constants;
    import core.GameEvent;
    import game.GameController;
    import domain.TrialResult;
    
    /**
     * ResultState - Displays trial result and handles scoring.
     * Shows whether answer was correct and updates progression.
     */
    public class ResultState extends BaseState {
        
        /** Callback for state transitions */
        public var onTransition:Function;
        /** Callback for validation */
        public var onValidate:Function;
        
        private var _trialResult:TrialResult;
        private var _displayTime:Number;
        private var _expected:Array;
        private var _actual:Array;
        private var _mode:String;
        private var _timedOut:Boolean;
        private var _reactionTime:Number;
        
        public function ResultState(controller:GameController) {
            super(controller, Constants.STATE_RESULT);
            _displayTime = Constants.RESULT_DISPLAY_TIME;
        }
        
        override public function enter(data:Object = null):void {
            super.enter(data);
            
            _expected = data ? data.expected : [];
            _actual = data ? data.actual : [];
            _mode = data && data.mode ? data.mode : Constants.MODE_FORWARD;
            _timedOut = data && data.timedOut ? data.timedOut : false;
            _reactionTime = data && data.reactionTime ? data.reactionTime : 0;
            
            // Create trial result
            _trialResult = new TrialResult();
            _trialResult.expected = _expected;
            _trialResult.actual = _actual;
            _trialResult.mode = _mode;
            _trialResult.timedOut = _timedOut;
            _trialResult.reactionTime = _reactionTime;
            _trialResult.totalItems = _expected.length;
            
            // Validate result
            validateResult();
            
            _eventBus.dispatch(GameEvent.VALIDATION_COMPLETE, {
                result: _trialResult,
                isCorrect: _trialResult.isCorrect,
                accuracy: _trialResult.accuracy
            });
        }
        
        private function validateResult():void {
            // Apply mode transformation to expected sequence
            var expectedSequence:Array = getExpectedForMode();
            
            // Compare sequences
            var correctCount:int = 0;
            var minLength:int = Math.min(expectedSequence.length, _actual.length);
            
            for (var i:int = 0; i < minLength; i++) {
                if (expectedSequence[i] == _actual[i]) {
                    correctCount++;
                }
            }
            
            _trialResult.correctItems = correctCount;
            _trialResult.isCorrect = (correctCount == _expected.length && 
                                       _actual.length == _expected.length);
            _trialResult.accuracy = _expected.length > 0 ? 
                                    correctCount / _expected.length : 0;
            
            // Call external validator if provided
            if (onValidate != null) {
                onValidate(_trialResult);
            }
            
            trace("[ResultState] Correct: " + _trialResult.isCorrect + 
                  " (" + correctCount + "/" + _expected.length + ")");
        }
        
        private function getExpectedForMode():Array {
            switch (_mode) {
                case Constants.MODE_REVERSE:
                    return _expected.slice().reverse();
                case Constants.MODE_SORTED:
                    return _expected.slice().sort(Array.NUMERIC);
                default:
                    return _expected;
            }
        }
        
        override public function update(deltaTime:Number):void {
            super.update(deltaTime);
            
            // Auto-transition after display time
            if (_stateTime >= _displayTime) {
                transitionToNext();
            }
        }
        
        private function transitionToNext():void {
            if (onTransition != null) {
                onTransition(Constants.STATE_IDLE, {
                    result: _trialResult
                });
            }
        }
        
        override public function handleInput(action:String, data:Object = null):void {
            // Allow early transition on tap
            if (action == "TAP" || action == "tap" || 
                action == "CONTINUE" || action == "continue") {
                transitionToNext();
            }
        }
        
        /**
         * Get the trial result
         */
        public function get trialResult():TrialResult {
            return _trialResult;
        }
        
        override public function canTransitionTo(targetState:String):Boolean {
            return targetState == Constants.STATE_IDLE || 
                   targetState == Constants.STATE_STIMULUS ||
                   targetState == Constants.STATE_CASTLE_UPDATE;
        }
    }
}
