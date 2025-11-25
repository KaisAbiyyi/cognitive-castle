package {
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.system.Capabilities;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.MouseEvent;

    public class Main extends Sprite {
        private var _sequenceGenerator:SequenceGenerator;
        private var _stimulusView:StimulusView;
        private var _inputManager:InputManager;
        private var _validator:Validator;
        private var _gameLoop:GameLoop;
        private var _currentSequence:Vector.<StimulusItem>;

        public function Main() {
            // 1. Setup Layar agar tidak gepeng (Responsive)
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;

            // 2. Initialize core components
            initializeComponents();

            // 3. Add start button for demo
            var startButton:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.size = 30;
            format.color = 0x0000FF;
            
            startButton.defaultTextFormat = format;
            startButton.text = "Start Trial";
            startButton.width = 200;
            startButton.height = 50;
            startButton.x = 300;
            startButton.y = 500;
            startButton.selectable = false;
            startButton.addEventListener(MouseEvent.CLICK, onStartClick);
            addChild(startButton);

            // 4. Cek Platform (optional debug)
            var platform:String = Capabilities.version;
            StimulusConfig.updateForStageSize(stage.stageWidth, stage.stageHeight);
            trace("Platform: " + platform + ", Resolution: " + stage.stageWidth + "x" + stage.stageHeight);
        }

        private function initializeComponents():void {
            // Initialize sequence generator
            _sequenceGenerator = new SequenceGenerator();

            // Initialize stimulus view
            _stimulusView = new StimulusView();
            _stimulusView.addEventListener(StimulusView.PRESENTATION_COMPLETE, onStimulusComplete);
            addChild(_stimulusView);

            // Initialize input manager
            _inputManager = InputManager.getInstance();
            addChild(_inputManager);

            // Initialize validator
            _validator = new Validator();

            // Initialize game loop
            _gameLoop = new GameLoop();
            _gameLoop.onResult = onValidationResult;
        }

        private function onStartClick(event:MouseEvent):void {
            startTrial();
        }

        private function startTrial():void {
            // Generate sequence
            _currentSequence = _sequenceGenerator.generateSequence(1); // Level 1 for demo

            // Present sequence
            _stimulusView.presentSequence(_currentSequence);
        }

        private function onStimulusComplete(event:*):void {
            // Start input phase
            _inputManager.startInputPhase(onInputReceived, onInputTimeout, 5000);
        }

        private function onInputReceived(inputBuffer:Vector.<int>):void {
            // Validate input
            _gameLoop.processTrial(inputBuffer, _currentSequence);
        }

        private function onInputTimeout():void {
            // Timeout - treat as incorrect
            var emptyInput:Vector.<int> = new Vector.<int>();
            _gameLoop.processTrial(emptyInput, _currentSequence);
        }

        private function onValidationResult(result:ValidationResult):void {
            // Handle result
            trace("Trial completed. Score: " + _gameLoop.getCurrentScore());
        }
    }
}