package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    /**
     * ScreenShake - Creates screen shake effect for wrong answers.
     * 
     * T1-085
     */
    public class ScreenShake extends Sprite {
        
        // Target to shake
        private var _target:DisplayObject;
        private var _originalX:Number;
        private var _originalY:Number;
        
        // Shake parameters
        private var _intensity:Number = 10;
        private var _duration:int = 300;
        private var _frequency:Number = 0.5;
        
        // Animation
        private var _shaking:Boolean = false;
        private var _progress:Number = 0;
        private var _phase:Number = 0;
        
        /**
         * Constructor
         */
        public function ScreenShake() {
            // Nothing needed
        }
        
        /**
         * Shake a display object
         * @param target The DisplayObject to shake
         * @param intensity Shake intensity in pixels
         * @param duration Shake duration in ms
         */
        public function shake(target:DisplayObject, intensity:Number = 10, duration:int = 300):void {
            if (_shaking) {
                // Already shaking, restore first
                restore();
            }
            
            _target = target;
            _intensity = intensity;
            _duration = duration;
            _originalX = target.x;
            _originalY = target.y;
            _progress = 0;
            _phase = 0;
            _shaking = true;
            
            addEventListener(Event.ENTER_FRAME, onShakeFrame);
        }
        
        /**
         * Animation frame handler
         */
        private function onShakeFrame(e:Event):void {
            if (!_target || !_shaking) {
                restore();
                return;
            }
            
            // Increment progress
            _progress += (1000 / 60) / _duration;
            _phase += _frequency;
            
            if (_progress >= 1) {
                restore();
                return;
            }
            
            // Calculate decay (shake reduces over time)
            var decay:Number = 1 - _progress;
            
            // Random offset with sine wave for smooth shake
            var offsetX:Number = Math.sin(_phase * 20) * _intensity * decay;
            var offsetY:Number = Math.cos(_phase * 15) * _intensity * decay * 0.5;
            
            // Add some randomness
            offsetX += (Math.random() - 0.5) * _intensity * decay * 0.5;
            offsetY += (Math.random() - 0.5) * _intensity * decay * 0.3;
            
            // Apply offset
            _target.x = _originalX + offsetX;
            _target.y = _originalY + offsetY;
        }
        
        /**
         * Stop shake and restore position
         */
        public function restore():void {
            removeEventListener(Event.ENTER_FRAME, onShakeFrame);
            
            if (_target) {
                _target.x = _originalX;
                _target.y = _originalY;
            }
            
            _shaking = false;
        }
        
        /**
         * Quick shake for wrong answer
         */
        public function shakeWrong(target:DisplayObject):void {
            shake(target, 8, 250);
        }
        
        /**
         * Strong shake for critical error
         */
        public function shakeStrong(target:DisplayObject):void {
            shake(target, 15, 400);
        }
        
        public function get isShaking():Boolean {
            return _shaking;
        }
    }
}
