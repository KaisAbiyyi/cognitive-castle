package core {
    
    import flash.events.EventDispatcher;
    import flash.events.Event;
    
    /**
     * EventBus - Global event dispatcher for decoupled communication between components.
     * Implements Singleton pattern for centralized event handling.
     * 
     * Usage:
     *   EventBus.getInstance().dispatch(GameEvent.TRIAL_COMPLETE, {score: 10});
     *   EventBus.getInstance().on(GameEvent.TRIAL_COMPLETE, onTrialComplete);
     * 
     * SOLID Principles:
     * - Single Responsibility: Only handles event dispatching
     * - Open/Closed: New event types can be added without modifying this class
     */
    public class EventBus extends EventDispatcher {
        
        private static var _instance:EventBus;
        
        // Event listeners registry for easy cleanup
        private var _listenerRegistry:Object = {};
        
        /**
         * Get singleton instance
         */
        public static function getInstance():EventBus {
            if (!_instance) {
                _instance = new EventBus();
            }
            return _instance;
        }
        
        /**
         * Constructor
         */
        public function EventBus() {
            if (_instance) {
                throw new Error("EventBus is a singleton. Use getInstance()");
            }
        }
        
        /**
         * Dispatch a typed game event
         * @param type Event type from GameEvent constants
         * @param data Optional data payload
         */
        public function dispatch(type:String, data:Object = null):void {
            var event:GameEvent = new GameEvent(type, data);
            dispatchEvent(event);
        }
        
        /**
         * Subscribe to an event type
         * @param type Event type
         * @param handler Handler function
         * @param priority Optional priority (higher = called first)
         */
        public function on(type:String, handler:Function, priority:int = 0):void {
            addEventListener(type, handler, false, priority);
            
            // Register for cleanup
            if (!_listenerRegistry[type]) {
                _listenerRegistry[type] = [];
            }
            _listenerRegistry[type].push(handler);
        }
        
        /**
         * Unsubscribe from an event type
         * @param type Event type
         * @param handler Handler function
         */
        public function off(type:String, handler:Function):void {
            removeEventListener(type, handler);
            
            // Remove from registry
            if (_listenerRegistry[type]) {
                var idx:int = _listenerRegistry[type].indexOf(handler);
                if (idx >= 0) {
                    _listenerRegistry[type].splice(idx, 1);
                }
            }
        }
        
        /**
         * Remove all listeners for a specific event type
         * @param type Event type
         */
        public function offAll(type:String):void {
            if (_listenerRegistry[type]) {
                for each (var handler:Function in _listenerRegistry[type]) {
                    removeEventListener(type, handler);
                }
                delete _listenerRegistry[type];
            }
        }
        
        /**
         * Clear all registered listeners
         */
        public function clear():void {
            for (var type:String in _listenerRegistry) {
                offAll(type);
            }
            _listenerRegistry = {};
        }
        
        /**
         * Check if event type has listeners
         * @param type Event type
         * @return True if listeners exist
         */
        public function hasListeners(type:String):Boolean {
            return hasEventListener(type);
        }
    }
}
