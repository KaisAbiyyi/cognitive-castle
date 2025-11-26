package game.states {
    
    import core.Constants;
    import core.GameEvent;
    import game.GameController;
    
    /**
     * StimulusState - Presents the sequence of stimuli to memorize.
     * Shows each stimulus one at a time with configurable timing.
     */
    public class StimulusState extends BaseState {
        
        /** Callback for state transitions */
        public var onTransition:Function;
        /** Callback when showing a stimulus item */
        public var onShowStimulus:Function;
        
        private var _sequence:Array;
        private var _currentIndex:int;
        private var _stimulusDuration:int;
        private var _isiDuration:int;
        private var _showingStimulus:Boolean;
        private var _itemTimer:Number;
        
        public function StimulusState(controller:GameController) {
            super(controller, Constants.STATE_STIMULUS);
            _stimulusDuration = Constants.STIMULUS_DURATION_DEFAULT;
            _isiDuration = Constants.ISI_DEFAULT;
        }
        
        override public function enter(data:Object = null):void {
            super.enter(data);
            
            _sequence = data ? data.sequence : [];
            _currentIndex = 0;
            _showingStimulus = true;
            _itemTimer = 0;
            
            _eventBus.dispatch(GameEvent.STIMULUS_START, {
                sequenceLength: _sequence.length
            });
            
            // Show first stimulus immediately
            if (_sequence.length > 0) {
                showCurrentStimulus();
            }
        }
        
        override public function update(deltaTime:Number):void {
            super.update(deltaTime);
            
            _itemTimer += deltaTime;
            
            if (_showingStimulus) {
                // Currently showing stimulus, check if time to hide
                if (_itemTimer >= _stimulusDuration) {
                    hideStimulus();
                    _itemTimer = 0;
                    _showingStimulus = false;
                    
                    // Move to next or finish
                    _currentIndex++;
                    if (_currentIndex >= _sequence.length) {
                        // All stimuli shown, transition to input
                        _eventBus.dispatch(GameEvent.STIMULUS_END, {});
                        if (onTransition != null) {
                            onTransition(Constants.STATE_INPUT, { sequence: _sequence });
                        }
                    }
                }
            } else {
                // In ISI, check if time to show next
                if (_itemTimer >= _isiDuration) {
                    _itemTimer = 0;
                    _showingStimulus = true;
                    showCurrentStimulus();
                }
            }
        }
        
        private function showCurrentStimulus():void {
            if (_currentIndex < _sequence.length) {
                var stimulus:Object = _sequence[_currentIndex];
                
                _eventBus.dispatch(GameEvent.STIMULUS_SHOW, {
                    index: _currentIndex,
                    total: _sequence.length,
                    stimulus: stimulus
                });
                
                if (onShowStimulus != null) {
                    onShowStimulus(stimulus, _currentIndex);
                }
            }
        }
        
        private function hideStimulus():void {
            _eventBus.dispatch(GameEvent.STIMULUS_HIDE, {
                index: _currentIndex
            });
            
            if (onShowStimulus != null) {
                onShowStimulus(null, _currentIndex);
            }
        }
        
        override public function canTransitionTo(targetState:String):Boolean {
            return targetState == Constants.STATE_INPUT || 
                   targetState == Constants.STATE_PAUSED;
        }
        
        /**
         * Set timing parameters
         */
        public function setTiming(stimulusDuration:int, isiDuration:int):void {
            _stimulusDuration = stimulusDuration;
            _isiDuration = isiDuration;
        }
    }
}
