package castle {
    
    import domain.TrialResult;
    
    /**
     * CastleArchitect - Core logic for castle construction and management.
     * Translates game performance into castle growth.
     * 
     * Responsibilities:
     * - Apply trial results to grow/modify castle
     * - Manage castle state and parts
     * - Handle damage, repair, and upgrades
     * - Track milestones and progress
     */
    public class CastleArchitect {
        
        // Debug flag
        private static const DEBUG:Boolean = true;
        
        // Singleton instance
        private static var _instance:CastleArchitect;
        
        // Castle state
        private var _state:CastleState;
        
        // Part ID counter
        private var _nextPartId:int = 1;
        
        // Currently unlocked stages (what we've built up to)
        private var _unlockedStageIndex:int = -1;
        
        // Score accumulated from trials
        private var _accumulatedScore:int = 0;
        
        /**
         * Get singleton instance
         */
        public static function getInstance():CastleArchitect {
            if (!_instance) {
                _instance = new CastleArchitect();
            }
            return _instance;
        }
        
        /**
         * Constructor
         */
        public function CastleArchitect() {
            _state = new CastleState();
        }
        
        /**
         * Initialize or reset architect with optional saved state
         */
        public function initialize(savedState:CastleState = null):void {
            if (savedState) {
                _state = savedState;
                _accumulatedScore = _state.totalScore;
                recalculateUnlockedStage();
            } else {
                _state = new CastleState();
                _accumulatedScore = 0;
                _unlockedStageIndex = -1;
            }
            
            if (DEBUG) {
                trace("CastleArchitect initialized. Score: " + _accumulatedScore + ", Parts: " + _state.parts.length);
            }
        }
        
        /**
         * Apply trial result and return build events
         * @param result Trial result from validation
         * @return Array of BuildEvents that occurred
         */
        public function applyTrialResult(result:TrialResult):Vector.<BuildEvent> {
            var events:Vector.<BuildEvent> = new Vector.<BuildEvent>();
            
            if (result.isCorrect) {
                // Calculate points earned
                var points:int = CastleConfig.calculateTrialPoints(
                    true,
                    result.streakAfter,
                    result.difficulty
                );
                
                _accumulatedScore += points;
                _state.totalScore = _accumulatedScore;
                
                if (DEBUG) {
                    trace("Trial correct! +" + points + " points. Total: " + _accumulatedScore);
                }
                
                // Check for new builds/upgrades
                var buildEvents:Vector.<BuildEvent> = checkGrowth();
                for each (var be:BuildEvent in buildEvents) {
                    events.push(be);
                }
                
                // Check for milestone
                var milestoneEvent:BuildEvent = checkMilestone();
                if (milestoneEvent) {
                    events.push(milestoneEvent);
                }
                
            } else {
                // Wrong answer - apply damage to random part
                if (_state.parts.length > 0) {
                    var damageEvent:BuildEvent = applyRandomDamage(CastleConfig.DAMAGE_MINOR);
                    if (damageEvent) {
                        events.push(damageEvent);
                    }
                }
            }
            
            // Update state metadata
            updateStateMetadata();
            
            return events;
        }
        
        /**
         * Check if we should build new parts or upgrade existing ones
         */
        private function checkGrowth():Vector.<BuildEvent> {
            var events:Vector.<BuildEvent> = new Vector.<BuildEvent>();
            var stages:Array = CastleConfig.GROWTH_STAGES;
            
            // Find stages we can now complete
            for (var i:int = _unlockedStageIndex + 1; i < stages.length; i++) {
                var stage:Object = stages[i];
                
                if (_accumulatedScore >= stage.minScore) {
                    if (DEBUG) {
                        trace("Unlocking stage " + i + " (score " + stage.minScore + "-" + stage.maxScore + ")");
                    }
                    
                    // Handle upgrades
                    if (stage.upgrade) {
                        var upgradeEvents:Vector.<BuildEvent> = upgradeAllToTier(stage.targetTier);
                        for each (var ue:BuildEvent in upgradeEvents) {
                            events.push(ue);
                        }
                    }
                    
                    // Handle new builds
                    if (stage.build && stage.build.length > 0) {
                        for each (var buildDef:Object in stage.build) {
                            var part:CastlePart = addPart(
                                buildDef.type,
                                1, // Start at tier 1
                                buildDef.gridX,
                                buildDef.gridY,
                                buildDef.variant
                            );
                            if (part) {
                                events.push(BuildEvent.addPart(part));
                            }
                        }
                    }
                    
                    _unlockedStageIndex = i;
                } else {
                    break; // Can't unlock higher stages yet
                }
            }
            
            return events;
        }
        
        /**
         * Upgrade all parts to specified tier
         */
        private function upgradeAllToTier(targetTier:int):Vector.<BuildEvent> {
            var events:Vector.<BuildEvent> = new Vector.<BuildEvent>();
            
            for each (var part:CastlePart in _state.parts) {
                if (part.tier < targetTier && part.isAlive) {
                    var oldTier:int = part.tier;
                    while (part.tier < targetTier && part.canUpgrade()) {
                        part.upgrade();
                        _state.totalUpgrades++;
                    }
                    if (part.tier > oldTier) {
                        events.push(BuildEvent.upgradePart(part));
                        if (DEBUG) {
                            trace("Upgraded " + part.id + " from tier " + oldTier + " to " + part.tier);
                        }
                    }
                }
            }
            
            return events;
        }
        
        /**
         * Check for new milestone
         */
        private function checkMilestone():BuildEvent {
            var currentMilestone:Object = CastleConfig.getMilestoneForScore(_accumulatedScore);
            var nextMilestone:Object = CastleConfig.getNextMilestone(_accumulatedScore);
            
            if (currentMilestone.name != _state.currentMilestone) {
                _state.currentMilestone = currentMilestone.name;
                _state.nextMilestone = nextMilestone.name;
                
                if (DEBUG) {
                    trace("Milestone reached: " + currentMilestone.name);
                }
                
                return BuildEvent.reachMilestone(currentMilestone.name);
            }
            
            _state.nextMilestone = nextMilestone.name;
            return null;
        }
        
        /**
         * Apply random damage to castle
         */
        private function applyRandomDamage(amount:int):BuildEvent {
            var livingParts:Vector.<CastlePart> = _state.getLivingParts();
            if (livingParts.length == 0) return null;
            
            var randomIndex:int = Math.floor(Math.random() * livingParts.length);
            var target:CastlePart = livingParts[randomIndex];
            
            target.damage(amount);
            
            if (DEBUG) {
                trace("Damage applied to " + target.id + ": " + amount + " (health now " + target.health + ")");
            }
            
            if (target.state == CastlePart.STATE_DESTROYED) {
                return BuildEvent.destroyPart(target);
            }
            
            return BuildEvent.damagePart(target, amount);
        }
        
        /**
         * Recalculate unlocked stage based on current state
         */
        private function recalculateUnlockedStage():void {
            var stages:Array = CastleConfig.GROWTH_STAGES;
            _unlockedStageIndex = -1;
            
            for (var i:int = 0; i < stages.length; i++) {
                if (_accumulatedScore >= stages[i].minScore) {
                    _unlockedStageIndex = i;
                }
            }
        }
        
        /**
         * Update state metadata
         */
        private function updateStateMetadata():void {
            _state.lastUpdated = new Date().getTime();
            _state.completionPercent = CastleConfig.getCompletionPercent(_accumulatedScore);
            _state.level = calculateLevel();
            _state.totalScore = _state.calculateTotalScore();
        }
        
        /**
         * Calculate castle level based on parts and upgrades
         */
        private function calculateLevel():int {
            var level:int = 0;
            
            // Count foundations = level 1
            if (_state.countPartsByType(CastlePart.TYPE_FOUNDATION) > 0) level = 1;
            // Add walls = level 2
            if (_state.countPartsByType(CastlePart.TYPE_WALL) >= 2) level = 2;
            // Add tower = level 3
            if (_state.countPartsByType(CastlePart.TYPE_TOWER) >= 1) level = 3;
            // Two towers = level 4
            if (_state.countPartsByType(CastlePart.TYPE_TOWER) >= 2) level = 4;
            // Keep = level 5
            if (_state.countPartsByType(CastlePart.TYPE_KEEP) >= 1) level = 5;
            // Tier 2+ parts = level 6+
            if (_state.highestTier >= 2) level = Math.max(level, 6);
            if (_state.highestTier >= 3) level = Math.max(level, 7);
            if (_state.highestTier >= 4) level = Math.max(level, 8);
            if (_state.highestTier >= 5) level = Math.max(level, 9);
            // Special parts = level 10
            if (_state.countPartsByType(CastlePart.TYPE_SPECIAL) >= 2) level = 10;
            
            return level;
        }
        
        // ========== PUBLIC API ==========
        
        /**
         * Get current castle state
         */
        public function getCastleState():CastleState {
            return _state;
        }
        
        /**
         * Get current castle state (alias)
         */
        public function get state():CastleState {
            return _state;
        }
        
        /**
         * Add a part to the castle
         */
        public function addPart(type:String, tier:int, gridX:int, gridY:int, variant:String = "default"):CastlePart {
            // Check if position is already occupied by same type
            var existing:Vector.<CastlePart> = _state.getPartsAt(gridX, gridY);
            for each (var ex:CastlePart in existing) {
                if (ex.type == type && ex.isAlive) {
                    if (DEBUG) trace("Part already exists at position");
                    return null;
                }
            }
            
            var part:CastlePart = new CastlePart(
                "part_" + _nextPartId++,
                type,
                tier,
                gridX,
                gridY
            );
            part.variant = variant;
            part.completeBuilding();
            
            _state.parts.push(part);
            _state.totalPartsBuilt++;
            
            if (DEBUG) {
                trace("Added part: " + part.toString());
            }
            
            return part;
        }
        
        /**
         * Upgrade a specific part
         */
        public function upgradePart(partId:String):Boolean {
            var part:CastlePart = _state.getPartById(partId);
            if (part && part.upgrade()) {
                _state.totalUpgrades++;
                return true;
            }
            return false;
        }
        
        /**
         * Damage a specific part
         */
        public function damagePart(partId:String, amount:int):void {
            var part:CastlePart = _state.getPartById(partId);
            if (part) {
                part.damage(amount);
            }
        }
        
        /**
         * Repair a specific part
         */
        public function repairPart(partId:String, amount:int = 0):void {
            var part:CastlePart = _state.getPartById(partId);
            if (part) {
                part.repair(amount > 0 ? amount : CastleConfig.REPAIR_FULL);
            }
        }
        
        /**
         * Repair all damaged parts
         */
        public function repairAll():int {
            var repairedCount:int = 0;
            var damaged:Vector.<CastlePart> = _state.getDamagedParts();
            for each (var part:CastlePart in damaged) {
                part.repair(CastleConfig.REPAIR_FULL);
                repairedCount++;
            }
            return repairedCount;
        }
        
        /**
         * Get total score
         */
        public function getTotalScore():int {
            return _accumulatedScore;
        }
        
        /**
         * Get completion percentage
         */
        public function getCompletionPercentage():Number {
            return _state.completionPercent;
        }
        
        /**
         * Get next milestone info
         */
        public function getNextMilestone():String {
            return _state.nextMilestone;
        }
        
        /**
         * Get current milestone info
         */
        public function getCurrentMilestone():String {
            return _state.currentMilestone;
        }
        
        /**
         * Get points needed for next milestone
         */
        public function getPointsToNextMilestone():int {
            var next:Object = CastleConfig.getNextMilestone(_accumulatedScore);
            return Math.max(0, next.score - _accumulatedScore);
        }
        
        /**
         * Add score directly (for debugging)
         */
        public function addScore(points:int):Vector.<BuildEvent> {
            _accumulatedScore += points;
            _state.totalScore = _accumulatedScore;
            
            var events:Vector.<BuildEvent> = checkGrowth();
            var milestone:BuildEvent = checkMilestone();
            if (milestone) events.push(milestone);
            
            updateStateMetadata();
            return events;
        }
        
        /**
         * Reset castle to empty state
         */
        public function reset():void {
            _state = new CastleState();
            _accumulatedScore = 0;
            _unlockedStageIndex = -1;
            _nextPartId = 1;
            
            if (DEBUG) {
                trace("CastleArchitect reset");
            }
        }
        
        /**
         * Debug: Get summary string
         */
        public function getSummary():String {
            return "Castle: " + _state.parts.length + " parts, " +
                   "Score: " + _accumulatedScore + ", " +
                   "Level: " + _state.level + ", " +
                   "Milestone: " + _state.currentMilestone + ", " +
                   "Next: " + _state.nextMilestone + " (" + getPointsToNextMilestone() + " pts)";
        }
    }
}
