package castle {
    
    import flash.utils.getTimer;
    import flash.system.System;
    
    /**
     * PerformanceProfiler - Performance monitoring for castle system.
     * Tracks FPS, memory usage, and operation timings.
     * 
     * T1-057: Performance profiling (60 FPS target)
     */
    public class PerformanceProfiler {
        
        // Debug flag
        private static const DEBUG:Boolean = true;
        
        // Target FPS
        public static const TARGET_FPS:int = 60;
        public static const FRAME_TIME_MS:Number = 1000 / TARGET_FPS; // ~16.67ms
        
        // Singleton instance
        private static var _instance:PerformanceProfiler;
        
        // FPS tracking
        private var _frameCount:int = 0;
        private var _lastFPSTime:int = 0;
        private var _currentFPS:Number = 0;
        private var _fpsHistory:Vector.<Number>;
        private var _fpsHistoryMax:int = 60;
        
        // Frame time tracking
        private var _frameStartTime:int = 0;
        private var _lastFrameTime:Number = 0;
        private var _frameTimeHistory:Vector.<Number>;
        
        // Memory tracking
        private var _lastMemory:Number = 0;
        private var _peakMemory:Number = 0;
        
        // Operation timing
        private var _operationTimings:Object;
        private var _activeOperations:Object;
        
        // Warnings
        private var _warnings:Vector.<String>;
        private var _maxWarnings:int = 50;
        
        /**
         * Get singleton instance
         */
        public static function getInstance():PerformanceProfiler {
            if (!_instance) {
                _instance = new PerformanceProfiler();
            }
            return _instance;
        }
        
        /**
         * Constructor
         */
        public function PerformanceProfiler() {
            _fpsHistory = new Vector.<Number>();
            _frameTimeHistory = new Vector.<Number>();
            _operationTimings = {};
            _activeOperations = {};
            _warnings = new Vector.<String>();
            _lastFPSTime = getTimer();
        }
        
        /**
         * Call at start of each frame
         */
        public function startFrame():void {
            _frameStartTime = getTimer();
        }
        
        /**
         * Call at end of each frame
         */
        public function endFrame():void {
            var now:int = getTimer();
            _lastFrameTime = now - _frameStartTime;
            _frameCount++;
            
            // Store frame time
            _frameTimeHistory.push(_lastFrameTime);
            if (_frameTimeHistory.length > _fpsHistoryMax) {
                _frameTimeHistory.shift();
            }
            
            // Check for slow frame
            if (_lastFrameTime > FRAME_TIME_MS * 1.5) {
                addWarning("Slow frame: " + _lastFrameTime.toFixed(2) + "ms (target: " + FRAME_TIME_MS.toFixed(2) + "ms)");
            }
            
            // Calculate FPS every second
            if (now - _lastFPSTime >= 1000) {
                _currentFPS = _frameCount * 1000 / (now - _lastFPSTime);
                _fpsHistory.push(_currentFPS);
                if (_fpsHistory.length > _fpsHistoryMax) {
                    _fpsHistory.shift();
                }
                
                _frameCount = 0;
                _lastFPSTime = now;
                
                // Update memory
                updateMemory();
                
                // Check FPS warning
                if (_currentFPS < TARGET_FPS * 0.9) {
                    addWarning("Low FPS: " + _currentFPS.toFixed(1) + " (target: " + TARGET_FPS + ")");
                }
            }
        }
        
        /**
         * Start timing an operation
         */
        public function startOperation(name:String):void {
            _activeOperations[name] = getTimer();
        }
        
        /**
         * End timing an operation
         */
        public function endOperation(name:String):void {
            if (!_activeOperations[name]) return;
            
            var elapsed:Number = getTimer() - _activeOperations[name];
            delete _activeOperations[name];
            
            // Store timing
            if (!_operationTimings[name]) {
                _operationTimings[name] = {
                    count: 0,
                    totalTime: 0,
                    minTime: Number.MAX_VALUE,
                    maxTime: 0
                };
            }
            
            var op:Object = _operationTimings[name];
            op.count++;
            op.totalTime += elapsed;
            op.minTime = Math.min(op.minTime, elapsed);
            op.maxTime = Math.max(op.maxTime, elapsed);
            
            // Check for slow operation
            if (elapsed > FRAME_TIME_MS / 2) {
                addWarning("Slow operation '" + name + "': " + elapsed.toFixed(2) + "ms");
            }
        }
        
        /**
         * Update memory tracking
         */
        private function updateMemory():void {
            _lastMemory = System.totalMemory / (1024 * 1024); // MB
            if (_lastMemory > _peakMemory) {
                _peakMemory = _lastMemory;
            }
        }
        
        /**
         * Add warning
         */
        private function addWarning(message:String):void {
            _warnings.push("[" + getTimer() + "ms] " + message);
            if (_warnings.length > _maxWarnings) {
                _warnings.shift();
            }
            
            if (DEBUG) {
                trace("[PERF WARNING] " + message);
            }
        }
        
        /**
         * Get current FPS
         */
        public function get currentFPS():Number {
            return _currentFPS;
        }
        
        /**
         * Get average FPS
         */
        public function get averageFPS():Number {
            if (_fpsHistory.length == 0) return 0;
            var sum:Number = 0;
            for each (var fps:Number in _fpsHistory) {
                sum += fps;
            }
            return sum / _fpsHistory.length;
        }
        
        /**
         * Get minimum FPS
         */
        public function get minFPS():Number {
            if (_fpsHistory.length == 0) return 0;
            var min:Number = Number.MAX_VALUE;
            for each (var fps:Number in _fpsHistory) {
                if (fps < min) min = fps;
            }
            return min;
        }
        
        /**
         * Get last frame time in ms
         */
        public function get lastFrameTime():Number {
            return _lastFrameTime;
        }
        
        /**
         * Get average frame time
         */
        public function get averageFrameTime():Number {
            if (_frameTimeHistory.length == 0) return 0;
            var sum:Number = 0;
            for each (var t:Number in _frameTimeHistory) {
                sum += t;
            }
            return sum / _frameTimeHistory.length;
        }
        
        /**
         * Get current memory usage in MB
         */
        public function get memoryUsage():Number {
            return _lastMemory;
        }
        
        /**
         * Get peak memory usage in MB
         */
        public function get peakMemoryUsage():Number {
            return _peakMemory;
        }
        
        /**
         * Check if performance is acceptable
         */
        public function get isPerformanceOK():Boolean {
            return _currentFPS >= TARGET_FPS * 0.9;
        }
        
        /**
         * Get operation stats
         */
        public function getOperationStats(name:String):Object {
            if (!_operationTimings[name]) return null;
            var op:Object = _operationTimings[name];
            return {
                count: op.count,
                totalTime: op.totalTime,
                avgTime: op.count > 0 ? op.totalTime / op.count : 0,
                minTime: op.minTime,
                maxTime: op.maxTime
            };
        }
        
        /**
         * Get all operation names
         */
        public function getOperationNames():Array {
            var names:Array = [];
            for (var name:String in _operationTimings) {
                names.push(name);
            }
            return names;
        }
        
        /**
         * Get warnings
         */
        public function getWarnings():Vector.<String> {
            return _warnings.concat();
        }
        
        /**
         * Get formatted report
         */
        public function getReport():String {
            var lines:Array = [
                "=== PERFORMANCE REPORT ===",
                "FPS: " + _currentFPS.toFixed(1) + " (avg: " + averageFPS.toFixed(1) + ", min: " + minFPS.toFixed(1) + ")",
                "Frame Time: " + _lastFrameTime.toFixed(2) + "ms (avg: " + averageFrameTime.toFixed(2) + "ms)",
                "Memory: " + _lastMemory.toFixed(2) + " MB (peak: " + _peakMemory.toFixed(2) + " MB)",
                "Status: " + (isPerformanceOK ? "OK" : "DEGRADED"),
                ""
            ];
            
            // Add operation stats
            var opNames:Array = getOperationNames();
            if (opNames.length > 0) {
                lines.push("=== OPERATIONS ===");
                for each (var name:String in opNames) {
                    var stats:Object = getOperationStats(name);
                    lines.push(name + ": " + stats.count + " calls, avg " + stats.avgTime.toFixed(2) + "ms");
                }
                lines.push("");
            }
            
            // Add recent warnings
            if (_warnings.length > 0) {
                lines.push("=== RECENT WARNINGS (" + _warnings.length + ") ===");
                var recentCount:int = Math.min(5, _warnings.length);
                for (var i:int = _warnings.length - recentCount; i < _warnings.length; i++) {
                    lines.push(_warnings[i]);
                }
            }
            
            return lines.join("\n");
        }
        
        /**
         * Get short summary for HUD
         */
        public function getHUDSummary():Object {
            return {
                fps: _currentFPS,
                frameTime: _lastFrameTime,
                memory: _lastMemory,
                isOK: isPerformanceOK
            };
        }
        
        /**
         * Reset all stats
         */
        public function reset():void {
            _fpsHistory.length = 0;
            _frameTimeHistory.length = 0;
            _operationTimings = {};
            _warnings.length = 0;
            _peakMemory = 0;
            _frameCount = 0;
            _lastFPSTime = getTimer();
        }
    }
}
