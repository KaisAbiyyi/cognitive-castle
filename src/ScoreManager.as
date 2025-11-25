package {

    /**
     * ScoreManager - Manages scoring rules and score tracking.
     */
    public class ScoreManager {

        private var _currentScore:int = 0;

        /**
         * Constructor
         */
        public function ScoreManager() {
            // Initialize
        }

        /**
         * Update score based on trial result
         * @param isCorrect Whether the trial was correct
         */
        public function updateScore(isCorrect:Boolean):void {
            if (isCorrect) {
                _currentScore += 1; // +1 for correct
            } else {
                // 0 for fail, no change
            }
        }

        /**
         * Get current score
         * @return Current score
         */
        public function getScore():int {
            return _currentScore;
        }

        /**
         * Reset score
         */
        public function resetScore():void {
            _currentScore = 0;
        }

        /**
         * Log trial result
         * @param result ValidationResult
         */
        public function logTrialResult(result:ValidationResult):void {
            trace("Trial result: " + result.toString());
        }
    }
}