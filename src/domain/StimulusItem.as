package domain {

    /**
     * StimulusItem - Represents a single item in the sequence challenge.
     * Contains visual properties for display and logical ID for validation.
     *
     * SOLID Principles:
     * - Single Responsibility: Only holds stimulus data and validation
     * - Open/Closed: Can be extended with new properties without changing existing code
     * - Liskov Substitution: Can be used anywhere StimulusItem is expected
     */
    public class StimulusItem {

        // ============ STATIC CONSTANTS ============
        /** Shape type */
        public static const TYPE_SHAPE:String = "shape";
        /** Color type */
        public static const TYPE_COLOR:String = "color";
        /** Number type */
        public static const TYPE_NUMBER:String = "number";
        /** Pattern type */
        public static const TYPE_PATTERN:String = "pattern";
        
        // Available shapes
        public static const SHAPE_CIRCLE:String = "circle";
        public static const SHAPE_SQUARE:String = "square";
        public static const SHAPE_TRIANGLE:String = "triangle";
        public static const SHAPE_STAR:String = "star";
        public static const SHAPE_DIAMOND:String = "diamond";
        public static const SHAPE_HEXAGON:String = "hexagon";
        public static const SHAPE_PENTAGON:String = "pentagon";
        public static const SHAPE_OCTAGON:String = "octagon";

        // ============ INSTANCE PROPERTIES ============
        
        /** Unique identifier for this item (used for validation) */
        public var id:int;
        
        /** Type category: "shape", "color", "number", "pattern" */
        public var type:String;
        
        /** Shape name: "circle", "square", "triangle", "star", "hexagon", "diamond" */
        public var shape:String;
        
        /** Hex color value */
        public var color:uint;
        
        /** Numerical value for sorting tasks */
        public var value:int;
        
        /** Display label for UI (e.g., "1", "A", shape emoji) */
        public var displayLabel:String;
        
        /** Position in original sequence (for validation) */
        public var position:int;
        
        /** Difficulty tier this item was generated for */
        public var tier:int;
        
        /** Timestamp when item was shown (for timing analysis) */
        public var shownAt:Number;
        
        /** Pattern data (for pattern-based stimuli) */
        public var patternData:Array;

        /**
         * Constructor
         * @param id Unique identifier
         * @param shape Shape/symbol name
         * @param color Hex color value
         * @param value Numerical value for sorting
         * @param type Type category
         */
        public function StimulusItem(id:int = 0, shape:String = "circle", color:uint = 0xFFFFFF, value:int = 0, type:String = "shape") {
            this.id = id;
            this.shape = shape;
            this.color = color;
            this.value = value;
            this.type = type;
            this.position = id;
            this.tier = 1;
            this.displayLabel = generateDisplayLabel();
        }
        
        /**
         * Generate display label based on type
         */
        private function generateDisplayLabel():String {
            switch (type) {
                case TYPE_NUMBER:
                    return String(value);
                case TYPE_COLOR:
                    return getColorName(color);
                case TYPE_SHAPE:
                default:
                    return getShapeEmoji(shape);
            }
        }
        
        /**
         * Get emoji/unicode for shape
         */
        private function getShapeEmoji(s:String):String {
            switch (s) {
                case SHAPE_CIRCLE: return "●";
                case SHAPE_SQUARE: return "■";
                case SHAPE_TRIANGLE: return "▲";
                case SHAPE_STAR: return "★";
                case SHAPE_DIAMOND: return "◆";
                case SHAPE_HEXAGON: return "⬡";
                case SHAPE_PENTAGON: return "⬠";
                case SHAPE_OCTAGON: return "⯃";
                default: return "?";
            }
        }
        
        /**
         * Get color name from hex
         */
        private function getColorName(c:uint):String {
            switch (c) {
                case 0xFF0000: return "Red";
                case 0x00FF00: return "Green";
                case 0x0000FF: return "Blue";
                case 0xFFFF00: return "Yellow";
                case 0xFF00FF: return "Magenta";
                case 0x00FFFF: return "Cyan";
                case 0xFFA500: return "Orange";
                case 0x800080: return "Purple";
                default: return "#" + c.toString(16);
            }
        }

        /**
         * Creates a copy of this stimulus item
         * @return New StimulusItem instance with same properties
         */
        public function clone():StimulusItem {
            var item:StimulusItem = new StimulusItem(id, shape, color, value, type);
            item.displayLabel = displayLabel;
            item.position = position;
            item.tier = tier;
            item.shownAt = shownAt;
            if (patternData) {
                item.patternData = patternData.slice();
            }
            return item;
        }

        /**
         * String representation for debugging
         * @return String description
         */
        public function toString():String {
            return "[StimulusItem id:" + id + " type:" + type + " shape:" + shape + 
                   " color:0x" + color.toString(16).toUpperCase() + " value:" + value + 
                   " label:'" + displayLabel + "']";
        }

        /**
         * Check if two items are visually identical (same symbol and color)
         * @param other Item to compare
         * @return True if visually identical
         */
        public function equalsVisual(other:StimulusItem):Boolean {
            if (!other) return false;
            return (shape == other.shape && color == other.color);
        }

        /**
         * Check if two items are logically identical (same id)
         * @param other Item to compare
         * @return True if same id
         */
        public function equals(other:StimulusItem):Boolean {
            if (!other) return false;
            return (id == other.id);
        }
        
        /**
         * Check if this item matches for sorting comparison
         * @param other Item to compare
         * @return Comparison result (-1, 0, 1)
         */
        public function compareTo(other:StimulusItem):int {
            if (value < other.value) return -1;
            if (value > other.value) return 1;
            return 0;
        }
        
        /**
         * Create a StimulusItem from button index (0-5)
         */
        public static function fromButtonIndex(index:int, tier:int = 1):StimulusItem {
            var shapes:Array = [SHAPE_CIRCLE, SHAPE_SQUARE, SHAPE_TRIANGLE, 
                               SHAPE_STAR, SHAPE_DIAMOND, SHAPE_HEXAGON];
            var colors:Array = [0x2196F3, 0xF44336, 0x4CAF50, 0xFFEB3B, 0x9C27B0, 0xFF9800];
            
            var shape:String = shapes[index % shapes.length];
            var color:uint = colors[index % colors.length];
            
            return new StimulusItem(index, shape, color, index + 1, TYPE_SHAPE);
        }
    }
}