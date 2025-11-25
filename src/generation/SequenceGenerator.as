package generation {

    import flash.utils.getTimer;
    import config.SequenceConfig;
    import domain.StimulusItem;

    /**
     * SequenceGenerator - Generates random sequences of stimulus items for the cognitive challenge.
     * Uses difficulty tiers from SequenceConfig with randomness rules to ensure fair challenge.
     *
     * SOLID Principles:
     * - Single Responsibility: Only handles sequence generation logic
     * - Open/Closed: Can be extended with new generation algorithms
     * - Dependency Inversion: Depends on abstractions (SequenceConfig)
     */
    public class SequenceGenerator {

        // Debug flag for conditional logging
        private static const DEBUG:Boolean = true;

        // Current difficulty level (placeholder - will be hooked to adaptive system later)
        private static var _currentLevel:int = 1;

        // Random seed for reproducible sequences (optional)
        private var _seed:uint;

        /**
         * Constructor
         * @param seed Optional random seed for reproducible sequences
         */
        public function SequenceGenerator(seed:uint = 0) {
            _seed = seed > 0 ? seed : getTimer();
        }

        /**
         * Set the current difficulty level
         * @param level Difficulty level (1-5)
         */
        public static function setCurrentLevel(level:int):void {
            _currentLevel = Math.max(1, Math.min(5, level));
        }

        /**
         * Get the current difficulty level
         * @return Current level
         */
        public static function getCurrentLevel():int {
            return _currentLevel;
        }

        /**
         * Generate a sequence of stimulus items based on difficulty level
         * @param difficultyLevel Override for current level (optional)
         * @return Vector of StimulusItem objects
         */
        public function generateSequence(difficultyLevel:int = -1):Vector.<StimulusItem> {
            var level:int = (difficultyLevel > 0) ? difficultyLevel : _currentLevel;
            var tier:Object = getDifficultyTier(level);

            var length:int = generateSequenceLength(tier.minLength, tier.maxLength);
            var availableSymbols:Array = SequenceConfig.SYMBOL_POOL.slice(0, tier.symbols);
            var availableColors:Array = SequenceConfig.COLORS.slice(0, tier.colors);

            var sequence:Vector.<StimulusItem> = new Vector.<StimulusItem>();

            for (var i:int = 0; i < length; i++) {
                var symbol:String = selectSymbol(availableSymbols, sequence, i);
                var color:uint = selectColor(availableColors, sequence, i);
                var id:int = i; // Simple sequential ID for now

                var item:StimulusItem = new StimulusItem(id, symbol, color);
                sequence.push(item);
            }

            return sequence;
        }

        /**
         * Get difficulty tier configuration
         * @param level Difficulty level
         * @return Tier configuration object
         */
        private function getDifficultyTier(level:int):Object {
            if (level < 1 || level > SequenceConfig.DIFFICULTY_TIERS.length) {
                level = 1;
            }
            return SequenceConfig.DIFFICULTY_TIERS[level - 1];
        }

        /**
         * Generate random sequence length within tier bounds
         * @param min Minimum length
         * @param max Maximum length
         * @return Random length
         */
        private function generateSequenceLength(min:int, max:int):int {
            return min + Math.floor(Math.random() * (max - min + 1));
        }

        /**
         * Select a symbol following randomness rules
         * @param availableSymbols Array of available symbols
         * @param currentSequence Current sequence being built
         * @param position Current position in sequence
         * @return Selected symbol
         */
        private function selectSymbol(availableSymbols:Array, currentSequence:Vector.<StimulusItem>, position:int):String {
            var candidates:Array = availableSymbols.slice(); // Copy array

            // Apply randomness rules: no three consecutive identical symbols
            if (position >= 2) {
                var prev1:String = currentSequence[position - 1].symbol;
                var prev2:String = currentSequence[position - 2].symbol;

                if (prev1 == prev2) {
                    // Remove the repeating symbol from candidates
                    var repeatIndex:int = candidates.indexOf(prev1);
                    if (repeatIndex >= 0) {
                        candidates.splice(repeatIndex, 1);
                    }
                }
            }

            // If no candidates left (unlikely), reset to full pool
            if (candidates.length == 0) {
                candidates = availableSymbols.slice();
            }

            return candidates[Math.floor(Math.random() * candidates.length)];
        }

        /**
         * Select a color following randomness rules
         * @param availableColors Array of available colors
         * @param currentSequence Current sequence being built
         * @param position Current position in sequence
         * @return Selected color
         */
        private function selectColor(availableColors:Array, currentSequence:Vector.<StimulusItem>, position:int):uint {
            var candidates:Array = availableColors.slice(); // Copy array

            // Apply randomness rules: ensure distinct colors (no immediate repeats)
            if (position >= 1 && SequenceConfig.COLOR_VARIATION.ensureDistinct) {
                var prevColor:uint = currentSequence[position - 1].color;
                var prevIndex:int = candidates.indexOf(prevColor);
                if (prevIndex >= 0) {
                    candidates.splice(prevIndex, 1);
                }
            }

            // If no candidates left, reset to full pool
            if (candidates.length == 0) {
                candidates = availableColors.slice();
            }

            return candidates[Math.floor(Math.random() * candidates.length)];
        }

        /**
         * Debug method: Generate and log a sequence for testing
         * @param level Difficulty level
         * @return Generated sequence
         */
        public function generateAndLogSequence(level:int = -1):Vector.<StimulusItem> {
            var sequence:Vector.<StimulusItem> = generateSequence(level);
            if (DEBUG) {
                trace("Generated sequence for level " + (level > 0 ? level : _currentLevel) + ":");
                for (var i:int = 0; i < sequence.length; i++) {
                    trace("  " + i + ": " + sequence[i].toString());
                }
            }
            return sequence;
        }

        /**
         * Test harness: Verify sequence generation rules
         * @param iterations Number of test sequences to generate
         */
        public function runTestHarness(iterations:int = 10):void {
            if (DEBUG) {
                trace("=== SequenceGenerator Test Harness ===");
                for (var level:int = 1; level <= 5; level++) {
                    trace("Testing Level " + level + ":");
                    for (var i:int = 0; i < iterations; i++) {
                        var sequence:Vector.<StimulusItem> = generateSequence(level);
                        validateSequence(sequence, level);
                    }
                }
                trace("=== Test Harness Complete ===");
            }
        }

        /**
         * Validate a generated sequence against rules
         * @param sequence Sequence to validate
         * @param level Expected difficulty level
         */
        private function validateSequence(sequence:Vector.<StimulusItem>, level:int):void {
            var tier:Object = getDifficultyTier(level);

            // Check length
            if (sequence.length < tier.minLength || sequence.length > tier.maxLength) {
                if (DEBUG) {
                    trace("ERROR: Invalid length " + sequence.length + " for level " + level);
                }
            }

            // Check symbol variety
            var usedSymbols:Object = {};
            var symbolCount:int = 0;
            for each (var item:StimulusItem in sequence) {
                if (!usedSymbols[item.symbol]) {
                    usedSymbols[item.symbol] = true;
                    symbolCount++;
                }
            }
            if (symbolCount > tier.symbols) {
                if (DEBUG) {
                    trace("ERROR: Too many symbol types (" + symbolCount + ") for level " + level + " (max " + tier.symbols + ")");
                }
            }

            // Check color rules
            for (var i:int = 1; i < sequence.length; i++) {
                if (SequenceConfig.COLOR_VARIATION.ensureDistinct &&
                    sequence[i].color == sequence[i-1].color) {
                    if (DEBUG) {
                        trace("ERROR: Consecutive same colors at position " + i);
                    }
                }
            }

            // Check symbol rules
            for (i = 2; i < sequence.length; i++) {
                if (sequence[i].symbol == sequence[i-1].symbol &&
                    sequence[i].symbol == sequence[i-2].symbol) {
                    if (DEBUG) {
                        trace("ERROR: Three consecutive same symbols at position " + i);
                    }
                }
            }
        }
    }
}