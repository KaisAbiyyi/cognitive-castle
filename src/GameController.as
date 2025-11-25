package {

    import flash.display.Sprite;
    import flash.display.SimpleButton;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.events.MouseEvent;
    import flash.utils.Timer;
    import flash.events.TimerEvent;

    /**
     * GameController - Manages the game loop finite state machine and orchestrates all game components.
     * Handles phase transitions: IDLE -> STIMULUS -> INPUT -> RESULT -> NEXT
     */
    public class GameController {

        // FSM States
        public static const STATE_IDLE:String = "idle";
        public static const STATE_STIMULUS:String = "stimulus";
        public static const STATE_INPUT:String = "input";
        public static const STATE_RESULT:String = "result";
        public static const STATE_NEXT:String = "next";

        // Singleton instance
        private static var _instance:GameController;

        // Current FSM state
        private var _currentState:String = STATE_IDLE;

        // Game components
        private var _hud:HUD;
        private var _sequenceGenerator:SequenceGenerator;
        private var _inputManager:InputManager;
        // private var _stimulusView:StimulusView; // Stub - implemented in Area 2
        // private var _validator:Validator; // Stub - implemented in Area 4

        // Game data
        private var _currentSequence:Vector.<StimulusItem>;
        private var _userInput:Vector.<int>;
        private var _isCorrect:Boolean;
        private var _trialCount:int = 0;

        // UI Components
        private var _nextTrialButton:SimpleButton;
        private var _autoAdvanceTimer:Timer;

        // Timing constants
        private const RESULT_DISPLAY_TIME:int = 3000; // 3 seconds

        /**
         * Get singleton instance
         * @return GameController instance
         */
        public static function getInstance():GameController {
            if (!_instance) {
                _instance = new GameController();
            }
            return _instance;
        }

        /**
         * Constructor (private for singleton)
         */
        public function GameController() {
            _sequenceGenerator = new SequenceGenerator();
            _inputManager = InputManager.getInstance();
            _autoAdvanceTimer = new Timer(RESULT_DISPLAY_TIME, 1);
            _autoAdvanceTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAutoAdvance);
        }

        /**
         * Initialize the game controller with HUD
         * @param hud HUD component
         */
        public function initialize(hud:HUD):void {
            _hud = hud;
            createNextTrialButton();
            enterState(STATE_IDLE);
        }

        /**
         * Create the Next Trial button
         */
        private function createNextTrialButton():void {
            // Create button graphics
            var upState:Sprite = createButtonState("Next Trial", 0x4CAF50);
            var overState:Sprite = createButtonState("Next Trial", 0x66BB6A);
            var downState:Sprite = createButtonState("Next Trial", 0x388E3C);

            _nextTrialButton = new SimpleButton(upState, overState, downState, upState);
            _nextTrialButton.x = (_hud.stage.stageWidth - _nextTrialButton.width) / 2;
            _nextTrialButton.y = _hud.stage.stageHeight - 100;
            _nextTrialButton.addEventListener(MouseEvent.CLICK, onNextTrialClick);
            _nextTrialButton.visible = false;

            if (_hud.stage) {
                _hud.stage.addChild(_nextTrialButton);
            }
        }

        /**
         * Create button state sprite
         * @param text Button text
         * @param color Background color
         * @return Sprite for button state
         */
        private function createButtonState(text:String, color:uint):Sprite {
            var sprite:Sprite = new Sprite();

            // Background
            sprite.graphics.beginFill(color);
            sprite.graphics.drawRoundRect(0, 0, 150, 40, 10);
            sprite.graphics.endFill();

            // Text
            var tf:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 16;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = "center";

            tf.defaultTextFormat = format;
            tf.text = text;
            tf.width = 150;
            tf.height = 40;
            tf.selectable = false;
            tf.x = 0;
            tf.y = 10;

            sprite.addChild(tf);
            return sprite;
        }

        /**
         * Enter a new FSM state
         * @param newState State to enter
         */
        private function enterState(newState:String):void {
            trace("Entering state: " + newState);
            _currentState = newState;

            switch (newState) {
                case STATE_IDLE:
                    onEnterIdle();
                    break;
                case STATE_STIMULUS:
                    onEnterStimulus();
                    break;
                case STATE_INPUT:
                    onEnterInput();
                    break;
                case STATE_RESULT:
                    onEnterResult();
                    break;
                case STATE_NEXT:
                    onEnterNext();
                    break;
            }
        }

        /**
         * Handle IDLE state entry
         */
        private function onEnterIdle():void {
            _hud.setStateText("Ready");
            _hud.setInstructionText("Press any key or tap to start the sequence challenge.");
            _nextTrialButton.visible = true;
        }

        /**
         * Handle STIMULUS state entry
         */
        private function onEnterStimulus():void {
            _hud.setStateText("Observe");
            _hud.setInstructionText("Watch the sequence carefully...");
            _nextTrialButton.visible = false;

            // Generate sequence
            _currentSequence = _sequenceGenerator.generateSequence(_hud.getLevel());
            _hud.setSpan(_currentSequence.length);

            // TODO: Show stimulus sequence using StimulusView
            // For now, simulate with timer
            var stimulusTimer:Timer = new Timer(1000, _currentSequence.length);
            stimulusTimer.addEventListener(TimerEvent.TIMER, onStimulusTick);
            stimulusTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onStimulusComplete);
            stimulusTimer.start();

            trace("Showing sequence: " + _currentSequence.length + " items");
        }

        /**
         * Handle stimulus tick (placeholder)
         */
        private function onStimulusTick(event:TimerEvent):void {
            var index:int = event.currentTarget.currentCount - 1;
            if (index < _currentSequence.length) {
                trace("Stimulus " + index + ": " + _currentSequence[index].toString());
            }
        }

        /**
         * Handle stimulus complete
         */
        private function onStimulusComplete(event:TimerEvent):void {
            enterState(STATE_INPUT);
        }

        /**
         * Handle INPUT state entry
         */
        private function onEnterInput():void {
            _hud.setStateText("Answer");
            _hud.setInstructionText("Reproduce the sequence by clicking the buttons in order.");

            // Start input collection
            _inputManager.startInputPhase(onInputReceived, onInputTimeout);
        }

        /**
         * Handle input received
         * @param input User input buffer
         */
        private function onInputReceived(input:Vector.<int>):void {
            _userInput = input.slice();
            trace("User input received: " + _userInput.join(","));

            // TODO: Validate input using Validator
            // For now, simple check
            _isCorrect = validateSimple(_currentSequence, _userInput);

            enterState(STATE_RESULT);
        }

        /**
         * Handle input timeout
         */
        private function onInputTimeout():void {
            _userInput = new Vector.<int>();
            _isCorrect = false;
            trace("Input timeout - incorrect");
            enterState(STATE_RESULT);
        }

        /**
         * Simple validation (placeholder)
         * @param sequence Correct sequence
         * @param input User input
         * @return True if correct
         */
        private function validateSimple(sequence:Vector.<StimulusItem>, input:Vector.<int>):Boolean {
            if (sequence.length != input.length) return false;

            for (var i:int = 0; i < sequence.length; i++) {
                if (sequence[i].id != input[i]) return false;
            }
            return true;
        }

        /**
         * Handle RESULT state entry
         */
        private function onEnterResult():void {
            _trialCount++;

            if (_isCorrect) {
                _hud.setScore(_hud.getScore() + 1);
                _hud.setStateText("Correct!");
                _hud.setInstructionText("Well done! Sequence completed successfully.");
                trace("Trial " + _trialCount + ": CORRECT");
            } else {
                _hud.setStateText("Incorrect");
                _hud.setInstructionText("Try again. Watch carefully next time.");
                trace("Trial " + _trialCount + ": INCORRECT");
            }

            // Auto-advance to next state after delay
            _autoAdvanceTimer.start();
        }

        /**
         * Handle NEXT state entry
         */
        private function onEnterNext():void {
            _hud.setStateText("Next Trial");
            _hud.setInstructionText("Get ready for the next sequence...");
            _nextTrialButton.visible = true;
        }

        /**
         * Handle next trial button click
         */
        private function onNextTrialClick(event:MouseEvent):void {
            if (_currentState == STATE_IDLE || _currentState == STATE_NEXT) {
                startNewTrial();
            }
        }

        /**
         * Handle auto-advance timer
         */
        private function onAutoAdvance(event:TimerEvent):void {
            if (_currentState == STATE_RESULT) {
                enterState(STATE_NEXT);
            }
        }

        /**
         * Start a new trial
         */
        private function startNewTrial():void {
            enterState(STATE_STIMULUS);
        }

        /**
         * Get current FSM state
         * @return Current state
         */
        public function getCurrentState():String {
            return _currentState;
        }

        /**
         * Force state transition (for debugging)
         * @param state State to enter
         */
        public function forceState(state:String):void {
            enterState(state);
        }
    }
}