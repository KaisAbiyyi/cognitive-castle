package {

    /**
     * ValidationResult - Contains the result of sequence validation.
     */
    public class ValidationResult {

        public var isCorrect:Boolean;
        public var errors:int;
        public var accuracy:Number; // 0.0 to 1.0
        public var userSequence:Vector.<StimulusItem>;
        public var correctSequence:Vector.<StimulusItem>;

        /**
         * Constructor
         * @param isCorrect Whether the sequence was correct
         * @param errors Number of errors
         * @param accuracy Accuracy percentage
         * @param userSequence User's input sequence
         * @param correctSequence The correct sequence
         */
        public function ValidationResult(isCorrect:Boolean, errors:int, accuracy:Number,
                                       userSequence:Vector.<StimulusItem>, correctSequence:Vector.<StimulusItem>) {
            this.isCorrect = isCorrect;
            this.errors = errors;
            this.accuracy = accuracy;
            this.userSequence = userSequence;
            this.correctSequence = correctSequence;
        }

        /**
         * String representation
         * @return String description
         */
        public function toString():String {
            return "[ValidationResult correct:" + isCorrect + " errors:" + errors + " accuracy:" + (accuracy * 100) + "%]";
        }
    }
}