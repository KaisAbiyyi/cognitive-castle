package game {
    
    import castle.AdditionTower;
    
    /**
     * ProgressionResult - Data class containing result of processing an answer
     * 
     * Used by ProgressionManager to communicate:
     * - What happened (correct/wrong)
     * - What to upgrade/damage
     * - Tower/castle changes
     * - Story/random mode progression
     */
    public class ProgressionResult {
        
        // Upgrade types (correct answers)
        public static const UPGRADE_NONE:String = "none";
        public static const UPGRADE_MAIN_CASTLE:String = "mainCastle";
        public static const UPGRADE_NEW_TOWER:String = "newTower";
        public static const UPGRADE_TOWER:String = "tower";
        
        // Shrink/remove types (wrong answers / horde damage)
        public static const SHRINK_MAIN_CASTLE:String = "shrinkMainCastle";
        public static const SHRINK_TOWER:String = "shrinkTower";
        public static const REMOVE_TOWER:String = "removeTower";
        
        // ========== BASIC RESULT ==========
        
        /** Whether the answer was correct */
        public var wasCorrect:Boolean = false;
        
        /** Type of upgrade/damage to apply */
        public var upgradeType:String = UPGRADE_NONE;
        
        /** Whether this is horde damage (vs puzzle result) */
        public var isHordeDamage:Boolean = false;
        
        // ========== SCALE VALUES (legacy support) ==========
        
        /** Target scale for the upgrade/shrink */
        public var targetScale:Number = 1.0;
        
        // ========== TOWER INFO ==========
        
        /** Tower batch number / creation index */
        public var towerBatch:int = 0;
        
        /** Tower side ("left" or "right") */
        public var towerSide:String = "";
        
        /** Reference to newly created tower (on UPGRADE_NEW_TOWER) */
        public var newTower:AdditionTower = null;
        
        /** ID of damaged tower */
        public var damagedTowerId:String = "";
        
        /** ID of removed tower */
        public var removedTowerId:String = "";
        
        /** ID of healed tower */
        public var healedTowerId:String = "";
        
        /** Whether tower should be removed */
        public var shouldRemoveTower:Boolean = false;
        
        /** Target size stage after damage (3/2/1/0) */
        public var targetSizeStage:int = 3;
        
        // ========== MAIN CASTLE INFO ==========
        
        /** Main castle size level after change */
        public var mainCastleLevel:int = 0;
        
        /** Main castle integrity stage (5-0, durability) */
        public var mainCastleIntegrity:int = 5;
        
        /** Whether castle is at critical (minimum) state */
        public var isCastleCritical:Boolean = false;
        
        /** Whether game is over (mainCastle destroyed) */
        public var isGameOver:Boolean = false;
        
        // ========== PROGRESSION INFO ==========
        
        /** Question number to reset to (for wrong answers in story mode) */
        public var resetToQuestion:int = 1;
        
        /** Wrong streak count (legacy) */
        public var wrongStreak:int = 0;
        
        /** Current story index (1-12) */
        public var storyIndex:int = 0;
        
        /** Current difficulty rank (1-6) for random mode */
        public var difficultyRank:int = 0;
        
        /** Whether story mode was just completed */
        public var storyCompleted:Boolean = false;
        
        /** Whether mode changed (story -> random) */
        public var modeChanged:Boolean = false;
        
        /** New mode after change */
        public var newMode:String = "";
        
        public function ProgressionResult() {}
        
        /**
         * Check if this result adds a new tower
         */
        public function get addsNewTower():Boolean {
            return wasCorrect && upgradeType == UPGRADE_NEW_TOWER && newTower != null;
        }
        
        /**
         * Check if this result removes a tower
         */
        public function get removesTower():Boolean {
            return !wasCorrect && shouldRemoveTower;
        }
        
        /**
         * Check if this result damages a tower (but doesn't remove)
         */
        public function get damagesTower():Boolean {
            return !wasCorrect && upgradeType == SHRINK_TOWER && !shouldRemoveTower;
        }
        
        /**
         * Check if this result damages main castle
         */
        public function get damagesMainCastle():Boolean {
            return !wasCorrect && upgradeType == SHRINK_MAIN_CASTLE;
        }
        
        public function toString():String {
            if (wasCorrect) {
                var towerInfo:String = "";
                if (newTower) {
                    towerInfo = ", newTower=" + newTower.id + " " + newTower.side;
                }
                return "[ProgressionResult CORRECT, type=" + upgradeType + 
                       ", mainLvl=" + mainCastleLevel + 
                       towerInfo + "]";
            } else {
                var damageInfo:String = "";
                if (damagedTowerId) {
                    damageInfo = ", damaged=" + damagedTowerId + " stage=" + targetSizeStage;
                }
                if (removedTowerId) {
                    damageInfo = ", removed=" + removedTowerId;
                }
                return "[ProgressionResult WRONG, type=" + upgradeType + 
                       damageInfo +
                       ", resetTo=" + resetToQuestion + "]";
            }
        }
    }
}
