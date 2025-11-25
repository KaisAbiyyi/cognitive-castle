package {
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.system.Capabilities;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import generation.SequenceGenerator;
    // import ui.StimulusView; // TODO: Implement in Area 2
    import input.InputManager;
    // import game.Validator; // TODO: Implement in Area 4
    // import game.GameLoop; // TODO: Implement in Area 4
    import domain.StimulusItem;
    import config.StimulusConfig;
    import ui.HUD;
    import game.GameController;

    /**
     * Main - Application entry point and component initialization.
     * Sets up the game environment and coordinates major components.
     *
     * SOLID Principles:
     * - Single Responsibility: Only initializes and coordinates components
     * - Dependency Inversion: Depends on abstractions rather than concrete implementations
     */
    public class Main extends Sprite {
        // Debug flag for conditional logging
        private static const DEBUG:Boolean = true;

        private var _sequenceGenerator:SequenceGenerator;
        // private var _stimulusView:StimulusView; // TODO: Implement in Area 2
        private var _inputManager:InputManager;
        // private var _validator:Validator; // TODO: Implement in Area 4
        // private var _gameLoop:GameLoop; // TODO: Implement in Area 4
        private var _currentSequence:Vector.<StimulusItem>;
        private var _hud:HUD;
        private var _gameController:GameController;

        public function Main() {
            // 1. Setup Layar agar tidak gepeng (Responsive)
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            // Listen for stage resize
            stage.addEventListener(Event.RESIZE, onStageResize);

            // 2. Initialize core components
            initializeComponents();

            // 3. Cek Platform (optional debug)
            var platform:String = Capabilities.version;
            StimulusConfig.updateForStageSize(stage.stageWidth, stage.stageHeight);
            if (DEBUG) {
                trace("===== APPLICATION STARTED =====");
                trace("Platform: " + platform);
                trace("Stage Size: " + stage.stageWidth + "x" + stage.stageHeight);
                trace("==============================");
            }
        }

        private function onStageResize(event:Event):void {
            if (DEBUG) {
                trace("Stage resized to: " + stage.stageWidth + "x" + stage.stageHeight);
            }
            // Update HUD and other components if needed
            if (_hud) {
                _hud.onResize();
            }
        }

        private function initializeComponents():void {
            // Initialize HUD with stage dimensions
            _hud = new HUD();
            _hud.initialize(stage.stageWidth, stage.stageHeight);
            _hud.addEventListener(HUD.START_TRIAL, onStartTrial);
            addChild(_hud);

            // Initialize game controller
            _gameController = GameController.getInstance();
            _gameController.initialize(_hud);

            // Initialize sequence generator
            _sequenceGenerator = new SequenceGenerator();

            // TODO: Initialize stimulus view (Area 2)
            // _stimulusView = new StimulusView();
            // _stimulusView.addEventListener(StimulusView.PRESENTATION_COMPLETE, onStimulusComplete);
            // addChild(_stimulusView);

            // Initialize input manager
            _inputManager = InputManager.getInstance();
            addChild(_inputManager);

            // TODO: Initialize validator and game loop (Area 4)
            // _validator = new Validator();
            // _gameLoop = new GameLoop();
            // _gameLoop.onResult = onValidationResult;
        }

        private function onStartTrial(event:Event):void {
            // Trigger FSM to start new trial
            _gameController.startNextTrial();
        }

        // TODO: Implement when StimulusView is ready (Area 2)
        // private function onStimulusComplete(event:*):void {
        //     // Start input phase
        //     _inputManager.startInputPhase(onInputReceived, onInputTimeout, 5000);
        // }

        // TODO: Implement when GameLoop is ready (Area 4)
        // private function onInputReceived(inputBuffer:Vector.<int>):void {
        //     // Validate input
        //     _gameLoop.processTrial(inputBuffer, _currentSequence);
        // }

        // TODO: Implement when GameLoop is ready (Area 4)
        // private function onInputTimeout():void {
        //     // Timeout - treat as incorrect
        //     var emptyInput:Vector.<int> = new Vector.<int>();
        //     _gameLoop.processTrial(emptyInput, _currentSequence);
        // }

        // TODO: Implement when GameLoop is ready (Area 4)
        // private function onValidationResult(result:ValidationResult):void {
        //     // Handle result
        //     trace("Trial completed. Score: " + _gameLoop.getCurrentScore());
        // }
    }
}