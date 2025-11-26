package services {
    
    import flash.net.SharedObject;
    import flash.utils.ByteArray;
    import core.Constants;
    
    /**
     * SaveSystem - Handles game state persistence using SharedObject.
     * Includes save versioning, auto-save, backup, and basic anti-tamper protection.
     * 
     * SOLID Principles:
     * - Single Responsibility: Only handles save/load operations
     * - Open/Closed: Can add new save fields without modifying core logic
     */
    public class SaveSystem {
        
        private static var _instance:SaveSystem;
        
        private var _sharedObject:SharedObject;
        private var _autoSaveCounter:int = 0;
        private var _backupSaves:Array = [];
        
        // Current save data in memory
        private var _currentData:SaveData;
        
        /**
         * Get singleton instance
         */
        public static function getInstance():SaveSystem {
            if (!_instance) {
                _instance = new SaveSystem();
            }
            return _instance;
        }
        
        /**
         * Constructor
         */
        public function SaveSystem() {
            try {
                _sharedObject = SharedObject.getLocal(Constants.SAVE_KEY);
            } catch (e:Error) {
                trace("[SaveSystem] Error accessing SharedObject: " + e.message);
                _sharedObject = null;
            }
            
            _currentData = new SaveData();
        }
        
        /**
         * Check if save data exists
         */
        public function hasExistingSave():Boolean {
            return _sharedObject && _sharedObject.data && _sharedObject.data.version;
        }
        
        /**
         * Load saved game state
         * @return True if load successful
         */
        public function loadState():Boolean {
            if (!_sharedObject || !_sharedObject.data || !_sharedObject.data.version) {
                trace("[SaveSystem] No save data found, using defaults");
                _currentData = new SaveData();
                return false;
            }
            
            try {
                var data:Object = _sharedObject.data;
                
                // Validate checksum
                var storedChecksum:String = data.checksum;
                var calculatedChecksum:String = calculateChecksum(data);
                
                if (storedChecksum != calculatedChecksum) {
                    trace("[SaveSystem] Checksum mismatch - possible tampering");
                    // Try to load from backup
                    if (!loadFromBackup()) {
                        _currentData = new SaveData();
                        return false;
                    }
                }
                
                // Load data into SaveData object
                _currentData = new SaveData();
                _currentData.version = data.version;
                _currentData.userId = data.userId;
                _currentData.createdAt = data.createdAt;
                _currentData.lastPlayedAt = data.lastPlayedAt;
                _currentData.currentDifficulty = data.currentDifficulty || 1;
                _currentData.currentMode = data.currentMode || Constants.MODE_FORWARD;
                
                // Load metrics
                if (data.metrics) {
                    _currentData.metrics.totalTrials = data.metrics.totalTrials || 0;
                    _currentData.metrics.correctTrials = data.metrics.correctTrials || 0;
                    _currentData.metrics.highestStreak = data.metrics.highestStreak || 0;
                    _currentData.metrics.currentStreak = data.metrics.currentStreak || 0;
                    _currentData.metrics.totalPlayTime = data.metrics.totalPlayTime || 0;
                    _currentData.metrics.sessionsPlayed = data.metrics.sessionsPlayed || 0;
                    _currentData.metrics.castleScore = data.metrics.castleScore || 0;
                    _currentData.metrics.highestDifficulty = data.metrics.highestDifficulty || 1;
                }
                
                // Load castle state
                if (data.castleState) {
                    _currentData.castleState = data.castleState;
                }
                
                // Load settings
                if (data.settings) {
                    _currentData.settings.masterVolume = data.settings.masterVolume;
                    _currentData.settings.sfxVolume = data.settings.sfxVolume;
                    _currentData.settings.hapticEnabled = data.settings.hapticEnabled;
                    _currentData.settings.colorBlindMode = data.settings.colorBlindMode;
                }
                
                trace("[SaveSystem] Save loaded successfully, version: " + _currentData.version);
                return true;
                
            } catch (e:Error) {
                trace("[SaveSystem] Error loading save: " + e.message);
                _currentData = new SaveData();
                return false;
            }
        }
        
        /**
         * Save current game state
         * @return True if save successful
         */
        public function saveState():Boolean {
            if (!_sharedObject) {
                trace("[SaveSystem] SharedObject not available");
                return false;
            }
            
            try {
                // Create backup before saving
                createBackup();
                
                // Update timestamp
                _currentData.lastPlayedAt = new Date().time;
                
                // Copy data to SharedObject
                var data:Object = _sharedObject.data;
                data.version = _currentData.version;
                data.userId = _currentData.userId;
                data.createdAt = _currentData.createdAt;
                data.lastPlayedAt = _currentData.lastPlayedAt;
                data.currentDifficulty = _currentData.currentDifficulty;
                data.currentMode = _currentData.currentMode;
                
                // Save metrics
                data.metrics = {
                    totalTrials: _currentData.metrics.totalTrials,
                    correctTrials: _currentData.metrics.correctTrials,
                    highestStreak: _currentData.metrics.highestStreak,
                    currentStreak: _currentData.metrics.currentStreak,
                    totalPlayTime: _currentData.metrics.totalPlayTime,
                    sessionsPlayed: _currentData.metrics.sessionsPlayed,
                    castleScore: _currentData.metrics.castleScore,
                    highestDifficulty: _currentData.metrics.highestDifficulty
                };
                
                // Save castle state
                data.castleState = _currentData.castleState;
                
                // Save settings
                data.settings = {
                    masterVolume: _currentData.settings.masterVolume,
                    sfxVolume: _currentData.settings.sfxVolume,
                    hapticEnabled: _currentData.settings.hapticEnabled,
                    colorBlindMode: _currentData.settings.colorBlindMode
                };
                
                // Calculate and store checksum
                data.checksum = calculateChecksum(data);
                
                // Flush to disk
                _sharedObject.flush();
                
                trace("[SaveSystem] Save successful");
                return true;
                
            } catch (e:Error) {
                trace("[SaveSystem] Error saving: " + e.message);
                return false;
            }
        }
        
        /**
         * Increment auto-save counter and save if threshold reached
         */
        public function checkAutoSave():void {
            _autoSaveCounter++;
            if (_autoSaveCounter >= Constants.AUTO_SAVE_INTERVAL) {
                saveState();
                _autoSaveCounter = 0;
            }
        }
        
        /**
         * Delete all save data
         */
        public function deleteSave():void {
            if (_sharedObject) {
                _sharedObject.clear();
            }
            _currentData = new SaveData();
            _backupSaves = [];
            trace("[SaveSystem] Save data deleted");
        }
        
        /**
         * Get current save data
         */
        public function get data():SaveData {
            return _currentData;
        }
        
        /**
         * Calculate checksum for anti-tamper
         */
        private function calculateChecksum(data:Object):String {
            // Simple checksum based on critical values
            var str:String = "";
            str += String(data.currentDifficulty || 0);
            if (data.metrics) {
                str += String(data.metrics.totalTrials || 0);
                str += String(data.metrics.correctTrials || 0);
                str += String(data.metrics.castleScore || 0);
            }
            str += Constants.SAVE_KEY; // Salt
            
            // Simple hash
            var hash:int = 0;
            for (var i:int = 0; i < str.length; i++) {
                hash = ((hash << 5) - hash) + str.charCodeAt(i);
                hash = hash & hash; // Convert to 32bit integer
            }
            
            return hash.toString(16);
        }
        
        /**
         * Create backup of current save
         */
        private function createBackup():void {
            if (!_sharedObject || !_sharedObject.data.version) return;
            
            // Clone current data
            var backup:Object = {};
            for (var key:String in _sharedObject.data) {
                backup[key] = _sharedObject.data[key];
            }
            
            _backupSaves.push(backup);
            
            // Keep only last N backups
            while (_backupSaves.length > Constants.MAX_BACKUP_SAVES) {
                _backupSaves.shift();
            }
        }
        
        /**
         * Try to load from backup
         */
        private function loadFromBackup():Boolean {
            if (_backupSaves.length == 0) return false;
            
            // Try backups from newest to oldest
            for (var i:int = _backupSaves.length - 1; i >= 0; i--) {
                var backup:Object = _backupSaves[i];
                var checksum:String = calculateChecksum(backup);
                
                if (checksum == backup.checksum) {
                    trace("[SaveSystem] Restored from backup " + i);
                    // Copy backup to current
                    for (var key:String in backup) {
                        _sharedObject.data[key] = backup[key];
                    }
                    return true;
                }
            }
            
            return false;
        }
        
        /**
         * Export save as Base64 string
         */
        public function exportSave():String {
            // TODO: Implement JSON export with Base64 encoding
            return "";
        }
        
        /**
         * Import save from Base64 string
         */
        public function importSave(data:String):Boolean {
            // TODO: Implement JSON import from Base64
            return false;
        }
    }
}

/**
 * SaveData - Data structure for save state
 */
class SaveData {
    public var version:String = "1.0.0";
    public var userId:String;
    public var createdAt:Number;
    public var lastPlayedAt:Number;
    public var currentDifficulty:int = 1;
    public var currentMode:String = "forward";
    public var metrics:GameMetrics;
    public var castleState:Object = {};
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

class GameMetrics {
    public var totalTrials:int = 0;
    public var correctTrials:int = 0;
    public var highestStreak:int = 0;
    public var currentStreak:int = 0;
    public var totalPlayTime:Number = 0;
    public var sessionsPlayed:int = 0;
    public var castleScore:int = 0;
    public var highestDifficulty:int = 1;
    public var averageReactionTime:Number = 0;
    public var bestReactionTime:Number = 0;
    public var partsBuilt:int = 0;
    public var partsUpgraded:int = 0;
}

class GameSettings {
    public var masterVolume:Number = 1.0;
    public var sfxVolume:Number = 1.0;
    public var hapticEnabled:Boolean = true;
    public var colorBlindMode:String = "none";
}
