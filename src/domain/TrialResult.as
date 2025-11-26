package domain {
    
    /**
     * TrialResult - Represents the outcome of a single trial.
     * Captures all data needed for analysis and scoring.
     * 
     * SOLID Principles:
     * - Single Responsibility: Only holds trial outcome data
     */
    public class TrialResult {
        /** Trial was fully correct */
        public var isCorrect:Boolean = false;
        /** Partial correctness (0-1) */
        public var accuracy:Number = 0;
        /** Reaction time in ms (from input start to submission) */
        public var reactionTime:Number = 0;
        /** Time spent on trial in ms (from stimulus start to result) */
        public var totalTime:Number = 0;
        /** Sequence length for this trial (alias: spanLength) */
        public var sequenceLength:int = 0;
        /** Difficulty level during this trial */
        public var difficulty:int = 1;
        /** Recall mode used (forward, reverse, sorted) */
        public var mode:String = "forward";
        /** Expected sequence */
        public var expected:Array = [];
        /** User's input sequence */
        public var actual:Array = [];
        /** Timestamp when trial started */
        public var timestamp:Number = 0;
        /** Number of correct items */
        public var correctItems:int = 0;
        /** Total items in sequence */
        public var totalItems:int = 0;
        /** Whether trial timed out */
        public var timedOut:Boolean = false;
        /** Score earned for this trial */
        public var scoreEarned:int = 0;
        /** Current streak after this trial */
        public var streakAfter:int = 0;
        /** Timeout duration for this trial (ms) */
        public var timeoutDuration:Number = 10000;
        
        public function TrialResult() {
            timestamp = new Date().time;
        }
        
        /**
         * Get span length (alias for sequenceLength)
         */
        public function get spanLength():int {
            return sequenceLength;
        }
        
        /**
         * Set span length (alias for sequenceLength)
         */
        public function set spanLength(value:int):void {
            sequenceLength = value;
        }
        
        /**
         * Get match percentage (correctItems / totalItems)
         */
        public function get matchPercentage():Number {
            if (totalItems == 0) return 0;
            return correctItems / totalItems;
        }
        
        /**
         * Get response time ratio (reactionTime / timeoutDuration)
         * Lower is better (faster response)
         */
        public function get responseTimeRatio():Number {
            if (timeoutDuration <= 0) return 1;
            return Math.min(1, reactionTime / timeoutDuration);
        }
        
        /**
         * Calculate and return the accuracy percentage
         */
        public function getAccuracyPercent():Number {
            if (totalItems == 0) return 0;
            return correctItems / totalItems;
        }
        
        /**
         * Create a clone of this result
         */
        public function clone():TrialResult {
            var r:TrialResult = new TrialResult();
            r.isCorrect = isCorrect;
            r.accuracy = accuracy;
            r.reactionTime = reactionTime;
            r.totalTime = totalTime;
            r.sequenceLength = sequenceLength;
            r.difficulty = difficulty;
            r.mode = mode;
            r.expected = expected.slice();
            r.actual = actual.slice();
            r.timestamp = timestamp;
            r.correctItems = correctItems;
            r.totalItems = totalItems;
            r.timedOut = timedOut;
            r.scoreEarned = scoreEarned;
            r.streakAfter = streakAfter;
            r.timeoutDuration = timeoutDuration;
            return r;
        }
        
        /**
         * Return string representation
         */
        public function toString():String {
            return "[TrialResult correct=" + isCorrect + " accuracy=" + accuracy.toFixed(2) + 
                   " rt=" + reactionTime + "ms diff=" + difficulty + " mode=" + mode + "]";
        }
    }
}