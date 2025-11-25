package {

    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldAutoSize;

    /**
     * HUD - Heads-Up Display component showing game state and instructions.
     * Displays score, level, phase instructions, and state guidance.
     */
    public class HUD extends Sprite {

        // Text fields
        private var _scoreText:TextField;
        private var _levelText:TextField;
        private var _instructionText:TextField;
        private var _stateText:TextField;

        // Current values
        private var _currentScore:int = 0;
        private var _currentLevel:int = 1;
        private var _currentSpan:int = 2;

        // Layout constants
        private const PADDING:int = 20;
        private const FONT_SIZE:int = 24;
        private const SMALL_FONT_SIZE:int = 18;

        /**
         * Constructor
         */
        public function HUD() {
            initializeTextFields();
            layoutComponents();
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
         * Layout components on stage
         */
        private function layoutComponents():void {
            if (!stage) return;

            var stageWidth:int = stage.stageWidth;
            var stageHeight:int = stage.stageHeight;

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
            layoutComponents();
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
            layoutComponents();
        }

        /**
         * Set instruction text
         * @param instruction Detailed instructions for the user
         */
        public function setInstructionText(instruction:String):void {
            _instructionText.text = instruction;
            layoutComponents();
        }

        /**
         * Handle stage resize
         */
        public function onResize():void {
            layoutComponents();
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