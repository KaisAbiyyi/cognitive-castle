package castle {
    
    import services.GameMetrics;
    import domain.TrialResult;
    
    /**
     * MetricsManager - Centralized manager for tracking all game metrics.
     * Provides real-time updates and debug display functionality.
     */
    public class MetricsManager {
        
        // Debug flag
        private static const DEBUG:Boolean = true;
        
        // Singleton instance
        private static var _instance:MetricsManager;
        
        // Core metrics
        private var _metrics:GameMetrics;
        
        // Session tracking
        private var _sessionStartTime:Number;
        private var _reactionTimes:Vector.<Number>;
        
        /**
         * Get singleton instance
         */
        public static function getInstance():MetricsManager {
            if (!_instance) {
                _instance = new MetricsManager();
            }
            return _instance;
        }
        
        /**
         * Constructor
         */
        public function MetricsManager() {
            _metrics = new GameMetrics();
            _reactionTimes = new Vector.<Number>();
            _sessionStartTime = new Date().getTime();
        }
        
        /**
         * Start a new session
         */
        public function startSession():void {
            _sessionStartTime = new Date().getTime();
            _metrics.sessionsPlayed++;
            _reactionTimes.length = 0;
            
            if (DEBUG) {
                trace("Session started. Total sessions: " + _metrics.sessionsPlayed);
            }
        }
        
        /**
         * End current session
         */
        public function endSession():void {
            updatePlayTime();
            
            if (DEBUG) {
                trace("Session ended. Total play time: " + formatPlayTime(_metrics.totalPlayTime));
            }
        }
        
        /**
         * Initialize with saved metrics
         */
        public function initialize(savedMetrics:GameMetrics = null):void {
            if (savedMetrics) {
                _metrics = savedMetrics.clone();
            } else {
                _metrics = new GameMetrics();
            }
            _reactionTimes.length = 0;
            _sessionStartTime = new Date().getTime();
            _metrics.sessionsPlayed++;
            
            if (DEBUG) {
                trace("MetricsManager initialized. Sessions: " + _metrics.sessionsPlayed);
            }
        }
        
        /**
         * Record trial result
         */
        public function recordTrial(result:TrialResult):void {
            _metrics.totalTrials++;
            
            if (result.isCorrect) {
                _metrics.correctTrials++;
                _metrics.currentStreak++;
                
                if (_metrics.currentStreak > _metrics.highestStreak) {
                    _metrics.highestStreak = _metrics.currentStreak;
                }
            } else {
                _metrics.currentStreak = 0;
            }
            
            // Track difficulty
            if (result.difficulty > _metrics.highestDifficulty) {
                _metrics.highestDifficulty = result.difficulty;
            }
            
            // Track reaction time
            if (result.reactionTime > 0) {
                _reactionTimes.push(result.reactionTime);
                updateReactionTimeStats(result.reactionTime);
            }
            
            // Track score
            _metrics.castleScore += result.scoreEarned;
            
            if (DEBUG) {
                trace("Trial recorded: " + (result.isCorrect ? "CORRECT" : "WRONG") + 
                      " | Streak: " + _metrics.currentStreak + 
                      " | Total: " + _metrics.totalTrials);
            }
        }
        
        /**
         * Update reaction time statistics
         */
        private function updateReactionTimeStats(rt:Number):void {
            // Update best reaction time
            if (_metrics.bestReactionTime == 0 || rt < _metrics.bestReactionTime) {
                _metrics.bestReactionTime = rt;
            }
            
            // Calculate average
            var sum:Number = 0;
            for each (var time:Number in _reactionTimes) {
                sum += time;
            }
            _metrics.averageReactionTime = sum / _reactionTimes.length;
        }
        
        /**
         * Record castle part built
         */
        public function recordPartBuilt():void {
            _metrics.partsBuilt++;
        }
        
        /**
         * Record castle part upgraded
         */
        public function recordPartUpgraded():void {
            _metrics.partsUpgraded++;
        }
        
        /**
         * Update play time (call periodically)
         */
        public function updatePlayTime():void {
            var now:Number = new Date().getTime();
            _metrics.totalPlayTime += now - _sessionStartTime;
            _sessionStartTime = now;
        }
        
        /**
         * Get current metrics
         */
        public function getMetrics():GameMetrics {
            return _metrics;
        }
        
        /**
         * Get metrics snapshot for saving
         */
        public function getMetricsSnapshot():GameMetrics {
            updatePlayTime();
            return _metrics.clone();
        }
        
        // ========== DEBUG DISPLAY ==========
        
        /**
         * Get formatted debug string
         */
        public function getDebugString():String {
            var lines:Array = [
                "=== GAME METRICS ===",
                "Trials: " + _metrics.correctTrials + "/" + _metrics.totalTrials + " (" + (_metrics.accuracy * 100).toFixed(1) + "%)",
                "Streak: " + _metrics.currentStreak + " (Best: " + _metrics.highestStreak + ")",
                "Difficulty: " + _metrics.highestDifficulty,
                "Castle Score: " + _metrics.castleScore,
                "Parts Built: " + _metrics.partsBuilt,
                "Parts Upgraded: " + _metrics.partsUpgraded,
                "Avg RT: " + _metrics.averageReactionTime.toFixed(0) + "ms",
                "Best RT: " + _metrics.bestReactionTime.toFixed(0) + "ms",
                "Play Time: " + formatPlayTime(_metrics.totalPlayTime),
                "Sessions: " + _metrics.sessionsPlayed
            ];
            return lines.join("\n");
        }
        
        /**
         * Format play time as HH:MM:SS
         */
        private function formatPlayTime(ms:Number):String {
            var totalSeconds:int = Math.floor(ms / 1000);
            var hours:int = Math.floor(totalSeconds / 3600);
            var minutes:int = Math.floor((totalSeconds % 3600) / 60);
            var seconds:int = totalSeconds % 60;
            
            return padZero(hours) + ":" + padZero(minutes) + ":" + padZero(seconds);
        }
        
        /**
         * Pad number with leading zero
         */
        private function padZero(n:int):String {
            return n < 10 ? "0" + n : String(n);
        }
        
        /**
         * Get short summary for HUD
         */
        public function getHUDSummary():Object {
            return {
                accuracy: _metrics.accuracy,
                streak: _metrics.currentStreak,
                highestStreak: _metrics.highestStreak,
                castleScore: _metrics.castleScore,
                totalTrials: _metrics.totalTrials,
                correctTrials: _metrics.correctTrials
            };
        }
        
        /**
         * Reset all metrics
         */
        public function reset():void {
            _metrics = new GameMetrics();
            _reactionTimes.length = 0;
            _sessionStartTime = new Date().getTime();
            
            if (DEBUG) {
                trace("MetricsManager reset");
            }
        }
    }
}
