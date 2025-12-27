package castle {
    
    /**
     * CastleState - Core game state for castle progression system.
     * 
     * Data model:
     * - mainCastle: Central castle with size levels
     * - towerCastle[]: Addition towers in CREATION ORDER (newest = last)
     * - leftTowers[]: Tower IDs on left side, ordered INNER to OUTER
     * - rightTowers[]: Tower IDs on right side, ordered INNER to OUTER
     * 
     * The "newest tower" is always towerCastle[length-1].
     * Node placement fills main-castle slots first, then grows outward.
     */
    public class CastleState {
        
        // Game modes
        public static const MODE_STORY:String = "STORY";
        public static const MODE_RANDOM:String = "RANDOM";
        
        // Tower sides
        public static const SIDE_LEFT:String = "LEFT";
        public static const SIDE_RIGHT:String = "RIGHT";
        public static const MAIN_ID:String = "MT";
        
        // Main castle size limits
        public static const MAIN_MIN_SIZE:int = 1;
        public static const MAIN_MAX_SIZE:int = 12;
        public static const MAIN_INITIAL_SIZE:int = 3;
        
        // Tower size stages (3=full, 0=destroyed)
        public static const TOWER_SIZE_FULL:int = 3;
        public static const TOWER_SIZE_DAMAGED:int = 2;
        public static const TOWER_SIZE_CRITICAL:int = 1;
        public static const TOWER_SIZE_DESTROYED:int = 0;
        
        // Tower growth tuning (visual size increases on win)
        private static const TOWER_GROWTH_STEP:Number = 0.05;
        
        // Story progression
        public static const STORY_MAX_INDEX:int = 12;
        public static const DIFFICULTY_MAX_RANK:int = 6;
        
        // ========== MAIN CASTLE STATE ==========
        
        /** Main castle growth/size level (increases on win) */
        public var mainCastleSizeLevel:int;
        
        /** Main castle minimum size */
        public var mainCastleMinSize:int;
        
        /** Main castle maximum size */
        public var mainCastleMaxSize:int;
        
        /** Main castle integrity/durability stage (5=full, 0=destroyed) */
        public var mainCastleIntegrityStage:int;
        
        /** Main castle maximum integrity stage */
        public var mainCastleMaxIntegrity:int;
        
        // ========== TOWER STATE ==========
        
        /** All addition towers in CREATION ORDER (newest = last) */
        public var towerCastle:Vector.<AdditionTower>;
        
        /** Tower IDs on left side, ordered INNER to OUTER */
        public var leftTowers:Vector.<String>;
        
        /** Tower IDs on right side, ordered INNER to OUTER */
        public var rightTowers:Vector.<String>;

        /** Main castle node pointer (left chain root) */
        public var mainLeftId:String;

        /** Main castle node pointer (right chain root) */
        public var mainRightId:String;
        
        /** Counter for generating unique tower IDs */
        private var _towerIdCounter:int;
        private var _leftIdCounter:int;
        private var _rightIdCounter:int;
        
        // ========== PROGRESSION STATE ==========
        
        /** Current win streak (resets on loss) */
        public var winStreak:int;
        
        /** Whether the last answer was wrong (random mode weighting) */
        public var lastAnswerWasWrong:Boolean;
        
        /** Last side where tower was added (debug/legacy) */
        public var lastAddedSide:String;
        
        /** Current game mode: STORY or RANDOM */
        public var mode:String;
        
        /** Current story question index (1-12) */
        public var storyIndex:int;
        
        /** Current difficulty rank in random mode (1-6) */
        public var difficultyRank:int;
        
        /** Total correct answers */
        public var totalCorrect:int;
        
        /** Total wrong answers */
        public var totalWrong:int;
        
        /** Timestamp of last player action (for horde idle detection) */
        public var lastPlayerActionTime:Number;
        
        /** Timestamp of last update */
        public var lastUpdated:Number;
        
        /**
         * Constructor - Initialize fresh game state
         */
        public function CastleState() {
            // Main castle
            mainCastleSizeLevel = MAIN_INITIAL_SIZE;
            mainCastleMinSize = MAIN_MIN_SIZE;
            mainCastleMaxSize = MAIN_MAX_SIZE;
            mainCastleIntegrityStage = 5; // Full durability (5 hits to destroy)
            mainCastleMaxIntegrity = 5;
            
            // Towers
            towerCastle = new Vector.<AdditionTower>();
            leftTowers = new Vector.<String>();
            rightTowers = new Vector.<String>();
            _towerIdCounter = 0;
            _leftIdCounter = 0;
            _rightIdCounter = 0;
            mainLeftId = null;
            mainRightId = null;
            
            // Progression
            winStreak = 0;
            lastAnswerWasWrong = false;
            lastAddedSide = null;
            mode = MODE_STORY;
            storyIndex = 1;
            difficultyRank = 1;
            totalCorrect = 0;
            totalWrong = 0;
            
            // Timestamps
            lastPlayerActionTime = new Date().getTime();
            lastUpdated = lastPlayerActionTime;
        }
        
        // ========== TOWER MANAGEMENT ==========
        
        /**
         * Get tower by ID
         */
        public function getTowerById(id:String):AdditionTower {
            for each (var tower:AdditionTower in towerCastle) {
                if (tower.id == id) return tower;
            }
            return null;
        }
        
        /**
         * Get the newest (most recently created) tower
         * This is always towerCastle[length-1]
         */
        public function getNewestTower():AdditionTower {
            if (towerCastle.length == 0) return null;
            return towerCastle[towerCastle.length - 1];
        }
        
        /**
         * Get the outermost tower on a specific side
         */
        public function getOutermostTower(side:String):AdditionTower {
            var chain:Vector.<String> = getSideChainIds(side);
            if (chain.length == 0) return null;
            return getTowerById(chain[chain.length - 1]);
        }

        private function getOutermostTowerOnSide(side:String):AdditionTower {
            return getOutermostTower(side);
        }

        private function getSideChainIds(side:String):Vector.<String> {
            var chain:Vector.<String> = new Vector.<String>();
            var currentId:String = (side == SIDE_LEFT) ? mainLeftId : mainRightId;
            
            while (currentId && currentId != "") {
                chain.push(currentId);
                var node:AdditionTower = getTowerById(currentId);
                if (!node) break;
                currentId = (side == SIDE_LEFT) ? node.leftId : node.rightId;
            }
            
            return chain;
        }

        private function rebuildSideListsFromNodes():void {
            leftTowers = getSideChainIds(SIDE_LEFT);
            rightTowers = getSideChainIds(SIDE_RIGHT);
        }
        
        /**
         * Count towers on a side
         */
        public function countTowersOnSide(side:String):int {
            return (side == SIDE_LEFT) ? leftTowers.length : rightTowers.length;
        }
        
        /**
         * Get total tower count
         */
        public function get towerCount():int {
            return towerCastle.length;
        }
        
        /**
         * Check if any towers exist
         */
        public function get hasTowers():Boolean {
            return towerCastle.length > 0;
        }
        
        /**
         * Add a new addition tower with node placement rules:
         * - Fill main-castle left/right slot if empty (random among null slots)
         * - Otherwise attach to the outermost node on a random side
         * 
         * @return The newly created tower
         */
        public function addTower():AdditionTower {
            var newSide:String = determineTowerSide();
            
            // Create new tower
            _towerIdCounter++;
            var newTower:AdditionTower = new AdditionTower();
            newTower.createdAtIndex = _towerIdCounter;
            newTower.side = newSide;
            newTower.sizeStage = TOWER_SIZE_FULL;
            newTower.leftId = null;
            newTower.rightId = null;
            
            if (newSide == SIDE_LEFT) {
                _leftIdCounter++;
                newTower.id = "L" + _leftIdCounter;
            } else {
                _rightIdCounter++;
                newTower.id = "R" + _rightIdCounter;
            }
            
            // Initialize growth scale (so wins after tower unlock always have visible feedback)
            newTower.maxScale = AdditionTower.getMaxScaleForCreatedIndex(newTower.createdAtIndex);
            newTower.baseScale = AdditionTower.getInitialBaseScaleForMaxScale(newTower.maxScale);
            if (isNaN(newTower.baseScale) || newTower.baseScale <= 0) newTower.baseScale = 1.0;
            newTower.baseScale = Math.min(newTower.baseScale, newTower.maxScale);
            
            // Add to creation order list
            towerCastle.push(newTower);
            
            // Attach node to the chain (outward-only)
            if (newSide == SIDE_LEFT) {
                if (mainLeftId == null) {
                    mainLeftId = newTower.id;
                } else {
                    var outerLeft:AdditionTower = getOutermostTowerOnSide(SIDE_LEFT);
                    if (outerLeft) {
                        outerLeft.leftId = newTower.id;
                    } else {
                        mainLeftId = newTower.id;
                    }
                }
            } else {
                if (mainRightId == null) {
                    mainRightId = newTower.id;
                } else {
                    var outerRight:AdditionTower = getOutermostTowerOnSide(SIDE_RIGHT);
                    if (outerRight) {
                        outerRight.rightId = newTower.id;
                    } else {
                        mainRightId = newTower.id;
                    }
                }
            }
            
            rebuildSideListsFromNodes();
            
            // Track last added side
            lastAddedSide = newSide;
            
            return newTower;
        }
        
        /**
         * Determine which side new tower should be placed on
         */
        private function determineTowerSide():String {
            // First fill main castle slots
            if (mainLeftId == null && mainRightId == null) {
                return (Math.random() < 0.5) ? SIDE_LEFT : SIDE_RIGHT;
            }
            if (mainLeftId == null) return SIDE_LEFT;
            if (mainRightId == null) return SIDE_RIGHT;
            
            // Both sides have at least one tower: pick randomly between the two outward chains.
            return (Math.random() < 0.5) ? SIDE_LEFT : SIDE_RIGHT;
        }
        
        /**
         * Remove the newest (most recently created) tower
         * This maintains the invariant: newest = last in towerCastle = outermost on its side
         * 
         * @return The removed tower, or null if no towers
         */
        public function removeNewestTower():AdditionTower {
            if (towerCastle.length == 0) return null;
            
            // Remove from creation order list
            var removed:AdditionTower = towerCastle.pop();
            detachTowerFromChain(removed);
            rebuildSideListsFromNodes();
            
            return removed;
        }

        private function detachTowerFromChain(removed:AdditionTower):void {
            if (!removed) return;
            
            if (removed.side == SIDE_LEFT) {
                if (mainLeftId == removed.id) {
                    mainLeftId = removed.leftId;
                    return;
                }
                
                var currentId:String = mainLeftId;
                while (currentId && currentId != "") {
                    var node:AdditionTower = getTowerById(currentId);
                    if (!node) break;
                    if (node.leftId == removed.id) {
                        node.leftId = removed.leftId;
                        return;
                    }
                    currentId = node.leftId;
                }
            } else {
                if (mainRightId == removed.id) {
                    mainRightId = removed.rightId;
                    return;
                }
                
                var currentRightId:String = mainRightId;
                while (currentRightId && currentRightId != "") {
                    var rightNode:AdditionTower = getTowerById(currentRightId);
                    if (!rightNode) break;
                    if (rightNode.rightId == removed.id) {
                        rightNode.rightId = removed.rightId;
                        return;
                    }
                    currentRightId = rightNode.rightId;
                }
            }
        }
        
        /**
         * Apply damage to newest tower (reduce sizeStage)
         * 
         * @return true if tower was destroyed (sizeStage reached 0)
         */
        public function damageNewestTower():Boolean {
            var tower:AdditionTower = getNewestTower();
            if (tower == null) return false;
            
            tower.sizeStage--;
            
            if (tower.sizeStage <= TOWER_SIZE_DESTROYED) {
                removeNewestTower();
                return true;
            }
            
            return false;
        }
        
        /**
         * Heal the most damaged tower (increase sizeStage by 1)
         * Searches from newest to oldest for a damaged tower
         * 
         * @return The healed tower, or null if no damaged towers
         */
        public function healMostRecentDamagedTower():AdditionTower {
            // Search from newest (end) to oldest (start)
            trace("[CastleState] Searching for damaged tower (newest to oldest):");
            for (var i:int = towerCastle.length - 1; i >= 0; i--) {
                var tower:AdditionTower = towerCastle[i];
                trace("  - " + tower.id + " stage=" + tower.sizeStage + "/" + TOWER_SIZE_FULL);
                if (tower.sizeStage < TOWER_SIZE_FULL) {
                    tower.sizeStage++;
                    trace("[CastleState] HEALED " + tower.id + " to stage " + tower.sizeStage);
                    return tower;
                }
            }
            trace("[CastleState] No damaged towers found");
            return null;
        }
        
        /**
         * Heal the newest tower only (1 stage), if damaged.
         * Used by the new "newest tower always gets the win feedback" rule.
         */
        public function healNewestTower():AdditionTower {
            var tower:AdditionTower = getNewestTower();
            if (!tower) return null;
            
            if (tower.sizeStage < TOWER_SIZE_FULL) {
                tower.sizeStage++;
                return tower;
            }
            
            return null;
        }
        
        /**
         * Grow the newest tower base scale (persistent growth), capped at its maxScale.
         * Returns the newest tower (or null if none).
         */
        public function growNewestTower():AdditionTower {
            var tower:AdditionTower = getNewestTower();
            if (!tower) return null;
            
            if (isNaN(tower.maxScale) || tower.maxScale <= 0) {
                tower.maxScale = AdditionTower.getMaxScaleForCreatedIndex(tower.createdAtIndex);
                if (isNaN(tower.maxScale) || tower.maxScale <= 0) tower.maxScale = 1.0;
            }
            if (isNaN(tower.baseScale) || tower.baseScale <= 0) {
                tower.baseScale = AdditionTower.getInitialBaseScaleForMaxScale(tower.maxScale);
                if (isNaN(tower.baseScale) || tower.baseScale <= 0) tower.baseScale = 1.0;
            }
            
            tower.baseScale = Math.min(tower.baseScale + TOWER_GROWTH_STEP, tower.maxScale);
            return tower;
        }
        
        /**
         * Get all towers that need healing (sizeStage < 3)
         */
        public function getDamagedTowers():Vector.<AdditionTower> {
            var result:Vector.<AdditionTower> = new Vector.<AdditionTower>();
            for each (var tower:AdditionTower in towerCastle) {
                if (tower.sizeStage < TOWER_SIZE_FULL) {
                    result.push(tower);
                }
            }
            return result;
        }
        
        // ========== MAIN CASTLE MANAGEMENT ==========
        
        /**
         * Grow main castle size (on win)
         */
        public function growMainCastle():void {
            if (mainCastleSizeLevel < mainCastleMaxSize) {
                mainCastleSizeLevel++;
            }
        }
        
        /**
         * Damage main castle integrity (on loss/horde)
         * @return true if castle is destroyed (integrity reached 0)
         */
        public function damageMainCastle():Boolean {
            if (mainCastleIntegrityStage > 0) {
                mainCastleIntegrityStage--;
            }
            return mainCastleIntegrityStage <= 0;
        }
        
        /**
         * Repair main castle integrity (on win, if no damaged towers)
         * @return true if integrity was repaired
         */
        public function repairMainCastle():Boolean {
            if (mainCastleIntegrityStage < mainCastleMaxIntegrity) {
                mainCastleIntegrityStage++;
                return true;
            }
            return false;
        }
        
        /**
         * Check if main castle is destroyed
         */
        public function get isMainCastleDestroyed():Boolean {
            return mainCastleIntegrityStage <= 0;
        }
        
        /**
         * Get main castle integrity percentage (0-100)
         */
        public function get mainCastleIntegrityPercent():Number {
            return (mainCastleIntegrityStage / mainCastleMaxIntegrity) * 100;
        }
        
        /**
         * Calculate main castle visual scale based on integrity
         * Stage 5: 1.00, Stage 4: 0.92, Stage 3: 0.84, Stage 2: 0.76, Stage 1: 0.68, Stage 0: 0.0
         */
        public function getMainCastleIntegrityScale():Number {
            switch (mainCastleIntegrityStage) {
                case 5: return 1.00;
                case 4: return 0.92;
                case 3: return 0.84;
                case 2: return 0.76;
                case 1: return 0.68;
                default: return 0.0; // Destroyed
            }
        }
        
        /**
         * Legacy: Shrink main castle size
         * @deprecated Use damageMainCastle() instead
         */
        public function shrinkMainCastle():Boolean {
            if (mainCastleSizeLevel > mainCastleMinSize) {
                mainCastleSizeLevel--;
            }
            return mainCastleSizeLevel <= mainCastleMinSize;
        }
        
        /**
         * Legacy: Check if main castle is at critical (minimum) size
         * @deprecated Use isMainCastleDestroyed instead
         */
        public function get isMainCastleCritical():Boolean {
            return mainCastleSizeLevel <= mainCastleMinSize || isMainCastleDestroyed;
        }
        
        // ========== PROGRESSION HELPERS ==========
        
        /**
         * Get story checkpoint (block number, 1-6)
         * Each block has 2 questions
         */
        public function getStoryBlock():int {
            return Math.ceil(storyIndex / 2);
        }
        
        /**
         * Calculate fallback question index after losing in story mode
         * Rule: Go back 2 blocks (4 questions)
         */
        public function getStoryFallbackIndex():int {
            var block:int = getStoryBlock();
            var fallbackBlock:int = Math.max(1, block - 2);
            return (fallbackBlock - 1) * 2 + 1;
        }
        
        /**
         * Advance story progress
         * @return true if story mode completed (switch to random)
         */
        public function advanceStory():Boolean {
            if (mode != MODE_STORY) return false;
            
            storyIndex++;
            
            if (storyIndex > STORY_MAX_INDEX) {
                // Story complete, switch to random mode
                mode = MODE_RANDOM;
                difficultyRank = 6; // Start at hardest
                return true;
            }
            
            return false;
        }
        
        /**
         * Update timestamp for player action (horde idle detection)
         */
        public function recordPlayerAction():void {
            lastPlayerActionTime = new Date().getTime();
        }
        
        // ========== SERIALIZATION ==========
        
        /**
         * Serialize to object for saving
         */
        public function toObject():Object {
            var towersArray:Array = [];
            for each (var tower:AdditionTower in towerCastle) {
                towersArray.push(tower.toObject());
            }
            
            var leftArray:Array = [];
            for each (var leftId:String in leftTowers) {
                leftArray.push(leftId);
            }
            
            var rightArray:Array = [];
            for each (var rightId:String in rightTowers) {
                rightArray.push(rightId);
            }
            
            return {
                mainCastleSizeLevel: mainCastleSizeLevel,
                mainCastleMinSize: mainCastleMinSize,
                mainCastleMaxSize: mainCastleMaxSize,
                mainCastleIntegrityStage: mainCastleIntegrityStage,
                mainCastleMaxIntegrity: mainCastleMaxIntegrity,
                towerCastle: towersArray,
                leftTowers: leftArray,
                rightTowers: rightArray,
                mainLeftId: mainLeftId,
                mainRightId: mainRightId,
                towerIdCounter: _towerIdCounter,
                leftIdCounter: _leftIdCounter,
                rightIdCounter: _rightIdCounter,
                winStreak: winStreak,
                lastAnswerWasWrong: lastAnswerWasWrong,
                lastAddedSide: lastAddedSide,
                mode: mode,
                storyIndex: storyIndex,
                difficultyRank: difficultyRank,
                totalCorrect: totalCorrect,
                totalWrong: totalWrong,
                lastPlayerActionTime: lastPlayerActionTime,
                lastUpdated: lastUpdated
            };
        }
        
        /**
         * Create CastleState from saved object
         */
        public static function fromObject(obj:Object):CastleState {
            var state:CastleState = new CastleState();
            
            // Main castle
            state.mainCastleSizeLevel = obj.mainCastleSizeLevel || MAIN_INITIAL_SIZE;
            state.mainCastleMinSize = obj.mainCastleMinSize || MAIN_MIN_SIZE;
            state.mainCastleMaxSize = obj.mainCastleMaxSize || MAIN_MAX_SIZE;
            state.mainCastleIntegrityStage = (obj.mainCastleIntegrityStage !== undefined) ? obj.mainCastleIntegrityStage : 5;
            state.mainCastleMaxIntegrity = obj.mainCastleMaxIntegrity || 5;
            
            // Towers
            state.towerCastle = new Vector.<AdditionTower>();
            if (obj.towerCastle) {
                for each (var towerObj:Object in obj.towerCastle) {
                    state.towerCastle.push(AdditionTower.fromObject(towerObj));
                }
            }
            
            state.leftTowers = new Vector.<String>();
            if (obj.leftTowers) {
                for each (var leftId:String in obj.leftTowers) {
                    state.leftTowers.push(leftId);
                }
            }
            
            state.rightTowers = new Vector.<String>();
            if (obj.rightTowers) {
                for each (var rightId:String in obj.rightTowers) {
                    state.rightTowers.push(rightId);
                }
            }
            
            state.mainLeftId = obj.mainLeftId || null;
            state.mainRightId = obj.mainRightId || null;
            state._towerIdCounter = obj.towerIdCounter || 0;
            state._leftIdCounter = obj.leftIdCounter || 0;
            state._rightIdCounter = obj.rightIdCounter || 0;
            
            // Progression
            state.winStreak = obj.winStreak || 0;
            state.lastAnswerWasWrong = (obj.lastAnswerWasWrong !== undefined) ? Boolean(obj.lastAnswerWasWrong) : false;
            state.lastAddedSide = obj.lastAddedSide || null;
            state.mode = obj.mode || MODE_STORY;
            state.storyIndex = obj.storyIndex || 1;
            state.difficultyRank = obj.difficultyRank || 1;
            state.totalCorrect = obj.totalCorrect || 0;
            state.totalWrong = obj.totalWrong || 0;
            
            // Timestamps
            state.lastPlayerActionTime = obj.lastPlayerActionTime || new Date().getTime();
            state.lastUpdated = obj.lastUpdated || new Date().getTime();

            state.rebuildNodeChainFromLists();
            
            return state;
        }

        private function rebuildNodeChainFromLists():void {
            var hasLists:Boolean = (leftTowers && leftTowers.length > 0) || (rightTowers && rightTowers.length > 0);
            
            if (hasLists) {
                mainLeftId = (leftTowers.length > 0) ? leftTowers[0] : null;
                mainRightId = (rightTowers.length > 0) ? rightTowers[0] : null;
                
                for each (var tower:AdditionTower in towerCastle) {
                    tower.leftId = null;
                    tower.rightId = null;
                }
                
                for (var i:int = 0; i < leftTowers.length; i++) {
                    var leftId:String = leftTowers[i];
                    var leftTower:AdditionTower = getTowerById(leftId);
                    if (leftTower) {
                        leftTower.leftId = (i + 1 < leftTowers.length) ? leftTowers[i + 1] : null;
                        leftTower.rightId = null;
                    }
                }
                
                for (var j:int = 0; j < rightTowers.length; j++) {
                    var rightId:String = rightTowers[j];
                    var rightTower:AdditionTower = getTowerById(rightId);
                    if (rightTower) {
                        rightTower.rightId = (j + 1 < rightTowers.length) ? rightTowers[j + 1] : null;
                        rightTower.leftId = null;
                    }
                }
            } else {
                rebuildSideListsFromNodes();
            }
            
            if (_towerIdCounter <= 0) {
                for each (var t:AdditionTower in towerCastle) {
                    if (t.createdAtIndex > _towerIdCounter) _towerIdCounter = t.createdAtIndex;
                }
            }
            
            if (_leftIdCounter <= 0) _leftIdCounter = computeSideCounter("L");
            if (_rightIdCounter <= 0) _rightIdCounter = computeSideCounter("R");
        }

        private function computeSideCounter(prefix:String):int {
            var maxId:int = 0;
            for each (var tower:AdditionTower in towerCastle) {
                if (tower.id && tower.id.indexOf(prefix) == 0) {
                    var num:int = parseInt(tower.id.substr(1));
                    if (!isNaN(num) && num > maxId) maxId = num;
                }
            }
            return maxId;
        }
        
        /**
         * Create a deep clone of this state
         */
        public function clone():CastleState {
            return CastleState.fromObject(this.toObject());
        }
        
        /**
         * Reset to initial state (new game)
         */
        public function reset():void {
            mainCastleSizeLevel = MAIN_INITIAL_SIZE;
            mainCastleIntegrityStage = 5; // Reset to full durability
            towerCastle = new Vector.<AdditionTower>();
            leftTowers = new Vector.<String>();
            rightTowers = new Vector.<String>();
            _towerIdCounter = 0;
            _leftIdCounter = 0;
            _rightIdCounter = 0;
            mainLeftId = null;
            mainRightId = null;
            winStreak = 0;
            lastAnswerWasWrong = false;
            lastAddedSide = null;
            mode = MODE_STORY;
            storyIndex = 1;
            difficultyRank = 1;
            totalCorrect = 0;
            totalWrong = 0;
            lastPlayerActionTime = new Date().getTime();
            lastUpdated = lastPlayerActionTime;
        }
        
        /**
         * String representation for debugging
         */
        public function toString():String {
            var leftStr:String = leftTowers.join(",");
            var rightStr:String = rightTowers.join(",");
            return "[CastleState mode=" + mode + 
                   " storyIdx=" + storyIndex + 
                   " mainSize=" + mainCastleSizeLevel + 
                   " towers=" + towerCastle.length + 
                   " L=[" + leftStr + "] R=[" + rightStr + "]" +
                   " winStreak=" + winStreak + "]";
        }
    }
}
