package ui {

    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import flash.events.Event;
    import config.StimulusConfig;
    import domain.StimulusItem;

    /**
     * StimulusView - Handles the visual presentation of stimulus sequences.
     * Renders items sequentially in the center of the screen with timing controls.
     *
     * SOLID Principles:
     * - Single Responsibility: Only handles stimulus presentation and rendering
     * - Open/Closed: Can be extended with new animation types without changing existing code
     * - Dependency Inversion: Depends on abstractions (StimulusConfig, StimulusItem)
     */
    public class StimulusView extends Sprite {

        private var _stimulusQueue:Vector.<StimulusItem>;
        private var _currentIndex:int = 0;
        private var _presentationTimer:Timer;
        private var _currentShape:Shape;
        private var _debugText:TextField;

        // Events
        public static const PRESENTATION_COMPLETE:String = "presentationComplete";

        /**
         * Constructor
         */
        public function StimulusView() {
            initializeView();
        }

        /**
         * Initialize the view components
         */
        private function initializeView():void {
            // Create debug text field
            if (StimulusConfig.SHOW_DEBUG_OVERLAY) {
                _debugText = new TextField();
                var format:TextFormat = new TextFormat();
                format.size = 20;
                format.color = 0xFFFFFF;
                _debugText.defaultTextFormat = format;
                _debugText.x = 10;
                _debugText.y = 10;
                _debugText.width = 200;
                _debugText.height = 30;
                addChild(_debugText);
            }
        }

        /**
         * Present a sequence of stimulus items
         * @param sequence Vector of StimulusItem to present
         */
        public function presentSequence(sequence:Vector.<StimulusItem>):void {
            _stimulusQueue = sequence;
            _currentIndex = 0;

            // Clear previous stimulus
            clearCurrentStimulus();

            // Start presentation
            presentNextItem();
        }

        /**
         * Present the next item in the queue
         */
        private function presentNextItem():void {
            if (_currentIndex >= _stimulusQueue.length) {
                // Sequence complete
                dispatchEvent(new Event(PRESENTATION_COMPLETE));
                return;
            }

            var item:StimulusItem = _stimulusQueue[_currentIndex];

            // Update debug text
            if (_debugText) {
                _debugText.text = (_currentIndex + 1) + " / " + _stimulusQueue.length;
            }

            // Render the stimulus
            renderStimulus(item);

            // Start timer for show duration
            _presentationTimer = new Timer(StimulusConfig.SHOW_DURATION, 1);
            _presentationTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onShowComplete);
            _presentationTimer.start();

            _currentIndex++;
        }

        /**
         * Render a stimulus item visually
         * @param item The stimulus item to render
         */
        private function renderStimulus(item:StimulusItem):void {
            clearCurrentStimulus();

            _currentShape = new Shape();
            _currentShape.x = StimulusConfig.CENTER_X;
            _currentShape.y = StimulusConfig.CENTER_Y;

            var graphics:* = _currentShape.graphics;
            graphics.beginFill(item.color);

            // Draw based on shape
            switch (item.shape) {
                case "circle":
                    graphics.drawCircle(0, 0, StimulusConfig.STIMULUS_SIZE / 2);
                    break;
                case "square":
                    graphics.drawRect(-StimulusConfig.STIMULUS_SIZE / 2, -StimulusConfig.STIMULUS_SIZE / 2,
                                     StimulusConfig.STIMULUS_SIZE, StimulusConfig.STIMULUS_SIZE);
                    break;
                case "triangle":
                    graphics.moveTo(0, -StimulusConfig.STIMULUS_SIZE / 2);
                    graphics.lineTo(-StimulusConfig.STIMULUS_SIZE / 2, StimulusConfig.STIMULUS_SIZE / 2);
                    graphics.lineTo(StimulusConfig.STIMULUS_SIZE / 2, StimulusConfig.STIMULUS_SIZE / 2);
                    graphics.lineTo(0, -StimulusConfig.STIMULUS_SIZE / 2);
                    break;
                // Add more shapes as needed
                default:
                    graphics.drawCircle(0, 0, StimulusConfig.STIMULUS_SIZE / 2);
                    break;
            }

            graphics.endFill();
            addChild(_currentShape);

            // Simple fade in animation (placeholder)
            _currentShape.alpha = 0;
            // In real implementation, use TweenLite or similar for smooth animation
            _currentShape.alpha = 1;
        }

        /**
         * Handle show duration complete
         * @param event Timer event
         */
        private function onShowComplete(event:TimerEvent):void {
            // Fade out
            if (_currentShape) {
                _currentShape.alpha = 0;
            }

            // Start inter-stimulus interval
            _presentationTimer = new Timer(StimulusConfig.INTER_STIMULUS_INTERVAL, 1);
            _presentationTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onIntervalComplete);
            _presentationTimer.start();
        }

        /**
         * Handle inter-stimulus interval complete
         * @param event Timer event
         */
        private function onIntervalComplete(event:TimerEvent):void {
            presentNextItem();
        }

        /**
         * Clear the current stimulus display
         */
        private function clearCurrentStimulus():void {
            if (_currentShape && contains(_currentShape)) {
                removeChild(_currentShape);
            }
            _currentShape = null;
        }

        /**
         * Stop presentation (for cleanup)
         */
        public function stopPresentation():void {
            if (_presentationTimer) {
                _presentationTimer.stop();
                _presentationTimer = null;
            }
            clearCurrentStimulus();
        }
    }
}