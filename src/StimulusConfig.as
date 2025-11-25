package {

    /**
     * StimulusConfig - Configuration constants for stimulus presentation timing and visuals.
     */
    public class StimulusConfig {

        // Timing constants (in milliseconds)
        public static const SHOW_DURATION:int = 1000;        // How long each stimulus is shown
        public static const INTER_STIMULUS_INTERVAL:int = 500; // Pause between stimuli
        public static const POST_SEQUENCE_PAUSE:int = 1000;   // Pause after sequence before input phase

        // Visual constants
        public static const STIMULUS_SIZE:int = 100;         // Size of stimulus symbols
        public static const CENTER_X:int = 400;              // Center X position (will be dynamic)
        public static const CENTER_Y:int = 300;              // Center Y position (will be dynamic)

        // Animation constants
        public static const FADE_IN_DURATION:int = 200;      // Fade in time
        public static const FADE_OUT_DURATION:int = 200;     // Fade out time

        // Debug overlay
        public static const SHOW_DEBUG_OVERLAY:Boolean = true; // Show index/total during playback
    }
}