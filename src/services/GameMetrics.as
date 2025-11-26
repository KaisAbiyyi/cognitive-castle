package services {
    
    /**
     * GameMetrics - Tracks all game statistics and performance metrics.
     */
    public class GameMetrics {
        /** Total trials played */
        public var totalTrials:int = 0;
        /** Total correct trials */
        public var correctTrials:int = 0;
        /** Highest streak achieved */
        public var highestStreak:int = 0;
        /** Current active streak */
        public var currentStreak:int = 0;
        /** Total play time in ms */
        public var totalPlayTime:Number = 0;
        /** Number of sessions played */
        public var sessionsPlayed:int = 0;
        /** Total castle score */
        public var castleScore:int = 0;
        /** Highest difficulty reached */
        public var highestDifficulty:int = 1;
        /** Average reaction time in ms */
        public var averageReactionTime:Number = 0;
        /** Best reaction time in ms */
        public var bestReactionTime:Number = 0;
        /** Total castle parts built */
        public var partsBuilt:int = 0;
        /** Total castle parts upgraded */
        public var partsUpgraded:int = 0;
        
        /**
         * Get accuracy as percentage
         */
        public function get accuracy():Number {
            if (totalTrials == 0) return 0;
            return correctTrials / totalTrials;
        }
        
        /**
         * Clone metrics
         */
        public function clone():GameMetrics {
            var m:GameMetrics = new GameMetrics();
            m.totalTrials = totalTrials;
            m.correctTrials = correctTrials;
            m.highestStreak = highestStreak;
            m.currentStreak = currentStreak;
            m.totalPlayTime = totalPlayTime;
            m.sessionsPlayed = sessionsPlayed;
            m.castleScore = castleScore;
            m.highestDifficulty = highestDifficulty;
            m.averageReactionTime = averageReactionTime;
            m.bestReactionTime = bestReactionTime;
            m.partsBuilt = partsBuilt;
            m.partsUpgraded = partsUpgraded;
            return m;
        }
    }
}
