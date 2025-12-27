package generation {
    
    /**
     * QuestionGenerator - Generates number arrangement questions.
     * 
     * Algorithm:
     * 1. Pick N unique random numbers from 0-9 (no repetition)
     * 2. Store as originalSequence
     * 3. Sort descending to create displayedSequence
     * 4. Calculate correctAnswer based on level:
     *    - EASY: originalSequence (remember original order)
     *    - MEDIUM: reverse of originalSequence
     *    - HARD: swap positions based on odd/even indices
     */
    public class QuestionGenerator {
        
        // ============ STATIC INSTANCE ============
        private static var _instance:QuestionGenerator;
        
        /** Available numbers pool (0-9) */
        private static const NUMBER_POOL:Array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        
        // ============ PROPERTIES ============
        
        /** Counter for unique question IDs */
        private var _questionIdCounter:int;
        
        /** Random seed (optional, for reproducible sequences) */
        private var _seed:uint;
        private var _useSeededRandom:Boolean;
        
        /** History of generated questions (for avoiding duplicates) */
        private var _history:Array;
        private var _maxHistorySize:int;
        
        /**
         * Get singleton instance
         */
        public static function getInstance():QuestionGenerator {
            if (!_instance) {
                _instance = new QuestionGenerator();
            }
            return _instance;
        }
        
        /**
         * Constructor
         */
        public function QuestionGenerator() {
            _questionIdCounter = 0;
            _seed = 0;
            _useSeededRandom = false;
            _history = [];
            _maxHistorySize = 50;
        }
        
        /**
         * Set seed for reproducible random sequences (for testing)
         */
        public function setSeed(seed:uint):void {
            _seed = seed;
            _useSeededRandom = true;
        }
        
        /**
         * Reset to use random sequences
         */
        public function useRandomSequences():void {
            _useSeededRandom = false;
        }
        
        /**
         * Clear question history
         */
        public function clearHistory():void {
            _history = [];
        }
        
        /**
         * Generate a new question
         * @param combination Number of digits (4, 6, or 8)
         * @param level Difficulty level (easy, medium, hard)
         * @return NumberQuestion object
         */
        public function generate(combination:int = 4, level:String = "easy"):NumberQuestion {
            // Validate combination
            if (combination != 4 && combination != 6 && combination != 8) {
                trace("QuestionGenerator: Invalid combination " + combination + ", defaulting to 4");
                combination = 4;
            }
            
            // Validate level
            if (level != NumberQuestion.LEVEL_EASY && 
                level != NumberQuestion.LEVEL_MEDIUM && 
                level != NumberQuestion.LEVEL_HARD) {
                trace("QuestionGenerator: Invalid level " + level + ", defaulting to easy");
                level = NumberQuestion.LEVEL_EASY;
            }
            
            var question:NumberQuestion = new NumberQuestion();
            question.id = ++_questionIdCounter;
            question.combination = combination;
            question.level = level;
            
            // Step 1: Generate original sequence (N unique random numbers from 1-10)
            question.originalSequence = generateOriginalSequence(combination);
            
            // Step 2: Create displayed sequence (sorted descending)
            question.displayedSequence = createDisplayedSequence(question.originalSequence);
            
            // Step 3: Calculate correct answer based on level
            question.correctAnswer = calculateCorrectAnswer(question.originalSequence, level);
            
            // Step 4: Generate instruction text
            question.instruction = generateInstruction(level);
            
            // Step 5: Set time limit
            question.timeLimit = question.getTimeLimit();
            
            // Add to history
            addToHistory(question);
            
            return question;
        }
        
        /**
         * Generate batch of questions with mixed difficulties
         * @param count Number of questions to generate
         * @param combination Number of digits (4, 6, or 8)
         * @param levels Array of levels to include (defaults to all)
         * @return Array of NumberQuestion objects
         */
        public function generateBatch(count:int, combination:int = 4, levels:Array = null):Array {
            if (!levels || levels.length == 0) {
                levels = [NumberQuestion.LEVEL_EASY, NumberQuestion.LEVEL_MEDIUM, NumberQuestion.LEVEL_HARD];
            }
            
            var questions:Array = [];
            var levelIndex:int = 0;
            
            for (var i:int = 0; i < count; i++) {
                var level:String = levels[levelIndex % levels.length];
                questions.push(generate(combination, level));
                levelIndex++;
            }
            
            return questions;
        }
        
        /**
         * Generate a progressive set of questions (easier to harder)
         * @param questionsPerLevel Number of questions per level
         * @param startCombination Starting combination (4, 6, or 8)
         * @return Array of NumberQuestion objects
         */
        public function generateProgressive(questionsPerLevel:int = 3, startCombination:int = 4):Array {
            var questions:Array = [];
            var combinations:Array = [4, 6, 8];
            var levels:Array = [NumberQuestion.LEVEL_EASY, NumberQuestion.LEVEL_MEDIUM, NumberQuestion.LEVEL_HARD];
            
            // Find start index
            var startIndex:int = combinations.indexOf(startCombination);
            if (startIndex < 0) startIndex = 0;
            
            // Generate questions progressing through combinations and levels
            for (var c:int = startIndex; c < combinations.length; c++) {
                for (var l:int = 0; l < levels.length; l++) {
                    for (var q:int = 0; q < questionsPerLevel; q++) {
                        questions.push(generate(combinations[c], levels[l]));
                    }
                }
            }
            
            return questions;
        }
        
        // ============ PRIVATE METHODS ============
        
        /**
         * Generate original sequence with N unique random numbers from 1-10
         */
        private function generateOriginalSequence(count:int):Array {
            var pool:Array = NUMBER_POOL.slice(); // Copy the pool
            var sequence:Array = [];
            
            // Fisher-Yates shuffle to pick random unique numbers
            for (var i:int = 0; i < count; i++) {
                var randomIndex:int = getRandomInt(0, pool.length - 1);
                sequence.push(pool[randomIndex]);
                pool.splice(randomIndex, 1); // Remove picked number
            }
            
            // Avoid generating exact duplicate of recent questions
            if (isDuplicateSequence(sequence)) {
                return generateOriginalSequence(count);
            }
            
            return sequence;
        }
        
        /**
         * Create displayed sequence by sorting descending (largest to smallest)
         */
        private function createDisplayedSequence(originalSequence:Array):Array {
            var sorted:Array = originalSequence.slice(); // Copy array
            sorted.sort(Array.NUMERIC | Array.DESCENDING);
            return sorted;
        }
        
        /**
         * Calculate correct answer based on level
         * @param originalSequence The original random sequence
         * @param level Difficulty level
         * @return Array representing the correct answer
         */
        private function calculateCorrectAnswer(originalSequence:Array, level:String):Array {
            switch (level) {
                case NumberQuestion.LEVEL_EASY:
                    // EASY: Return to original order
                    return originalSequence.slice();
                    
                case NumberQuestion.LEVEL_MEDIUM:
                    // MEDIUM: Reverse of original order
                    return originalSequence.slice().reverse();
                    
                case NumberQuestion.LEVEL_HARD:
                    // HARD: Swap odd/even index positions
                    return swapOddEvenPositions(originalSequence);
                    
                default:
                    return originalSequence.slice();
            }
        }
        
        /**
         * Swap odd and even indexed positions
         * Example: [7, 3, 8, 1] -> swap positions to get pattern
         * Index:    0  1  2  3
         * Odd indices (1, 3): values 3, 1
         * Even indices (0, 2): values 7, 8
         * Result: Even values go to odd positions and vice versa
         * [3, 7, 1, 8] - index 0 gets value from index 1, index 1 gets value from index 0, etc.
         */
        private function swapOddEvenPositions(sequence:Array):Array {
            var result:Array = sequence.slice();
            
            // Swap adjacent pairs (index 0 with 1, index 2 with 3, etc.)
            for (var i:int = 0; i < result.length - 1; i += 2) {
                var temp:* = result[i];
                result[i] = result[i + 1];
                result[i + 1] = temp;
            }
            
            return result;
        }
        
        /**
         * Generate instruction text based on level
         */
        private function generateInstruction(level:String):String {
            switch (level) {
                case NumberQuestion.LEVEL_EASY:
                    return "Susun kembali angka-angka sesuai urutan aslinya!";
                    
                case NumberQuestion.LEVEL_MEDIUM:
                    return "Susun angka-angka dalam urutan TERBALIK dari urutan aslinya!";
                    
                case NumberQuestion.LEVEL_HARD:
                    return "Tukar posisi angka ganjil dan genap dari urutan aslinya!";
                    
                default:
                    return "Susun angka-angka dengan benar!";
            }
        }
        
        /**
         * Check if sequence is duplicate of recent questions
         */
        private function isDuplicateSequence(sequence:Array):Boolean {
            var sequenceStr:String = sequence.join(",");
            
            for (var i:int = 0; i < _history.length; i++) {
                var q:NumberQuestion = _history[i] as NumberQuestion;
                if (q && q.originalSequence.join(",") == sequenceStr) {
                    return true;
                }
            }
            
            return false;
        }
        
        /**
         * Add question to history
         */
        private function addToHistory(question:NumberQuestion):void {
            _history.push(question);
            
            // Trim history if too large
            while (_history.length > _maxHistorySize) {
                _history.shift();
            }
        }
        
        /**
         * Get random integer between min and max (inclusive)
         */
        private function getRandomInt(min:int, max:int):int {
            if (_useSeededRandom) {
                // Simple seeded random (Linear Congruential Generator)
                _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
                return min + (_seed % (max - min + 1));
            }
            return min + Math.floor(Math.random() * (max - min + 1));
        }
        
        // ============ UTILITY METHODS ============
        
        /**
         * Get available combinations
         */
        public function getAvailableCombinations():Array {
            return [
                { value: NumberQuestion.COMBO_4, label: "4 Angka", description: "Kombinasi 4 angka unik" },
                { value: NumberQuestion.COMBO_6, label: "6 Angka", description: "Kombinasi 6 angka unik" },
                { value: NumberQuestion.COMBO_8, label: "8 Angka", description: "Kombinasi 8 angka unik" }
            ];
        }
        
        /**
         * Get available levels
         */
        public function getAvailableLevels():Array {
            return [
                { value: NumberQuestion.LEVEL_EASY, label: "Mudah", description: "Susun kembali ke urutan asli" },
                { value: NumberQuestion.LEVEL_MEDIUM, label: "Sedang", description: "Susun terbalik dari urutan asli" },
                { value: NumberQuestion.LEVEL_HARD, label: "Sulit", description: "Tukar posisi ganjil/genap" }
            ];
        }
        
        /**
         * Example generator for documentation
         * Shows how questions are generated with examples
         */
        public function generateExample(combination:int = 4, level:String = "easy"):String {
            var example:String = "=== CONTOH SOAL ===\n";
            example += "Kombinasi: " + combination + " angka\n";
            example += "Level: " + level + "\n\n";
            
            // Generate example
            var q:NumberQuestion = generate(combination, level);
            
            example += "Urutan Asli (random): [" + q.originalSequence.join(", ") + "]\n";
            example += "Ditampilkan (sorted): [" + q.displayedSequence.join(", ") + "]\n";
            example += "Jawaban Benar:       [" + q.correctAnswer.join(", ") + "]\n\n";
            
            example += "Instruksi: " + q.instruction + "\n";
            example += "Waktu: " + q.timeLimit + " detik\n";
            example += "Multiplier Skor: " + q.getDifficultyMultiplier() + "x\n";
            
            return example;
        }
        
        /**
         * Get total questions generated this session
         */
        public function getQuestionsGenerated():int {
            return _questionIdCounter;
        }
        
        /**
         * Reset generator state
         */
        public function reset():void {
            _questionIdCounter = 0;
            _history = [];
            _useSeededRandom = false;
            _consecutiveSwitch = 0;
            _consecutiveSix = 0;
        }
        
        // ============ STORY MODE QUESTION GENERATION ============
        
        /**
         * Difficulty rank constants (1-6)
         * Maps to combinations and levels for story/random modes
         */
        public static const RANK_4_FORWARD:int = 1;   // 4 digit, same order
        public static const RANK_6_FORWARD:int = 2;   // 6 digit, same order
        public static const RANK_4_REVERSE:int = 3;   // 4 digit, reverse
        public static const RANK_6_REVERSE:int = 4;   // 6 digit, reverse
        public static const RANK_4_SWITCH:int = 5;    // 4 digit, odd/even switch
        public static const RANK_6_SWITCH:int = 6;    // 6 digit, odd/even switch
        
        private static const RANDOM_TYPE_FORWARD:String = "forward";
        private static const RANDOM_TYPE_REVERSE:String = "reverse";
        private static const RANDOM_TYPE_SWITCH:String = "switch";
        
        /** Track recent random picks for constrained random */
        private var _consecutiveSwitch:int = 0;
        private var _consecutiveSix:int = 0;
        
        /**
         * Get question for STORY MODE based on story index (1-12)
         * 
         * Story question mapping:
         * - Soal 1-2:   4 digit, urut sesuai (forward)
         * - Soal 3-4:   6 digit, urut sesuai (forward)
         * - Soal 5-6:   4 digit, urut reverse
         * - Soal 7-8:   6 digit, urut reverse
         * - Soal 9-10:  4 digit, switch ganjil/genap
         * - Soal 11-12: 6 digit, switch ganjil/genap
         * 
         * @param storyIndex Question index (1-12)
         * @return NumberQuestion
         */
        public function getStoryQuestion(storyIndex:int):NumberQuestion {
            // Clamp to valid range
            if (storyIndex < 1) storyIndex = 1;
            if (storyIndex > 12) storyIndex = 12;
            
            var combination:int;
            var level:String;
            
            // Determine combination and level based on story index
            if (storyIndex <= 2) {
                // Soal 1-2: 4 digit forward
                combination = NumberQuestion.COMBO_4;
                level = NumberQuestion.LEVEL_EASY;
            } else if (storyIndex <= 4) {
                // Soal 3-4: 6 digit forward
                combination = NumberQuestion.COMBO_6;
                level = NumberQuestion.LEVEL_EASY;
            } else if (storyIndex <= 6) {
                // Soal 5-6: 4 digit reverse
                combination = NumberQuestion.COMBO_4;
                level = NumberQuestion.LEVEL_MEDIUM;
            } else if (storyIndex <= 8) {
                // Soal 7-8: 6 digit reverse
                combination = NumberQuestion.COMBO_6;
                level = NumberQuestion.LEVEL_MEDIUM;
            } else if (storyIndex <= 10) {
                // Soal 9-10: 4 digit switch
                combination = NumberQuestion.COMBO_4;
                level = NumberQuestion.LEVEL_HARD;
            } else {
                // Soal 11-12: 6 digit switch
                combination = NumberQuestion.COMBO_6;
                level = NumberQuestion.LEVEL_HARD;
            }
            
            return generate(combination, level);
        }
        
        /**
         * Get question for RANDOM/ENDLESS MODE.
         * 
         * Random behavior:
         * - Size: 4 or 6 (random)
         * - Type: forward/reverse/switch (random)
         * 
         * Constraints:
         * - Switch cannot appear 3 times in a row
         * - Size 6 cannot appear 4 times in a row
         * - After a wrong answer, switch is less likely
         * 
         * @param difficultyRank Legacy parameter (ignored in random selection)
         * @param lastAnswerWasWrong Whether the last answer was wrong
         * @return NumberQuestion
         */
        public function getRandomQuestion(difficultyRank:int, lastAnswerWasWrong:Boolean = false):NumberQuestion {
            var combination:int = pickRandomCombination();
            var type:String = pickRandomType(lastAnswerWasWrong);
            
            updateRandomStreaks(combination, type);
            
            var level:String = levelFromRandomType(type);
            return generate(combination, level);
        }
        
        private function pickRandomCombination():int {
            if (_consecutiveSix >= 3) {
                return NumberQuestion.COMBO_4;
            }
            return (Math.random() < 0.5) ? NumberQuestion.COMBO_4 : NumberQuestion.COMBO_6;
        }
        
        private function pickRandomType(lastAnswerWasWrong:Boolean):String {
            var allowSwitch:Boolean = (_consecutiveSwitch < 2);
            var forwardWeight:Number;
            var reverseWeight:Number;
            var switchWeight:Number;
            
            if (!allowSwitch) {
                forwardWeight = 0.5;
                reverseWeight = 0.5;
                switchWeight = 0.0;
            } else if (lastAnswerWasWrong) {
                forwardWeight = 0.4;
                reverseWeight = 0.4;
                switchWeight = 0.2;
            } else {
                forwardWeight = 0.34;
                reverseWeight = 0.33;
                switchWeight = 0.33;
            }
            
            var total:Number = forwardWeight + reverseWeight + switchWeight;
            var roll:Number = Math.random() * total;
            
            if (roll < forwardWeight) {
                return RANDOM_TYPE_FORWARD;
            }
            if (roll < forwardWeight + reverseWeight) {
                return RANDOM_TYPE_REVERSE;
            }
            return RANDOM_TYPE_SWITCH;
        }
        
        private function levelFromRandomType(type:String):String {
            switch (type) {
                case RANDOM_TYPE_REVERSE:
                    return NumberQuestion.LEVEL_MEDIUM;
                case RANDOM_TYPE_SWITCH:
                    return NumberQuestion.LEVEL_HARD;
                case RANDOM_TYPE_FORWARD:
                default:
                    return NumberQuestion.LEVEL_EASY;
            }
        }
        
        private function updateRandomStreaks(combination:int, type:String):void {
            if (type == RANDOM_TYPE_SWITCH) {
                _consecutiveSwitch++;
            } else {
                _consecutiveSwitch = 0;
            }
            
            if (combination == NumberQuestion.COMBO_6) {
                _consecutiveSix++;
            } else {
                _consecutiveSix = 0;
            }
        }
        
        /**
         * Generate question from difficulty rank (1-6)
         * 
         * Rank mapping:
         * 1 = 4 digit forward (easy)
         * 2 = 6 digit forward (easy)
         * 3 = 4 digit reverse (medium)
         * 4 = 6 digit reverse (medium)
         * 5 = 4 digit switch (hard)
         * 6 = 6 digit switch (hard)
         */
        public function generateFromRank(rank:int):NumberQuestion {
            var combination:int;
            var level:String;
            
            switch (rank) {
                case 1:
                    combination = NumberQuestion.COMBO_4;
                    level = NumberQuestion.LEVEL_EASY;
                    break;
                case 2:
                    combination = NumberQuestion.COMBO_6;
                    level = NumberQuestion.LEVEL_EASY;
                    break;
                case 3:
                    combination = NumberQuestion.COMBO_4;
                    level = NumberQuestion.LEVEL_MEDIUM;
                    break;
                case 4:
                    combination = NumberQuestion.COMBO_6;
                    level = NumberQuestion.LEVEL_MEDIUM;
                    break;
                case 5:
                    combination = NumberQuestion.COMBO_4;
                    level = NumberQuestion.LEVEL_HARD;
                    break;
                case 6:
                default:
                    combination = NumberQuestion.COMBO_6;
                    level = NumberQuestion.LEVEL_HARD;
                    break;
            }
            
            return generate(combination, level);
        }
        
        /**
         * Get rank from story index (for logging/debug)
         */
        public function getRankFromStoryIndex(storyIndex:int):int {
            if (storyIndex <= 2) return RANK_4_FORWARD;
            if (storyIndex <= 4) return RANK_6_FORWARD;
            if (storyIndex <= 6) return RANK_4_REVERSE;
            if (storyIndex <= 8) return RANK_6_REVERSE;
            if (storyIndex <= 10) return RANK_4_SWITCH;
            return RANK_6_SWITCH;
        }
        
        /**
         * Get human-readable description for a rank
         */
        public function getRankDescription(rank:int):String {
            switch (rank) {
                case 1: return "4 digit - Urut Sesuai";
                case 2: return "6 digit - Urut Sesuai";
                case 3: return "4 digit - Urut Terbalik";
                case 4: return "6 digit - Urut Terbalik";
                case 5: return "4 digit - Tukar Ganjil/Genap";
                case 6: return "6 digit - Tukar Ganjil/Genap";
                default: return "Unknown";
            }
        }
    }
}
