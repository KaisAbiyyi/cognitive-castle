package generation {

    import flash.utils.getTimer;
    import config.SequenceConfig;
    import domain.StimulusItem;
    import core.Constants;

    /**
     * SequenceGenerator - Generates random sequences of stimulus items for the cognitive challenge.
     * Supports multiple generation algorithms:
     * - Random with constraints (no triple repeat)
     * - Pattern-based generation
     * - Difficulty-scaled (length + complexity)
     *
     * SOLID Principles:
     * - Single Responsibility: Only handles sequence generation logic
     * - Open/Closed: Can be extended with new generation algorithms
     * - Dependency Inversion: Depends on abstractions (SequenceConfig)
     */
    public class SequenceGenerator {

        // Debug flag for conditional logging
        private static const DEBUG:Boolean = true;

        // Generation algorithms
        public static const ALGO_RANDOM:String = "random";
        public static const ALGO_PATTERN:String = "pattern";
        public static const ALGO_MIXED:String = "mixed";

        // Current difficulty level (1-15)
        private var _currentLevel:int = 1;

        // Random seed for reproducible sequences
        private var _seed:uint;
        
        // Last generated sequence (for undo/replay)
        private var _lastSequence:Vector.<StimulusItem>;
        
        // Generation statistics
        private var _sequencesGenerated:int = 0;

        /**
         * Constructor
         * @param seed Optional random seed for reproducible sequences
         */
        public function SequenceGenerator(seed:uint = 0) {
            _seed = seed > 0 ? seed : getTimer();
        }

        /**
         * Set the current difficulty level
         * @param level Difficulty level (1-15)
         */
        public function setLevel(level:int):void {
            _currentLevel = Math.max(1, Math.min(Constants.DIFFICULTY_LEVELS, level));
        }

        /**
         * Get the current difficulty level
         * @return Current level
         */
        public function get currentLevel():int {
            return _currentLevel;
        }

        /**
         * Generate a sequence of stimulus items based on difficulty level
         * @param difficultyLevel Override for current level (optional)
         * @param algorithm Generation algorithm to use
         * @return Vector of StimulusItem objects
         */
        public function generateSequence(difficultyLevel:int = -1, algorithm:String = null):Vector.<StimulusItem> {
            var level:int = (difficultyLevel > 0) ? difficultyLevel : _currentLevel;
            var tier:Object = getDifficultyTier(level);
            var algo:String = algorithm || (tier.usePattern ? ALGO_PATTERN : ALGO_RANDOM);

            var sequence:Vector.<StimulusItem>;
            
            switch (algo) {
                case ALGO_PATTERN:
                    sequence = generatePatternSequence(tier, level);
                    break;
                case ALGO_MIXED:
                    sequence = generateMixedSequence(tier, level);
                    break;
                case ALGO_RANDOM:
                default:
                    sequence = generateRandomSequence(tier, level);
                    break;
            }
            
            // Validate and store
            if (validateSequence(sequence, level)) {
                _lastSequence = sequence;
                _sequencesGenerated++;
            }
            
            return sequence;
        }
        
        /**
         * Generate a random sequence with constraints
         */
        private function generateRandomSequence(tier:Object, level:int):Vector.<StimulusItem> {
            var length:int = generateSequenceLength(tier.minLength, tier.maxLength);
            var availableShapes:Array = SequenceConfig.SYMBOL_POOL.slice(0, tier.symbols);
            var availableColors:Array = SequenceConfig.COLORS.slice(0, tier.colors);

            var sequence:Vector.<StimulusItem> = new Vector.<StimulusItem>();

            for (var i:int = 0; i < length; i++) {
                var shape:String = selectShape(availableShapes, sequence, i);
                var color:uint = selectColor(availableColors, sequence, i);
                var value:int = i + 1; // Sequential value for sorting

                var item:StimulusItem = new StimulusItem(i, shape, color, value, StimulusItem.TYPE_SHAPE);
                item.position = i;
                item.tier = level;
                sequence.push(item);
            }

            return sequence;
        }
        
        /**
         * Generate a pattern-based sequence (e.g., ABAB, AABB, ABC)
         */
        private function generatePatternSequence(tier:Object, level:int):Vector.<StimulusItem> {
            var patterns:Array = getPatterns(tier);
            var pattern:String = patterns[Math.floor(Math.random() * patterns.length)];
            
            var length:int = generateSequenceLength(tier.minLength, tier.maxLength);
            var availableShapes:Array = SequenceConfig.SYMBOL_POOL.slice(0, tier.symbols);
            var availableColors:Array = SequenceConfig.COLORS.slice(0, tier.colors);
            
            // Map pattern letters to actual items
            var mapping:Object = {};
            var mappingIndex:int = 0;
            
            var sequence:Vector.<StimulusItem> = new Vector.<StimulusItem>();
            
            for (var i:int = 0; i < length; i++) {
                var patternChar:String = pattern.charAt(i % pattern.length);
                
                if (!mapping[patternChar]) {
                    mapping[patternChar] = {
                        shape: availableShapes[mappingIndex % availableShapes.length],
                        color: availableColors[mappingIndex % availableColors.length]
                    };
                    mappingIndex++;
                }
                
                var mapped:Object = mapping[patternChar];
                var item:StimulusItem = new StimulusItem(
                    i, 
                    mapped.shape, 
                    mapped.color, 
                    i + 1, 
                    StimulusItem.TYPE_PATTERN
                );
                item.position = i;
                item.tier = level;
                item.patternData = [patternChar, pattern];
                sequence.push(item);
            }
            
            return sequence;
        }
        
        /**
         * Generate a mixed sequence (random with occasional patterns)
         */
        private function generateMixedSequence(tier:Object, level:int):Vector.<StimulusItem> {
            // 50% chance of pattern-based
            if (Math.random() < 0.5) {
                return generatePatternSequence(tier, level);
            }
            return generateRandomSequence(tier, level);
        }
        
        /**
         * Get available patterns for a tier
         */
        private function getPatterns(tier:Object):Array {
            var complexity:int = tier.patternComplexity || 1;
            
            // Simple patterns
            var simple:Array = ["AB", "ABB", "AAB"];
            // Medium patterns
            var medium:Array = ["ABC", "ABAB", "AABB", "ABBA"];
            // Complex patterns
            var complex:Array = ["ABCD", "ABCABC", "AABBCC", "ABACAD"];
            
            switch (complexity) {
                case 3: return complex.concat(medium);
                case 2: return medium.concat(simple);
                default: return simple;
            }
        }

        /**
         * Get difficulty tier configuration for levels 1-15
         * @param level Difficulty level
         * @return Tier configuration object
         */
        private function getDifficultyTier(level:int):Object {
            // 15-level difficulty progression
            var tiers:Array = [
                // Level 1-3: Beginner
                { level: 1, minLength: 2, maxLength: 3, symbols: 2, colors: 2, usePattern: false, patternComplexity: 1 },
                { level: 2, minLength: 3, maxLength: 3, symbols: 3, colors: 2, usePattern: false, patternComplexity: 1 },
                { level: 3, minLength: 3, maxLength: 4, symbols: 3, colors: 3, usePattern: false, patternComplexity: 1 },
                
                // Level 4-6: Easy
                { level: 4, minLength: 4, maxLength: 4, symbols: 4, colors: 3, usePattern: false, patternComplexity: 1 },
                { level: 5, minLength: 4, maxLength: 5, symbols: 4, colors: 4, usePattern: false, patternComplexity: 1 },
                { level: 6, minLength: 5, maxLength: 5, symbols: 5, colors: 4, usePattern: true, patternComplexity: 1 },
                
                // Level 7-9: Medium
                { level: 7, minLength: 5, maxLength: 6, symbols: 5, colors: 5, usePattern: true, patternComplexity: 2 },
                { level: 8, minLength: 6, maxLength: 6, symbols: 6, colors: 5, usePattern: true, patternComplexity: 2 },
                { level: 9, minLength: 6, maxLength: 7, symbols: 6, colors: 6, usePattern: true, patternComplexity: 2 },
                
                // Level 10-12: Hard
                { level: 10, minLength: 7, maxLength: 7, symbols: 6, colors: 6, usePattern: true, patternComplexity: 2 },
                { level: 11, minLength: 7, maxLength: 8, symbols: 6, colors: 6, usePattern: true, patternComplexity: 3 },
                { level: 12, minLength: 8, maxLength: 8, symbols: 6, colors: 6, usePattern: true, patternComplexity: 3 },
                
                // Level 13-15: Expert
                { level: 13, minLength: 8, maxLength: 9, symbols: 6, colors: 6, usePattern: true, patternComplexity: 3 },
                { level: 14, minLength: 9, maxLength: 10, symbols: 6, colors: 6, usePattern: true, patternComplexity: 3 },
                { level: 15, minLength: 10, maxLength: 12, symbols: 6, colors: 6, usePattern: true, patternComplexity: 3 }
            ];
            
            level = Math.max(1, Math.min(15, level));
            return tiers[level - 1];
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
         * Select a shape following randomness rules
         * @param availableShapes Array of available shapes
         * @param currentSequence Current sequence being built
         * @param position Current position in sequence
         * @return Selected shape
         */
        private function selectShape(availableShapes:Array, currentSequence:Vector.<StimulusItem>, position:int):String {
            var candidates:Array = availableShapes.slice();

            // Apply randomness rules: no three consecutive identical shapes
            if (position >= 2) {
                var prev1:String = currentSequence[position - 1].shape;
                var prev2:String = currentSequence[position - 2].shape;

                if (prev1 == prev2) {
                    var repeatIndex:int = candidates.indexOf(prev1);
                    if (repeatIndex >= 0) {
                        candidates.splice(repeatIndex, 1);
                    }
                }
            }

            if (candidates.length == 0) {
                candidates = availableShapes.slice();
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
            var candidates:Array = availableColors.slice();

            // Ensure distinct colors (no immediate repeats)
            if (position >= 1 && SequenceConfig.COLOR_VARIATION.ensureDistinct) {
                var prevColor:uint = currentSequence[position - 1].color;
                var prevIndex:int = candidates.indexOf(prevColor);
                if (prevIndex >= 0) {
                    candidates.splice(prevIndex, 1);
                }
            }

            if (candidates.length == 0) {
                candidates = availableColors.slice();
            }

            return candidates[Math.floor(Math.random() * candidates.length)];
        }
        
        /**
         * Get the expected sequence for a given mode
         * @param sequence Original sequence
         * @param mode Recall mode (forward, reverse, sorted)
         * @return Expected sequence for validation
         */
        public function getExpectedSequence(sequence:Vector.<StimulusItem>, mode:String):Vector.<int> {
            var expected:Vector.<int> = new Vector.<int>();
            var items:Vector.<StimulusItem> = sequence.slice();
            
            switch (mode) {
                case Constants.MODE_REVERSE:
                    items = items.reverse();
                    break;
                case Constants.MODE_SORTED:
                    items.sort(function(a:StimulusItem, b:StimulusItem):int {
                        return a.value - b.value;
                    });
                    break;
                // Forward is default - no change
            }
            
            for each (var item:StimulusItem in items) {
                expected.push(item.id);
            }
            
            return expected;
        }

        /**
         * Validate a generated sequence against rules
         * @param sequence Sequence to validate
         * @param level Expected difficulty level
         * @return True if valid
         */
        public function validateSequence(sequence:Vector.<StimulusItem>, level:int):Boolean {
            if (!sequence || sequence.length == 0) return false;
            
            var tier:Object = getDifficultyTier(level);
            var valid:Boolean = true;

            // Check length
            if (sequence.length < tier.minLength || sequence.length > tier.maxLength) {
                if (DEBUG) {
                    trace("[SequenceGenerator] Invalid length " + sequence.length + 
                          " for level " + level + " (expected " + tier.minLength + "-" + tier.maxLength + ")");
                }
                valid = false;
            }

            // Check no three consecutive identical shapes
            for (var i:int = 2; i < sequence.length; i++) {
                if (sequence[i].shape == sequence[i-1].shape &&
                    sequence[i].shape == sequence[i-2].shape) {
                    if (DEBUG) {
                        trace("[SequenceGenerator] Three consecutive same shapes at position " + i);
                    }
                    valid = false;
                }
            }

            // Check no immediate color repeats
            if (SequenceConfig.COLOR_VARIATION.ensureDistinct) {
                for (i = 1; i < sequence.length; i++) {
                    if (sequence[i].color == sequence[i-1].color) {
                        if (DEBUG) {
                            trace("[SequenceGenerator] Consecutive same colors at position " + i);
                        }
                        valid = false;
                    }
                }
            }

            return valid;
        }
        
        /**
         * Get the last generated sequence
         */
        public function get lastSequence():Vector.<StimulusItem> {
            return _lastSequence;
        }
        
        /**
         * Get total sequences generated
         */
        public function get sequencesGenerated():int {
            return _sequencesGenerated;
        }

        /**
         * Debug method: Generate and log a sequence for testing
         * @param level Difficulty level
         * @return Generated sequence
         */
        public function generateAndLog(level:int = -1):Vector.<StimulusItem> {
            var sequence:Vector.<StimulusItem> = generateSequence(level);
            if (DEBUG) {
                trace("Generated sequence for level " + (level > 0 ? level : _currentLevel) + ":");
                for (var i:int = 0; i < sequence.length; i++) {
                    trace("  " + i + ": " + sequence[i].toString());
                }
            }
            return sequence;
        }
    }
}