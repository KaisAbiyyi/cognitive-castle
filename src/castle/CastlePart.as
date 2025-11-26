package castle {
    
    /**
     * CastlePart - Represents a single component of the castle.
     * Each part has a type, tier, position, health, and visual state.
     * 
     * Types: "foundation", "wall", "tower", "decoration", "keep", "special"
     * States: "building", "healthy", "damaged", "destroyed"
     */
    public class CastlePart {
        
        // Part Types
        public static const TYPE_FOUNDATION:String = "foundation";
        public static const TYPE_WALL:String = "wall";
        public static const TYPE_TOWER:String = "tower";
        public static const TYPE_DECORATION:String = "decoration";
        public static const TYPE_KEEP:String = "keep";
        public static const TYPE_SPECIAL:String = "special";
        
        // Part States
        public static const STATE_BUILDING:String = "building";
        public static const STATE_HEALTHY:String = "healthy";
        public static const STATE_DAMAGED:String = "damaged";
        public static const STATE_DESTROYED:String = "destroyed";
        
        // Unique identifier
        public var id:String;
        
        // Part type (foundation, wall, tower, decoration, keep, special)
        public var type:String;
        
        // Tier level (1-5) - higher tier = stronger/better looking
        public var tier:int;
        
        // Grid position
        public var gridX:int;
        public var gridY:int;
        
        // Health (0-100)
        public var health:int;
        
        // Current state
        public var state:String;
        
        // Z-index for rendering order
        public var zIndex:int;
        
        // Variant for visual diversity (e.g., wall_left, wall_right, tower_round, tower_square)
        public var variant:String;
        
        // Timestamp when part was built
        public var builtAt:Number;
        
        // Score value this part contributes
        public var scoreValue:int;
        
        /**
         * Constructor
         * @param id Unique identifier
         * @param type Part type
         * @param tier Tier level (1-5)
         * @param gridX Grid X position
         * @param gridY Grid Y position
         */
        public function CastlePart(id:String, type:String, tier:int = 1, gridX:int = 0, gridY:int = 0) {
            this.id = id;
            this.type = type;
            this.tier = Math.max(1, Math.min(5, tier));
            this.gridX = gridX;
            this.gridY = gridY;
            this.health = 100;
            this.state = STATE_BUILDING;
            this.zIndex = calculateZIndex();
            this.variant = "default";
            this.builtAt = new Date().getTime();
            this.scoreValue = calculateScoreValue();
        }
        
        /**
         * Calculate z-index based on type and position
         */
        private function calculateZIndex():int {
            var baseZ:int = 0;
            switch (type) {
                case TYPE_FOUNDATION: baseZ = 0; break;
                case TYPE_WALL: baseZ = 100; break;
                case TYPE_TOWER: baseZ = 200; break;
                case TYPE_KEEP: baseZ = 300; break;
                case TYPE_DECORATION: baseZ = 400; break;
                case TYPE_SPECIAL: baseZ = 500; break;
            }
            return baseZ + gridY * 10 + gridX;
        }
        
        /**
         * Calculate score value based on type and tier
         */
        private function calculateScoreValue():int {
            var baseScore:int = 0;
            switch (type) {
                case TYPE_FOUNDATION: baseScore = 5; break;
                case TYPE_WALL: baseScore = 10; break;
                case TYPE_TOWER: baseScore = 25; break;
                case TYPE_KEEP: baseScore = 50; break;
                case TYPE_DECORATION: baseScore = 5; break;
                case TYPE_SPECIAL: baseScore = 100; break;
            }
            return baseScore * tier;
        }
        
        /**
         * Check if part can be upgraded
         */
        public function canUpgrade():Boolean {
            return tier < 5 && state == STATE_HEALTHY;
        }
        
        /**
         * Upgrade part to next tier
         * @return True if upgrade successful
         */
        public function upgrade():Boolean {
            if (!canUpgrade()) return false;
            tier++;
            scoreValue = calculateScoreValue();
            return true;
        }
        
        /**
         * Apply damage to part
         * @param amount Damage amount (0-100)
         */
        public function damage(amount:int):void {
            health = Math.max(0, health - amount);
            updateState();
        }
        
        /**
         * Repair part
         * @param amount Repair amount (0-100)
         */
        public function repair(amount:int):void {
            health = Math.min(100, health + amount);
            updateState();
        }
        
        /**
         * Update state based on health
         */
        private function updateState():void {
            if (health <= 0) {
                state = STATE_DESTROYED;
            } else if (health < 50) {
                state = STATE_DAMAGED;
            } else {
                state = STATE_HEALTHY;
            }
        }
        
        /**
         * Mark part as completed building
         */
        public function completeBuilding():void {
            if (state == STATE_BUILDING) {
                state = STATE_HEALTHY;
            }
        }
        
        /**
         * Check if part is functional (not destroyed)
         */
        public function get isAlive():Boolean {
            return state != STATE_DESTROYED;
        }
        
        /**
         * Check if part needs repair
         */
        public function get needsRepair():Boolean {
            return health < 100 && state != STATE_DESTROYED;
        }
        
        /**
         * Get health percentage
         */
        public function get healthPercent():Number {
            return health / 100;
        }
        
        /**
         * Serialize to object for saving
         */
        public function toObject():Object {
            return {
                id: id,
                type: type,
                tier: tier,
                gridX: gridX,
                gridY: gridY,
                health: health,
                state: state,
                zIndex: zIndex,
                variant: variant,
                builtAt: builtAt,
                scoreValue: scoreValue
            };
        }
        
        /**
         * Create CastlePart from saved object
         */
        public static function fromObject(obj:Object):CastlePart {
            var part:CastlePart = new CastlePart(
                obj.id,
                obj.type,
                obj.tier,
                obj.gridX,
                obj.gridY
            );
            part.health = obj.health;
            part.state = obj.state;
            part.zIndex = obj.zIndex;
            part.variant = obj.variant || "default";
            part.builtAt = obj.builtAt || 0;
            part.scoreValue = obj.scoreValue || part.calculateScoreValue();
            return part;
        }
        
        /**
         * String representation
         */
        public function toString():String {
            return "[CastlePart id=" + id + " type=" + type + " tier=" + tier + 
                   " pos=(" + gridX + "," + gridY + ") health=" + health + " state=" + state + "]";
        }
    }
}
