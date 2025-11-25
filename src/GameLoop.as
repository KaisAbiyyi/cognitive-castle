package {

    /**
     * GameLoop - Simple integration of validation into main loop.
     * Handles Stimulus -> Input -> Validate -> Result flow.
     */
    public class GameLoop {

        private var _validator:Validator;
        private var _scoreManager:ScoreManager;

        // Callbacks
        public var onResult:Function; // function(result:ValidationResult):void

        /**
         * Constructor
         */
        public function GameLoop() {
            _validator = new Validator();
            _scoreManager = new ScoreManager();
        }

        /**
         * Process a complete trial
         * @param userInput User's input stimulus IDs
         * @param correctSequence The correct sequence
         */
        public function processTrial(userInput:Vector.<int>, correctSequence:Vector.<StimulusItem>):void {
            var result:ValidationResult = _validator.validate(userInput, correctSequence);
            _scoreManager.updateScore(result.isCorrect);
            _scoreManager.logTrialResult(result);

            if (onResult != null) {
                onResult(result);
            }
        }

        /**
         * Get current score
         * @return Current score
         */
        public function getCurrentScore():int {
            return _scoreManager.getScore();
        }

        /**
         * Set validation mode
         * @param mode Validation mode
         */
        public function setValidationMode(mode:String):void {
            _validator.setMode(mode);
        }
    }
}