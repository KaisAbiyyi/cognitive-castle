package generation {
    
    import flash.events.Event;
    
    /**
     * QuestionEvent - Custom event for question-related events.
     * Carries question data and validation results.
     */
    public class QuestionEvent extends Event {
        
        // ============ EVENT TYPES ============
        /** Fired when a new question is ready */
        public static const QUESTION_READY:String = "questionReady";
        
        /** Fired when an answer has been validated */
        public static const ANSWER_VALIDATED:String = "answerValidated";
        
        /** Fired when session is complete */
        public static const SESSION_COMPLETE:String = "sessionComplete";
        
        /** Fired when player levels up */
        public static const LEVEL_UP:String = "levelUp";
        
        /** Fired when player levels down */
        public static const LEVEL_DOWN:String = "levelDown";
        
        /** Fired when time runs out */
        public static const TIME_OUT:String = "timeOut";
        
        // ============ PROPERTIES ============
        
        /** The question associated with this event */
        public var question:NumberQuestion;
        
        /** Additional data (validation result, level info, etc.) */
        public var data:Object;
        
        /**
         * Constructor
         * @param type Event type string
         * @param question The NumberQuestion object (can be null)
         * @param data Additional data object (can be null)
         * @param bubbles Whether event bubbles
         * @param cancelable Whether event is cancelable
         */
        public function QuestionEvent(
            type:String, 
            question:NumberQuestion = null, 
            data:Object = null,
            bubbles:Boolean = false, 
            cancelable:Boolean = false
        ) {
            super(type, bubbles, cancelable);
            this.question = question;
            this.data = data || {};
        }
        
        /**
         * Clone this event
         */
        override public function clone():Event {
            var evt:QuestionEvent = new QuestionEvent(type, question, data, bubbles, cancelable);
            return evt;
        }
        
        /**
         * String representation
         */
        override public function toString():String {
            return "[QuestionEvent type=" + type + 
                   " question=" + (question ? question.id : "null") + 
                   " data=" + (data ? "present" : "null") + "]";
        }
        
        // ============ CONVENIENCE GETTERS ============
        
        /**
         * Get whether answer was correct (for ANSWER_VALIDATED events)
         */
        public function get isCorrect():Boolean {
            return data && data.isCorrect === true;
        }
        
        /**
         * Get score earned (for ANSWER_VALIDATED events)
         */
        public function get score():int {
            return data && data.totalScore ? int(data.totalScore) : 0;
        }
        
        /**
         * Get accuracy percentage (for ANSWER_VALIDATED events)
         */
        public function get accuracy():Number {
            return data && data.accuracy ? Number(data.accuracy) : 0;
        }
        
        /**
         * Get new combination (for LEVEL_UP/LEVEL_DOWN events)
         */
        public function get newCombination():int {
            return data && data.combination ? int(data.combination) : 0;
        }
        
        /**
         * Get new level (for LEVEL_UP/LEVEL_DOWN events)
         */
        public function get newLevel():String {
            return data && data.level ? String(data.level) : "";
        }
    }
}
