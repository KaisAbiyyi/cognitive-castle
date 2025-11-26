package game.states {
    
    import core.IGameState;
    import core.EventBus;
    import game.GameController;
    
    /**
     * BaseState - Abstract base class for all game states.
     * Provides common functionality and controller access.
     * 
     * SOLID Principles:
     * - Single Responsibility: Common state behavior
     * - Liskov Substitution: All states are interchangeable via IGameState
     */
    public class BaseState implements IGameState {
        
        protected var _controller:GameController;
        protected var _eventBus:EventBus;
        protected var _stateName:String;
        protected var _stateTime:Number = 0;
        protected var _isPaused:Boolean = false;
        
        /**
         * Constructor
         * @param controller Reference to game controller
         * @param stateName Name of this state
         */
        public function BaseState(controller:GameController, stateName:String) {
            _controller = controller;
            _stateName = stateName;
            _eventBus = EventBus.getInstance();
        }
        
        /**
         * Enter the state
         * @param data Optional data passed from previous state
         */
        public function enter(data:Object = null):void {
            _stateTime = 0;
            _isPaused = false;
            trace("[State] Entering: " + _stateName);
        }
        
        /**
         * Exit the state
         * @return Optional data for next state
         */
        public function exit():Object {
            trace("[State] Exiting: " + _stateName);
            return null;
        }
        
        /**
         * Update the state each frame
         * @param deltaTime Time since last update in milliseconds
         */
        public function update(deltaTime:Number):void {
            if (!_isPaused) {
                _stateTime += deltaTime;
            }
        }
        
        /**
         * Handle input events
         * @param action The input action type
         * @param data Optional input data
         */
        public function handleInput(action:String, data:Object = null):void {
            // Override in subclasses
        }
        
        /**
         * Check if transition to another state is allowed
         * @param targetState Target state name
         * @return True if allowed
         */
        public function canTransitionTo(targetState:String):Boolean {
            // Default: allow all transitions
            return true;
        }
        
        /**
         * Pause the state
         */
        public function pause():void {
            _isPaused = true;
            trace("[State] Paused: " + _stateName);
        }
        
        /**
         * Resume the state
         */
        public function resume():void {
            _isPaused = false;
            trace("[State] Resumed: " + _stateName);
        }
        
        /**
         * Get state name
         */
        public function get name():String {
            return _stateName;
        }
        
        /**
         * Get time spent in this state
         */
        public function get stateTime():Number {
            return _stateTime;
        }
    }
}
