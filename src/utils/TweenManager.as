package utils {
    
    import flash.display.DisplayObject;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    
    /**
     * TweenManager - Simple tweening system for UI animations.
     * Provides basic property animation without external dependencies.
     * 
     * Usage:
     *   TweenManager.to(sprite, 0.5, {x: 100, alpha: 1, onComplete: callback});
     */
    public class TweenManager {
        
        private static var _tweens:Vector.<TweenData>;
        private static var _initialized:Boolean = false;
        private static var _lastTime:Number = 0;
        
        /**
         * Initialize the tween manager
         */
        public static function init():void {
            if (!_initialized) {
                _tweens = new Vector.<TweenData>();
                _lastTime = getTimer();
                _initialized = true;
            }
        }
        
        /**
         * Create a tween to animate properties
         * @param target Display object to animate
         * @param duration Duration in seconds
         * @param props Properties object with target values and callbacks
         * @return TweenData reference
         */
        public static function to(target:Object, duration:Number, props:Object):TweenData {
            init();
            
            var tween:TweenData = new TweenData();
            tween.target = target;
            tween.duration = duration * 1000; // Convert to ms
            tween.startTime = getTimer();
            tween.props = {};
            tween.startProps = {};
            tween.easing = props.ease || easeOutQuad;
            tween.onComplete = props.onComplete;
            tween.onUpdate = props.onUpdate;
            
            // Capture start values and target values
            for (var prop:String in props) {
                if (prop != "ease" && prop != "onComplete" && prop != "onUpdate" && 
                    prop != "delay" && target.hasOwnProperty(prop)) {
                    tween.startProps[prop] = target[prop];
                    tween.props[prop] = props[prop];
                }
            }
            
            // Handle delay
            if (props.delay) {
                tween.startTime += props.delay * 1000;
            }
            
            _tweens.push(tween);
            return tween;
        }
        
        /**
         * Create a tween from current values
         * @param target Display object
         * @param duration Duration in seconds
         * @param props Start values (will animate TO current values)
         */
        public static function from(target:Object, duration:Number, props:Object):TweenData {
            init();
            
            // Store current values
            var currentValues:Object = {};
            for (var prop:String in props) {
                if (prop != "ease" && prop != "onComplete" && prop != "onUpdate" && 
                    prop != "delay" && target.hasOwnProperty(prop)) {
                    currentValues[prop] = target[prop];
                    target[prop] = props[prop]; // Set to start value
                }
            }
            
            // Copy callbacks
            currentValues.ease = props.ease;
            currentValues.onComplete = props.onComplete;
            currentValues.onUpdate = props.onUpdate;
            currentValues.delay = props.delay;
            
            return to(target, duration, currentValues);
        }
        
        /**
         * Update all active tweens (call every frame)
         */
        public static function update():void {
            if (!_initialized || _tweens.length == 0) return;
            
            var currentTime:Number = getTimer();
            var i:int = _tweens.length;
            
            while (--i >= 0) {
                var tween:TweenData = _tweens[i];
                
                // Check if tween has started (delay)
                if (currentTime < tween.startTime) continue;
                
                var elapsed:Number = currentTime - tween.startTime;
                var progress:Number = Math.min(1, elapsed / tween.duration);
                var eased:Number = tween.easing(progress);
                
                // Update properties
                for (var prop:String in tween.props) {
                    var start:Number = tween.startProps[prop];
                    var end:Number = tween.props[prop];
                    tween.target[prop] = start + (end - start) * eased;
                }
                
                // Callback
                if (tween.onUpdate != null) {
                    tween.onUpdate(progress);
                }
                
                // Complete
                if (progress >= 1) {
                    _tweens.splice(i, 1);
                    if (tween.onComplete != null) {
                        tween.onComplete();
                    }
                }
            }
        }
        
        /**
         * Kill tweens on a target
         * @param target Object to stop tweening
         * @param complete Whether to jump to end values
         */
        public static function kill(target:Object, complete:Boolean = false):void {
            if (!_initialized) return;
            
            var i:int = _tweens.length;
            while (--i >= 0) {
                if (_tweens[i].target == target) {
                    if (complete) {
                        var tween:TweenData = _tweens[i];
                        for (var prop:String in tween.props) {
                            tween.target[prop] = tween.props[prop];
                        }
                    }
                    _tweens.splice(i, 1);
                }
            }
        }
        
        /**
         * Kill all tweens
         */
        public static function killAll():void {
            if (_initialized) {
                _tweens.length = 0;
            }
        }
        
        /**
         * Check if target is being tweened
         */
        public static function isTweening(target:Object):Boolean {
            if (!_initialized) return false;
            for each (var tween:TweenData in _tweens) {
                if (tween.target == target) return true;
            }
            return false;
        }
        
        // ============ EASING FUNCTIONS ============
        
        public static function linear(t:Number):Number {
            return t;
        }
        
        public static function easeInQuad(t:Number):Number {
            return t * t;
        }
        
        public static function easeOutQuad(t:Number):Number {
            return t * (2 - t);
        }
        
        public static function easeInOutQuad(t:Number):Number {
            return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
        }
        
        public static function easeInCubic(t:Number):Number {
            return t * t * t;
        }
        
        public static function easeOutCubic(t:Number):Number {
            return (--t) * t * t + 1;
        }
        
        public static function easeInOutCubic(t:Number):Number {
            return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
        }
        
        public static function easeOutBack(t:Number):Number {
            var c1:Number = 1.70158;
            var c3:Number = c1 + 1;
            return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2);
        }
        
        public static function easeOutElastic(t:Number):Number {
            var c4:Number = (2 * Math.PI) / 3;
            return t === 0 ? 0 : t === 1 ? 1 :
                Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * c4) + 1;
        }
        
        public static function easeOutBounce(t:Number):Number {
            var n1:Number = 7.5625;
            var d1:Number = 2.75;
            if (t < 1 / d1) {
                return n1 * t * t;
            } else if (t < 2 / d1) {
                t -= 1.5 / d1;
                return n1 * t * t + 0.75;
            } else if (t < 2.5 / d1) {
                t -= 2.25 / d1;
                return n1 * t * t + 0.9375;
            } else {
                t -= 2.625 / d1;
                return n1 * t * t + 0.984375;
            }
        }
    }
}

/**
 * Internal tween data holder
 */
class TweenData {
    public var target:Object;
    public var duration:Number;
    public var startTime:Number;
    public var props:Object;
    public var startProps:Object;
    public var easing:Function;
    public var onComplete:Function;
    public var onUpdate:Function;
}
