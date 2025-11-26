package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Graphics;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.filters.GlowFilter;
    import flash.filters.DropShadowFilter;
    import config.VisualConfig;
    
    /**
     * InputButton - Interactive button with multiple states and feedback animations.
     * States: Normal, Hover, Pressed, Disabled, Correct, Wrong
     * 
     * T1-067, T1-068, T1-069, T1-070
     */
    public class InputButton extends Sprite {
        
        // Events
        public static const BUTTON_CLICKED:String = "buttonClicked";
        
        // States
        public static const STATE_NORMAL:String = "normal";
        public static const STATE_HOVER:String = "hover";
        public static const STATE_PRESSED:String = "pressed";
        public static const STATE_DISABLED:String = "disabled";
        public static const STATE_CORRECT:String = "correct";
        public static const STATE_WRONG:String = "wrong";
        
        // Visual properties
        private var _width:Number;
        private var _height:Number;
        private var _cornerRadius:Number = 8;
        private var _shape:String;
        private var _color:uint;
        private var _index:int;
        
        // State
        private var _state:String = STATE_NORMAL;
        private var _enabled:Boolean = true;
        private var _selected:Boolean = false;
        
        // Visual elements
        private var _background:Shape;
        private var _shapeRenderer:ShapeRenderer;
        private var _overlay:Shape;
        private var _feedbackTimer:Timer;
        
        // Colors
        private var _bgNormal:uint = 0xFFFFFF;
        private var _bgHover:uint = 0xF5F5F5;
        private var _bgPressed:uint = 0xE0E0E0;
        private var _bgDisabled:uint = 0xEEEEEE;
        private var _bgCorrect:uint = 0xE8F5E9;
        private var _bgWrong:uint = 0xFFEBEE;
        
        private var _borderNormal:uint = 0xCCCCCC;
        private var _borderHover:uint = 0x999999;
        private var _borderPressed:uint = 0x666666;
        private var _borderCorrect:uint = 0x4CAF50;
        private var _borderWrong:uint = 0xF44336;
        
        // Animation
        private var _animating:Boolean = false;
        private var _pulsePhase:Number = 0;
        
        /**
         * Constructor
         * @param index Button index (0-5)
         * @param width Button width
         * @param height Button height
         * @param shape Shape type
         * @param color Shape color
         */
        public function InputButton(
            index:int, 
            width:Number = 70, 
            height:Number = 70,
            shape:String = null,
            color:uint = 0
        ) {
            _index = index;
            _width = width;
            _height = height;
            
            // Get visuals from config if not specified
            if (shape == null || color == 0) {
                var visuals:Object = VisualConfig.getButtonVisuals(index);
                _shape = shape || visuals.shape;
                _color = color || visuals.color;
            } else {
                _shape = shape;
                _color = color;
            }
            
            createBackground();
            createShapeRenderer();
            createOverlay();
            setupInteraction();
            
            updateVisuals();
        }
        
        /**
         * Create background shape
         */
        private function createBackground():void {
            _background = new Shape();
            addChild(_background);
        }
        
        /**
         * Create shape renderer
         */
        private function createShapeRenderer():void {
            var shapeSize:Number = Math.min(_width, _height) * 0.6;
            _shapeRenderer = new ShapeRenderer(_shape, _color, shapeSize);
            _shapeRenderer.x = _width / 2;
            _shapeRenderer.y = _height / 2;
            addChild(_shapeRenderer);
        }
        
        /**
         * Create overlay for feedback effects
         */
        private function createOverlay():void {
            _overlay = new Shape();
            _overlay.alpha = 0;
            addChild(_overlay);
        }
        
        /**
         * Setup mouse/touch interaction
         */
        private function setupInteraction():void {
            buttonMode = true;
            useHandCursor = true;
            mouseChildren = false;
            
            addEventListener(MouseEvent.ROLL_OVER, onRollOver);
            addEventListener(MouseEvent.ROLL_OUT, onRollOut);
            addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            addEventListener(MouseEvent.CLICK, onClick);
        }
        
        // ============ STATE MANAGEMENT ============
        
        /**
         * Set button state
         */
        public function setState(state:String):void {
            if (_state == state) return;
            _state = state;
            updateVisuals();
            
            // Auto-feedback animation for correct/wrong
            if (state == STATE_CORRECT || state == STATE_WRONG) {
                playFeedbackAnimation(state);
            }
        }
        
        /**
         * Update visuals based on current state
         */
        private function updateVisuals():void {
            var bgColor:uint;
            var borderColor:uint;
            var borderWidth:Number = 2;
            var shadowAlpha:Number = 0.1;
            
            switch (_state) {
                case STATE_HOVER:
                    bgColor = _bgHover;
                    borderColor = _borderHover;
                    shadowAlpha = 0.15;
                    break;
                case STATE_PRESSED:
                    bgColor = _bgPressed;
                    borderColor = _borderPressed;
                    borderWidth = 3;
                    shadowAlpha = 0.05;
                    break;
                case STATE_DISABLED:
                    bgColor = _bgDisabled;
                    borderColor = _borderNormal;
                    _shapeRenderer.alpha = 0.4;
                    break;
                case STATE_CORRECT:
                    bgColor = _bgCorrect;
                    borderColor = _borderCorrect;
                    borderWidth = 3;
                    break;
                case STATE_WRONG:
                    bgColor = _bgWrong;
                    borderColor = _borderWrong;
                    borderWidth = 3;
                    break;
                case STATE_NORMAL:
                default:
                    bgColor = _bgNormal;
                    borderColor = _borderNormal;
                    _shapeRenderer.alpha = 1;
            }
            
            // Draw background
            var g:Graphics = _background.graphics;
            g.clear();
            g.lineStyle(borderWidth, borderColor, 1);
            g.beginFill(bgColor);
            g.drawRoundRect(0, 0, _width, _height, _cornerRadius, _cornerRadius);
            g.endFill();
            
            // Apply shadow
            var shadow:DropShadowFilter = new DropShadowFilter(
                2, 90, 0x000000, shadowAlpha, 4, 4, 1
            );
            
            // Apply glow for correct/wrong states
            if (_state == STATE_CORRECT) {
                var correctGlow:GlowFilter = new GlowFilter(
                    _borderCorrect, 0.6, 10, 10, 2
                );
                this.filters = [shadow, correctGlow];
            } else if (_state == STATE_WRONG) {
                var wrongGlow:GlowFilter = new GlowFilter(
                    _borderWrong, 0.6, 10, 10, 2
                );
                this.filters = [shadow, wrongGlow];
            } else {
                this.filters = [shadow];
            }
        }
        
        // ============ INTERACTION HANDLERS ============
        
        private function onRollOver(e:MouseEvent):void {
            if (!_enabled) return;
            if (_state == STATE_CORRECT || _state == STATE_WRONG) return;
            setState(STATE_HOVER);
        }
        
        private function onRollOut(e:MouseEvent):void {
            if (!_enabled) return;
            if (_state == STATE_CORRECT || _state == STATE_WRONG) return;
            setState(STATE_NORMAL);
        }
        
        private function onMouseDown(e:MouseEvent):void {
            if (!_enabled) return;
            if (_state == STATE_CORRECT || _state == STATE_WRONG) return;
            setState(STATE_PRESSED);
            
            // Scale down slightly
            scaleX = 0.95;
            scaleY = 0.95;
        }
        
        private function onMouseUp(e:MouseEvent):void {
            if (!_enabled) return;
            
            // Reset scale
            scaleX = 1.0;
            scaleY = 1.0;
            
            if (_state == STATE_CORRECT || _state == STATE_WRONG) return;
            setState(STATE_HOVER);
        }
        
        private function onClick(e:MouseEvent):void {
            if (!_enabled) return;
            
            // Dispatch custom event with button data
            dispatchEvent(new Event(BUTTON_CLICKED, true));
        }
        
        // ============ FEEDBACK ANIMATIONS ============
        
        /**
         * Play feedback animation for correct/wrong
         */
        private function playFeedbackAnimation(feedbackType:String):void {
            _animating = true;
            
            if (feedbackType == STATE_CORRECT) {
                playPulseAnimation();
            } else if (feedbackType == STATE_WRONG) {
                playShakeAnimation();
            }
            
            // Auto-reset after delay
            _feedbackTimer = new Timer(800, 1);
            _feedbackTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onFeedbackComplete);
            _feedbackTimer.start();
        }
        
        /**
         * Pulse animation for correct
         */
        private function playPulseAnimation():void {
            _pulsePhase = 0;
            addEventListener(Event.ENTER_FRAME, onPulseFrame);
        }
        
        private function onPulseFrame(e:Event):void {
            _pulsePhase += 0.15;
            
            var scale:Number = 1 + Math.sin(_pulsePhase * 2) * 0.05;
            scaleX = scale;
            scaleY = scale;
            
            if (_pulsePhase > Math.PI * 2) {
                removeEventListener(Event.ENTER_FRAME, onPulseFrame);
                scaleX = 1;
                scaleY = 1;
            }
        }
        
        /**
         * Shake animation for wrong
         */
        private function playShakeAnimation():void {
            _pulsePhase = 0;
            var originalX:Number = x;
            addEventListener(Event.ENTER_FRAME, function onShakeFrame(e:Event):void {
                _pulsePhase += 0.3;
                
                x = originalX + Math.sin(_pulsePhase * 8) * 4 * (1 - _pulsePhase / (Math.PI * 2));
                
                if (_pulsePhase > Math.PI * 2) {
                    removeEventListener(Event.ENTER_FRAME, onShakeFrame);
                    x = originalX;
                }
            });
        }
        
        private function onFeedbackComplete(e:TimerEvent):void {
            _animating = false;
            if (_enabled) {
                setState(STATE_NORMAL);
            }
        }
        
        // ============ PUBLIC METHODS ============
        
        /**
         * Show correct feedback
         */
        public function showCorrect():void {
            setState(STATE_CORRECT);
        }
        
        /**
         * Show wrong feedback
         */
        public function showWrong():void {
            setState(STATE_WRONG);
        }
        
        /**
         * Reset to normal state
         */
        public function reset():void {
            _animating = false;
            scaleX = 1;
            scaleY = 1;
            if (_feedbackTimer) {
                _feedbackTimer.stop();
            }
            setState(STATE_NORMAL);
        }
        
        /**
         * Enable/disable button
         */
        public function setEnabled(enabled:Boolean):void {
            _enabled = enabled;
            buttonMode = enabled;
            useHandCursor = enabled;
            
            if (!enabled) {
                setState(STATE_DISABLED);
            } else {
                setState(STATE_NORMAL);
            }
        }
        
        /**
         * Update shape and color
         */
        public function updateVisualContent(shape:String, color:uint):void {
            _shape = shape;
            _color = color;
            
            if (_shapeRenderer) {
                _shapeRenderer.update(shape, color, Math.min(_width, _height) * 0.6);
            }
        }
        
        /**
         * Trigger haptic feedback (mobile)
         * Note: Requires AIR native extension for actual haptic
         */
        public function triggerHaptic():void {
            // Placeholder - would use ANE for actual haptic feedback
            trace("[InputButton] Haptic feedback triggered for button " + _index);
        }
        
        // ============ GETTERS ============
        
        public function get index():int { return _index; }
        public function get shapeType():String { return _shape; }
        public function get color():uint { return _color; }
        public function get currentState():String { return _state; }
        public function get isEnabled():Boolean { return _enabled; }
    }
}
