package game {
    
    import core.Constants;
    import core.EventBus;
    import core.GameEvent;
    import domain.TrialResult;
    
    /**
     * ProgressionController - Handles difficulty progression using 1-Up/2-Down staircase.
     * Tracks rolling accuracy and adjusts difficulty based on performance.
     * 
     * SOLID Principles:
     * - Single Responsibility: Only handles difficulty progression logic
     * - Open/Closed: Progression rules can be configured via Constants
     */
    public class ProgressionController {
        
        private var _eventBus:EventBus;
        
        // Current state
        private var _currentDifficulty:int;
        private var _currentSpan:int;
        private var _currentMode:String;
        
        // Tracking
        private var _consecutiveCorrect:int = 0;
        private var _consecutiveIncorrect:int = 0;
        private var _recentResults:Array = [];
        private var _totalTrials:int = 0;
        private var _totalCorrect:int = 0;
        
        // Staircase parameters
        private var _upThreshold:int;
        private var _downThreshold:int;
        private var _windowSize:int;
        
        /**
         * Constructor
         * @param eventBus Event bus for dispatching events
         */
        public function ProgressionController(eventBus:EventBus = null) {
            _eventBus = eventBus || EventBus.getInstance();
            
            // Initialize from constants
            _currentDifficulty = Constants.DIFFICULTY_START;
            _currentSpan = Constants.SEQUENCE_LENGTH_START;
            _currentMode = Constants.MODE_FORWARD;
            _upThreshold = Constants.CONSECUTIVE_CORRECT_TO_UP;
            _downThreshold = Constants.CONSECUTIVE_INCORRECT_TO_DOWN;
            _windowSize = Constants.ROLLING_WINDOW_SIZE;
            
            _recentResults = [];
        }
        
        /**
         * Process a trial result and update progression
         * @param result The trial result to process
         * @return Object with progression changes {difficultyChanged, spanChanged, newDifficulty, newSpan}
         */
        public function processResult(result:TrialResult):Object {
            _totalTrials++;
            
            // Track in rolling window
            _recentResults.push(result.isCorrect);
            if (_recentResults.length > _windowSize) {
                _recentResults.shift();
            }
            
            var previousDifficulty:int = _currentDifficulty;
            var previousSpan:int = _currentSpan;
            
            if (result.isCorrect) {
                _totalCorrect++;
                _consecutiveCorrect++;
                _consecutiveIncorrect = 0;
                
                // 1-Up: Level up after N consecutive correct
                if (_consecutiveCorrect >= _upThreshold) {
                    levelUp();
                    _consecutiveCorrect = 0;
                }
            } else {
                _consecutiveIncorrect++;
                _consecutiveCorrect = 0;
                
                // 2-Down: Level down after N consecutive incorrect
                if (_consecutiveIncorrect >= _downThreshold) {
                    levelDown();
                    _consecutiveIncorrect = 0;
                }
            }
            
            var changes:Object = {
                difficultyChanged: _currentDifficulty != previousDifficulty,
                spanChanged: _currentSpan != previousSpan,
                newDifficulty: _currentDifficulty,
                newSpan: _currentSpan,
                rollingAccuracy: getRollingAccuracy()
            };
            
            // Dispatch event if difficulty changed
            if (changes.difficultyChanged) {
                _eventBus.dispatch(GameEvent.DIFFICULTY_CHANGED, {
                    oldDifficulty: previousDifficulty,
                    newDifficulty: _currentDifficulty,
                    direction: _currentDifficulty > previousDifficulty ? "up" : "down"
                });
            }
            
            if (changes.spanChanged) {
                _eventBus.dispatch(GameEvent.SPAN_CHANGED, {
                    oldSpan: previousSpan,
                    newSpan: _currentSpan
                });
            }
            
            return changes;
        }
        
        /**
         * Level up - increase difficulty
         */
        private function levelUp():void {
            if (_currentDifficulty < Constants.DIFFICULTY_LEVELS) {
                _currentDifficulty++;
                updateSpanForDifficulty();
                trace("[Progression] Level UP: " + _currentDifficulty);
            }
        }
        
        /**
         * Level down - decrease difficulty
         */
        private function levelDown():void {
            if (_currentDifficulty > 1) {
                _currentDifficulty--;
                updateSpanForDifficulty();
                trace("[Progression] Level DOWN: " + _currentDifficulty);
            }
        }
        
        /**
         * Update span based on current difficulty
         */
        private function updateSpanForDifficulty():void {
            // Map difficulty (1-15) to span (3-12)
            // Difficulty 1-3: span 3
            // Difficulty 4-6: span 4
            // Difficulty 7-9: span 5
            // Difficulty 10-12: span 6
            // Difficulty 13-15: span 7+
            var spanLevel:int = Math.floor((_currentDifficulty - 1) / 3);
            _currentSpan = Math.min(
                Constants.SEQUENCE_LENGTH_MAX,
                Constants.SEQUENCE_LENGTH_START + spanLevel
            );
        }
        
        /**
         * Get rolling accuracy from recent trials
         */
        public function getRollingAccuracy():Number {
            if (_recentResults.length == 0) return 0;
            
            var correct:int = 0;
            for (var i:int = 0; i < _recentResults.length; i++) {
                if (_recentResults[i]) correct++;
            }
            return correct / _recentResults.length;
        }
        
        /**
         * Get overall accuracy
         */
        public function getOverallAccuracy():Number {
            if (_totalTrials == 0) return 0;
            return _totalCorrect / _totalTrials;
        }
        
        /**
         * Set the current mode
         */
        public function setMode(mode:String):void {
            if (mode == Constants.MODE_FORWARD || 
                mode == Constants.MODE_REVERSE || 
                mode == Constants.MODE_SORTED) {
                _currentMode = mode;
                trace("[Progression] Mode set to: " + mode);
            }
        }
        
        /**
         * Reset progression to initial state
         */
        public function reset():void {
            _currentDifficulty = Constants.DIFFICULTY_START;
            _currentSpan = Constants.SEQUENCE_LENGTH_START;
            _consecutiveCorrect = 0;
            _consecutiveIncorrect = 0;
            _recentResults = [];
            _totalTrials = 0;
            _totalCorrect = 0;
        }
        
        /**
         * Set difficulty directly (for loading saves)
         */
        public function setDifficulty(level:int):void {
            _currentDifficulty = Math.max(1, Math.min(Constants.DIFFICULTY_LEVELS, level));
            updateSpanForDifficulty();
        }
        
        /**
         * Get timeout duration for current difficulty
         * Decreases as difficulty increases
         */
        public function getTimeoutForDifficulty():int {
            // Base timeout (10s) decreases by 500ms per 2 difficulty levels
            var reduction:int = Math.floor((_currentDifficulty - 1) / 2) * 500;
            var timeout:int = Constants.INPUT_TIMEOUT_DEFAULT - reduction;
            return Math.max(Constants.INPUT_TIMEOUT_MIN, timeout);
        }
        
        /**
         * Get stimulus display duration for current difficulty
         * Decreases as difficulty increases
         */
        public function getStimulusDuration():int {
            // Base duration (1000ms) decreases by 100ms per 3 difficulty levels
            var reduction:int = Math.floor((_currentDifficulty - 1) / 3) * 100;
            var duration:int = Constants.STIMULUS_DURATION_DEFAULT - reduction;
            return Math.max(Constants.STIMULUS_DURATION_MIN, duration);
        }
        
        /**
         * Get inter-stimulus interval for current difficulty
         */
        public function getInterStimulusInterval():int {
            // Base ISI (500ms) decreases by 50ms per 3 difficulty levels
            var reduction:int = Math.floor((_currentDifficulty - 1) / 3) * 50;
            var isi:int = Constants.ISI_DEFAULT - reduction;
            return Math.max(Constants.ISI_MIN, isi);
        }
        
        /**
         * Check if mode should transition to more difficult mode
         * Forward -> Reverse -> Sorted
         */
        public function checkModeTransition():Boolean {
            // Transition modes at certain difficulty thresholds
            if (_currentDifficulty >= 8 && _currentMode == Constants.MODE_FORWARD) {
                _currentMode = Constants.MODE_REVERSE;
                _eventBus.dispatch(GameEvent.DIFFICULTY_CHANGED, {
                    modeChanged: true,
                    newMode: _currentMode
                });
                trace("[Progression] Mode transitioned to REVERSE at difficulty " + _currentDifficulty);
                return true;
            }
            if (_currentDifficulty >= 12 && _currentMode == Constants.MODE_REVERSE) {
                _currentMode = Constants.MODE_SORTED;
                _eventBus.dispatch(GameEvent.DIFFICULTY_CHANGED, {
                    modeChanged: true,
                    newMode: _currentMode
                });
                trace("[Progression] Mode transitioned to SORTED at difficulty " + _currentDifficulty);
                return true;
            }
            return false;
        }
        
        /**
         * Get current progression parameters
         */
        public function getProgressionParams():Object {
            return {
                difficulty: _currentDifficulty,
                span: _currentSpan,
                mode: _currentMode,
                timeout: getTimeoutForDifficulty(),
                stimulusDuration: getStimulusDuration(),
                isi: getInterStimulusInterval(),
                rollingAccuracy: getRollingAccuracy(),
                overallAccuracy: getOverallAccuracy(),
                consecutiveCorrect: _consecutiveCorrect,
                consecutiveIncorrect: _consecutiveIncorrect
            };
        }
        
        // ============ GETTERS ============
        
        public function get currentDifficulty():int { return _currentDifficulty; }
        public function get currentSpan():int { return _currentSpan; }
        public function get currentMode():String { return _currentMode; }
        public function get consecutiveCorrect():int { return _consecutiveCorrect; }
        public function get consecutiveIncorrect():int { return _consecutiveIncorrect; }
        public function get totalTrials():int { return _totalTrials; }
        public function get totalCorrect():int { return _totalCorrect; }
    }
}