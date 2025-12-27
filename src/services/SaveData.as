package services {
    
    import core.Constants;
    
    /**
     * SaveData - Data structure for save state.
     * Contains all persistent game data.
     */
    public class SaveData {
        public var version:String = "1.0.0";
        public var userId:String;
        public var createdAt:Number;
        public var lastPlayedAt:Number;
        public var currentDifficulty:int = 1;
        public var currentMode:String = "forward";
        public var metrics:GameMetrics;
        public var castleState:Object = {};
        public var castleScale:Number = 1.0;
        public var settings:GameSettings;
        
        public function SaveData() {
            userId = generateUserId();
            createdAt = new Date().time;
            lastPlayedAt = createdAt;
            metrics = new GameMetrics();
            settings = new GameSettings();
        }
        
        private function generateUserId():String {
            return "user_" + new Date().time.toString(36) + "_" + Math.floor(Math.random() * 10000).toString(36);
        }
    }
}
