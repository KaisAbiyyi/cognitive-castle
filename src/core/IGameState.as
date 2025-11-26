package core {
    
    /**
     * IGameState - Interface for FSM states.
     * Enables State pattern for clean state management.
     * 
     * SOLID Principles:
     * - Interface Segregation: Small, focused interface
     * - Dependency Inversion: Components depend on this interface, not concrete states
     */
    public interface IGameState {
        
        /**
         * Get the state identifier
         * @return State name from Constants
         */
        function get name():String;
        
        /**
         * Called when entering this state
         * @param data Optional data passed from previous state
         */
        function enter(data:Object = null):void;
        
        /**
         * Called every frame while in this state
         * @param deltaTime Time since last update in ms
         */
        function update(deltaTime:Number):void;
        
        /**
         * Called when exiting this state
         * @return Optional data to pass to next state
         */
        function exit():Object;
        
        /**
         * Check if transition to another state is allowed
         * @param targetState Target state name
         * @return True if transition is allowed
         */
        function canTransitionTo(targetState:String):Boolean;
        
        /**
         * Handle user input in this state
         * @param action Input action type
         * @param data Input data
         */
        function handleInput(action:String, data:Object = null):void;
        
        /**
         * Pause the state (e.g., app minimized)
         */
        function pause():void;
        
        /**
         * Resume the state
         */
        function resume():void;
    }
}
