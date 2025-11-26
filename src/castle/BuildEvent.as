package castle {
    
    /**
     * BuildEvent - Represents a castle construction/modification event.
     * Emitted when parts are added, upgraded, damaged, or repaired.
     */
    public class BuildEvent {
        
        // Event Types (short form)
        public static const TYPE_ADD:String = "add";
        public static const TYPE_UPGRADE:String = "upgrade";
        public static const TYPE_DAMAGE:String = "damage";
        public static const TYPE_REPAIR:String = "repair";
        public static const TYPE_DESTROY:String = "destroy";
        public static const TYPE_MILESTONE:String = "milestone";
        
        // Event Types (long form aliases)
        public static const TYPE_PART_ADDED:String = "add";
        public static const TYPE_PART_UPGRADED:String = "upgrade";
        public static const TYPE_PART_DAMAGED:String = "damage";
        public static const TYPE_PART_REPAIRED:String = "repair";
        public static const TYPE_PART_DESTROYED:String = "destroy";
        public static const TYPE_MILESTONE_REACHED:String = "milestone";
        
        // Event type
        public var type:String;
        
        // Affected part (null for milestone events)
        public var part:CastlePart;
        
        // Milestone name (for milestone events)
        public var milestoneName:String;
        
        // Milestone ID (alias for milestoneName)
        public function get milestoneId():String { return milestoneName; }
        public function set milestoneId(value:String):void { milestoneName = value; }
        
        // Score change from this event
        public var scoreChange:int;
        
        // Score delta (alias for scoreChange)
        public function get scoreDelta():int { return scoreChange; }
        public function set scoreDelta(value:int):void { scoreChange = value; }
        
        // Message to display
        public var message:String;
        
        // Timestamp
        public var timestamp:Number;
        
        /**
         * Constructor
         */
        public function BuildEvent(type:String, part:CastlePart = null) {
            this.type = type;
            this.part = part;
            this.scoreChange = 0;
            this.message = "";
            this.timestamp = new Date().getTime();
        }
        
        /**
         * Create ADD event
         */
        public static function addPart(part:CastlePart):BuildEvent {
            var event:BuildEvent = new BuildEvent(TYPE_ADD, part);
            event.scoreChange = part.scoreValue;
            event.message = "Built " + formatPartName(part);
            return event;
        }
        
        /**
         * Create UPGRADE event
         */
        public static function upgradePart(part:CastlePart):BuildEvent {
            var event:BuildEvent = new BuildEvent(TYPE_UPGRADE, part);
            event.scoreChange = part.scoreValue / part.tier; // Increment value
            event.message = "Upgraded " + formatPartName(part) + " to Tier " + part.tier;
            return event;
        }
        
        /**
         * Create DAMAGE event
         */
        public static function damagePart(part:CastlePart, amount:int):BuildEvent {
            var event:BuildEvent = new BuildEvent(TYPE_DAMAGE, part);
            event.scoreChange = 0; // Damage doesn't change score directly
            event.message = formatPartName(part) + " took " + amount + " damage!";
            return event;
        }
        
        /**
         * Create REPAIR event
         */
        public static function repairPart(part:CastlePart, amount:int):BuildEvent {
            var event:BuildEvent = new BuildEvent(TYPE_REPAIR, part);
            event.scoreChange = 0;
            event.message = "Repaired " + formatPartName(part) + " +" + amount + " HP";
            return event;
        }
        
        /**
         * Create DESTROY event
         */
        public static function destroyPart(part:CastlePart):BuildEvent {
            var event:BuildEvent = new BuildEvent(TYPE_DESTROY, part);
            event.scoreChange = -part.scoreValue;
            event.message = formatPartName(part) + " was destroyed!";
            return event;
        }
        
        /**
         * Create MILESTONE event
         */
        public static function reachMilestone(milestoneName:String):BuildEvent {
            var event:BuildEvent = new BuildEvent(TYPE_MILESTONE, null);
            event.milestoneName = milestoneName;
            event.message = "Milestone Reached: " + milestoneName + "!";
            return event;
        }
        
        /**
         * Format part name for display
         */
        private static function formatPartName(part:CastlePart):String {
            var typeName:String = part.type.charAt(0).toUpperCase() + part.type.substr(1);
            if (part.variant != "default") {
                return typeName + " (" + part.variant + ")";
            }
            return typeName;
        }
        
        /**
         * String representation
         */
        public function toString():String {
            return "[BuildEvent type=" + type + " message=" + message + " score=" + scoreChange + "]";
        }
    }
}
