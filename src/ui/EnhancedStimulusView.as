package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.filters.GlowFilter;
    import flash.filters.BlurFilter;
    import domain.StimulusItem;
    import config.VisualConfig;
    
    /**
     * EnhancedStimulusView - Advanced stimulus presentation with animations.
     * Features: Fade in/out, scale animations, glow effects, progress indicator, focus mode.
     * 
     * T1-063, T1-064, T1-065, T1-066
     */
    public class EnhancedStimulusView extends Sprite {
        
        // Events
        public static const PRESENTATION_COMPLETE:String = "presentationComplete";
        public static const ITEM_SHOWN:String = "itemShown";
        public static const ITEM_HIDDEN:String = "itemHidden";
        
        // Animation states
        private static const STATE_IDLE:String = "idle";
        private static const STATE_FADE_IN:String = "fadeIn";
        private static const STATE_SHOWING:String = "showing";
        private static const STATE_FADE_OUT:String = "fadeOut";
        private static const STATE_INTERVAL:String = "interval";
        
        // Configuration
        private var _showDuration:int = 800;
        private var _fadeInDuration:int = 200;
        private var _fadeOutDuration:int = 150;
        private var _intervalDuration:int = 300;
        private var _stimulusSize:Number = 80;
        private var _centerX:Number = 400;
        private var _centerY:Number = 300;
        
        // Queue
        private var _queue:Vector.<StimulusItem>;
        private var _currentIndex:int = 0;
        
        // State
        private var _state:String = STATE_IDLE;
        private var _animationTimer:Timer;
        private var _animationProgress:Number = 0;
        
        // Visual elements
        private var _container:Sprite;
        private var _shapeRenderer:ShapeRenderer;
        private var _progressIndicator:Sprite;
        private var _progressDots:Array;
        private var _focusOverlay:Shape;
        
        // Animation state
        private var _targetAlpha:Number = 1;
        private var _targetScale:Number = 1;
        private var _startAlpha:Number = 0;
        private var _startScale:Number = 0.5;
        
        // Focus mode
        private var _focusModeEnabled:Boolean = false;
        
        /**
         * Constructor
         */
        public function EnhancedStimulusView() {
            _queue = new Vector.<StimulusItem>();
            _progressDots = [];
            
            createContainer();
            createProgressIndicator();
            createFocusOverlay();
        }
        
        /**
         * Create main container
         */
        private function createContainer():void {
            _container = new Sprite();
            addChild(_container);
        }
        
        /**
         * Create progress indicator (dots)
         */
        private function createProgressIndicator():void {
            _progressIndicator = new Sprite();
            _progressIndicator.visible = false;
            addChild(_progressIndicator);
        }
        
        /**
         * Create focus mode overlay (dim background)
         */
        private function createFocusOverlay():void {
            _focusOverlay = new Shape();
            _focusOverlay.visible = false;
            addChildAt(_focusOverlay, 0);
        }
        
        /**
         * Configure the view
         */
        public function configure(
            centerX:Number, 
            centerY:Number, 
            stimulusSize:Number = 80,
            showDuration:int = 800,
            fadeInDuration:int = 200,
            fadeOutDuration:int = 150,
            intervalDuration:int = 300
        ):void {
            _centerX = centerX;
            _centerY = centerY;
            _stimulusSize = stimulusSize;
            _showDuration = showDuration;
            _fadeInDuration = fadeInDuration;
            _fadeOutDuration = fadeOutDuration;
            _intervalDuration = intervalDuration;
            
            _container.x = _centerX;
            _container.y = _centerY;
        }
        
        /**
         * Present a sequence of stimulus items
         */
        public function presentSequence(sequence:Vector.<StimulusItem>):void {
            _queue = sequence;
            _currentIndex = 0;
            
            // Setup progress indicator
            updateProgressIndicator();
            _progressIndicator.visible = true;
            
            // Enable focus mode if configured
            if (_focusModeEnabled) {
                showFocusOverlay();
            }
            
            // Start presenting
            presentNextItem();
        }
        
        /**
         * Present the next item
         */
        private function presentNextItem():void {
            if (_currentIndex >= _queue.length) {
                // Complete
                onSequenceComplete();
                return;
            }
            
            var item:StimulusItem = _queue[_currentIndex];
            
            // Record shown time
            item.shownAt = new Date().getTime();
            
            // Create shape renderer for this item
            createShapeForItem(item);
            
            // Update progress dots
            highlightProgressDot(_currentIndex);
            
            // Start fade in
            startFadeIn();
        }
        
        /**
         * Create shape renderer for item
         */
        private function createShapeForItem(item:StimulusItem):void {
            // Clear previous
            while (_container.numChildren > 0) {
                _container.removeChildAt(0);
            }
            
            _shapeRenderer = new ShapeRenderer(item.shape, item.color, _stimulusSize);
            _shapeRenderer.alpha = 0;
            _shapeRenderer.scaleX = 0.5;
            _shapeRenderer.scaleY = 0.5;
            
            _container.addChild(_shapeRenderer);
        }
        
        // ============ ANIMATION STATES ============
        
        private function startFadeIn():void {
            _state = STATE_FADE_IN;
            _startAlpha = 0;
            _targetAlpha = 1;
            _startScale = 0.5;
            _targetScale = 1.0;
            _animationProgress = 0;
            
            startAnimation(_fadeInDuration);
        }
        
        private function startShowing():void {
            _state = STATE_SHOWING;
            
            // Apply glow during show
            if (_shapeRenderer) {
                _shapeRenderer.setGlow(VisualConfig.GLOW_HIGHLIGHT, 10, 1.5);
            }
            
            dispatchEvent(new Event(ITEM_SHOWN));
            
            // Wait for show duration
            _animationTimer = new Timer(_showDuration, 1);
            _animationTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onShowComplete);
            _animationTimer.start();
        }
        
        private function startFadeOut():void {
            _state = STATE_FADE_OUT;
            _startAlpha = 1;
            _targetAlpha = 0;
            _startScale = 1.0;
            _targetScale = 0.8;
            _animationProgress = 0;
            
            if (_shapeRenderer) {
                _shapeRenderer.removeGlow();
            }
            
            startAnimation(_fadeOutDuration);
        }
        
        private function startInterval():void {
            _state = STATE_INTERVAL;
            
            dispatchEvent(new Event(ITEM_HIDDEN));
            
            // Clear display
            while (_container.numChildren > 0) {
                _container.removeChildAt(0);
            }
            
            // Wait for interval
            _animationTimer = new Timer(_intervalDuration, 1);
            _animationTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onIntervalComplete);
            _animationTimer.start();
        }
        
        // ============ ANIMATION ENGINE ============
        
        private function startAnimation(duration:int):void {
            if (_animationTimer) {
                _animationTimer.stop();
            }
            
            // Use ENTER_FRAME for smooth animation
            addEventListener(Event.ENTER_FRAME, onAnimationFrame);
            
            // Timer for completion
            _animationTimer = new Timer(duration, 1);
            _animationTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAnimationComplete);
            _animationTimer.start();
        }
        
        private function onAnimationFrame(e:Event):void {
            if (!_shapeRenderer) return;
            
            // Calculate progress (0 to 1)
            var elapsed:Number = _animationTimer.currentCount > 0 ? 
                                 _animationTimer.delay : 
                                 _animationTimer.delay - (_animationTimer.delay - 
                                 (_animationTimer.currentCount * _animationTimer.delay));
            
            // Smooth easing
            _animationProgress += 0.1;
            if (_animationProgress > 1) _animationProgress = 1;
            
            var eased:Number = easeOutCubic(_animationProgress);
            
            // Apply interpolation
            _shapeRenderer.alpha = _startAlpha + (_targetAlpha - _startAlpha) * eased;
            var scale:Number = _startScale + (_targetScale - _startScale) * eased;
            _shapeRenderer.scaleX = scale;
            _shapeRenderer.scaleY = scale;
        }
        
        private function onAnimationComplete(e:TimerEvent):void {
            removeEventListener(Event.ENTER_FRAME, onAnimationFrame);
            
            // Apply final values
            if (_shapeRenderer) {
                _shapeRenderer.alpha = _targetAlpha;
                _shapeRenderer.scaleX = _targetScale;
                _shapeRenderer.scaleY = _targetScale;
            }
            
            // Transition to next state
            switch (_state) {
                case STATE_FADE_IN:
                    startShowing();
                    break;
                case STATE_FADE_OUT:
                    startInterval();
                    break;
            }
        }
        
        private function onShowComplete(e:TimerEvent):void {
            startFadeOut();
        }
        
        private function onIntervalComplete(e:TimerEvent):void {
            _currentIndex++;
            presentNextItem();
        }
        
        private function onSequenceComplete():void {
            _state = STATE_IDLE;
            _progressIndicator.visible = false;
            
            if (_focusModeEnabled) {
                hideFocusOverlay();
            }
            
            dispatchEvent(new Event(PRESENTATION_COMPLETE));
        }
        
        // ============ PROGRESS INDICATOR ============
        
        private function updateProgressIndicator():void {
            // Clear previous dots
            while (_progressIndicator.numChildren > 0) {
                _progressIndicator.removeChildAt(0);
            }
            _progressDots = [];
            
            var dotSize:Number = 8;
            var gap:Number = 12;
            var totalWidth:Number = _queue.length * dotSize + (_queue.length - 1) * gap;
            var startX:Number = _centerX - totalWidth / 2;
            var dotY:Number = _centerY + _stimulusSize + 30;
            
            for (var i:int = 0; i < _queue.length; i++) {
                var dot:Shape = new Shape();
                var g:* = dot.graphics;
                
                g.beginFill(0xCCCCCC);
                g.drawCircle(0, 0, dotSize / 2);
                g.endFill();
                
                dot.x = startX + i * (dotSize + gap) + dotSize / 2;
                dot.y = dotY;
                
                _progressIndicator.addChild(dot);
                _progressDots.push(dot);
            }
        }
        
        private function highlightProgressDot(index:int):void {
            for (var i:int = 0; i < _progressDots.length; i++) {
                var dot:Shape = _progressDots[i];
                var g:* = dot.graphics;
                g.clear();
                
                if (i < index) {
                    // Completed
                    g.beginFill(0x4CAF50);
                } else if (i == index) {
                    // Current
                    g.beginFill(0x2196F3);
                    dot.scaleX = 1.3;
                    dot.scaleY = 1.3;
                } else {
                    // Upcoming
                    g.beginFill(0xCCCCCC);
                    dot.scaleX = 1;
                    dot.scaleY = 1;
                }
                
                g.drawCircle(0, 0, 4);
                g.endFill();
            }
        }
        
        // ============ FOCUS MODE ============
        
        public function enableFocusMode(enabled:Boolean):void {
            _focusModeEnabled = enabled;
        }
        
        private function showFocusOverlay():void {
            var g:* = _focusOverlay.graphics;
            g.clear();
            g.beginFill(0x000000, 0.5);
            g.drawRect(-1000, -1000, 3000, 3000);
            g.endFill();
            
            // Cut out center area
            // (In full implementation, use a mask or blend mode)
            
            _focusOverlay.visible = true;
        }
        
        private function hideFocusOverlay():void {
            _focusOverlay.visible = false;
        }
        
        // ============ EASING FUNCTIONS ============
        
        private function easeOutCubic(t:Number):Number {
            return 1 - Math.pow(1 - t, 3);
        }
        
        private function easeInOutQuad(t:Number):Number {
            return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
        }
        
        // ============ CONTROL ============
        
        /**
         * Stop presentation
         */
        public function stopPresentation():void {
            if (_animationTimer) {
                _animationTimer.stop();
                _animationTimer = null;
            }
            
            removeEventListener(Event.ENTER_FRAME, onAnimationFrame);
            
            while (_container.numChildren > 0) {
                _container.removeChildAt(0);
            }
            
            _progressIndicator.visible = false;
            _focusOverlay.visible = false;
            _state = STATE_IDLE;
        }
        
        /**
         * Pause presentation
         */
        public function pausePresentation():void {
            if (_animationTimer) {
                _animationTimer.stop();
            }
            removeEventListener(Event.ENTER_FRAME, onAnimationFrame);
        }
        
        /**
         * Resume presentation
         */
        public function resumePresentation():void {
            if (_animationTimer) {
                _animationTimer.start();
            }
            addEventListener(Event.ENTER_FRAME, onAnimationFrame);
        }
        
        // ============ GETTERS ============
        
        public function get currentIndex():int { return _currentIndex; }
        public function get totalItems():int { return _queue ? _queue.length : 0; }
        public function get isPresenting():Boolean { return _state != STATE_IDLE; }
        public function get state():String { return _state; }
    }
}
