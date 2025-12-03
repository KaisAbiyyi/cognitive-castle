package generation {
    
    /**
     * NumberQuestion - Data class representing a single number arrangement question.
     * Contains the original sequence, displayed sequence (sorted), answer, and metadata.
     * 
     * Supports three combinations:
     * - 4 digits: Numbers 0-9, pick 4 unique
     * - 6 digits: Numbers 0-9, pick 6 unique
     * - 8 digits: Numbers 0-9, pick 8 unique
     * 
     * Supports three difficulty levels:
     * - EASY: Recall original order
     * - MEDIUM: Recall reversed order
     * - HARD: Swap odd/even indexed positions
     */
    public class NumberQuestion {
        
        // ============ COMBINATION TYPES ============
        /** 4-digit combination */
        public static const COMBO_4:int = 4;
        /** 6-digit combination */
        public static const COMBO_6:int = 6;
        /** 8-digit combination */
        public static const COMBO_8:int = 8;
        
        // ============ DIFFICULTY LEVELS ============
        /** Easy: Recall original order */
        public static const LEVEL_EASY:String = "easy";
        /** Medium: Recall reversed order */
        public static const LEVEL_MEDIUM:String = "medium";
        /** Hard: Swap odd/even index positions */
        public static const LEVEL_HARD:String = "hard";
        
        // ============ PROPERTIES ============
        
        /** Unique question ID */
        public var id:int;
        
        /** Combination type (4, 6, or 8) */
        public var combination:int;
        
        /** Difficulty level (easy, medium, hard) */
        public var level:String;
        
        /** Original randomly generated sequence (the answer for EASY level) */
        public var originalSequence:Array;
        
        /** Displayed sequence (sorted from largest to smallest) */
        public var displayedSequence:Array;
        
        /** Correct answer based on level rules */
        public var correctAnswer:Array;
        
        /** Instruction text to show the player */
        public var instruction:String;
        
        /** Timestamp when question was created */
        public var createdAt:Number;
        
        /** Time limit in seconds for this question */
        public var timeLimit:int;
        
        /**
         * Constructor
         */
        public function NumberQuestion() {
            this.id = 0;
            this.combination = COMBO_4;
            this.level = LEVEL_EASY;
            this.originalSequence = [];
            this.displayedSequence = [];
            this.correctAnswer = [];
            this.instruction = "";
            this.createdAt = new Date().time;
            this.timeLimit = 30;
        }
        
        /**
         * Get difficulty multiplier for scoring
         */
        public function getDifficultyMultiplier():Number {
            var baseMultiplier:Number = 1.0;
            
            // Combination multiplier
            switch (combination) {
                case COMBO_4: baseMultiplier = 1.0; break;
                case COMBO_6: baseMultiplier = 1.5; break;
                case COMBO_8: baseMultiplier = 2.0; break;
            }
            
            // Level multiplier
            switch (level) {
                case LEVEL_EASY: baseMultiplier *= 1.0; break;
                case LEVEL_MEDIUM: baseMultiplier *= 1.5; break;
                case LEVEL_HARD: baseMultiplier *= 2.0; break;
            }
            
            return baseMultiplier;
        }
        
        /**
         * Get time limit based on combination and level
         */
        public function getTimeLimit():int {
            var base:int = 15;
            
            // Add time for more digits
            switch (combination) {
                case COMBO_4: base = 15; break;
                case COMBO_6: base = 25; break;
                case COMBO_8: base = 35; break;
            }
            
            // Adjust for level
            switch (level) {
                case LEVEL_EASY: break; // No change
                case LEVEL_MEDIUM: base += 5; break;
                case LEVEL_HARD: base += 10; break;
            }
            
            return base;
        }
        
        /**
         * Validate a user's answer
         * @param userAnswer Array of numbers entered by user
         * @return Object with isCorrect, correctCount, accuracy
         */
        public function validateAnswer(userAnswer:Array):Object {
            var result:Object = {
                isCorrect: false,
                correctCount: 0,
                totalCount: correctAnswer.length,
                accuracy: 0,
                errors: []
            };
            
            if (!userAnswer || userAnswer.length != correctAnswer.length) {
                result.errors.push("Jumlah angka tidak sesuai");
                return result;
            }
            
            for (var i:int = 0; i < correctAnswer.length; i++) {
                if (userAnswer[i] == correctAnswer[i]) {
                    result.correctCount++;
                } else {
                    result.errors.push("Posisi " + (i + 1) + ": seharusnya " + correctAnswer[i] + ", Anda jawab " + userAnswer[i]);
                }
            }
            
            result.accuracy = result.correctCount / result.totalCount;
            result.isCorrect = (result.correctCount == result.totalCount);
            
            return result;
        }
        
        /**
         * Get human-readable level name in Indonesian
         */
        public function getLevelName():String {
            switch (level) {
                case LEVEL_EASY: return "Mudah";
                case LEVEL_MEDIUM: return "Sedang";
                case LEVEL_HARD: return "Sulit";
                default: return level;
            }
        }
        
        /**
         * Clone this question
         */
        public function clone():NumberQuestion {
            var q:NumberQuestion = new NumberQuestion();
            q.id = this.id;
            q.combination = this.combination;
            q.level = this.level;
            q.originalSequence = this.originalSequence.slice();
            q.displayedSequence = this.displayedSequence.slice();
            q.correctAnswer = this.correctAnswer.slice();
            q.instruction = this.instruction;
            q.createdAt = this.createdAt;
            q.timeLimit = this.timeLimit;
            return q;
        }
        
        /**
         * Convert to string representation for debugging
         */
        public function toString():String {
            return "[NumberQuestion id=" + id + 
                   " combo=" + combination + 
                   " level=" + level + 
                   " original=[" + originalSequence.join(",") + "]" +
                   " displayed=[" + displayedSequence.join(",") + "]" +
                   " answer=[" + correctAnswer.join(",") + "]]";
        }
    }
}
