package game {
    
    import core.Constants;
    import core.IGameState;
    import core.EventBus;
    import core.GameEvent;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    
    /**
     * StateMachine - Manages FSM state transitions with history and recovery.
     * Orchestrates state changes, validates transitions, and tracks history.
     * 
     * SOLID Principles:
     * - Single Responsibility: Only manages state machine logic
     * - Open/Closed: New states added without modifying core logic
     */
    public class StateMachine {
        
        private var _states:Dictionary;
        private var _currentState:IGameState;
        private var _previousState:IGameState;
        private var _eventBus:EventBus;
        private var _isPaused:Boolean = false;
        
        // Transition history
        private var _stateHistory:Vector.<StateHistoryEntry>;
        private var _maxHistorySize:int = 50;
        
        // Allowed transitions (optional - if empty, all transitions allowed)
        private var _allowedTransitions:Dictionary;
        
        // Error recovery
        private var _fallbackState:String = null;
        private var _transitionInProgress:Boolean = false;
        
        // Debugging
        private static const DEBUG:Boolean = true;
        
        // Transition callback
        public var onStateChange:Function;
        
        /**
         * Constructor
         */
        public function StateMachine() {
            _states = new Dictionary();
            _stateHistory = new Vector.<StateHistoryEntry>();
            _allowedTransitions = new Dictionary();
            _eventBus = EventBus.getInstance();
        }
        
        /**
         * Register a state with the state machine
         * @param name State name from Constants
         * @param state State instance
         */
        public function registerState(name:String, state:IGameState):void {
            _states[name] = state;
            if (DEBUG) {
                trace("[StateMachine] Registered state: " + name);
            }
        }
        
        /**
         * Define allowed transitions from a state
         * @param fromState Source state name
         * @param toStates Array of allowed target state names
         */
        public function defineTransitions(fromState:String, toStates:Array):void {
            _allowedTransitions[fromState] = toStates;
            if (DEBUG) {
                trace("[StateMachine] Defined transitions from " + fromState + ": " + toStates.join(", "));
            }
        }
        
        /**
         * Set fallback state for error recovery
         * @param stateName State to transition to on error
         */
        public function setFallbackState(stateName:String):void {
            _fallbackState = stateName;
        }
        
        /**
         * Get a registered state
         * @param name State name
         * @return State instance or null
         */
        public function getState(name:String):IGameState {
            return _states[name];
        }
        
        /**
         * Change to a new state
         * @param targetState Target state name
         * @param data Optional data to pass to new state
         * @return True if transition successful
         */
        public function changeState(targetState:String, data:Object = null):Boolean {
            // Prevent re-entrant transitions
            if (_transitionInProgress) {
                trace("[StateMachine] WARNING: Transition already in progress, queuing: " + targetState);
                return false;
            }
            
            // Validate target state exists
            if (!_states[targetState]) {
                trace("[StateMachine] ERROR: Unknown state: " + targetState);
                return false;
            }
            
            // Check allowed transitions (if defined)
            if (_currentState) {
                var currentName:String = _currentState.name;
                if (_allowedTransitions[currentName] != null) {
                    var allowed:Array = _allowedTransitions[currentName] as Array;
                    if (allowed.indexOf(targetState) == -1) {
                        trace("[StateMachine] Transition not in allowed list: " + 
                              currentName + " -> " + targetState);
                        return false;
                    }
                }
                
                // Check state's own transition validation
                if (!_currentState.canTransitionTo(targetState)) {
                    trace("[StateMachine] Transition denied by state: " + 
                          currentName + " -> " + targetState);
                    return false;
                }
            }
            
            _transitionInProgress = true;
            
            try {
                // Exit current state
                var exitData:Object = null;
                if (_currentState) {
                    exitData = _currentState.exit();
                    _previousState = _currentState;
                }
                
                // Record in history
                addHistoryEntry(_previousState ? _previousState.name : null, targetState);
                
                // Merge exit data with passed data
                var enterData:Object = data || {};
                if (exitData) {
                    for (var key:String in exitData) {
                        if (!enterData.hasOwnProperty(key)) {
                            enterData[key] = exitData[key];
                        }
                    }
                }
                
                // Enter new state
                _currentState = _states[targetState];
                _currentState.enter(enterData);
                
                if (DEBUG) {
                    trace("[StateMachine] " + 
                          (_previousState ? _previousState.name : "null") + 
                          " -> " + _currentState.name);
                }
                
                // Dispatch event
                _eventBus.dispatch(GameEvent.STATE_CHANGED, {
                    previousState: _previousState ? _previousState.name : null,
                    currentState: _currentState.name,
                    data: enterData
                });
                
                // Call callback
                if (onStateChange != null) {
                    onStateChange(_currentState.name, _previousState ? _previousState.name : null);
                }
                
                _transitionInProgress = false;
                return true;
                
            } catch (e:Error) {
                trace("[StateMachine] ERROR during transition: " + e.message);
                _transitionInProgress = false;
                
                // Attempt recovery
                if (_fallbackState && targetState != _fallbackState) {
                    return recover();
                }
                return false;
            }
        }
        
        /**
         * Update the current state
         * @param deltaTime Time since last update in ms
         */
        public function update(deltaTime:Number):void {
            if (_currentState && !_isPaused) {
                _currentState.update(deltaTime);
            }
        }
        
        /**
         * Pass input to current state
         * @param action Input action type
         * @param data Optional input data
         */
        public function handleInput(action:String, data:Object = null):void {
            if (_currentState && !_isPaused) {
                _currentState.handleInput(action, data);
            }
        }
        
        /**
         * Pause the state machine
         */
        public function pause():void {
            _isPaused = true;
            if (_currentState) {
                _currentState.pause();
            }
            _eventBus.dispatch(GameEvent.GAME_PAUSED, {});
        }
        
        /**
         * Resume the state machine
         */
        public function resume():void {
            _isPaused = false;
            if (_currentState) {
                _currentState.resume();
            }
            _eventBus.dispatch(GameEvent.GAME_RESUMED, {});
        }
        
        /**
         * Check if state machine is paused
         */
        public function get isPaused():Boolean {
            return _isPaused;
        }
        
        /**
         * Get current state name
         */
        public function get currentStateName():String {
            return _currentState ? _currentState.name : null;
        }
        
        /**
         * Get current state instance
         */
        public function get currentState():IGameState {
            return _currentState;
        }
        
        /**
         * Get previous state name
         */
        public function get previousStateName():String {
            return _previousState ? _previousState.name : null;
        }
        
        /**
         * Check if in a specific state
         * @param stateName State name to check
         * @return True if current state matches
         */
        public function isInState(stateName:String):Boolean {
            return _currentState && _currentState.name == stateName;
        }
        
        // ============ TRANSITION HISTORY ============
        
        /**
         * Get transition history
         * @return Copy of history array
         */
        public function getHistory():Array {
            var result:Array = [];
            for each (var entry:StateHistoryEntry in _stateHistory) {
                result.push({
                    fromState: entry.fromState,
                    toState: entry.toState,
                    timestamp: entry.timestamp,
                    duration: entry.duration
                });
            }
            return result;
        }
        
        /**
         * Clear transition history
         */
        public function clearHistory():void {
            _stateHistory.length = 0;
        }
        
        /**
         * Get time spent in current state
         * @return Milliseconds in current state
         */
        public function getTimeInCurrentState():int {
            if (_stateHistory.length == 0) return 0;
            return getTimer() - _stateHistory[_stateHistory.length - 1].timestamp;
        }
        
        // ============ ERROR RECOVERY ============
        
        /**
         * Force transition to a state (ignores validation)
         * @param targetState Target state name
         * @param data Optional data
         * @return True if successful
         */
        public function forceState(targetState:String, data:Object = null):Boolean {
            if (!_states[targetState]) {
                trace("[StateMachine] ERROR: Cannot force to unknown state: " + targetState);
                return false;
            }
            
            if (DEBUG) {
                trace("[StateMachine] FORCING state: " + 
                      (currentStateName || "null") + " -> " + targetState);
            }
            
            // Exit current without validation
            if (_currentState) {
                try {
                    _currentState.exit();
                } catch (e:Error) {
                    trace("[StateMachine] Error exiting state: " + e.message);
                }
                _previousState = _currentState;
            }
            
            // Enter new state
            _currentState = _states[targetState];
            try {
                _currentState.enter(data || {});
            } catch (e:Error) {
                trace("[StateMachine] Error entering state: " + e.message);
            }
            
            // Record in history
            addHistoryEntry(_previousState ? _previousState.name : null, targetState);
            
            // Dispatch event
            _eventBus.dispatch(GameEvent.STATE_CHANGED, {
                previousState: _previousState ? _previousState.name : null,
                currentState: _currentState.name,
                forced: true
            });
            
            return true;
        }
        
        /**
         * Recover to fallback state
         * @return True if recovery successful
         */
        public function recover():Boolean {
            if (!_fallbackState) {
                trace("[StateMachine] No fallback state defined for recovery");
                return false;
            }
            
            trace("[StateMachine] RECOVERING to fallback state: " + _fallbackState);
            return forceState(_fallbackState, { recovered: true });
        }
        
        /**
         * Add entry to transition history
         */
        private function addHistoryEntry(from:String, to:String):void {
            var entry:StateHistoryEntry = new StateHistoryEntry();
            entry.fromState = from;
            entry.toState = to;
            entry.timestamp = getTimer();
            entry.duration = 0;
            
            // Calculate duration of previous state
            if (_stateHistory.length > 0) {
                var prev:StateHistoryEntry = _stateHistory[_stateHistory.length - 1];
                prev.duration = entry.timestamp - prev.timestamp;
            }
            
            _stateHistory.push(entry);
            
            // Trim history if too large
            while (_stateHistory.length > _maxHistorySize) {
                _stateHistory.shift();
            }
        }
    }
}

/**
 * Internal class for state history entries
 */
class StateHistoryEntry {
    public var fromState:String;
    public var toState:String;
    public var timestamp:int;
    public var duration:int;
}