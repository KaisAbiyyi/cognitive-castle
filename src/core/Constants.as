package core {
    
    /**
     * Constants - Central configuration constants for the entire game.
     * All magic numbers and configuration values should be defined here.
     * 
     * SOLID Principles:
     * - Single Responsibility: Only holds constant values
     * - Open/Closed: New constants can be added without modifying existing code
     */
    public class Constants {
        
        // ============ VERSION ============
        public static const VERSION:String = "1.0.0";
        public static const BUILD_NUMBER:int = 1;
        
        // ============ DEBUG FLAGS ============
        public static const DEBUG:Boolean = true;
        public static const SHOW_FPS:Boolean = true;
        public static const SHOW_MEMORY:Boolean = true;
        public static const VERBOSE_LOG:Boolean = true;
        
        // ============ TIMING - STIMULUS ============
        /** Default stimulus display duration (ms) */
        public static const STIMULUS_DURATION_DEFAULT:int = 1000;
        /** Minimum stimulus duration (ms) */
        public static const STIMULUS_DURATION_MIN:int = 600;
        /** Maximum stimulus duration (ms) */
        public static const STIMULUS_DURATION_MAX:int = 1500;
        /** Inter-stimulus interval default (ms) */
        public static const ISI_DEFAULT:int = 500;
        /** Inter-stimulus interval min (ms) */
        public static const ISI_MIN:int = 300;
        /** Inter-stimulus interval max (ms) */
        public static const ISI_MAX:int = 800;
        
        // ============ TIMING - INPUT ============
        /** Default input timeout (ms) */
        public static const INPUT_TIMEOUT_DEFAULT:int = 10000;
        /** Minimum input timeout (ms) */
        public static const INPUT_TIMEOUT_MIN:int = 5000;
        /** Maximum input timeout (ms) */
        public static const INPUT_TIMEOUT_MAX:int = 30000;
        /** Input timeout per item (ms) - added per sequence item */
        public static const INPUT_TIMEOUT_PER_ITEM:int = 2000;
        
        // ============ TIMING - UI ============
        /** Result display time (ms) */
        public static const RESULT_DISPLAY_TIME:int = 2500;
        /** Transition animation duration (ms) */
        public static const TRANSITION_DURATION:int = 300;
        /** Button press feedback duration (ms) */
        public static const BUTTON_FEEDBACK_DURATION:int = 100;
        
        // ============ SEQUENCE ============
        /** Minimum sequence length */
        public static const SEQUENCE_LENGTH_MIN:int = 3;
        /** Maximum sequence length */
        public static const SEQUENCE_LENGTH_MAX:int = 12;
        /** Default starting sequence length */
        public static const SEQUENCE_LENGTH_START:int = 3;
        /** Number of stimulus types (shapes/colors) */
        public static const STIMULUS_TYPES_COUNT:int = 6;
        
        // ============ DIFFICULTY ============
        /** Total number of difficulty levels */
        public static const DIFFICULTY_LEVELS:int = 15;
        /** Starting difficulty level */
        public static const DIFFICULTY_START:int = 1;
        /** Accuracy threshold to level up (%) */
        public static const LEVEL_UP_THRESHOLD:Number = 0.85;
        /** Accuracy threshold to level down (%) */
        public static const LEVEL_DOWN_THRESHOLD:Number = 0.60;
        /** Rolling window size for accuracy calculation */
        public static const ROLLING_WINDOW_SIZE:int = 5;
        /** Consecutive correct to level up */
        public static const CONSECUTIVE_CORRECT_TO_UP:int = 2;
        /** Consecutive incorrect to level down */
        public static const CONSECUTIVE_INCORRECT_TO_DOWN:int = 2;
        
        // ============ SCORING ============
        /** Base score per correct answer */
        public static const SCORE_BASE:int = 10;
        /** Bonus per difficulty level */
        public static const SCORE_DIFFICULTY_BONUS:int = 5;
        /** Streak bonus at 3 */
        public static const STREAK_BONUS_3:int = 5;
        /** Streak bonus at 5 */
        public static const STREAK_BONUS_5:int = 15;
        /** Streak bonus at 10 */
        public static const STREAK_BONUS_10:int = 50;
        /** Partial credit multiplier (0-1) */
        public static const PARTIAL_CREDIT_MULTIPLIER:Number = 0.5;
        
        // ============ VISUAL ============
        /** Default font */
        public static const FONT_DEFAULT:String = "Arial";
        /** Button size (px) */
        public static const BUTTON_SIZE:int = 80;
        /** Button spacing (px) */
        public static const BUTTON_SPACING:int = 15;
        /** Button corner radius (px) */
        public static const BUTTON_CORNER_RADIUS:int = 8;
        
        // ============ COLORS ============
        /** Primary background color */
        public static const COLOR_BG_PRIMARY:uint = 0x1a1a2e;
        /** Secondary background color */
        public static const COLOR_BG_SECONDARY:uint = 0x16213e;
        /** Accent color */
        public static const COLOR_ACCENT:uint = 0x0f3460;
        /** Highlight color */
        public static const COLOR_HIGHLIGHT:uint = 0xe94560;
        /** Text primary color */
        public static const COLOR_TEXT_PRIMARY:uint = 0xFFFFFF;
        /** Text secondary color */
        public static const COLOR_TEXT_SECONDARY:uint = 0xCCCCCC;
        /** Success color */
        public static const COLOR_SUCCESS:uint = 0x4CAF50;
        /** Error color */
        public static const COLOR_ERROR:uint = 0xF44336;
        /** Warning color */
        public static const COLOR_WARNING:uint = 0xFF9800;
        
        // ============ STIMULUS COLORS (Color-blind safe) ============
        public static const STIMULUS_COLORS:Array = [
            0x2196F3,  // Blue
            0xF44336,  // Red
            0x4CAF50,  // Green
            0xFFEB3B,  // Yellow
            0x9C27B0,  // Purple
            0xFF9800,  // Orange
            0x00BCD4,  // Cyan
            0xE91E63   // Pink
        ];
        
        // ============ STIMULUS SHAPES ============
        public static const STIMULUS_SHAPES:Array = [
            "circle",
            "square",
            "triangle",
            "star",
            "hexagon",
            "diamond"
        ];
        
        // ============ GAME MODES ============
        public static const MODE_FORWARD:String = "forward";
        public static const MODE_REVERSE:String = "reverse";
        public static const MODE_SORTED:String = "sorted";
        
        // ============ FSM STATES ============
        public static const STATE_MENU:String = "menu";
        public static const STATE_IDLE:String = "idle";
        public static const STATE_READY:String = "ready";
        public static const STATE_STIMULUS:String = "stimulus";
        public static const STATE_DELAY:String = "delay";
        public static const STATE_INPUT:String = "input";
        public static const STATE_VALIDATING:String = "validating";
        public static const STATE_RESULT:String = "result";
        public static const STATE_CASTLE_UPDATE:String = "castle_update";
        public static const STATE_TRANSITION:String = "transition";
        public static const STATE_PAUSED:String = "paused";
        public static const STATE_SESSION_END:String = "session_end";
        
        // ============ SAVE DATA ============
        /** Save data key */
        public static const SAVE_KEY:String = "cognitive_castle_save";
        /** Auto-save interval (trials) */
        public static const AUTO_SAVE_INTERVAL:int = 5;
        /** Maximum backup saves */
        public static const MAX_BACKUP_SAVES:int = 3;
        
        // ============ CASTLE ============
        /** Score threshold for foundation */
        public static const CASTLE_THRESHOLD_FOUNDATION:int = 10;
        /** Score threshold for walls */
        public static const CASTLE_THRESHOLD_WALLS:int = 30;
        /** Score threshold for first tower */
        public static const CASTLE_THRESHOLD_TOWER_1:int = 60;
        /** Score threshold for decorations */
        public static const CASTLE_THRESHOLD_DECORATIONS:int = 100;
        /** Score threshold for tier 2 upgrade */
        public static const CASTLE_THRESHOLD_TIER_2:int = 150;
        /** Score threshold for keep */
        public static const CASTLE_THRESHOLD_KEEP:int = 200;
        
        // ============ PERFORMANCE ============
        /** Target FPS */
        public static const TARGET_FPS:int = 60;
        /** Memory warning threshold (MB) */
        public static const MEMORY_WARNING_MB:int = 100;
        /** Memory critical threshold (MB) */
        public static const MEMORY_CRITICAL_MB:int = 150;
    }
}
