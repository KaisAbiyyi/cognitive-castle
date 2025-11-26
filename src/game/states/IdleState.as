package game.states {
    
    import core.Constants;
    import core.GameEvent;
    import game.GameController;
    
    /**
     * IdleState - Initial waiting state before game starts.
     * Waits for user to press START button.
     */
    public class IdleState extends BaseState {
        
        /** Callback for state transitions */
        public var onTransition:Function;
        
        public function IdleState(controller:GameController) {
            super(controller, Constants.STATE_IDLE);
        }
        
        override public function enter(data:Object = null):void {
            super.enter(data);
            _eventBus.dispatch(GameEvent.STATE_IDLE, {});
        }
        
        override public function handleInput(action:String, data:Object = null):void {
            if (action == "START" || action == "start") {
                if (onTransition != null) {
                    onTransition(Constants.STATE_STIMULUS);
                }
            }
        }
        
        override public function canTransitionTo(targetState:String):Boolean {
            // From idle, can only go to stimulus or menu
            return targetState == Constants.STATE_STIMULUS || 
                   targetState == Constants.STATE_MENU;
        }
    }
}
