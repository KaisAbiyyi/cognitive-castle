package game {

    import flash.display.Sprite;
    import flash.display.SimpleButton;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.events.MouseEvent;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import ui.HUD;
    import generation.SequenceGenerator;
    import input.InputManager;
    import domain.StimulusItem;
    import domain.TrialResult;
    import castle.CastleArchitect;
    import castle.CastleView;
    import castle.CastlePanel;
    import castle.CastleConfig;
    import castle.BuildEvent;
    import castle.EffectsManager;
    import castle.MetricsManager;

    /**
     * GameController - Manages the game loop finite state machine and orchestrates all game components.
     * Handles phase transitions: IDLE -> STIMULUS -> INPUT -> RESULT -> NEXT
     *
     * SOLID Principles:
     * - Single Responsibility: Only orchestrates game flow and state management
     * - Open/Closed: Can be extended with new game states without changing existing code
     * - Dependency Inversion: Depends on abstractions (HUD, SequenceGenerator, InputManager)
     */
    public class GameController {

        // Debug flag for conditional logging (set to false for release builds)
        private static const DEBUG:Boolean = true;

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
        
        // Castle components
        private var _castleArchitect:CastleArchitect;
        private var _castleView:CastleView;
        private var _castlePanel:CastlePanel;
        private var _effectsManager:EffectsManager;
        private var _metricsManager:MetricsManager;
        
        // Streak tracking
        private var _currentStreak:int = 0;
        private var _trialStartTime:Number = 0;
        private var _inputStartTime:Number = 0;

        // Game data
        private var _currentSequence:Vector.<StimulusItem>;
        private var _userInput:Vector.<int>;
        private var _isCorrect:Boolean;
        private var _trialCount:int = 0;
        private var _currentStimulusIndex:int = 0; // Track which stimulus is being shown
        private var _stimulusTimer:Timer; // Timer for stimulus presentation

        // UI Components
        private var _nextTrialButton:SimpleButton;
        private var _autoAdvanceTimer:Timer;
        private var _stimulusDisplay:TextField; // Week 1 placeholder for stimulus
        private var _userInputDisplay:TextField; // Show user's input as they click

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
            
            // Initialize castle system
            _castleArchitect = new CastleArchitect();
            _metricsManager = MetricsManager.getInstance();
        }

        /**
         * Initialize the game controller with HUD
         * @param hud HUD component
         */
        public function initialize(hud:HUD):void {
            _hud = hud;
            createStimulusDisplay();
            createUserInputDisplay();
            initializeCastleUI();
            enterState(STATE_IDLE);
            
            // Start metrics session
            _metricsManager.startSession();
        }
        
        /**
         * Initialize castle view and panel
         */
        private function initializeCastleUI():void {
            if (!_hud.parent) return;
            
            var stage:* = _hud.parent.stage || _hud.parent;
            
            // Create castle view (left side)
            _castleView = new CastleView(200, 180);
            _castleView.x = 10;
            _castleView.y = 60;
            _hud.parent.addChild(_castleView);
            
            // Create castle panel (right side)
            _castlePanel = new CastlePanel(180, 140);
            _castlePanel.x = stage.stageWidth - 190;
            _castlePanel.y = 60;
            _hud.parent.addChild(_castlePanel);
            
            // Create effects manager with parent
            _effectsManager = EffectsManager.getInstance();
            _effectsManager.setParent(_hud.parent as Sprite);
            
            // Initial render
            _castleView.render(_castleArchitect.state);
            _castlePanel.updateFromState(_castleArchitect.state, _currentStreak);
            
            if (DEBUG) {
                trace("Castle UI initialized");
            }
        }

        /**
         * Create stimulus display TextField (Week 1 placeholder)
         */
        private function createStimulusDisplay():void {
            _stimulusDisplay = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 80;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = "center";
            
            _stimulusDisplay.defaultTextFormat = format;
            _stimulusDisplay.width = 400;
            _stimulusDisplay.height = 100;
            
            // Position at center of actual stage
            if (_hud.parent && _hud.parent.stage) {
                _stimulusDisplay.x = (_hud.parent.stage.stageWidth - 400) / 2;
                _stimulusDisplay.y = (_hud.parent.stage.stageHeight - 100) / 2;
            } else {
                // Fallback positioning
                _stimulusDisplay.x = 40;
                _stimulusDisplay.y = 100;
            }
            
            _stimulusDisplay.selectable = false;
            _stimulusDisplay.visible = false;
            
            // Add to HUD's parent (stage)
            if (_hud.parent) {
                _hud.parent.addChild(_stimulusDisplay);
            }
        }

        /**
         * Create user input display TextField (shows input as user clicks)
         */
        private function createUserInputDisplay():void {
            _userInputDisplay = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 40;
            format.color = 0x00FF00; // Green color
            format.bold = true;
            format.align = "center";
            
            _userInputDisplay.defaultTextFormat = format;
            _userInputDisplay.width = 600;
            _userInputDisplay.height = 60;
            
            // Position below center
            if (_hud.parent && _hud.parent.stage) {
                _userInputDisplay.x = (_hud.parent.stage.stageWidth - 600) / 2;
                _userInputDisplay.y = (_hud.parent.stage.stageHeight / 2) + 80;
            } else {
                _userInputDisplay.x = 40;
                _userInputDisplay.y = 180;
            }
            
            _userInputDisplay.selectable = false;
            _userInputDisplay.visible = false;
            _userInputDisplay.text = "Your input: ";
            
            // Add to HUD's parent (stage)
            if (_hud.parent) {
                _hud.parent.addChild(_userInputDisplay);
            }
        }

        /**
         * Start next trial (public method called from HUD START button or NEXT button)
         */
        public function startNextTrial():void {
            createNextTrialButton();
            startNewTrial();
        }

        /**
         * Create the Next Trial button (only if not already created)
         */
        private function createNextTrialButton():void {
            // Only create once
            if (_nextTrialButton) {
                return;
            }

            // Create button graphics
            var upState:Sprite = createButtonState("Next Trial", 0x4CAF50);
            var overState:Sprite = createButtonState("Next Trial", 0x66BB6A);
            var downState:Sprite = createButtonState("Next Trial", 0x388E3C);

            _nextTrialButton = new SimpleButton(upState, overState, downState, upState);
            
            // Position using actual stage dimensions
            if (_hud.parent && _hud.parent.stage) {
                _nextTrialButton.x = (_hud.parent.stage.stageWidth - _nextTrialButton.width) / 2;
                _nextTrialButton.y = _hud.parent.stage.stageHeight - 100;
            } else {
                _nextTrialButton.x = 175;
                _nextTrialButton.y = 200;
            }
            
            _nextTrialButton.addEventListener(MouseEvent.CLICK, onNextTrialClick);
            _nextTrialButton.visible = false;

            // Add to HUD's parent (stage)
            if (_hud.parent) {
                _hud.parent.addChild(_nextTrialButton);
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
            if (DEBUG) {
                trace("Entering state: " + newState);
            }
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
            // Don't show next trial button in IDLE state - it's shown via HUD START button
        }

        /**
         * Handle STIMULUS state entry
         */
        private function onEnterStimulus():void {
            _hud.setStateText("Observe");
            _hud.setInstructionText("Watch the sequence carefully...");
            if (_nextTrialButton) {
                _nextTrialButton.visible = false;
            }
            
            // Record trial start time
            _trialStartTime = new Date().getTime();

            // Generate sequence
            _currentSequence = _sequenceGenerator.generateSequence(_hud.getLevel());
            _hud.setSpan(_currentSequence.length);

            if (DEBUG) {
                trace("========== STIMULUS PHASE ==========");
                trace("Generated sequence: " + _currentSequence.length + " items");
                var seqIds:Array = [];
                for each (var debugItem:StimulusItem in _currentSequence) {
                    seqIds.push(debugItem.id);
                }
                trace("Sequence IDs: " + seqIds.join(", "));
                trace("====================================");
            }

            // Show first stimulus immediately
            _currentStimulusIndex = 0;
            showCurrentStimulus();
            
            // Set timer for next stimuli (1.5 seconds per item)
            _stimulusTimer = new Timer(1500);
            _stimulusTimer.addEventListener(TimerEvent.TIMER, onStimulusTick);
            _stimulusTimer.start();
            
            if (DEBUG) {
                trace("Stimulus timer started - 1.5s interval");
            }
        }

        /**
         * Show current stimulus item
         */
        private function showCurrentStimulus():void {
            if (_currentStimulusIndex < _currentSequence.length) {
                var item:StimulusItem = _currentSequence[_currentStimulusIndex];
                _stimulusDisplay.text = String(item.id + 1); // Show 1-indexed
                _stimulusDisplay.visible = true;
                
                if (DEBUG) {
                    trace("Showing stimulus " + (_currentStimulusIndex + 1) + "/" + _currentSequence.length + ": ID=" + item.id + " (display: " + (item.id + 1) + ")");
                }
            }
        }

        /**
         * Handle stimulus tick - advance to next stimulus or complete
         */
        private function onStimulusTick(event:TimerEvent):void {
            _currentStimulusIndex++;
            
            if (_currentStimulusIndex < _currentSequence.length) {
                // Show next stimulus
                showCurrentStimulus();
            } else {
                // All stimuli shown, move to input phase
                if (_stimulusTimer) {
                    _stimulusTimer.stop();
                    _stimulusTimer.removeEventListener(TimerEvent.TIMER, onStimulusTick);
                    _stimulusTimer = null;
                }
                _stimulusDisplay.visible = false;
                
                if (DEBUG) {
                    trace("All " + _currentSequence.length + " stimuli shown, moving to INPUT");
                }
                
                enterState(STATE_INPUT);
            }
        }

        /**
         * Handle INPUT state entry
         */
        private function onEnterInput():void {
            _hud.setStateText("Answer");
            _hud.setInstructionText("Reproduce the sequence by clicking the buttons in order.");
            
            // Record input start time
            _inputStartTime = new Date().getTime();

            // Show user input display
            _userInputDisplay.text = "Your input: ";
            _userInputDisplay.visible = true;

            if (DEBUG) {
                trace("onEnterInput - Sequence length: " + _currentSequence.length);
                trace("Showing " + _currentSequence.length + " input buttons");
            }

            // Start input collection with callback for each button click
            // Only show buttons matching the sequence length
            _inputManager.startInputPhase(onInputReceived, onInputTimeout, 10000, onButtonClicked, _currentSequence.length);
        }

        /**
         * Handle each button click (update display)
         */
        private function onButtonClicked(buffer:Vector.<int>):void {
            // Convert buffer to 1-indexed display
            var displayArray:Array = [];
            for each (var id:int in buffer) {
                displayArray.push(String(id + 1));
            }
            _userInputDisplay.text = "Your input: " + displayArray.join(", ");
            
            if (DEBUG) {
                trace("Current input buffer: " + displayArray.join(", "));
            }
        }

        /**
         * Handle input received
         * @param input User input buffer
         */
        private function onInputReceived(input:Vector.<int>):void {
            _userInput = new Vector.<int>();
            for each (var id:int in input) {
                _userInput.push(id);
            }
            
            // Hide user input display
            _userInputDisplay.visible = false;
            
            if (DEBUG) {
                trace("========== VALIDATION ==========");
                trace("User input received: " + _userInput.join(","));
                
                // Show expected sequence
                var expectedIds:Array = [];
                for each (var item:StimulusItem in _currentSequence) {
                    expectedIds.push(item.id);
                }
                trace("Expected sequence: " + expectedIds.join(","));
                trace("Length match: " + (_currentSequence.length == _userInput.length));
            }

            // TODO: Validate input using Validator
            // For now, simple check
            _isCorrect = validateSimple(_currentSequence, _userInput);
            
            if (DEBUG) {
                trace("Validation result: " + (_isCorrect ? "CORRECT" : "INCORRECT"));
                trace("================================");
            }

            enterState(STATE_RESULT);
        }

        /**
         * Handle input timeout
         */
        private function onInputTimeout():void {
            _userInput = new Vector.<int>();
            _isCorrect = false;
            if (DEBUG) {
                trace("Input timeout - incorrect");
            }
            enterState(STATE_RESULT);
        }

        /**
         * Simple validation (placeholder)
         * @param sequence Correct sequence
         * @param input User input
         * @return True if correct
         */
        private function validateSimple(sequence:Vector.<StimulusItem>, userInput:Vector.<int>):Boolean {
            if (sequence.length != userInput.length) {
                if (DEBUG) {
                    trace("Length mismatch: " + sequence.length + " vs " + userInput.length);
                }
                return false;
            }

            for (var i:int = 0; i < sequence.length; i++) {
                if (DEBUG) {
                    trace("Comparing position " + i + ": expected=" + sequence[i].id + " got=" + userInput[i]);
                }
                if (sequence[i].id != userInput[i]) {
                    if (DEBUG) {
                        trace("Mismatch at position " + i);
                    }
                    return false;
                }
            }
            return true;
        }

        /**
         * Handle RESULT state entry
         */
        private function onEnterResult():void {
            _trialCount++;
            var now:Number = new Date().getTime();
            
            // Calculate reaction time
            var reactionTime:Number = now - _inputStartTime;
            var totalTime:Number = now - _trialStartTime;
            
            // Update streak
            if (_isCorrect) {
                _currentStreak++;
            } else {
                _currentStreak = 0;
            }

            // Build comparison text
            var expectedIds:Array = [];
            for each (var item:StimulusItem in _currentSequence) {
                expectedIds.push(String(item.id + 1)); // 1-indexed
            }
            var userIds:Array = [];
            for each (var id:int in _userInput) {
                userIds.push(String(id + 1)); // 1-indexed
            }
            
            // Create TrialResult for castle system
            var trialResult:TrialResult = new TrialResult();
            trialResult.isCorrect = _isCorrect;
            trialResult.reactionTime = reactionTime;
            trialResult.totalTime = totalTime;
            trialResult.sequenceLength = _currentSequence.length;
            trialResult.difficulty = _hud.getLevel();
            trialResult.expected = expectedIds;
            trialResult.actual = userIds;
            trialResult.streakAfter = _currentStreak;
            trialResult.totalItems = _currentSequence.length;
            trialResult.correctItems = _isCorrect ? _currentSequence.length : countCorrectItems();
            trialResult.accuracy = trialResult.totalItems > 0 ? trialResult.correctItems / trialResult.totalItems : 0;
            
            // Calculate score using CastleConfig
            trialResult.scoreEarned = CastleConfig.calculateTrialPoints(_isCorrect, _currentStreak, _hud.getLevel());
            
            // Apply to castle system
            var buildEvents:Vector.<BuildEvent> = _castleArchitect.applyTrialResult(trialResult);
            
            // Record in metrics
            _metricsManager.recordTrial(trialResult);
            
            // Process build events for effects
            processBuildEvents(buildEvents, trialResult.scoreEarned);
            
            // Update castle view and panel
            updateCastleDisplay();
            
            var comparisonText:String = "\nExpected: " + expectedIds.join(", ") + 
                                       "\nYou entered: " + userIds.join(", ");

            if (_isCorrect) {
                _hud.setScore(_hud.getScore() + 1);
                _hud.setStateText("Correct! +" + trialResult.scoreEarned + " pts");
                _hud.setInstructionText("Well done! Sequence completed successfully." + comparisonText);
                if (DEBUG) {
                    trace("Trial " + _trialCount + ": CORRECT - +" + trialResult.scoreEarned + " pts, Streak: " + _currentStreak);
                }
            } else {
                _hud.setStateText("Incorrect");
                _hud.setInstructionText("Try again. Watch carefully next time." + comparisonText);
                if (DEBUG) {
                    trace("Trial " + _trialCount + ": INCORRECT - Streak reset");
                }
            }

            // Auto-advance to next state after delay
            _autoAdvanceTimer.start();
        }
        
        /**
         * Count correct items for partial accuracy
         */
        private function countCorrectItems():int {
            var count:int = 0;
            var minLen:int = Math.min(_currentSequence.length, _userInput.length);
            for (var i:int = 0; i < minLen; i++) {
                if (_currentSequence[i].id == _userInput[i]) {
                    count++;
                }
            }
            return count;
        }
        
        /**
         * Process build events and show effects
         */
        private function processBuildEvents(events:Vector.<BuildEvent>, score:int):void {
            if (!_effectsManager || !_castleView) return;
            
            var centerPos:* = _castleView.getCenter();
            var cx:Number = _castleView.x + centerPos.x;
            var cy:Number = _castleView.y + centerPos.y;
            
            for each (var event:BuildEvent in events) {
                switch (event.type) {
                    case BuildEvent.TYPE_PART_ADDED:
                        _effectsManager.playConstructionEffect(cx, cy, event.part.type);
                        _metricsManager.recordPartBuilt();
                        break;
                        
                    case BuildEvent.TYPE_PART_UPGRADED:
                        _effectsManager.playUpgradeEffect(cx, cy, event.part.tier);
                        _metricsManager.recordPartUpgraded();
                        break;
                        
                    case BuildEvent.TYPE_PART_DAMAGED:
                        _effectsManager.playDamageEffect(cx, cy, event.scoreDelta);
                        break;
                        
                    case BuildEvent.TYPE_MILESTONE_REACHED:
                        _effectsManager.showMilestoneNotification(event.milestoneId, cx, cy - 40);
                        if (_castlePanel) {
                            _castlePanel.showMilestoneReached(event.milestoneId);
                        }
                        break;
                }
            }
            
            // Show score popup for correct answers
            if (score > 0) {
                _effectsManager.playCorrectEffect(cx, cy - 20, score);
                
                // Show streak effect for streaks of 3+
                if (_currentStreak >= 3) {
                    _effectsManager.playStreakEffect(cx, cy - 60, _currentStreak);
                }
            }
        }
        
        /**
         * Update castle display
         */
        private function updateCastleDisplay():void {
            if (_castleView) {
                _castleView.render(_castleArchitect.state);
            }
            if (_castlePanel) {
                _castlePanel.updateFromState(_castleArchitect.state, _currentStreak);
            }
        }

        /**
         * Handle NEXT state entry
         */
        private function onEnterNext():void {
            _hud.setStateText("Next Trial");
            _hud.setInstructionText("Get ready for the next sequence...");
            if (_nextTrialButton) {
                _nextTrialButton.visible = true;
            }
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