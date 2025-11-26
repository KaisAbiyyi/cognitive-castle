package game {

    import domain.ValidationResult;
    import domain.TrialResult;
    import core.EventBus;
    import core.GameEvent;
    import core.Constants;

    /**
     * ScoreManager - Manages scoring rules, streaks, and achievements.
     *
     * SOLID Principles:
     * - Single Responsibility: Only handles scoring logic
     * - Open/Closed: Can be extended with new scoring rules without changing existing code
     * - Interface Segregation: Provides focused scoring methods
     */
    public class ScoreManager {
        
        // Scoring constants
        private static const BASE_SCORE:int = 100;
        private static const STREAK_MULTIPLIER:Number = 0.1;
        private static const SPEED_BONUS_THRESHOLD:Number = 0.5; // Complete in < 50% time for bonus
        private static const SPEED_BONUS_MULTIPLIER:Number = 1.5;
        private static const PERFECT_SPAN_BONUS:int = 50;

        private var _currentScore:int = 0;
        private var _highScore:int = 0;
        private var _currentStreak:int = 0;
        private var _bestStreak:int = 0;
        private var _totalTrials:int = 0;
        private var _correctTrials:int = 0;
        private var _perfectTrials:int = 0; // No mistakes, fast response
        
        // Achievement tracking
        private var _achievements:Vector.<String>;
        private var _unlockedAchievements:Vector.<String>;
        
        // Event bus
        private var _eventBus:EventBus;
        
        // Debug
        private static const DEBUG:Boolean = true;

        /**
         * Constructor
         */
        public function ScoreManager() {
            _achievements = new Vector.<String>();
            _unlockedAchievements = new Vector.<String>();
            _eventBus = EventBus.getInstance();
            initializeAchievements();
        }
        
        /**
         * Initialize achievement definitions
         */
        private function initializeAchievements():void {
            _achievements.push("FIRST_CORRECT");      // First correct answer
            _achievements.push("STREAK_5");           // 5 in a row
            _achievements.push("STREAK_10");          // 10 in a row
            _achievements.push("STREAK_25");          // 25 in a row
            _achievements.push("PERFECT_10");         // 10 perfect trials
            _achievements.push("SCORE_1000");         // Reach 1000 points
            _achievements.push("SCORE_5000");         // Reach 5000 points
            _achievements.push("SPAN_6");             // Complete span 6
            _achievements.push("SPAN_9");             // Complete span 9
            _achievements.push("SPEED_DEMON");        // 10 speed bonuses
        }

        /**
         * Calculate and award score for a trial
         * @param result TrialResult with trial data
         * @return Score earned for this trial
         */
        public function calculateScore(result:TrialResult):int {
            _totalTrials++;
            
            if (!result.isCorrect) {
                // Reset streak on failure
                _currentStreak = 0;
                
                if (DEBUG) {
                    trace("[ScoreManager] Incorrect - Streak reset. Score: " + _currentScore);
                }
                return 0;
            }
            
            _correctTrials++;
            _currentStreak++;
            if (_currentStreak > _bestStreak) {
                _bestStreak = _currentStreak;
            }
            
            // Base score scaled by span length
            var spanBonus:Number = 1 + (result.spanLength - 2) * 0.25; // +25% per span level above 2
            var basePoints:int = int(BASE_SCORE * spanBonus);
            
            // Streak multiplier
            var streakBonus:Number = 1 + (_currentStreak - 1) * STREAK_MULTIPLIER;
            var streakPoints:int = int(basePoints * streakBonus);
            
            // Speed bonus
            var speedBonus:int = 0;
            if (result.responseTimeRatio < SPEED_BONUS_THRESHOLD) {
                speedBonus = int(streakPoints * (SPEED_BONUS_MULTIPLIER - 1));
            }
            
            // Perfect trial (100% accuracy, fast response)
            var perfectBonus:int = 0;
            if (result.matchPercentage >= 1.0 && result.responseTimeRatio < SPEED_BONUS_THRESHOLD) {
                _perfectTrials++;
                perfectBonus = PERFECT_SPAN_BONUS;
            }
            
            var totalEarned:int = streakPoints + speedBonus + perfectBonus;
            _currentScore += totalEarned;
            
            // Update high score
            if (_currentScore > _highScore) {
                _highScore = _currentScore;
            }
            
            // Check achievements
            checkAchievements(result);
            
            // Dispatch score event
            _eventBus.dispatch(GameEvent.SCORE_UPDATED, {
                earned: totalEarned,
                total: _currentScore,
                streak: _currentStreak,
                breakdown: {
                    base: basePoints,
                    streakMultiplier: streakBonus,
                    speedBonus: speedBonus,
                    perfectBonus: perfectBonus
                }
            });
            
            if (DEBUG) {
                trace("[ScoreManager] Correct! +" + totalEarned + 
                      " (base:" + basePoints + 
                      " streak:" + int(streakBonus * 100) + "%" +
                      " speed:" + speedBonus + 
                      " perfect:" + perfectBonus + ")" +
                      " Total: " + _currentScore + " Streak: " + _currentStreak);
            }
            
            return totalEarned;
        }
        
        /**
         * Check and unlock achievements
         */
        private function checkAchievements(result:TrialResult):void {
            // First correct
            if (_correctTrials == 1) {
                unlockAchievement("FIRST_CORRECT");
            }
            
            // Streak achievements
            if (_currentStreak == 5) unlockAchievement("STREAK_5");
            if (_currentStreak == 10) unlockAchievement("STREAK_10");
            if (_currentStreak == 25) unlockAchievement("STREAK_25");
            
            // Perfect trials
            if (_perfectTrials == 10) unlockAchievement("PERFECT_10");
            
            // Score milestones
            if (_currentScore >= 1000) unlockAchievement("SCORE_1000");
            if (_currentScore >= 5000) unlockAchievement("SCORE_5000");
            
            // Span achievements
            if (result.spanLength >= 6) unlockAchievement("SPAN_6");
            if (result.spanLength >= 9) unlockAchievement("SPAN_9");
        }
        
        /**
         * Unlock an achievement
         */
        private function unlockAchievement(id:String):void {
            if (_unlockedAchievements.indexOf(id) >= 0) return; // Already unlocked
            
            _unlockedAchievements.push(id);
            
            _eventBus.dispatch(GameEvent.ACHIEVEMENT_UNLOCKED, {
                id: id,
                totalUnlocked: _unlockedAchievements.length,
                totalAchievements: _achievements.length
            });
            
            if (DEBUG) {
                trace("[ScoreManager] 🏆 ACHIEVEMENT UNLOCKED: " + id);
            }
        }

        /**
         * Update score based on simple trial result (legacy support)
         * @param isCorrect Whether the trial was correct
         */
        public function updateScore(isCorrect:Boolean):void {
            if (isCorrect) {
                _currentScore += BASE_SCORE;
                _currentStreak++;
            } else {
                _currentStreak = 0;
            }
        }

        /**
         * Get current score
         */
        public function getScore():int {
            return _currentScore;
        }
        
        /**
         * Get high score
         */
        public function getHighScore():int {
            return _highScore;
        }
        
        /**
         * Get current streak
         */
        public function getStreak():int {
            return _currentStreak;
        }
        
        /**
         * Get best streak
         */
        public function getBestStreak():int {
            return _bestStreak;
        }
        
        /**
         * Get accuracy percentage
         */
        public function getAccuracy():Number {
            if (_totalTrials == 0) return 0;
            return _correctTrials / _totalTrials;
        }
        
        /**
         * Get total trials
         */
        public function getTotalTrials():int {
            return _totalTrials;
        }
        
        /**
         * Get correct trials
         */
        public function getCorrectTrials():int {
            return _correctTrials;
        }
        
        /**
         * Get unlocked achievements
         */
        public function getUnlockedAchievements():Vector.<String> {
            return _unlockedAchievements.slice();
        }

        /**
         * Reset score and stats
         */
        public function resetScore():void {
            _currentScore = 0;
            _currentStreak = 0;
            // Note: Don't reset high score, best streak, or achievements
        }
        
        /**
         * Full reset (including achievements)
         */
        public function fullReset():void {
            _currentScore = 0;
            _highScore = 0;
            _currentStreak = 0;
            _bestStreak = 0;
            _totalTrials = 0;
            _correctTrials = 0;
            _perfectTrials = 0;
            _unlockedAchievements.length = 0;
        }

        /**
         * Log trial result
         * @param result ValidationResult
         */
        public function logTrialResult(result:ValidationResult):void {
            if (DEBUG) {
                trace("[ScoreManager] Trial: " + result.toString());
            }
        }
        
        /**
         * Get stats summary
         */
        public function getStats():Object {
            return {
                score: _currentScore,
                highScore: _highScore,
                streak: _currentStreak,
                bestStreak: _bestStreak,
                totalTrials: _totalTrials,
                correctTrials: _correctTrials,
                perfectTrials: _perfectTrials,
                accuracy: getAccuracy(),
                achievements: _unlockedAchievements.length + "/" + _achievements.length
            };
        }
    }
}