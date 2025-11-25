package {

    /**
     * StimulusItem - Represents a single item in the sequence challenge.
     * Contains visual properties for display and logical ID for validation.
     */
    public class StimulusItem {

        // Unique identifier for this item (used for validation)
        public var id:int;

        // Visual properties
        public var symbol:String;  // e.g., "circle", "square"
        public var color:uint;     // Hex color value

        // Optional: additional properties for future expansion
        public var value:int;      // Numerical value if needed for sorting tasks
        public var type:String;    // Type category (e.g., "geometric", "numeric")

        /**
         * Constructor
         * @param id Unique identifier
         * @param symbol Shape/symbol name
         * @param color Hex color value
         * @param value Optional numerical value
         * @param type Optional type category
         */
        public function StimulusItem(id:int, symbol:String, color:uint, value:int = 0, type:String = "geometric") {
            this.id = id;
            this.symbol = symbol;
            this.color = color;
            this.value = value;
            this.type = type;
        }

        /**
         * Creates a copy of this stimulus item
         * @return New StimulusItem instance with same properties
         */
        public function clone():StimulusItem {
            return new StimulusItem(id, symbol, color, value, type);
        }

        /**
         * String representation for debugging
         * @return String description
         */
        public function toString():String {
            return "[StimulusItem id:" + id + " symbol:" + symbol + " color:0x" + color.toString(16) + "]";
        }

        /**
         * Check if two items are visually identical (same symbol and color)
         * @param other Item to compare
         * @return True if visually identical
         */
        public function equalsVisual(other:StimulusItem):Boolean {
            return (symbol == other.symbol && color == other.color);
        }

        /**
         * Check if two items are logically identical (same id)
         * @param other Item to compare
         * @return True if same id
         */
        public function equals(other:StimulusItem):Boolean {
            return (id == other.id);
        }
    }
}