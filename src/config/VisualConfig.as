package config {
    
    /**
     * VisualConfig - Visual vocabulary for stimulus presentation.
     * Contains color-blind safe colors, shape definitions, and display modes.
     * 
     * T1-062: 6 shapes + 8 colors (color-blind safe)
     */
    public class VisualConfig {
        
        // ============ SHAPES (6 core shapes) ============
        
        public static const SHAPE_CIRCLE:String = "circle";
        public static const SHAPE_SQUARE:String = "square";
        public static const SHAPE_TRIANGLE:String = "triangle";
        public static const SHAPE_STAR:String = "star";
        public static const SHAPE_HEXAGON:String = "hexagon";
        public static const SHAPE_DIAMOND:String = "diamond";
        
        /** All available shapes */
        public static const SHAPES:Array = [
            SHAPE_CIRCLE,
            SHAPE_SQUARE,
            SHAPE_TRIANGLE,
            SHAPE_STAR,
            SHAPE_HEXAGON,
            SHAPE_DIAMOND
        ];
        
        /** Shape display names */
        public static const SHAPE_NAMES:Object = {
            circle: "Circle",
            square: "Square",
            triangle: "Triangle",
            star: "Star",
            hexagon: "Hexagon",
            diamond: "Diamond"
        };
        
        /** Shape unicode symbols for labels */
        public static const SHAPE_SYMBOLS:Object = {
            circle: "●",
            square: "■",
            triangle: "▲",
            star: "★",
            hexagon: "⬡",
            diamond: "◆"
        };
        
        // ============ COLORS (8 color-blind safe - Wong palette) ============
        // Based on Wong, B. (2011) "Color blindness" Nature Methods
        
        /** Blue - distinguishable by all */
        public static const COLOR_BLUE:uint = 0x0072B2;
        
        /** Orange - high contrast */
        public static const COLOR_ORANGE:uint = 0xE69F00;
        
        /** Sky Blue - light variant */
        public static const COLOR_SKY_BLUE:uint = 0x56B4E9;
        
        /** Bluish Green - distinct from blue */
        public static const COLOR_TEAL:uint = 0x009E73;
        
        /** Yellow - bright accent */
        public static const COLOR_YELLOW:uint = 0xF0E442;
        
        /** Vermillion - red-orange */
        public static const COLOR_VERMILLION:uint = 0xD55E00;
        
        /** Reddish Purple - magenta variant */
        public static const COLOR_PURPLE:uint = 0xCC79A7;
        
        /** Black - for contrast */
        public static const COLOR_BLACK:uint = 0x000000;
        
        /** All color-blind safe colors */
        public static const COLORS:Array = [
            COLOR_BLUE,
            COLOR_ORANGE,
            COLOR_SKY_BLUE,
            COLOR_TEAL,
            COLOR_YELLOW,
            COLOR_VERMILLION,
            COLOR_PURPLE,
            COLOR_BLACK
        ];
        
        /** Color names for display */
        public static const COLOR_NAMES:Object = {};
        
        // Initialize color names
        {
            COLOR_NAMES[COLOR_BLUE] = "Blue";
            COLOR_NAMES[COLOR_ORANGE] = "Orange";
            COLOR_NAMES[COLOR_SKY_BLUE] = "Sky Blue";
            COLOR_NAMES[COLOR_TEAL] = "Teal";
            COLOR_NAMES[COLOR_YELLOW] = "Yellow";
            COLOR_NAMES[COLOR_VERMILLION] = "Red";
            COLOR_NAMES[COLOR_PURPLE] = "Purple";
            COLOR_NAMES[COLOR_BLACK] = "Black";
        }
        
        // ============ NUMBER MODE (1-9) ============
        
        /** Numbers for number mode */
        public static const NUMBERS:Array = [1, 2, 3, 4, 5, 6, 7, 8, 9];
        
        // ============ LETTER MODE (A-F) ============
        
        /** Letters for letter mode */
        public static const LETTERS:Array = ["A", "B", "C", "D", "E", "F"];
        
        // ============ DISPLAY MODES ============
        
        public static const MODE_SHAPE:String = "shape";
        public static const MODE_COLOR:String = "color";
        public static const MODE_NUMBER:String = "number";
        public static const MODE_LETTER:String = "letter";
        public static const MODE_COMBINED:String = "combined"; // Shape + Color
        
        // ============ ANIMATION TIMINGS ============
        
        /** Fade in duration (ms) */
        public static const FADE_IN_DURATION:int = 200;
        
        /** Fade out duration (ms) */
        public static const FADE_OUT_DURATION:int = 150;
        
        /** Scale animation duration (ms) */
        public static const SCALE_DURATION:int = 250;
        
        /** Glow pulse duration (ms) */
        public static const GLOW_DURATION:int = 500;
        
        // ============ STIMULUS SIZES ============
        
        /** Base stimulus size (pixels at 1x scale) */
        public static const STIMULUS_SIZE:int = 80;
        
        /** Minimum size */
        public static const STIMULUS_MIN_SIZE:int = 40;
        
        /** Maximum size */
        public static const STIMULUS_MAX_SIZE:int = 120;
        
        // ============ GLOW EFFECTS ============
        
        /** Glow color for correct */
        public static const GLOW_CORRECT:uint = 0x4CAF50;
        
        /** Glow color for wrong */
        public static const GLOW_WRONG:uint = 0xF44336;
        
        /** Glow color for highlight */
        public static const GLOW_HIGHLIGHT:uint = 0xFFEB3B;
        
        /** Glow blur amount */
        public static const GLOW_BLUR:Number = 15;
        
        /** Glow strength */
        public static const GLOW_STRENGTH:Number = 2;
        
        // ============ HELPER METHODS ============
        
        /**
         * Get random shape
         */
        public static function getRandomShape():String {
            return SHAPES[Math.floor(Math.random() * SHAPES.length)];
        }
        
        /**
         * Get random color (color-blind safe)
         */
        public static function getRandomColor():uint {
            return COLORS[Math.floor(Math.random() * COLORS.length)];
        }
        
        /**
         * Get color name from hex value
         */
        public static function getColorName(color:uint):String {
            if (COLOR_NAMES.hasOwnProperty(color)) {
                return COLOR_NAMES[color];
            }
            return "#" + color.toString(16).toUpperCase();
        }
        
        /**
         * Get shape symbol (unicode)
         */
        public static function getShapeSymbol(shape:String):String {
            if (SHAPE_SYMBOLS.hasOwnProperty(shape)) {
                return SHAPE_SYMBOLS[shape];
            }
            return "?";
        }
        
        /**
         * Get shape by index (0-5)
         */
        public static function getShapeByIndex(index:int):String {
            if (index >= 0 && index < SHAPES.length) {
                return SHAPES[index];
            }
            return SHAPE_CIRCLE;
        }
        
        /**
         * Get color by index (0-7)
         */
        public static function getColorByIndex(index:int):uint {
            if (index >= 0 && index < COLORS.length) {
                return COLORS[index];
            }
            return COLOR_BLUE;
        }
        
        /**
         * Get shape index
         */
        public static function getShapeIndex(shape:String):int {
            return SHAPES.indexOf(shape);
        }
        
        /**
         * Get color index
         */
        public static function getColorIndex(color:uint):int {
            return COLORS.indexOf(color);
        }
        
        /**
         * Generate shape-color combination for button index
         */
        public static function getButtonVisuals(index:int):Object {
            return {
                shape: getShapeByIndex(index % SHAPES.length),
                color: getColorByIndex(index % COLORS.length)
            };
        }
        
        /**
         * Check if two colors have sufficient contrast (for backgrounds)
         * Simple luminance-based check
         */
        public static function hasContrast(color1:uint, color2:uint, minRatio:Number = 4.5):Boolean {
            var lum1:Number = getLuminance(color1);
            var lum2:Number = getLuminance(color2);
            
            var lighter:Number = Math.max(lum1, lum2);
            var darker:Number = Math.min(lum1, lum2);
            
            return (lighter + 0.05) / (darker + 0.05) >= minRatio;
        }
        
        /**
         * Calculate relative luminance of a color
         */
        private static function getLuminance(color:uint):Number {
            var r:Number = ((color >> 16) & 0xFF) / 255;
            var g:Number = ((color >> 8) & 0xFF) / 255;
            var b:Number = (color & 0xFF) / 255;
            
            r = (r <= 0.03928) ? r / 12.92 : Math.pow((r + 0.055) / 1.055, 2.4);
            g = (g <= 0.03928) ? g / 12.92 : Math.pow((g + 0.055) / 1.055, 2.4);
            b = (b <= 0.03928) ? b / 12.92 : Math.pow((b + 0.055) / 1.055, 2.4);
            
            return 0.2126 * r + 0.7152 * g + 0.0722 * b;
        }
        
        /**
         * Get contrasting text color for a background
         */
        public static function getContrastingTextColor(backgroundColor:uint):uint {
            var luminance:Number = getLuminance(backgroundColor);
            return (luminance > 0.5) ? 0x000000 : 0xFFFFFF;
        }
    }
}
