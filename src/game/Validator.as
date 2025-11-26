package game {

    import domain.StimulusItem;
    import domain.ValidationResult;

    /**
     * Validator - Validates user input against generated sequences.
     * Supports different validation modes for various challenge types.
     *
     * SOLID Principles:
     * - Single Responsibility: Only handles validation logic
     * - Open/Closed: Can be extended with new validation modes without changing existing code
     * - Dependency Inversion: Depends on abstractions (ValidationResult)
     */
    public class Validator {

        public static const MODE_FORWARD:String = "forward";     // Exact order match
        public static const MODE_REVERSE:String = "reverse";     // Reverse order match
        public static const MODE_SORT:String = "sort";           // Sorted order match

        private var _validationMode:String = MODE_FORWARD;

        /**
         * Constructor
         * @param mode Validation mode
         */
        public function Validator(mode:String = MODE_FORWARD) {
            _validationMode = mode;
        }

        /**
         * Set validation mode
         * @param mode New validation mode
         */
        public function setMode(mode:String):void {
            _validationMode = mode;
        }

        /**
         * Validate user input against correct sequence
         * @param userInput Vector of stimulus IDs from user
         * @param correctSequence Vector of StimulusItem (correct sequence)
         * @return ValidationResult
         */
        public function validate(userInput:Vector.<int>, correctSequence:Vector.<StimulusItem>):ValidationResult {
            // Convert InputAction to StimulusItem sequence
            var userSequence:Vector.<StimulusItem> = convertInputToSequence(userInput, correctSequence);

            // Apply validation mode
            var processedUser:Vector.<StimulusItem> = processSequenceForMode(userSequence);
            var processedCorrect:Vector.<StimulusItem> = processSequenceForMode(correctSequence.slice());

            // Compare sequences
            var errors:int = 0;
            var minLength:int = Math.min(processedUser.length, processedCorrect.length);

            for (var i:int = 0; i < minLength; i++) {
                if (!sequencesMatchAt(processedUser, processedCorrect, i)) {
                    errors++;
                }
            }

            // Add errors for length mismatch
            errors += Math.abs(processedUser.length - processedCorrect.length);

            var isCorrect:Boolean = (errors == 0);
            var accuracy:Number = processedCorrect.length > 0 ? (processedCorrect.length - errors) / processedCorrect.length : 0;

            return new ValidationResult(isCorrect, errors, accuracy, userSequence, correctSequence);
        }

        /**
         * Convert user input indices to StimulusItem sequence
         * @param input User input (button indices that were clicked: 0, 1, 2, etc.)
         * @param correctSequence Correct sequence that was displayed
         * @return Vector of StimulusItem representing user's answer
         */
        private function convertInputToSequence(input:Vector.<int>, correctSequence:Vector.<StimulusItem>):Vector.<StimulusItem> {
            var sequence:Vector.<StimulusItem> = new Vector.<StimulusItem>();

            // User input contains button indices (0, 1, 2, etc.)
            // Each index should map to the item at that position in the displayed sequence
            // E.g., if user clicked buttons [0, 1], they're recalling items at index 0 and 1
            for each (var buttonIndex:int in input) {
                if (buttonIndex >= 0 && buttonIndex < correctSequence.length) {
                    // Get the item that was at this position in the sequence
                    sequence.push(correctSequence[buttonIndex]);
                }
            }

            return sequence;
        }

        /**
         * Process sequence according to validation mode
         * @param sequence Original sequence
         * @return Processed sequence
         */
        private function processSequenceForMode(sequence:Vector.<StimulusItem>):Vector.<StimulusItem> {
            var processed:Vector.<StimulusItem> = sequence.slice();

            switch (_validationMode) {
                case MODE_REVERSE:
                    processed.reverse();
                    break;
                case MODE_SORT:
                    // Sort by value (numerical order for cognitive task)
                    processed.sort(compareByShape);
                    break;
                case MODE_FORWARD:
                default:
                    // No change
                    break;
            }

            return processed;
        }

        /**
         * Compare two sequences at specific index
         * @param seq1 First sequence
         * @param seq2 Second sequence
         * @param index Index to compare
         * @return True if match
         */
        private function sequencesMatchAt(seq1:Vector.<StimulusItem>, seq2:Vector.<StimulusItem>, index:int):Boolean {
            if (index >= seq1.length || index >= seq2.length) {
                return false;
            }

            var item1:StimulusItem = seq1[index];
            var item2:StimulusItem = seq2[index];

            // For forward/reverse mode, check exact match
            // For sort mode, might check different criteria
            return item1.equals(item2);
        }

        /**
         * Compare function for sorting by shape
         * @param a First item
         * @param b Second item
         * @return Comparison result
         */
        private function compareByShape(a:StimulusItem, b:StimulusItem):int {
            if (a.shape < b.shape) return -1;
            if (a.shape > b.shape) return 1;
            return 0;
        }
    }
}