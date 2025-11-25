package {

    /**
     * SequenceConfig - Defines the difficulty tiers, symbol pools, and color variations for sequence generation.
     * This class provides static constants for the sequence challenge mechanics.
     */
    public class SequenceConfig {

        // Base symbol pool - geometric shapes for visual stimuli
        public static const SYMBOL_POOL:Array = [
            "circle",
            "square",
            "triangle",
            "star",
            "diamond",
            "hexagon"
        ];

        // Color pool - distinct colors for visual differentiation (colorblind-friendly)
        public static const COLORS:Array = [
            0xFF0000, // Red
            0x00FF00, // Green
            0x0000FF, // Blue
            0xFFFF00, // Yellow
            0xFF00FF, // Magenta
            0x00FFFF  // Cyan
        ];

        // Difficulty tiers with progressive complexity
        // Each tier defines: level, min/max sequence length, available symbols, available colors
        public static const DIFFICULTY_TIERS:Array = [
            // Tier 1: Beginner - Short sequences, limited symbols/colors
            {
                level: 1,
                minLength: 2,
                maxLength: 3,
                symbols: 2,  // Use first 2 symbols from pool
                colors: 2    // Use first 2 colors from pool
            },
            // Tier 2: Easy - Slightly longer, more variety
            {
                level: 2,
                minLength: 3,
                maxLength: 4,
                symbols: 3,
                colors: 3
            },
            // Tier 3: Medium - Moderate complexity
            {
                level: 3,
                minLength: 4,
                maxLength: 5,
                symbols: 4,
                colors: 4
            },
            // Tier 4: Hard - Longer sequences, full variety
            {
                level: 4,
                minLength: 5,
                maxLength: 6,
                symbols: 6,
                colors: 6
            },
            // Tier 5: Expert - Maximum challenge
            {
                level: 5,
                minLength: 6,
                maxLength: 7,
                symbols: 6,
                colors: 6
            }
        ];

        // Length curve progression - how sequence length increases with performance
        public static const LENGTH_PROGRESSION:Object = {
            baseLength: 2,           // Starting length
            incrementThreshold: 3,   // Correct trials needed to increase length
            maxLength: 9,            // Maximum sequence length
            decrementOnFailure: 1    // Length reduction on failure
        };

        // Color variation rules
        public static const COLOR_VARIATION:Object = {
            ensureDistinct: true,    // Ensure no two consecutive items have same color
            allowRepeats: false,     // Allow color repeats within sequence (set to false for now)
            minContrast: 0.3         // Minimum color contrast ratio (for accessibility)
        };

        // Symbol variation rules
        public static const SYMBOL_VARIATION:Object = {
            ensureDistinct: true,    // Ensure no three consecutive identical symbols
            allowRepeats: true,      // Allow symbol repeats within sequence
            maxConsecutive: 2        // Maximum consecutive identical symbols
        };

    }
}