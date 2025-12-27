package services {
    
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import core.Constants;
    
    /**
     * SaveSystem - Handles game state persistence using a JSON file.
     * Includes save versioning, auto-save, backup, and basic anti-tamper protection.
     * 
     * SOLID Principles:
     * - Single Responsibility: Only handles save/load operations
     * - Open/Closed: Can add new save fields without modifying core logic
     */
    public class SaveSystem {
        
        private static var _instance:SaveSystem;
        
        private static const SAVE_FILENAME:String = "cognitive_castle_save.json";

        private var _autoSaveCounter:int = 0;
        private var _backupSaves:Array = [];
        private var _lastSavedSnapshot:Object = null;
        
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
            _currentData = new SaveData();
        }
        
        /**
         * Check if save data exists
         */
        public function hasExistingSave():Boolean {
            var saveFile:File = resolveSaveFileForRead();
            return saveFile != null && saveFile.exists;
        }
        
        /**
         * Load saved game state
         * @return True if load successful
         */
        public function loadState():Boolean {
            try {
                var saveFile:File = resolveSaveFileForRead();
                if (!saveFile || !saveFile.exists) {
                    trace("[SaveSystem] No save file found, using defaults");
                    _currentData = new SaveData();
                    return false;
                }
                
                var stream:FileStream = new FileStream();
                stream.open(saveFile, FileMode.READ);
                var raw:String = stream.readUTFBytes(stream.bytesAvailable);
                stream.close();
                
                if (!raw || raw.length == 0) {
                    trace("[SaveSystem] Save file empty, using defaults");
                    _currentData = new SaveData();
                    return false;
                }
                
                var data:Object = JSON.parse(raw);
                
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
                
                applyDataObject(data);
                
                trace("[SaveSystem] Save loaded successfully from: " + saveFile.nativePath);
                return true;
                
            } catch (e:Error) {
                trace("[SaveSystem] Error loading save: " + e.message);
                _currentData = new SaveData();
                return false;
            }
            
            return false;
        }
        
        /**
         * Save current game state
         * @return True if save successful
         */
        public function saveState():Boolean {
            try {
                // Create backup before saving
                if (_lastSavedSnapshot) {
                    createBackup(_lastSavedSnapshot);
                }
                
                // Update timestamp
                _currentData.lastPlayedAt = new Date().time;
                
                var data:Object = buildDataObject();
                
                // Calculate and store checksum
                data.checksum = calculateChecksum(data);
                
                var json:String = JSON.stringify(data);
                var saveFile:File = resolveSaveFileForWrite();
                var wrote:Boolean = writeToFile(saveFile, json);
                
                if (!wrote) {
                    var fallback:File = getFallbackSaveFile();
                    if (fallback.nativePath != saveFile.nativePath) {
                        wrote = writeToFile(fallback, json);
                        if (wrote) {
                            saveFile = fallback;
                        }
                    }
                }
                
                if (!wrote) {
                    trace("[SaveSystem] Error saving: unable to write save file");
                    return false;
                }
                
                _lastSavedSnapshot = data;
                
                trace("[SaveSystem] Save successful to: " + saveFile.nativePath);
                return true;
                
            } catch (e:Error) {
                trace("[SaveSystem] Error saving: " + e.message);
                return false;
            }
            
            return false;
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
            try {
                var primary:File = getPrimarySaveFile();
                if (primary && primary.exists) {
                    primary.deleteFile();
                }
            } catch (e:Error) {
                trace("[SaveSystem] Error deleting primary save: " + e.message);
            }
            
            try {
                var fallback:File = getFallbackSaveFile();
                if (fallback && fallback.exists) {
                    fallback.deleteFile();
                }
            } catch (e:Error) {
                trace("[SaveSystem] Error deleting fallback save: " + e.message);
            }
            _currentData = new SaveData();
            _backupSaves = [];
            _lastSavedSnapshot = null;
            trace("[SaveSystem] Save data deleted");
        }
        
        /**
         * Get current save data
         */
        public function get data():SaveData {
            return _currentData;
        }

        private function buildDataObject():Object {
            var data:Object = {};
            data.version = _currentData.version;
            data.userId = _currentData.userId;
            data.createdAt = _currentData.createdAt;
            data.lastPlayedAt = _currentData.lastPlayedAt;
            data.currentDifficulty = _currentData.currentDifficulty;
            data.currentMode = _currentData.currentMode;
            data.castleState = _currentData.castleState;
            data.castleScale = _currentData.castleScale;
            
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
            
            data.settings = {
                masterVolume: _currentData.settings.masterVolume,
                sfxVolume: _currentData.settings.sfxVolume,
                hapticEnabled: _currentData.settings.hapticEnabled,
                colorBlindMode: _currentData.settings.colorBlindMode
            };
            
            return data;
        }

        private function applyDataObject(data:Object):void {
            _currentData = new SaveData();
            _currentData.version = data.version || _currentData.version;
            _currentData.userId = data.userId || _currentData.userId;
            _currentData.createdAt = data.createdAt || _currentData.createdAt;
            _currentData.lastPlayedAt = data.lastPlayedAt || _currentData.lastPlayedAt;
            _currentData.currentDifficulty = data.currentDifficulty || 1;
            _currentData.currentMode = data.currentMode || Constants.MODE_FORWARD;
            _currentData.castleState = data.castleState || {};
            _currentData.castleScale = (data.castleScale !== undefined) ? Number(data.castleScale) : NaN;
            
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
            
            if (data.settings) {
                _currentData.settings.masterVolume = data.settings.masterVolume;
                _currentData.settings.sfxVolume = data.settings.sfxVolume;
                _currentData.settings.hapticEnabled = data.settings.hapticEnabled;
                _currentData.settings.colorBlindMode = data.settings.colorBlindMode;
            }
            
            _lastSavedSnapshot = data;
        }

        private function getPrimarySaveFile():File {
            return File.applicationDirectory.resolvePath(SAVE_FILENAME);
        }
        
        private function getFallbackSaveFile():File {
            return File.applicationStorageDirectory.resolvePath(SAVE_FILENAME);
        }
        
        private function resolveSaveFileForRead():File {
            var primary:File = getPrimarySaveFile();
            var fallback:File = getFallbackSaveFile();
            
            if (primary && primary.exists && fallback && fallback.exists) {
                var primaryDate:Date = primary.modificationDate;
                var fallbackDate:Date = fallback.modificationDate;
                if (fallbackDate && primaryDate && fallbackDate.time > primaryDate.time) {
                    return fallback;
                }
                return primary;
            }
            if (primary && primary.exists) return primary;
            if (fallback && fallback.exists) return fallback;
            
            return primary;
        }
        
        private function resolveSaveFileForWrite():File {
            return getPrimarySaveFile();
        }
        
        private function writeToFile(file:File, contents:String):Boolean {
            if (!file) return false;
            
            var stream:FileStream = new FileStream();
            try {
                stream.open(file, FileMode.WRITE);
                stream.writeUTFBytes(contents);
                stream.close();
                return true;
            } catch (e:Error) {
                try {
                    stream.close();
                } catch (closeError:Error) {
                }
                trace("[SaveSystem] Error writing save file: " + e.message);
                return false;
            }
            
            return false;
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
        private function createBackup(snapshot:Object):void {
            if (!snapshot) return;
            
            var backup:Object = cloneObject(snapshot);
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
                    applyDataObject(backup);
                    return true;
                }
            }
            
            return false;
        }
        
        private function cloneObject(obj:Object):Object {
            if (!obj) return {};
            return JSON.parse(JSON.stringify(obj));
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
