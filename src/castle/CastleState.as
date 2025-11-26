package castle {
    
    /**
     * CastleState - Snapshot of entire castle at a point in time.
     * Used for saving/loading and tracking castle progress.
     */
    public class CastleState {
        
        // All castle parts
        public var parts:Vector.<CastlePart>;
        
        // Total accumulated score
        public var totalScore:int;
        
        // Current milestone name
        public var currentMilestone:String;
        
        // Next milestone to achieve
        public var nextMilestone:String;
        
        // Completion percentage (0-100)
        public var completionPercent:Number;
        
        // Timestamp of last update
        public var lastUpdated:Number;
        
        // Total parts ever built (including destroyed)
        public var totalPartsBuilt:int;
        
        // Total parts upgraded
        public var totalUpgrades:int;
        
        // Castle level (based on total score)
        public var level:int;
        
        /**
         * Constructor
         */
        public function CastleState() {
            parts = new Vector.<CastlePart>();
            totalScore = 0;
            currentMilestone = "Empty Land";
            nextMilestone = "Foundation";
            completionPercent = 0;
            lastUpdated = new Date().getTime();
            totalPartsBuilt = 0;
            totalUpgrades = 0;
            level = 0;
        }
        
        /**
         * Get part by ID
         */
        public function getPartById(id:String):CastlePart {
            for each (var part:CastlePart in parts) {
                if (part.id == id) return part;
            }
            return null;
        }
        
        /**
         * Get parts by type
         */
        public function getPartsByType(type:String):Vector.<CastlePart> {
            var result:Vector.<CastlePart> = new Vector.<CastlePart>();
            for each (var part:CastlePart in parts) {
                if (part.type == type) result.push(part);
            }
            return result;
        }
        
        /**
         * Get parts at grid position
         */
        public function getPartsAt(gridX:int, gridY:int):Vector.<CastlePart> {
            var result:Vector.<CastlePart> = new Vector.<CastlePart>();
            for each (var part:CastlePart in parts) {
                if (part.gridX == gridX && part.gridY == gridY) {
                    result.push(part);
                }
            }
            return result;
        }
        
        /**
         * Get all living (non-destroyed) parts
         */
        public function getLivingParts():Vector.<CastlePart> {
            var result:Vector.<CastlePart> = new Vector.<CastlePart>();
            for each (var part:CastlePart in parts) {
                if (part.isAlive) result.push(part);
            }
            return result;
        }
        
        /**
         * Get all damaged parts
         */
        public function getDamagedParts():Vector.<CastlePart> {
            var result:Vector.<CastlePart> = new Vector.<CastlePart>();
            for each (var part:CastlePart in parts) {
                if (part.needsRepair) result.push(part);
            }
            return result;
        }
        
        /**
         * Count parts by type
         */
        public function countPartsByType(type:String):int {
            var count:int = 0;
            for each (var part:CastlePart in parts) {
                if (part.type == type && part.isAlive) count++;
            }
            return count;
        }
        
        /**
         * Get average health of all parts
         */
        public function get averageHealth():Number {
            if (parts.length == 0) return 100;
            var totalHealth:int = 0;
            var aliveCount:int = 0;
            for each (var part:CastlePart in parts) {
                if (part.isAlive) {
                    totalHealth += part.health;
                    aliveCount++;
                }
            }
            return aliveCount > 0 ? totalHealth / aliveCount : 0;
        }
        
        /**
         * Calculate total score from all living parts
         */
        public function calculateTotalScore():int {
            var score:int = 0;
            for each (var part:CastlePart in parts) {
                if (part.isAlive) {
                    score += part.scoreValue;
                }
            }
            return score;
        }
        
        /**
         * Get highest tier of any part
         */
        public function get highestTier():int {
            var maxTier:int = 0;
            for each (var part:CastlePart in parts) {
                if (part.tier > maxTier) maxTier = part.tier;
            }
            return maxTier;
        }
        
        /**
         * Check if castle has any parts
         */
        public function get isEmpty():Boolean {
            return parts.length == 0 || getLivingParts().length == 0;
        }
        
        /**
         * Serialize to object for saving
         */
        public function toObject():Object {
            var partsArray:Array = [];
            for each (var part:CastlePart in parts) {
                partsArray.push(part.toObject());
            }
            return {
                parts: partsArray,
                totalScore: totalScore,
                currentMilestone: currentMilestone,
                nextMilestone: nextMilestone,
                completionPercent: completionPercent,
                lastUpdated: lastUpdated,
                totalPartsBuilt: totalPartsBuilt,
                totalUpgrades: totalUpgrades,
                level: level
            };
        }
        
        /**
         * Create CastleState from saved object
         */
        public static function fromObject(obj:Object):CastleState {
            var state:CastleState = new CastleState();
            
            if (obj.parts) {
                for each (var partObj:Object in obj.parts) {
                    state.parts.push(CastlePart.fromObject(partObj));
                }
            }
            
            state.totalScore = obj.totalScore || 0;
            state.currentMilestone = obj.currentMilestone || "Empty Land";
            state.nextMilestone = obj.nextMilestone || "Foundation";
            state.completionPercent = obj.completionPercent || 0;
            state.lastUpdated = obj.lastUpdated || 0;
            state.totalPartsBuilt = obj.totalPartsBuilt || 0;
            state.totalUpgrades = obj.totalUpgrades || 0;
            state.level = obj.level || 0;
            
            return state;
        }
        
        /**
         * Create a clone of this state
         */
        public function clone():CastleState {
            return CastleState.fromObject(this.toObject());
        }
        
        /**
         * String representation
         */
        public function toString():String {
            return "[CastleState parts=" + parts.length + " score=" + totalScore + 
                   " level=" + level + " milestone=" + currentMilestone + "]";
        }
    }
}
