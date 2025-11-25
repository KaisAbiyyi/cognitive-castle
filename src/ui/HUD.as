package ui {

    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.SimpleButton;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import flash.events.MouseEvent;

    /**
     * HUD - Heads-Up Display component showing game state and instructions.
     * Displays score, level, phase instructions, and state guidance.
     *
     * SOLID Principles:
     * - Single Responsibility: Only handles UI display and updates
     * - Open/Closed: Can be extended with new display elements without changing existing code
     * - Interface Segregation: Provides focused UI update methods
     */
    public class HUD extends Sprite {

        // Text fields
        private var _scoreText:TextField;
        private var _levelText:TextField;
        private var _instructionText:TextField;
        private var _stateText:TextField;
        private var _startButton:flash.display.SimpleButton;

        // Current values
        private var _currentScore:int = 0;
        private var _currentLevel:int = 1;
        private var _currentSpan:int = 2;

        // Stage dimensions
        private var _stageWidth:Number = 1920;
        private var _stageHeight:Number = 1080;

        // Layout constants
        private const PADDING:int = 20;
        private const FONT_SIZE:int = 24;
        private const SMALL_FONT_SIZE:int = 18;
        
        // Events
        public static const START_TRIAL:String = "startTrial";

        /**
         * Constructor
         */
        public function HUD() {
            initializeTextFields();
        }

        /**
         * Initialize the HUD with stage dimensions
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            drawBackground(stageWidth, stageHeight);
            createStartButton(stageWidth, stageHeight);
            layoutComponents(stageWidth, stageHeight);
            updateDisplay();
        }

        /**
         * Initialize text field components
         */
        private function initializeTextFields():void {
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = FONT_SIZE;
            format.color = 0xFFFFFF;
            format.bold = true;

            var smallFormat:TextFormat = new TextFormat();
            smallFormat.font = "Arial";
            smallFormat.size = SMALL_FONT_SIZE;
            smallFormat.color = 0xFFFFFF;

            // Score display (top left)
            _scoreText = new TextField();
            _scoreText.defaultTextFormat = format;
            _scoreText.autoSize = TextFieldAutoSize.LEFT;
            _scoreText.selectable = false;
            addChild(_scoreText);

            // Level/Span display (top right)
            _levelText = new TextField();
            _levelText.defaultTextFormat = format;
            _levelText.autoSize = TextFieldAutoSize.RIGHT;
            _levelText.selectable = false;
            addChild(_levelText);

            // State text (center top)
            _stateText = new TextField();
            _stateText.defaultTextFormat = format;
            _stateText.autoSize = TextFieldAutoSize.CENTER;
            _stateText.selectable = false;
            addChild(_stateText);

            // Instruction text (bottom center)
            _instructionText = new TextField();
            _instructionText.defaultTextFormat = smallFormat;
            _instructionText.autoSize = TextFieldAutoSize.CENTER;
            _instructionText.multiline = true;
            _instructionText.wordWrap = true;
            _instructionText.selectable = false;
            addChild(_instructionText);
        }

        /**
         * Draw background
         */
        private function drawBackground(stageWidth:Number, stageHeight:Number):void {
            graphics.beginFill(0x1a1a2e, 1);
            graphics.drawRect(0, 0, stageWidth, stageHeight);
            graphics.endFill();
        }

        /**
         * Create start button
         */
        private function createStartButton(stageWidth:Number, stageHeight:Number):void {
            var upState:Sprite = createButtonState(0x4a90e2, "START");
            var overState:Sprite = createButtonState(0x357abd, "START");
            var downState:Sprite = createButtonState(0x1a4d7f, "START");

            _startButton = new SimpleButton(upState, overState, downState, upState);
            _startButton.x = (stageWidth - 200) / 2;
            _startButton.y = (stageHeight - 60) / 2;
            _startButton.addEventListener(MouseEvent.CLICK, onStartButtonClick);
            addChild(_startButton);
        }

        /**
         * Create a button state sprite
         */
        private function createButtonState(color:uint, label:String):Sprite {
            var sprite:Sprite = new Sprite();
            sprite.graphics.beginFill(color, 1);
            sprite.graphics.drawRect(0, 0, 200, 60);
            sprite.graphics.endFill();

            var textField:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 20;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;

            textField.defaultTextFormat = format;
            textField.text = label;
            textField.width = 200;
            textField.height = 60;
            textField.y = 15;
            textField.selectable = false;

            sprite.addChild(textField);
            return sprite;
        }

        /**
         * Start button click handler
         */
        private function onStartButtonClick(event:MouseEvent):void {
            dispatchEvent(new Event(START_TRIAL));
            _startButton.visible = false;
        }

        /**
         * Layout components on stage
         */
        private function layoutComponents(stageWidth:Number, stageHeight:Number):void {
            // Score - top left
            _scoreText.x = PADDING;
            _scoreText.y = PADDING;

            // Level - top right
            _levelText.x = stageWidth - _levelText.width - PADDING;
            _levelText.y = PADDING;

            // State text - center top
            _stateText.x = (stageWidth - _stateText.width) / 2;
            _stateText.y = PADDING * 2;

            // Instructions - bottom center
            _instructionText.x = (stageWidth - _instructionText.width) / 2;
            _instructionText.y = stageHeight - _instructionText.height - PADDING;
            _instructionText.width = stageWidth - PADDING * 2;
        }

        /**
         * Update all display text
         */
        private function updateDisplay():void {
            _scoreText.text = "Score: " + _currentScore;
            _levelText.text = "Level: " + _currentLevel + " (Span: " + _currentSpan + ")";
            layoutComponents(_stageWidth, _stageHeight);
        }

        /**
         * Set the current score
         * @param score New score value
         */
        public function setScore(score:int):void {
            _currentScore = score;
            updateDisplay();
        }

        /**
         * Set the current level
         * @param level New level value
         */
        public function setLevel(level:int):void {
            _currentLevel = level;
            updateDisplay();
        }

        /**
         * Set the current span length
         * @param span New span value
         */
        public function setSpan(span:int):void {
            _currentSpan = span;
            updateDisplay();
        }

        /**
         * Set the current game phase state text
         * @param stateText Text describing current phase (e.g., "Ready", "Observe", "Answer")
         */
        public function setStateText(stateText:String):void {
            _stateText.text = stateText;
            layoutComponents(_stageWidth, _stageHeight);
        }

        /**
         * Set instruction text
         * @param instruction Detailed instructions for the user
         */
        public function setInstructionText(instruction:String):void {
            _instructionText.text = instruction;
            layoutComponents(_stageWidth, _stageHeight);
        }

        /**
         * Handle stage resize
         */
        public function onResize():void {
            layoutComponents(_stageWidth, _stageHeight);
        }

        /**
         * Get current score
         * @return Current score
         */
        public function getScore():int {
            return _currentScore;
        }

        /**
         * Get current level
         * @return Current level
         */
        public function getLevel():int {
            return _currentLevel;
        }

        /**
         * Get current span
         * @return Current span
         */
        public function getSpan():int {
            return _currentSpan;
        }
    }
}