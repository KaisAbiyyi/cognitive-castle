package castle {
    
    /**
     * AdditionTower - Data model for an addition tower node.
     * 
     * Towers are nodes in a left/right chain off the main castle:
     * - Left chain uses leftId pointers (outward only)
     * - Right chain uses rightId pointers (outward only)
     * 
     * Size stages:
     * - 3 = Full/Normal (just spawned or fully healed)
     * - 2 = Damaged (took 1 hit)
     * - 1 = Critical (took 2 hits)
     * - 0 = Destroyed (tower removed after 3 hits)
     */
    public class AdditionTower {
        
        // Size stage constants
        public static const SIZE_FULL:int = 3;
        public static const SIZE_DAMAGED:int = 2;
        public static const SIZE_CRITICAL:int = 1;
        public static const SIZE_DESTROYED:int = 0;
        
        // Side constants
        public static const SIDE_LEFT:String = "LEFT";
        public static const SIDE_RIGHT:String = "RIGHT";
        
        /** Unique tower ID (e.g., "L1", "R1", ...) */
        public var id:String;
        
        /** Creation order index (1, 2, 3, ...) for debugging */
        public var createdAtIndex:int;
        
        /** Which side of main castle: "LEFT" or "RIGHT" */
        public var side:String;
        
        /** Current size stage: 3=full, 2=damaged, 1=critical, 0=destroyed */
        public var sizeStage:int;

        /** Outward node pointer on the left chain (only used for LEFT side) */
        public var leftId:String;

        /** Outward node pointer on the right chain (only used for RIGHT side) */
        public var rightId:String;

        /**
         * Base (full-health) scale for this tower. This is the persistent "growth" value
         * that increases on wins, and is then multiplied by the sizeStage damage factor.
         */
        public var baseScale:Number;

        /**
         * Maximum base scale for this tower (growth cap).
         */
        public var maxScale:Number;
        
        // ========== OPTIONAL VISUAL PROPERTIES ==========
        
        /** Visual X offset from anchor point */
        public var visualOffsetX:Number;
        
        /** Visual Y offset from anchor point */
        public var visualOffsetY:Number;
        
        /** Visual width (for rendering) */
        public var width:Number;
        
        /** Visual height (for rendering) */
        public var height:Number;

        /** Image path used for this tower */
        public var imageUrl:String;
        
        /**
         * Constructor
         */
        public function AdditionTower() {
            id = "";
            createdAtIndex = 0;
            side = SIDE_LEFT;
            sizeStage = SIZE_FULL;
            baseScale = 1.0;
            maxScale = 1.0;
            leftId = null;
            rightId = null;
            visualOffsetX = 0;
            visualOffsetY = 0;
            width = 0;
            height = 0;
            imageUrl = "assets/images/Game/towerCastle.png";
        }

        /**
         * Default max scale for a tower by creation index (1, 2, 3...).
         * Kept in the model so both state and UI can stay consistent.
         */
        public static function getMaxScaleForCreatedIndex(createdAtIndex:int):Number {
            if (createdAtIndex <= 0) return 1.0;
            switch (createdAtIndex) {
                case 1: return 1.25;
                case 2: return 1.0;
                case 3: return 0.85;
                default: return 0.7;
            }
        }

        /**
         * Default initial base scale for a new tower, derived from its max scale.
         * The ratio ensures new towers have room to grow on subsequent wins.
         */
        public static function getInitialBaseScaleForMaxScale(maxScale:Number):Number {
            if (isNaN(maxScale) || maxScale <= 0) return 1.0;
            return maxScale * 0.8;
        }
        
        /**
         * Check if tower is at full health
         */
        public function get isFull():Boolean {
            return sizeStage >= SIZE_FULL;
        }
        
        /**
         * Check if tower is damaged (but not destroyed)
         */
        public function get isDamaged():Boolean {
            return sizeStage > SIZE_DESTROYED && sizeStage < SIZE_FULL;
        }
        
        /**
         * Check if tower is destroyed
         */
        public function get isDestroyed():Boolean {
            return sizeStage <= SIZE_DESTROYED;
        }
        
        /**
         * Check if tower is critical (one hit from destruction)
         */
        public function get isCritical():Boolean {
            return sizeStage == SIZE_CRITICAL;
        }
        
        /**
         * Get visual scale for tower based on sizeStage
         * Stage 3 (full) = 1.00
         * Stage 2 (damaged) = 0.85
         * Stage 1 (critical) = 0.70
         * Stage 0 (destroyed) = 0.00
         */
        public function getScale():Number {
            var stageFactor:Number;
            switch (sizeStage) {
                case SIZE_FULL: stageFactor = 1.00; break;
                case SIZE_DAMAGED: stageFactor = 0.85; break;
                case SIZE_CRITICAL: stageFactor = 0.70; break;
                default: stageFactor = 0.00; break; // Destroyed
            }
            
            var effectiveMax:Number = (!isNaN(maxScale) && maxScale > 0) ? maxScale : 1.0;
            var effectiveBase:Number = (!isNaN(baseScale) && baseScale > 0) ? baseScale : 1.0;
            effectiveBase = Math.min(effectiveBase, effectiveMax);
            
            return effectiveBase * stageFactor;
        }
        
        /**
         * Apply damage (reduce size stage by 1)
         * @return true if tower is now destroyed
         */
        public function damage():Boolean {
            if (sizeStage > SIZE_DESTROYED) {
                sizeStage--;
            }
            return isDestroyed;
        }
        
        /**
         * Apply healing (increase size stage by 1, max = full)
         * @return true if tower was healed (wasn't already full)
         */
        public function heal():Boolean {
            if (sizeStage < SIZE_FULL) {
                sizeStage++;
                return true;
            }
            return false;
        }
        
        /**
         * Get visual scale multiplier based on size stage
         * This converts size stage to a visual scale factor
         */
        public function getVisualScale():Number {
            return getScale();
        }
        
        /**
         * Serialize to object for saving
         */
        public function toObject():Object {
            return {
                id: id,
                createdAtIndex: createdAtIndex,
                side: side,
                sizeStage: sizeStage,
                leftId: leftId,
                rightId: rightId,
                baseScale: baseScale,
                maxScale: maxScale,
                visualOffsetX: visualOffsetX,
                visualOffsetY: visualOffsetY,
                width: width,
                height: height,
                imageUrl: imageUrl
            };
        }
        
        /**
         * Create AdditionTower from saved object
         */
        public static function fromObject(obj:Object):AdditionTower {
            var tower:AdditionTower = new AdditionTower();
            tower.id = obj.id || "";
            tower.createdAtIndex = obj.createdAtIndex || 0;
            tower.side = obj.side || SIDE_LEFT;
            tower.sizeStage = (obj.sizeStage !== undefined) ? obj.sizeStage : SIZE_FULL;
            tower.leftId = obj.leftId || null;
            tower.rightId = obj.rightId || null;
            
            // Growth fields (backwards compatible defaults)
            tower.maxScale = (obj.maxScale !== undefined) ? Number(obj.maxScale) :
                getMaxScaleForCreatedIndex(tower.createdAtIndex);
            tower.baseScale = (obj.baseScale !== undefined) ? Number(obj.baseScale) : 1.0;
            if (isNaN(tower.maxScale) || tower.maxScale <= 0) tower.maxScale = 1.0;
            if (isNaN(tower.baseScale) || tower.baseScale <= 0) tower.baseScale = 1.0;
            tower.baseScale = Math.min(tower.baseScale, tower.maxScale);
            
            tower.visualOffsetX = obj.visualOffsetX || 0;
            tower.visualOffsetY = obj.visualOffsetY || 0;
            tower.width = obj.width || 0;
            tower.height = obj.height || 0;
            tower.imageUrl = obj.imageUrl || "assets/images/Game/towerCastle.png";
            return tower;
        }
        
        /**
         * Create a clone of this tower
         */
        public function clone():AdditionTower {
            return AdditionTower.fromObject(this.toObject());
        }
        
        /**
         * String representation for debugging
         */
        public function toString():String {
            return "[AdditionTower id=" + id + 
                   " side=" + side + 
                   " sizeStage=" + sizeStage + 
                   " idx=" + createdAtIndex + "]";
        }
    }
}
