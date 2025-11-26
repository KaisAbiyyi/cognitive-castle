package services {
    
    /**
     * GameSettings - User preferences and game settings.
     */
    public class GameSettings {
        /** Master volume (0-1) */
        public var masterVolume:Number = 0.7;
        /** SFX volume (0-1) */
        public var sfxVolume:Number = 0.7;
        /** Music volume (0-1) */
        public var musicVolume:Number = 0.5;
        /** Vibration/haptics enabled */
        public var hapticEnabled:Boolean = true;
        /** Color blind mode */
        public var colorBlindMode:Boolean = false;
        /** Show tutorial hints */
        public var showHints:Boolean = true;
        /** Auto-advance level */
        public var autoAdvance:Boolean = true;
        /** Large text mode */
        public var largeText:Boolean = false;
        /** Animation speed (1=normal, 2=fast, 0.5=slow) */
        public var animationSpeed:Number = 1.0;
        /** Current recall mode (FORWARD, REVERSE, SORTED) */
        public var recallMode:String = "FORWARD";
        /** Custom castle theme */
        public var castleTheme:String = "DEFAULT";
        /** Language code */
        public var language:String = "en";
        /** Last session date */
        public var lastSessionDate:String = "";
        
        /**
         * Clone settings
         */
        public function clone():GameSettings {
            var s:GameSettings = new GameSettings();
            s.masterVolume = masterVolume;
            s.sfxVolume = sfxVolume;
            s.musicVolume = musicVolume;
            s.hapticEnabled = hapticEnabled;
            s.colorBlindMode = colorBlindMode;
            s.showHints = showHints;
            s.autoAdvance = autoAdvance;
            s.largeText = largeText;
            s.animationSpeed = animationSpeed;
            s.recallMode = recallMode;
            s.castleTheme = castleTheme;
            s.language = language;
            s.lastSessionDate = lastSessionDate;
            return s;
        }
    }
}
