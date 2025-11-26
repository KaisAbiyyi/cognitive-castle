package utils {
    
    /**
     * ObjectPool - Generic object pooling for memory optimization.
     * Reuses objects instead of creating new ones to reduce GC pressure.
     * 
     * Usage:
     *   var pool:ObjectPool = new ObjectPool(MyClass, 10);
     *   var obj:MyClass = pool.get() as MyClass;
     *   pool.release(obj);
     * 
     * SOLID Principles:
     * - Single Responsibility: Only manages object pooling
     * - Open/Closed: Works with any class type
     */
    public class ObjectPool {
        
        private var _pool:Vector.<Object>;
        private var _factory:Class;
        private var _maxSize:int;
        private var _growSize:int;
        private var _resetFunction:Function;
        
        // Stats
        private var _totalCreated:int = 0;
        private var _currentActive:int = 0;
        
        /**
         * Constructor
         * @param factory Class to instantiate for new objects
         * @param initialSize Initial pool size
         * @param maxSize Maximum pool size (0 = unlimited)
         * @param growSize How many objects to create when pool is empty
         * @param resetFunction Optional function to reset object state: function(obj:Object):void
         */
        public function ObjectPool(factory:Class, initialSize:int = 10, maxSize:int = 0, growSize:int = 5, resetFunction:Function = null) {
            _factory = factory;
            _maxSize = maxSize;
            _growSize = growSize;
            _resetFunction = resetFunction;
            _pool = new Vector.<Object>();
            
            // Pre-populate pool
            grow(initialSize);
        }
        
        /**
         * Get an object from the pool
         * @return Pooled object or new instance if pool is empty
         */
        public function get():Object {
            if (_pool.length == 0) {
                grow(_growSize);
            }
            
            var obj:Object = _pool.pop();
            _currentActive++;
            return obj;
        }
        
        /**
         * Return an object to the pool
         * @param obj Object to return
         */
        public function release(obj:Object):void {
            if (!obj) return;
            
            // Check if pool is at max size
            if (_maxSize > 0 && _pool.length >= _maxSize) {
                // Let GC handle it
                return;
            }
            
            // Reset object if reset function provided
            if (_resetFunction != null) {
                _resetFunction(obj);
            }
            
            _pool.push(obj);
            _currentActive--;
        }
        
        /**
         * Grow the pool by creating new objects
         * @param count Number of objects to create
         */
        private function grow(count:int):void {
            for (var i:int = 0; i < count; i++) {
                if (_maxSize > 0 && _pool.length >= _maxSize) {
                    break;
                }
                _pool.push(new _factory());
                _totalCreated++;
            }
        }
        
        /**
         * Clear the pool and release all objects
         */
        public function clear():void {
            _pool.length = 0;
            _currentActive = 0;
        }
        
        /**
         * Get current pool size (available objects)
         */
        public function get available():int {
            return _pool.length;
        }
        
        /**
         * Get number of active (checked out) objects
         */
        public function get active():int {
            return _currentActive;
        }
        
        /**
         * Get total objects created by this pool
         */
        public function get totalCreated():int {
            return _totalCreated;
        }
        
        /**
         * Pre-warm the pool to a specific size
         * @param size Target size
         */
        public function prewarm(size:int):void {
            var needed:int = size - _pool.length;
            if (needed > 0) {
                grow(needed);
            }
        }
    }
}
