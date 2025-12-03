package generation {
    
    import flash.events.EventDispatcher;
    
    /**
     * QuestionManager - Manages question sessions, tracks player progress,
     * and coordinates between question generation and game flow.
     * 
     * Events:
     * - "questionReady": New question is ready
     * - "answerValidated": Answer has been validated
     * - "sessionComplete": All questions in session completed
     * - "levelUp": Player advanced to next level
     */
    public class QuestionManager extends EventDispatcher {
        
        // ============ EVENTS ============
        public static const EVENT_QUESTION_READY:String = "questionReady";
        public static const EVENT_ANSWER_VALIDATED:String = "answerValidated";
        public static const EVENT_SESSION_COMPLETE:String = "sessionComplete";
        public static const EVENT_LEVEL_UP:String = "levelUp";
        
        // ============ SINGLETON ============
        private static var _instance:QuestionManager;
        
        // ============ PROPERTIES ============
        
        /** Question generator instance */
        private var _generator:QuestionGenerator;
        
        /** Current active question */
        private var _currentQuestion:NumberQuestion;
        
        /** Queue of upcoming questions */
        private var _questionQueue:Array;
        
        /** Current session statistics */
        private var _sessionStats:Object;
        
        /** Current difficulty settings */
        private var _currentCombination:int;
        private var _currentLevel:String;
        
        /** Auto-progression settings */
        private var _autoProgressEnabled:Boolean;
        private var _correctStreakForLevelUp:int;
        private var _incorrectStreakForLevelDown:int;
        
        /** Current streak counters */
        private var _correctStreak:int;
        private var _incorrectStreak:int;
        
        /**
         * Get singleton instance
         */
        public static function getInstance():QuestionManager {
            if (!_instance) {
                _instance = new QuestionManager();
            }
            return _instance;
        }
        
        /**
         * Constructor
         */
        public function QuestionManager() {
            _generator = QuestionGenerator.getInstance();
            _questionQueue = [];
            _currentQuestion = null;
            
            // Default settings
            _currentCombination = NumberQuestion.COMBO_4;
            _currentLevel = NumberQuestion.LEVEL_EASY;
            
            _autoProgressEnabled = true;
            _correctStreakForLevelUp = 3;
            _incorrectStreakForLevelDown = 2;
            
            resetSession();
        }
        
        /**
         * Reset session statistics
         */
        public function resetSession():void {
            _sessionStats = {
                totalQuestions: 0,
                correctAnswers: 0,
                incorrectAnswers: 0,
                totalScore: 0,
                totalTime: 0,
                averageAccuracy: 0,
                levelHistory: [],
                startTime: new Date().time
            };
            
            _correctStreak = 0;
            _incorrectStreak = 0;
            _questionQueue = [];
        }
        
        /**
         * Start a new session with specified settings
         */
        public function startSession(combination:int = 4, level:String = "easy"):void {
            resetSession();
            _currentCombination = combination;
            _currentLevel = level;
            
            // Pre-generate first batch of questions
            generateQuestionBatch(5);
        }
        
        /**
         * Get next question from queue or generate new one
         */
        public function getNextQuestion():NumberQuestion {
            // Generate more questions if queue is low
            if (_questionQueue.length < 3) {
                generateQuestionBatch(5);
            }
            
            // Get question from queue
            if (_questionQueue.length > 0) {
                _currentQuestion = _questionQueue.shift() as NumberQuestion;
            } else {
                // Fallback: generate single question
                _currentQuestion = _generator.generate(_currentCombination, _currentLevel);
            }
            
            _sessionStats.totalQuestions++;
            
            // Dispatch event
            dispatchEvent(new QuestionEvent(EVENT_QUESTION_READY, _currentQuestion));
            
            return _currentQuestion;
        }
        
        /**
         * Submit answer for current question
         * @param userAnswer Array of numbers
         * @return Validation result object
         */
        public function submitAnswer(userAnswer:Array, timeSpent:Number = 0):Object {
            if (!_currentQuestion) {
                return { isCorrect: false, error: "No active question" };
            }
            
            // Validate answer
            var result:Object = _currentQuestion.validateAnswer(userAnswer);
            result.timeSpent = timeSpent;
            result.question = _currentQuestion;
            
            // Update statistics
            updateSessionStats(result);
            
            // Update streaks and check for level change
            if (result.isCorrect) {
                _correctStreak++;
                _incorrectStreak = 0;
                
                // Calculate score with bonuses
                result.baseScore = 100;
                result.difficultyBonus = Math.floor(result.baseScore * (_currentQuestion.getDifficultyMultiplier() - 1));
                
                // Time bonus (faster = more points)
                var timeRatio:Number = Math.max(0, 1 - (timeSpent / _currentQuestion.timeLimit));
                result.timeBonus = Math.floor(50 * timeRatio);
                
                result.totalScore = result.baseScore + result.difficultyBonus + result.timeBonus;
                _sessionStats.totalScore += result.totalScore;
                
                // Check for level up
                if (_autoProgressEnabled && _correctStreak >= _correctStreakForLevelUp) {
                    progressToNextLevel();
                }
            } else {
                _incorrectStreak++;
                _correctStreak = 0;
                result.totalScore = 0;
                
                // Check for level down
                if (_autoProgressEnabled && _incorrectStreak >= _incorrectStreakForLevelDown) {
                    regressToPreviousLevel();
                }
            }
            
            _sessionStats.totalTime += timeSpent;
            
            // Dispatch event
            dispatchEvent(new QuestionEvent(EVENT_ANSWER_VALIDATED, _currentQuestion, result));
            
            return result;
        }
        
        /**
         * Skip current question (counts as incorrect)
         */
        public function skipQuestion():void {
            if (_currentQuestion) {
                submitAnswer([], _currentQuestion.timeLimit);
            }
        }
        
        // ============ DIFFICULTY MANAGEMENT ============
        
        /**
         * Set current combination
         */
        public function setCombination(combination:int):void {
            if (combination == 4 || combination == 6 || combination == 8) {
                _currentCombination = combination;
                regenerateQueue();
            }
        }
        
        /**
         * Set current level
         */
        public function setLevel(level:String):void {
            if (level == NumberQuestion.LEVEL_EASY || 
                level == NumberQuestion.LEVEL_MEDIUM || 
                level == NumberQuestion.LEVEL_HARD) {
                _currentLevel = level;
                regenerateQueue();
            }
        }
        
        /**
         * Progress to next difficulty level
         */
        private function progressToNextLevel():void {
            var oldLevel:String = _currentLevel;
            var oldCombo:int = _currentCombination;
            
            // Progress order: Easy->Medium->Hard, then increase combination
            if (_currentLevel == NumberQuestion.LEVEL_EASY) {
                _currentLevel = NumberQuestion.LEVEL_MEDIUM;
            } else if (_currentLevel == NumberQuestion.LEVEL_MEDIUM) {
                _currentLevel = NumberQuestion.LEVEL_HARD;
            } else if (_currentLevel == NumberQuestion.LEVEL_HARD) {
                // Move to next combination
                if (_currentCombination == NumberQuestion.COMBO_4) {
                    _currentCombination = NumberQuestion.COMBO_6;
                    _currentLevel = NumberQuestion.LEVEL_EASY;
                } else if (_currentCombination == NumberQuestion.COMBO_6) {
                    _currentCombination = NumberQuestion.COMBO_8;
                    _currentLevel = NumberQuestion.LEVEL_EASY;
                }
                // Already at max (8 HARD) - stay there
            }
            
            // Only dispatch if actually changed
            if (oldLevel != _currentLevel || oldCombo != _currentCombination) {
                _correctStreak = 0;
                _sessionStats.levelHistory.push({
                    type: "up",
                    fromCombination: oldCombo,
                    fromLevel: oldLevel,
                    toCombination: _currentCombination,
                    toLevel: _currentLevel,
                    time: new Date().time
                });
                
                regenerateQueue();
                dispatchEvent(new QuestionEvent(EVENT_LEVEL_UP, null, {
                    combination: _currentCombination,
                    level: _currentLevel
                }));
            }
        }
        
        /**
         * Regress to previous difficulty level
         */
        private function regressToPreviousLevel():void {
            var oldLevel:String = _currentLevel;
            var oldCombo:int = _currentCombination;
            
            // Regress order: Hard->Medium->Easy, then decrease combination
            if (_currentLevel == NumberQuestion.LEVEL_HARD) {
                _currentLevel = NumberQuestion.LEVEL_MEDIUM;
            } else if (_currentLevel == NumberQuestion.LEVEL_MEDIUM) {
                _currentLevel = NumberQuestion.LEVEL_EASY;
            } else if (_currentLevel == NumberQuestion.LEVEL_EASY) {
                // Move to previous combination
                if (_currentCombination == NumberQuestion.COMBO_8) {
                    _currentCombination = NumberQuestion.COMBO_6;
                    _currentLevel = NumberQuestion.LEVEL_HARD;
                } else if (_currentCombination == NumberQuestion.COMBO_6) {
                    _currentCombination = NumberQuestion.COMBO_4;
                    _currentLevel = NumberQuestion.LEVEL_HARD;
                }
                // Already at min (4 EASY) - stay there
            }
            
            // Only regenerate if actually changed
            if (oldLevel != _currentLevel || oldCombo != _currentCombination) {
                _incorrectStreak = 0;
                _sessionStats.levelHistory.push({
                    type: "down",
                    fromCombination: oldCombo,
                    fromLevel: oldLevel,
                    toCombination: _currentCombination,
                    toLevel: _currentLevel,
                    time: new Date().time
                });
                
                regenerateQueue();
            }
        }
        
        // ============ PRIVATE HELPERS ============
        
        /**
         * Generate a batch of questions for the queue
         */
        private function generateQuestionBatch(count:int):void {
            for (var i:int = 0; i < count; i++) {
                _questionQueue.push(_generator.generate(_currentCombination, _currentLevel));
            }
        }
        
        /**
         * Clear and regenerate question queue
         */
        private function regenerateQueue():void {
            _questionQueue = [];
            generateQuestionBatch(5);
        }
        
        /**
         * Update session statistics
         */
        private function updateSessionStats(result:Object):void {
            if (result.isCorrect) {
                _sessionStats.correctAnswers++;
            } else {
                _sessionStats.incorrectAnswers++;
            }
            
            // Update average accuracy
            _sessionStats.averageAccuracy = _sessionStats.correctAnswers / _sessionStats.totalQuestions;
        }
        
        // ============ GETTERS ============
        
        /** Get current question */
        public function get currentQuestion():NumberQuestion {
            return _currentQuestion;
        }
        
        /** Get current combination setting */
        public function get currentCombination():int {
            return _currentCombination;
        }
        
        /** Get current level setting */
        public function get currentLevel():String {
            return _currentLevel;
        }
        
        /** Get session statistics */
        public function get sessionStats():Object {
            return _sessionStats;
        }
        
        /** Get correct streak count */
        public function get correctStreak():int {
            return _correctStreak;
        }
        
        /** Get incorrect streak count */
        public function get incorrectStreak():int {
            return _incorrectStreak;
        }
        
        /** Get/set auto progression */
        public function get autoProgressEnabled():Boolean {
            return _autoProgressEnabled;
        }
        public function set autoProgressEnabled(value:Boolean):void {
            _autoProgressEnabled = value;
        }
        
        /** Get questions remaining in queue */
        public function get queueLength():int {
            return _questionQueue.length;
        }
        
        /**
         * Get formatted session summary
         */
        public function getSessionSummary():String {
            var summary:String = "=== RINGKASAN SESI ===\n";
            summary += "Total Soal: " + _sessionStats.totalQuestions + "\n";
            summary += "Benar: " + _sessionStats.correctAnswers + "\n";
            summary += "Salah: " + _sessionStats.incorrectAnswers + "\n";
            summary += "Akurasi: " + Math.round(_sessionStats.averageAccuracy * 100) + "%\n";
            summary += "Total Skor: " + _sessionStats.totalScore + "\n";
            
            var duration:Number = (new Date().time - _sessionStats.startTime) / 1000;
            summary += "Durasi: " + Math.floor(duration / 60) + "m " + Math.floor(duration % 60) + "s\n";
            
            return summary;
        }
        
        /**
         * Get current difficulty as readable string
         */
        public function getCurrentDifficultyString():String {
            var levelName:String = "";
            switch (_currentLevel) {
                case NumberQuestion.LEVEL_EASY: levelName = "Mudah"; break;
                case NumberQuestion.LEVEL_MEDIUM: levelName = "Sedang"; break;
                case NumberQuestion.LEVEL_HARD: levelName = "Sulit"; break;
            }
            return _currentCombination + " Angka - " + levelName;
        }
    }
}
