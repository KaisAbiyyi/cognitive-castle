package core {
    
    import flash.utils.Dictionary;
    
    /**
     * ServiceLocator - Central registry for game services.
     * Implements Service Locator pattern for dependency injection.
     * 
     * SOLID Principles:
     * - Single Responsibility: Only manages service registry
     * - Dependency Inversion: Components depend on locator, not concrete services
     */
    public class ServiceLocator {
        
        private static var _instance:ServiceLocator;
        private var _services:Dictionary;
        private var _factories:Dictionary;
        
        /**
         * Get singleton instance
         */
        public static function getInstance():ServiceLocator {
            if (!_instance) {
                _instance = new ServiceLocator();
            }
            return _instance;
        }
        
        /**
         * Static helper for quick service access
         */
        public static function get(serviceName:String):* {
            return getInstance().getService(serviceName);
        }
        
        /**
         * Constructor
         */
        public function ServiceLocator() {
            _services = new Dictionary();
            _factories = new Dictionary();
        }
        
        /**
         * Register a service instance
         * @param name Service name
         * @param service Service instance
         */
        public function register(name:String, service:Object):void {
            _services[name] = service;
            trace("[ServiceLocator] Registered: " + name);
        }
        
        /**
         * Register a factory function for lazy instantiation
         * @param name Service name
         * @param factory Factory function () => Service
         */
        public function registerFactory(name:String, factory:Function):void {
            _factories[name] = factory;
            trace("[ServiceLocator] Registered factory: " + name);
        }
        
        /**
         * Get a service by name
         * @param name Service name
         * @return Service instance or null
         */
        public function getService(name:String):* {
            // Check direct services first
            if (_services[name]) {
                return _services[name];
            }
            
            // Check factories (lazy initialization)
            if (_factories[name]) {
                var factory:Function = _factories[name];
                var service:Object = factory();
                _services[name] = service;
                delete _factories[name];
                trace("[ServiceLocator] Lazy-loaded: " + name);
                return service;
            }
            
            trace("[ServiceLocator] WARNING: Service not found: " + name);
            return null;
        }
        
        /**
         * Check if a service exists
         * @param name Service name
         * @return True if registered
         */
        public function has(name:String):Boolean {
            return _services[name] != null || _factories[name] != null;
        }
        
        /**
         * Remove a service
         * @param name Service name
         */
        public function unregister(name:String):void {
            delete _services[name];
            delete _factories[name];
            trace("[ServiceLocator] Unregistered: " + name);
        }
        
        /**
         * Clear all services
         */
        public function clear():void {
            _services = new Dictionary();
            _factories = new Dictionary();
            trace("[ServiceLocator] Cleared all services");
        }
        
        // ============ WELL-KNOWN SERVICE NAMES ============
        public static const SAVE_SYSTEM:String = "SaveSystem";
        public static const EVENT_BUS:String = "EventBus";
        public static const SOUND_MANAGER:String = "SoundManager";
        public static const CASTLE_ARCHITECT:String = "CastleArchitect";
        public static const PROGRESSION:String = "ProgressionController";
        public static const ANALYTICS:String = "Analytics";
    }
}
