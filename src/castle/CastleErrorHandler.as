package castle {
    
    /**
     * CastleErrorHandler - Centralized error handling for castle system.
     * Provides validation, recovery, and error logging.
     * 
     * T1-056: Castle system error handling
     */
    public class CastleErrorHandler {
        
        // Debug flag
        private static const DEBUG:Boolean = true;
        
        // Error codes
        public static const ERR_INVALID_PART_TYPE:int = 1001;
        public static const ERR_INVALID_TIER:int = 1002;
        public static const ERR_INVALID_POSITION:int = 1003;
        public static const ERR_PART_NOT_FOUND:int = 1004;
        public static const ERR_PART_DESTROYED:int = 1005;
        public static const ERR_CANNOT_UPGRADE:int = 1006;
        public static const ERR_INVALID_STATE:int = 1007;
        public static const ERR_SERIALIZATION:int = 1008;
        public static const ERR_DESERIALIZATION:int = 1009;
        public static const ERR_GRID_OCCUPIED:int = 1010;
        public static const ERR_OUT_OF_BOUNDS:int = 1011;
        
        // Error log
        private static var _errorLog:Vector.<Object> = new Vector.<Object>();
        private static var _maxLogSize:int = 100;
        
        // Error callbacks
        private static var _onError:Function = null;
        
        /**
         * Set error callback
         */
        public static function setErrorCallback(callback:Function):void {
            _onError = callback;
        }
        
        /**
         * Log an error
         */
        public static function logError(code:int, message:String, context:Object = null):void {
            var error:Object = {
                code: code,
                message: message,
                context: context,
                timestamp: new Date().getTime()
            };
            
            _errorLog.push(error);
            
            // Trim log if too large
            if (_errorLog.length > _maxLogSize) {
                _errorLog.shift();
            }
            
            if (DEBUG) {
                trace("[CastleError " + code + "] " + message);
                if (context) {
                    trace("  Context: " + JSON.stringify(context));
                }
            }
            
            // Call callback if set
            if (_onError != null) {
                _onError(error);
            }
        }
        
        /**
         * Validate part type
         */
        public static function validatePartType(type:String):Boolean {
            var validTypes:Array = [
                CastlePart.TYPE_FOUNDATION,
                CastlePart.TYPE_WALL,
                CastlePart.TYPE_TOWER,
                CastlePart.TYPE_DECORATION,
                CastlePart.TYPE_KEEP,
                CastlePart.TYPE_SPECIAL
            ];
            
            if (validTypes.indexOf(type) == -1) {
                logError(ERR_INVALID_PART_TYPE, "Invalid part type: " + type, { type: type });
                return false;
            }
            return true;
        }
        
        /**
         * Validate tier level
         */
        public static function validateTier(tier:int):Boolean {
            if (tier < 1 || tier > 5) {
                logError(ERR_INVALID_TIER, "Tier must be 1-5, got: " + tier, { tier: tier });
                return false;
            }
            return true;
        }
        
        /**
         * Validate grid position
         */
        public static function validatePosition(gridX:int, gridY:int):Boolean {
            if (gridX < 0 || gridX >= CastleConfig.GRID_WIDTH ||
                gridY < 0 || gridY >= CastleConfig.GRID_HEIGHT) {
                logError(ERR_OUT_OF_BOUNDS, 
                    "Position out of bounds: (" + gridX + ", " + gridY + ")",
                    { gridX: gridX, gridY: gridY });
                return false;
            }
            return true;
        }
        
        /**
         * Validate part state
         */
        public static function validatePartState(state:String):Boolean {
            var validStates:Array = [
                CastlePart.STATE_BUILDING,
                CastlePart.STATE_HEALTHY,
                CastlePart.STATE_DAMAGED,
                CastlePart.STATE_DESTROYED
            ];
            
            if (validStates.indexOf(state) == -1) {
                logError(ERR_INVALID_STATE, "Invalid part state: " + state, { state: state });
                return false;
            }
            return true;
        }
        
        /**
         * Validate CastlePart object
         */
        public static function validatePart(part:CastlePart):Boolean {
            if (part == null) {
                logError(ERR_PART_NOT_FOUND, "Part is null");
                return false;
            }
            
            return validatePartType(part.type) &&
                   validateTier(part.tier) &&
                   validatePosition(part.gridX, part.gridY) &&
                   validatePartState(part.state);
        }
        
        /**
         * Validate serialized castle state object
         */
        public static function validateSerializedState(obj:Object):Boolean {
            if (obj == null) {
                logError(ERR_DESERIALIZATION, "Serialized state is null");
                return false;
            }
            
            // Check required fields
            var requiredFields:Array = ["parts", "totalScore"];
            for each (var field:String in requiredFields) {
                if (!obj.hasOwnProperty(field)) {
                    logError(ERR_DESERIALIZATION, "Missing field: " + field, { object: obj });
                    return false;
                }
            }
            
            // Validate parts array
            if (!(obj.parts is Array)) {
                logError(ERR_DESERIALIZATION, "Parts must be an array");
                return false;
            }
            
            return true;
        }
        
        /**
         * Try to recover from corrupted state
         */
        public static function recoverState(corruptedState:Object):CastleState {
            if (DEBUG) {
                trace("[CastleErrorHandler] Attempting state recovery...");
            }
            
            var recovered:CastleState = new CastleState();
            
            try {
                // Try to salvage parts
                if (corruptedState && corruptedState.parts is Array) {
                    for each (var partObj:Object in corruptedState.parts) {
                        try {
                            var part:CastlePart = CastlePart.fromObject(partObj);
                            if (validatePart(part)) {
                                recovered.parts.push(part);
                            }
                        } catch (e:Error) {
                            logError(ERR_DESERIALIZATION, "Failed to recover part: " + e.message);
                        }
                    }
                }
                
                // Try to salvage score
                if (corruptedState && corruptedState.totalScore is Number) {
                    recovered.totalScore = int(corruptedState.totalScore);
                } else {
                    // Recalculate from parts
                    recovered.totalScore = recovered.calculateTotalScore();
                }
                
                if (DEBUG) {
                    trace("[CastleErrorHandler] Recovered " + recovered.parts.length + " parts");
                }
                
            } catch (e:Error) {
                logError(ERR_DESERIALIZATION, "Recovery failed: " + e.message);
                // Return empty state as fallback
                recovered = new CastleState();
            }
            
            return recovered;
        }
        
        /**
         * Get error log
         */
        public static function getErrorLog():Vector.<Object> {
            return _errorLog.concat(); // Return copy
        }
        
        /**
         * Get last error
         */
        public static function getLastError():Object {
            if (_errorLog.length > 0) {
                return _errorLog[_errorLog.length - 1];
            }
            return null;
        }
        
        /**
         * Clear error log
         */
        public static function clearLog():void {
            _errorLog.length = 0;
        }
        
        /**
         * Get error message for code
         */
        public static function getErrorMessage(code:int):String {
            switch (code) {
                case ERR_INVALID_PART_TYPE: return "Invalid part type";
                case ERR_INVALID_TIER: return "Invalid tier level";
                case ERR_INVALID_POSITION: return "Invalid grid position";
                case ERR_PART_NOT_FOUND: return "Part not found";
                case ERR_PART_DESTROYED: return "Part is destroyed";
                case ERR_CANNOT_UPGRADE: return "Cannot upgrade part";
                case ERR_INVALID_STATE: return "Invalid part state";
                case ERR_SERIALIZATION: return "Serialization error";
                case ERR_DESERIALIZATION: return "Deserialization error";
                case ERR_GRID_OCCUPIED: return "Grid position occupied";
                case ERR_OUT_OF_BOUNDS: return "Position out of bounds";
                default: return "Unknown error";
            }
        }
        
        /**
         * Get formatted error report
         */
        public static function getErrorReport():String {
            var lines:Array = ["=== CASTLE ERROR REPORT ==="];
            lines.push("Total errors: " + _errorLog.length);
            lines.push("");
            
            for (var i:int = Math.max(0, _errorLog.length - 10); i < _errorLog.length; i++) {
                var err:Object = _errorLog[i];
                lines.push("[" + err.code + "] " + err.message);
            }
            
            return lines.join("\n");
        }
    }
}
