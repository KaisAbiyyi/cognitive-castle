package core {
    
    import flash.events.Event;
    
    /**
     * GameEvent - Custom event class for game-specific events.
     * Carries typed event data for decoupled communication.
     * 
     * SOLID Principles:
     * - Single Responsibility: Only represents a game event with data
     * - Open/Closed: New event types added as constants, no class modification needed
     */
    public class GameEvent extends Event {
        
        // ============ GAME STATE EVENTS ============
        /** Game initialized and ready */
        public static const GAME_READY:String = "game_ready";
        /** Game paused */
        public static const GAME_PAUSED:String = "game_paused";
        /** Game resumed */
        public static const GAME_RESUMED:String = "game_resumed";
        /** Session started */
        public static const SESSION_START:String = "session_start";
        /** Session ended */
        public static const SESSION_END:String = "session_end";
        
        // ============ FSM STATE EVENTS ============
        /** FSM state changed */
        public static const STATE_CHANGED:String = "state_changed";
        /** Entering IDLE state */
        public static const STATE_IDLE:String = "state_idle";
        /** Entering READY state */
        public static const STATE_READY:String = "state_ready";
        /** Entering STIMULUS state */
        public static const STATE_STIMULUS:String = "state_stimulus";
        /** Entering DELAY state */
        public static const STATE_DELAY:String = "state_delay";
        /** Entering INPUT state */
        public static const STATE_INPUT:String = "state_input";
        /** Entering VALIDATING state */
        public static const STATE_VALIDATING:String = "state_validating";
        /** Entering RESULT state */
        public static const STATE_RESULT:String = "state_result";
        /** Entering CASTLE_UPDATE state */
        public static const STATE_CASTLE_UPDATE:String = "state_castle_update";
        /** Entering TRANSITION state */
        public static const STATE_TRANSITION:String = "state_transition";
        
        // ============ STIMULUS EVENTS ============
        /** Stimulus presentation started */
        public static const STIMULUS_START:String = "stimulus_start";
        /** Single stimulus item shown */
        public static const STIMULUS_SHOW:String = "stimulus_show";
        /** Single stimulus item hidden */
        public static const STIMULUS_HIDE:String = "stimulus_hide";
        /** Stimulus presentation ended */
        public static const STIMULUS_END:String = "stimulus_end";
        /** Stimulus presentation complete */
        public static const STIMULUS_COMPLETE:String = "stimulus_complete";
        
        // ============ INPUT EVENTS ============
        /** Input phase started */
        public static const INPUT_START:String = "input_start";
        /** User tapped/clicked input */
        public static const INPUT_TAP:String = "input_tap";
        /** User input received */
        public static const INPUT_RECEIVED:String = "input_received";
        /** Inputs cleared */
        public static const INPUT_CLEARED:String = "input_cleared";
        /** Input buffer updated */
        public static const INPUT_BUFFER_UPDATED:String = "input_buffer_updated";
        /** Input phase complete */
        public static const INPUT_COMPLETE:String = "input_complete";
        /** Input timeout occurred */
        public static const INPUT_TIMEOUT:String = "input_timeout";
        /** Input undone (backspace) */
        public static const INPUT_UNDO:String = "input_undo";
        /** Countdown timer tick */
        public static const COUNTDOWN_TICK:String = "countdown_tick";
        
        // ============ VALIDATION EVENTS ============
        /** Validation started */
        public static const VALIDATION_START:String = "validation_start";
        /** Validation complete */
        public static const VALIDATION_COMPLETE:String = "validation_complete";
        /** Answer is correct */
        public static const ANSWER_CORRECT:String = "answer_correct";
        /** Answer is incorrect */
        public static const ANSWER_INCORRECT:String = "answer_incorrect";
        
        // ============ TRIAL EVENTS ============
        /** New trial starting */
        public static const TRIAL_START:String = "trial_start";
        /** Trial complete */
        public static const TRIAL_COMPLETE:String = "trial_complete";
        
        // ============ SCORE EVENTS ============
        /** Score changed */
        public static const SCORE_CHANGED:String = "score_changed";
        /** Score updated with detailed breakdown */
        public static const SCORE_UPDATED:String = "score_updated";
        /** Streak updated */
        public static const STREAK_UPDATED:String = "streak_updated";
        /** Level changed */
        public static const LEVEL_CHANGED:String = "level_changed";
        /** Difficulty adjusted */
        public static const DIFFICULTY_CHANGED:String = "difficulty_changed";
        /** Sequence span changed */
        public static const SPAN_CHANGED:String = "span_changed";
        /** Achievement unlocked */
        public static const ACHIEVEMENT_UNLOCKED:String = "achievement_unlocked";
        
        // ============ CASTLE EVENTS ============
        /** Castle part added */
        public static const CASTLE_PART_ADDED:String = "castle_part_added";
        /** Castle part upgraded */
        public static const CASTLE_PART_UPGRADED:String = "castle_part_upgraded";
        /** Castle part damaged */
        public static const CASTLE_PART_DAMAGED:String = "castle_part_damaged";
        /** Castle part repaired */
        public static const CASTLE_PART_REPAIRED:String = "castle_part_repaired";
        /** Castle milestone reached */
        public static const CASTLE_MILESTONE:String = "castle_milestone";
        
        // ============ UI EVENTS ============
        /** Button clicked */
        public static const BUTTON_CLICK:String = "button_click";
        /** Menu opened */
        public static const MENU_OPEN:String = "menu_open";
        /** Menu closed */
        public static const MENU_CLOSE:String = "menu_close";
        /** Settings changed */
        public static const SETTINGS_CHANGED:String = "settings_changed";
        
        // ============ SAVE EVENTS ============
        /** Save started */
        public static const SAVE_START:String = "save_start";
        /** Save complete */
        public static const SAVE_COMPLETE:String = "save_complete";
        /** Save failed */
        public static const SAVE_FAILED:String = "save_failed";
        /** Load complete */
        public static const LOAD_COMPLETE:String = "load_complete";
        /** Load failed */
        public static const LOAD_FAILED:String = "load_failed";
        
        // ============ DEBUG EVENTS ============
        /** Debug message */
        public static const DEBUG_LOG:String = "debug_log";
        /** Debug state dump */
        public static const DEBUG_DUMP:String = "debug_dump";
        
        // Event data payload
        private var _data:Object;
        
        /**
         * Constructor
         * @param type Event type
         * @param data Optional data payload
         * @param bubbles Whether event bubbles
         * @param cancelable Whether event is cancelable
         */
        public function GameEvent(type:String, data:Object = null, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
            _data = data || {};
        }
        
        /**
         * Get event data payload
         */
        public function get data():Object {
            return _data;
        }
        
        /**
         * Get typed property from data
         * @param key Property key
         * @param defaultValue Default value if not found
         * @return Property value or default
         */
        public function get(key:String, defaultValue:* = null):* {
            if (_data && _data.hasOwnProperty(key)) {
                return _data[key];
            }
            return defaultValue;
        }
        
        /**
         * Clone the event
         */
        override public function clone():Event {
            return new GameEvent(type, _data, bubbles, cancelable);
        }
        
        /**
         * String representation
         */
        override public function toString():String {
            return formatToString("GameEvent", "type", "data");
        }
    }
}
