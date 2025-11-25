package {

    /**
     * InputAction - Unified input event model that abstracts Touch vs Mouse events.
     * Used to standardize input handling across platforms.
     */
    public class InputAction {

        // Action types
        public static const PRESS:String = "press";
        public static const RELEASE:String = "release";
        public static const CLICK:String = "click";

        // Properties
        public var type:String;        // Action type (PRESS, RELEASE, CLICK)
        public var stimulusId:int;     // Logical stimulus ID (mapped from UI element)
        public var x:Number;           // Screen X coordinate
        public var y:Number;           // Screen Y coordinate
        public var timestamp:uint;     // Timestamp when action occurred

        /**
         * Constructor
         * @param type Action type
         * @param stimulusId Logical stimulus identifier
         * @param x Screen X position
         * @param y Screen Y position
         * @param timestamp Event timestamp
         */
        public function InputAction(type:String, stimulusId:int, x:Number = 0, y:Number = 0, timestamp:uint = 0) {
            this.type = type;
            this.stimulusId = stimulusId;
            this.x = x;
            this.y = y;
            this.timestamp = timestamp > 0 ? timestamp : new Date().time;
        }

        /**
         * String representation for debugging
         * @return String description
         */
        public function toString():String {
            return "[InputAction type:" + type + " stimulusId:" + stimulusId + " pos:(" + x + "," + y + ") time:" + timestamp + "]";
        }
    }
}