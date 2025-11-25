package config {

    /**
     * StimulusConfig - Configuration constants for stimulus presentation timing and visuals.
     *
     * SOLID Principles:
     * - Single Responsibility: Only provides configuration data
     * - Open/Closed: Can be extended with new configurations without changing existing code
     * - Interface Segregation: Provides only configuration-related constants
     */
    public class StimulusConfig {

        // Timing constants (in milliseconds)
        public static const SHOW_DURATION:int = 800;         // How long each stimulus is shown (800ms per PRD)
        public static const INTER_STIMULUS_INTERVAL:int = 500; // Pause between stimuli
        public static const POST_SEQUENCE_PAUSE:int = 1000;   // Pause after sequence before input phase

        // Dynamic visual constants (will be set based on stage size)
        private static var _centerX:int = 400;
        private static var _centerY:int = 300;
        private static var _stimulusSize:int = 100;

        // Debug overlay
        public static const SHOW_DEBUG_OVERLAY:Boolean = true; // Show index/total during playback

        /**
         * Update constants based on stage dimensions
         * @param stageWidth Stage width
         * @param stageHeight Stage height
         */
        public static function updateForStageSize(stageWidth:int, stageHeight:int):void {
            _centerX = stageWidth / 2;
            _centerY = stageHeight / 2;
            _stimulusSize = Math.min(stageWidth, stageHeight) / 8; // Adaptive size
        }

        public static function get CENTER_X():int { return _centerX; }
        public static function get CENTER_Y():int { return _centerY; }
        public static function get STIMULUS_SIZE():int { return _stimulusSize; }
    }
}