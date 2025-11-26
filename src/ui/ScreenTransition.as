package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.filters.BlurFilter;
    
    /**
     * ScreenTransition - Handles screen transitions with various effects.
     * Effects: Fade, Slide, Zoom
     * 
     * T1-083
     */
    public class ScreenTransition extends Sprite {
        
        // Transition types
        public static const FADE:String = "fade";
        public static const SLIDE_LEFT:String = "slideLeft";
        public static const SLIDE_RIGHT:String = "slideRight";
        public static const SLIDE_UP:String = "slideUp";
        public static const SLIDE_DOWN:String = "slideDown";
        public static const ZOOM_IN:String = "zoomIn";
        public static const ZOOM_OUT:String = "zoomOut";
        
        // Events
        public static const TRANSITION_COMPLETE:String = "transitionComplete";
        public static const TRANSITION_MID:String = "transitionMid";
        
        // Overlay for fade effect
        private var _overlay:Shape;
        private var _overlayColor:uint = 0x000000;
        
        // Animation
        private var _duration:int = 300;
        private var _progress:Number = 0;
        private var _transitionType:String;
        private var _transitionIn:Boolean = true;
        
        // Screen dimensions
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Target display object
        private var _target:DisplayObject;
        private var _originalX:Number;
        private var _originalY:Number;
        private var _originalScaleX:Number;
        private var _originalScaleY:Number;
        private var _originalAlpha:Number;
        
        /**
         * Constructor
         */
        public function ScreenTransition(stageWidth:Number, stageHeight:Number) {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            createOverlay();
        }
        
        /**
         * Create fade overlay
         */
        private function createOverlay():void {
            _overlay = new Shape();
            _overlay.alpha = 0;
            _overlay.visible = false;
            addChild(_overlay);
            
            drawOverlay();
        }
        
        private function drawOverlay():void {
            _overlay.graphics.clear();
            _overlay.graphics.beginFill(_overlayColor);
            _overlay.graphics.drawRect(0, 0, _stageWidth, _stageHeight);
            _overlay.graphics.endFill();
        }
        
        /**
         * Set overlay color
         */
        public function setOverlayColor(color:uint):void {
            _overlayColor = color;
            drawOverlay();
        }
        
        /**
         * Play transition out (hide screen)
         */
        public function transitionOut(type:String = FADE, target:DisplayObject = null, duration:int = 300):void {
            _transitionType = type;
            _duration = duration;
            _transitionIn = false;
            _target = target;
            _progress = 0;
            
            if (_target) {
                saveOriginalProperties();
            }
            
            if (type == FADE) {
                _overlay.visible = true;
                _overlay.alpha = 0;
            }
            
            addEventListener(Event.ENTER_FRAME, onTransitionFrame);
        }
        
        /**
         * Play transition in (show screen)
         */
        public function transitionIn(type:String = FADE, target:DisplayObject = null, duration:int = 300):void {
            _transitionType = type;
            _duration = duration;
            _transitionIn = true;
            _target = target;
            _progress = 0;
            
            if (_target) {
                saveOriginalProperties();
                setupInitialState();
            }
            
            if (type == FADE) {
                _overlay.visible = true;
                _overlay.alpha = 1;
            }
            
            addEventListener(Event.ENTER_FRAME, onTransitionFrame);
        }
        
        /**
         * Save original properties of target
         */
        private function saveOriginalProperties():void {
            _originalX = _target.x;
            _originalY = _target.y;
            _originalScaleX = _target.scaleX;
            _originalScaleY = _target.scaleY;
            _originalAlpha = _target.alpha;
        }
        
        /**
         * Setup initial state for transition in
         */
        private function setupInitialState():void {
            switch (_transitionType) {
                case SLIDE_LEFT:
                    _target.x = _stageWidth;
                    break;
                case SLIDE_RIGHT:
                    _target.x = -_stageWidth;
                    break;
                case SLIDE_UP:
                    _target.y = _stageHeight;
                    break;
                case SLIDE_DOWN:
                    _target.y = -_stageHeight;
                    break;
                case ZOOM_IN:
                    _target.scaleX = 0;
                    _target.scaleY = 0;
                    _target.alpha = 0;
                    break;
                case ZOOM_OUT:
                    _target.scaleX = 2;
                    _target.scaleY = 2;
                    _target.alpha = 0;
                    break;
            }
        }
        
        /**
         * Animation frame handler
         */
        private function onTransitionFrame(e:Event):void {
            // Increment progress (60fps assumed)
            _progress += (1000 / 60) / _duration;
            
            if (_progress >= 1) {
                _progress = 1;
                removeEventListener(Event.ENTER_FRAME, onTransitionFrame);
            }
            
            // Apply easing
            var eased:Number = easeInOutQuad(_progress);
            
            // Apply transition
            if (_transitionIn) {
                applyTransitionIn(eased);
            } else {
                applyTransitionOut(eased);
            }
            
            // Dispatch mid event
            if (_progress >= 0.5 && _progress < 0.55) {
                dispatchEvent(new Event(TRANSITION_MID));
            }
            
            // Complete
            if (_progress >= 1) {
                onTransitionComplete();
            }
        }
        
        /**
         * Apply transition in effect
         */
        private function applyTransitionIn(progress:Number):void {
            switch (_transitionType) {
                case FADE:
                    _overlay.alpha = 1 - progress;
                    if (_target) _target.alpha = _originalAlpha * progress;
                    break;
                    
                case SLIDE_LEFT:
                    if (_target) _target.x = _stageWidth + (_originalX - _stageWidth) * progress;
                    break;
                    
                case SLIDE_RIGHT:
                    if (_target) _target.x = -_stageWidth + (_originalX + _stageWidth) * progress;
                    break;
                    
                case SLIDE_UP:
                    if (_target) _target.y = _stageHeight + (_originalY - _stageHeight) * progress;
                    break;
                    
                case SLIDE_DOWN:
                    if (_target) _target.y = -_stageHeight + (_originalY + _stageHeight) * progress;
                    break;
                    
                case ZOOM_IN:
                    if (_target) {
                        _target.scaleX = _originalScaleX * progress;
                        _target.scaleY = _originalScaleY * progress;
                        _target.alpha = _originalAlpha * progress;
                    }
                    break;
                    
                case ZOOM_OUT:
                    if (_target) {
                        _target.scaleX = 2 + (_originalScaleX - 2) * progress;
                        _target.scaleY = 2 + (_originalScaleY - 2) * progress;
                        _target.alpha = _originalAlpha * progress;
                    }
                    break;
            }
        }
        
        /**
         * Apply transition out effect
         */
        private function applyTransitionOut(progress:Number):void {
            switch (_transitionType) {
                case FADE:
                    _overlay.alpha = progress;
                    if (_target) _target.alpha = _originalAlpha * (1 - progress);
                    break;
                    
                case SLIDE_LEFT:
                    if (_target) _target.x = _originalX - _stageWidth * progress;
                    break;
                    
                case SLIDE_RIGHT:
                    if (_target) _target.x = _originalX + _stageWidth * progress;
                    break;
                    
                case SLIDE_UP:
                    if (_target) _target.y = _originalY - _stageHeight * progress;
                    break;
                    
                case SLIDE_DOWN:
                    if (_target) _target.y = _originalY + _stageHeight * progress;
                    break;
                    
                case ZOOM_IN:
                    if (_target) {
                        _target.scaleX = _originalScaleX + progress;
                        _target.scaleY = _originalScaleY + progress;
                        _target.alpha = _originalAlpha * (1 - progress);
                    }
                    break;
                    
                case ZOOM_OUT:
                    if (_target) {
                        _target.scaleX = _originalScaleX * (1 - progress);
                        _target.scaleY = _originalScaleY * (1 - progress);
                        _target.alpha = _originalAlpha * (1 - progress);
                    }
                    break;
            }
        }
        
        /**
         * Handle transition complete
         */
        private function onTransitionComplete():void {
            if (_transitionType == FADE && _transitionIn) {
                _overlay.visible = false;
            }
            
            // Restore original properties if transitioning in
            if (_transitionIn && _target) {
                _target.x = _originalX;
                _target.y = _originalY;
                _target.scaleX = _originalScaleX;
                _target.scaleY = _originalScaleY;
                _target.alpha = _originalAlpha;
            }
            
            dispatchEvent(new Event(TRANSITION_COMPLETE));
        }
        
        /**
         * Easing function
         */
        private function easeInOutQuad(t:Number):Number {
            return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
        }
        
        /**
         * Update dimensions on resize
         */
        public function resize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            drawOverlay();
        }
    }
}
