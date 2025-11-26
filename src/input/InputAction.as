package input {

    import flash.geom.Point;

    /**
     * InputAction - Unified input event model that abstracts Touch vs Mouse vs Keyboard events.
     * Used to standardize input handling across platforms.
     *
     * SOLID Principles:
     * - Single Responsibility: Only represents input action data
     * - Open/Closed: Can be extended with new action types without changing existing code
     * - Liskov Substitution: Can be used anywhere InputAction is expected
     */
    public class InputAction {

        // ============ ACTION TYPES ============
        public static const PRESS:String = "press";
        public static const RELEASE:String = "release";
        public static const CLICK:String = "click";
        public static const TAP:String = "tap";
        public static const KEY:String = "key";
        public static const UNDO:String = "undo";
        public static const CLEAR:String = "clear";
        public static const SUBMIT:String = "submit";
        
        // ============ INPUT METHODS ============
        public static const METHOD_MOUSE:String = "mouse";
        public static const METHOD_TOUCH:String = "touch";
        public static const METHOD_KEYBOARD:String = "keyboard";

        // ============ PROPERTIES ============
        
        /** Action type (PRESS, RELEASE, CLICK, TAP, KEY, UNDO, CLEAR, SUBMIT) */
        public var type:String;
        
        /** Logical stimulus/button ID (mapped from UI element) */
        public var targetId:int;
        
        /** Screen position where action occurred */
        public var position:Point;
        
        /** Timestamp when action occurred (ms since epoch) */
        public var timestamp:Number;
        
        /** Input method used (mouse, touch, keyboard) */
        public var inputMethod:String;
        
        /** Raw key code for keyboard input */
        public var keyCode:int;
        
        /** Whether this is a repeat action (key held down) */
        public var isRepeat:Boolean;
        
        /** Delta time since input phase started (ms) */
        public var deltaTime:Number;

        /**
         * Constructor
         * @param type Action type
         * @param targetId Logical stimulus/button identifier
         * @param position Screen position (optional)
         * @param inputMethod Input method used
         * @param timestamp Event timestamp
         */
        public function InputAction(type:String, targetId:int = -1, position:Point = null, 
                                    inputMethod:String = "mouse", timestamp:Number = 0) {
            this.type = type;
            this.targetId = targetId;
            this.position = position || new Point(0, 0);
            this.inputMethod = inputMethod;
            this.timestamp = timestamp > 0 ? timestamp : new Date().time;
            this.keyCode = -1;
            this.isRepeat = false;
            this.deltaTime = 0;
        }
        
        /**
         * Create from mouse event data
         */
        public static function fromMouse(type:String, targetId:int, x:Number, y:Number):InputAction {
            return new InputAction(type, targetId, new Point(x, y), METHOD_MOUSE);
        }
        
        /**
         * Create from touch event data
         */
        public static function fromTouch(type:String, targetId:int, x:Number, y:Number):InputAction {
            return new InputAction(type, targetId, new Point(x, y), METHOD_TOUCH);
        }
        
        /**
         * Create from keyboard event data
         */
        public static function fromKeyboard(type:String, targetId:int, keyCode:int):InputAction {
            var action:InputAction = new InputAction(type, targetId, null, METHOD_KEYBOARD);
            action.keyCode = keyCode;
            return action;
        }
        
        /**
         * Create an undo action
         */
        public static function createUndo(inputMethod:String = "keyboard"):InputAction {
            return new InputAction(UNDO, -1, null, inputMethod);
        }
        
        /**
         * Create a clear action
         */
        public static function createClear(inputMethod:String = "keyboard"):InputAction {
            return new InputAction(CLEAR, -1, null, inputMethod);
        }
        
        /**
         * Create a submit action
         */
        public static function createSubmit(inputMethod:String = "keyboard"):InputAction {
            return new InputAction(SUBMIT, -1, null, inputMethod);
        }

        /**
         * Clone this action
         */
        public function clone():InputAction {
            var action:InputAction = new InputAction(type, targetId, position.clone(), inputMethod, timestamp);
            action.keyCode = keyCode;
            action.isRepeat = isRepeat;
            action.deltaTime = deltaTime;
            return action;
        }

        /**
         * String representation for debugging
         * @return String description
         */
        public function toString():String {
            var posStr:String = position ? "(" + position.x.toFixed(0) + "," + position.y.toFixed(0) + ")" : "(-)";
            return "[InputAction type:" + type + " target:" + targetId + " method:" + inputMethod + 
                   " pos:" + posStr + " dt:" + deltaTime.toFixed(0) + "ms]";
        }
    }
}