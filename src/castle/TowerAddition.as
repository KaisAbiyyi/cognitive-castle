package castle {
    
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.display.Shape;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    /**
     * TowerAddition - Represents an additional tower that appears on castle upgrades
     * 
     * Each tower has:
     * - batch: Creation index (1 = first created)
     * - side: "left" or "right" 
     * - scale: Current scale (starts small, grows with upgrades)
     * - maxScale: Maximum scale for this batch
     */
    public class TowerAddition extends Sprite {
        
        private static const DEBUG:Boolean = true;
        
        // Animation constants
        private static const POPUP_DURATION_MS:int = 500;
        private static const POPUP_OVERSHOOT:Number = 1.15; // Bounce overshoot
        
        // Tower properties
        private var _towerId:String;
        private var _batch:int;
        private var _side:String;
        private var _currentScale:Number;
        private var _maxScale:Number;
        private var _initialScale:Number;
        private var _imageUrl:String;
        
        // Visual components
        private var _bitmap:Bitmap;
        private var _isLoaded:Boolean = false;
        
        // Positioning
        private var _baseY:Number = 0;
        private var _targetX:Number = 0;
        private var _targetY:Number = 0;
        
        // Animation
        private var _popupTimer:Timer;
        private var _popupStartTime:Number = 0;
        private var _isAnimating:Boolean = false;
        
        // Shrink animation (smooth)
        private var _shrinkTimer:Timer;
        private var _shrinkStartTime:Number = 0;
        private var _shrinkFromScale:Number = 0;
        private var _shrinkToScale:Number = 0;
        private var _shrinkOnComplete:Function;
        
        // Pulse animation (win feedback when already at max)
        private var _pulseTimer:Timer;
        private var _pulseStartTime:Number = 0;
        private var _pulseBaseScale:Number = 0;
        private var _pulseAmount:Number = 0.06;
        private var _pulseDurationMs:int = 260;
        private var _pulseOnComplete:Function;
        
        // Removal animation
        private var _removalTimer:Timer;
        private var _removalStartTime:Number = 0;
        private var _removalInitialScale:Number = 0;
        private var _removalOnComplete:Function;
        private var _removalGears:Vector.<Shape>;
        private var _removalNumGears:int = 0;
        
        /**
         * Constructor
         * @param batch Tower creation index
         * @param side "left" or "right"
         * @param initialScale Starting scale
         * @param maxScale Maximum scale for this batch
         * @param towerId Unique node ID (L1, R1, ...)
         * @param imageUrl Optional image path override
         */
        public function TowerAddition(batch:int, side:String, initialScale:Number, maxScale:Number, towerId:String = "", imageUrl:String = null) {
            _batch = batch;
            _side = side;
            _towerId = towerId;
            _initialScale = initialScale;
            _currentScale = initialScale;
            _maxScale = maxScale;
            _imageUrl = (imageUrl && imageUrl.length > 0) ? imageUrl : "assets/images/Game/towerCastle.png";
            
            // Start invisible for animation
            this.alpha = 0;
            this.scaleX = 0;
            this.scaleY = 0;
            
            loadTowerImage();
        }
        
        private function loadTowerImage():void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
            loader.load(new URLRequest(_imageUrl));
        }
        
        private function onImageLoaded(e:Event):void {
            _bitmap = Bitmap(e.target.content);
            _bitmap.smoothing = true;
            
            // Position bitmap so origin is at bottom-center (for proper ground alignment)
            _bitmap.x = -_bitmap.width / 2;
            _bitmap.y = -_bitmap.height;
            
            addChild(_bitmap);
            _isLoaded = true;
            
            if (DEBUG) {
                trace("[TowerAddition] Loaded tower id=" + _towerId + ", batch=" + _batch + ", side=" + _side + ", scale=" + _currentScale);
            }
            
            dispatchEvent(new Event(Event.COMPLETE));
        }
        
        /**
         * Start popup animation (call after positioning)
         */
        public function playPopupAnimation():void {
            if (_isAnimating) return;
            stopPulseTimer();
            
            _isAnimating = true;
            _popupStartTime = new Date().getTime();
            
            // Start from invisible and small
            this.alpha = 0;
            this.scaleX = 0;
            this.scaleY = 0;
            
            _popupTimer = new Timer(16); // ~60fps
            _popupTimer.addEventListener(TimerEvent.TIMER, onPopupTick);
            _popupTimer.start();
            
            if (DEBUG) {
                trace("[TowerAddition] Starting popup animation for id=" + _towerId + ", batch=" + _batch + ", side=" + _side);
            }
        }
        
        private function onPopupTick(e:TimerEvent):void {
            var elapsed:Number = new Date().getTime() - _popupStartTime;
            var progress:Number = Math.min(elapsed / POPUP_DURATION_MS, 1.0);
            
            // Elastic easing for bouncy effect
            var easedProgress:Number = elasticEaseOut(progress);
            
            // Apply scale with bounce
            var targetScale:Number = _currentScale;
            this.scaleX = targetScale * easedProgress;
            this.scaleY = targetScale * easedProgress;
            
            // Fade in quickly
            this.alpha = Math.min(progress * 2, 1.0);
            
            if (progress >= 1.0) {
                stopPopupTimer();
                _isAnimating = false;
                
                // Ensure final scale is exact
                this.scaleX = _currentScale;
                this.scaleY = _currentScale;
                this.alpha = 1;
                
                if (DEBUG) {
                    trace("[TowerAddition] Popup animation complete");
                }
            }
        }
        
        private function stopPopupTimer():void {
            if (_popupTimer) {
                _popupTimer.stop();
                _popupTimer.removeEventListener(TimerEvent.TIMER, onPopupTick);
                _popupTimer = null;
            }
        }
        
        private function stopShrinkTimer(clearCallback:Boolean = true):void {
            if (_shrinkTimer) {
                _shrinkTimer.stop();
                _shrinkTimer.removeEventListener(TimerEvent.TIMER, onShrinkTick);
                _shrinkTimer = null;
            }
            if (clearCallback) {
                _shrinkOnComplete = null;
            }
        }
        
        private function stopPulseTimer(clearCallback:Boolean = true):void {
            if (_pulseTimer) {
                _pulseTimer.stop();
                _pulseTimer.removeEventListener(TimerEvent.TIMER, onPulseTick);
                _pulseTimer = null;
                _isAnimating = false;
            }
            if (clearCallback) {
                _pulseOnComplete = null;
            }
        }
        
        private function cleanupRemovalGears():void {
            if (!_removalGears) return;
            for each (var gear:Shape in _removalGears) {
                if (gear && contains(gear)) {
                    removeChild(gear);
                }
            }
            _removalGears = null;
            _removalNumGears = 0;
        }
        
        private function stopRemovalTimer(clearCallback:Boolean = true):void {
            if (_removalTimer) {
                _removalTimer.stop();
                _removalTimer.removeEventListener(TimerEvent.TIMER, onRemovalTick);
                _removalTimer = null;
            }
            cleanupRemovalGears();
            if (clearCallback) {
                _removalOnComplete = null;
            }
        }
        
        /**
         * Elastic ease out function for bouncy animation
         */
        private function elasticEaseOut(t:Number):Number {
            if (t == 0 || t == 1) return t;
            
            var p:Number = 0.3;
            var s:Number = p / 4;
            
            return Math.pow(2, -10 * t) * Math.sin((t - s) * (2 * Math.PI) / p) + 1;
        }
        
        /**
         * Apply scale to tower
         */
        public function applyScale(scale:Number):void {
            // If we're pulsing, external scale updates should win.
            stopPulseTimer();
            _currentScale = Math.min(scale, _maxScale);
            
            if (_isLoaded && !_isAnimating) {
                this.scaleX = _currentScale;
                this.scaleY = _currentScale;
            }
        }
        
        /**
         * Grow tower by increment with animation
         */
        public function grow(increment:Number):void {
            var oldScale:Number = _currentScale;
            _currentScale = Math.min(_currentScale + increment, _maxScale);
            
            if (_isLoaded) {
                // Animate the growth
                animateGrowth(oldScale, _currentScale);
            }
        }
        
        /**
         * Animate growth from old to new scale
         */
        private function animateGrowth(fromScale:Number, toScale:Number):void {
            var startTime:Number = new Date().getTime();
            var duration:Number = 300;
            
            var growTimer:Timer = new Timer(16);
            growTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
                var elapsed:Number = new Date().getTime() - startTime;
                var progress:Number = Math.min(elapsed / duration, 1.0);
                
                // Bounce easing
                var easedProgress:Number = elasticEaseOut(progress);
                var currentScale:Number = fromScale + (toScale - fromScale) * easedProgress;
                
                scaleX = currentScale;
                scaleY = currentScale;
                
                if (progress >= 1.0) {
                    growTimer.stop();
                    scaleX = toScale;
                    scaleY = toScale;
                }
            });
            growTimer.start();
        }
        
        /**
         * Position tower at the edge of anchor
         * @param anchorX X position of anchor center
         * @param anchorY Y position of anchor (bottom)
         * @param anchorHalfWidth Half-width of anchor sprite
         * @param gap Gap between tower and anchor (0 for edge-to-edge)
         */
        public function positionAtEdge(anchorX:Number, anchorY:Number, anchorHalfWidth:Number, gap:Number = 0):void {
            var towerHalfWidth:Number = _bitmap ? (_bitmap.width * _currentScale) / 2 : 25;
            
            if (_side == "left") {
                // Tower's right edge touches anchor's left edge
                this.x = anchorX - anchorHalfWidth - towerHalfWidth - gap;
            } else {
                // Tower's left edge touches anchor's right edge
                this.x = anchorX + anchorHalfWidth + towerHalfWidth + gap;
            }
            
            // Position Y at same ground level as anchor
            this.y = anchorY;
            _baseY = anchorY;
            _targetX = this.x;
            _targetY = this.y;
        }
        
        /**
         * Legacy positioning method (for backwards compatibility)
         */
        public function positionRelativeTo(anchorX:Number, anchorY:Number, anchorWidth:Number, gap:Number = 10):void {
            positionAtEdge(anchorX, anchorY, anchorWidth / 2, gap);
        }
        
        /**
         * Get tower width at current scale
         */
        public function getWidth():Number {
            if (!_bitmap) return 50 * _currentScale;
            return _bitmap.width * _currentScale;
        }
        
        /**
         * Get tower half width at current scale
         */
        public function getHalfWidth():Number {
            return getWidth() / 2;
        }
        
        /**
         * Get tower height at current scale
         */
        public function getHeight():Number {
            if (!_bitmap) return 100 * _currentScale;
            return _bitmap.height * _currentScale;
        }
        
        /**
         * Shrink tower with smooth animation (no bounce)
         */
        public function shrink(targetScale:Number, onComplete:Function = null):void {
            // If the tower is currently popping in, cancel that so shrink/removal always applies.
            // (Wrong answers should immediately affect the tower.)
            stopPopupTimer();
            stopPulseTimer();
            this.alpha = 1;
            
            // If a removal animation is running, ignore shrink requests.
            if (_removalTimer) return;
            
            // Cancel an in-progress shrink so the newest target wins.
            stopShrinkTimer();
            
            // Start from the current visual scale to avoid jumpy transitions.
            _shrinkFromScale = this.scaleX;
            _shrinkToScale = targetScale;
            _currentScale = targetScale;
            _shrinkOnComplete = onComplete;
            
            _isAnimating = true;
            _shrinkStartTime = new Date().getTime();
            
            _shrinkTimer = new Timer(16);
            _shrinkTimer.addEventListener(TimerEvent.TIMER, onShrinkTick);
            _shrinkTimer.start();
        }
        
        /**
         * Scale to target with smooth animation (for repair/scale up)
         */
        public function scaleToTarget(targetScale:Number, onComplete:Function = null):void {
            // Cancel any in-progress animations
            stopPopupTimer();
            stopShrinkTimer();
            stopPulseTimer();
            this.alpha = 1;
            
            // If a removal animation is running, ignore scale requests.
            if (_removalTimer) return;
            
            // Start from the current visual scale
            _shrinkFromScale = this.scaleX;
            _shrinkToScale = Math.min(targetScale, _maxScale);
            _currentScale = _shrinkToScale;
            _shrinkOnComplete = onComplete;
            
            _isAnimating = true;
            _shrinkStartTime = new Date().getTime();
            
            _shrinkTimer = new Timer(16);
            _shrinkTimer.addEventListener(TimerEvent.TIMER, onShrinkTick);
            _shrinkTimer.start();
        }
        
        private function onShrinkTick(e:TimerEvent):void {
            var elapsed:Number = new Date().getTime() - _shrinkStartTime;
            var duration:Number = 400;
            var progress:Number = Math.min(elapsed / duration, 1.0);
            
            var easedProgress:Number = easeOutQuad(progress);
            var currentScale:Number = _shrinkFromScale + (_shrinkToScale - _shrinkFromScale) * easedProgress;
            
            this.scaleX = currentScale;
            this.scaleY = currentScale;
            
            if (progress >= 1.0) {
                var cb:Function = _shrinkOnComplete;
                _shrinkOnComplete = null;
                
                stopShrinkTimer(false);
                this.scaleX = _shrinkToScale;
                this.scaleY = _shrinkToScale;
                _currentScale = _shrinkToScale; // CRITICAL: Sync internal scale with visual
                _isAnimating = false;
                if (cb != null) cb();
            }
        }
        
        /**
         * Play removal animation with spinning gears
         */
        public function playRemovalAnimation(onComplete:Function = null):void {
            // Removal should always win (e.g., 3-wrong streak or horde destroy).
            stopPopupTimer();
            stopShrinkTimer();
            stopPulseTimer();
            if (_removalTimer) return;
            
            _isAnimating = true;
            _removalStartTime = new Date().getTime();
            _removalInitialScale = (this.scaleX > 0) ? this.scaleX : _currentScale;
            _removalOnComplete = onComplete;
            
            // Create gear particles
            cleanupRemovalGears();
            _removalGears = new Vector.<Shape>();
            _removalNumGears = 8;
            
            for (var i:int = 0; i < _removalNumGears; i++) {
                var gear:Shape = createGearShape(15 + Math.random() * 10);
                gear.x = 0;
                gear.y = -this.getHeight() / 2;
                addChild(gear);
                _removalGears.push(gear);
            }
            
            _removalTimer = new Timer(16);
            _removalTimer.addEventListener(TimerEvent.TIMER, onRemovalTick);
            _removalTimer.start();
        }
        
        private function onRemovalTick(e:TimerEvent):void {
            var elapsed:Number = new Date().getTime() - _removalStartTime;
            var duration:Number = 800;
            var progress:Number = Math.min(elapsed / duration, 1.0);
            
            // Tower shrinks and fades
            var shrinkProgress:Number = easeOutQuad(progress);
            this.scaleX = _removalInitialScale * (1 - shrinkProgress);
            this.scaleY = _removalInitialScale * (1 - shrinkProgress);
            this.alpha = 1 - shrinkProgress;
            
            // Gears fly outward and spin
            if (_removalGears && _removalNumGears > 0) {
                for (var j:int = 0; j < _removalGears.length; j++) {
                    var g:Shape = _removalGears[j];
                    var angle:Number = (j / _removalNumGears) * Math.PI * 2;
                    var distance:Number = progress * 100;
                    g.x = Math.cos(angle) * distance;
                    g.y = -this.getHeight() / 2 + Math.sin(angle) * distance - progress * 50;
                    g.rotation += 15;
                    g.alpha = 1 - progress;
                    g.scaleX = 1 - progress * 0.5;
                    g.scaleY = 1 - progress * 0.5;
                }
            }
            
            if (progress >= 1.0) {
                var cb:Function = _removalOnComplete;
                _removalOnComplete = null;
                
                stopRemovalTimer(false);
                _isAnimating = false;
                if (cb != null) cb();
            }
        }
        
        /**
         * Pulse animation without changing the final scale (used for "win confirm" at max growth).
         * @param amount Relative bump amount (e.g., 0.06 = +6%)
         * @param durationMs Total pulse duration in ms
         */
        public function pulse(amount:Number = 0.06, durationMs:int = 260, onComplete:Function = null):void {
            // Removal should always win.
            if (_removalTimer) return;
            
            stopPopupTimer();
            stopShrinkTimer();
            stopPulseTimer();
            
            this.alpha = 1;
            
            _pulseAmount = amount;
            _pulseDurationMs = durationMs;
            _pulseOnComplete = onComplete;
            _pulseStartTime = new Date().getTime();
            _pulseBaseScale = (this.scaleX > 0) ? this.scaleX : _currentScale;
            
            _isAnimating = true;
            
            _pulseTimer = new Timer(16);
            _pulseTimer.addEventListener(TimerEvent.TIMER, onPulseTick);
            _pulseTimer.start();
        }
        
        private function onPulseTick(e:TimerEvent):void {
            var elapsed:Number = new Date().getTime() - _pulseStartTime;
            var progress:Number = Math.min(elapsed / _pulseDurationMs, 1.0);
            
            // One smooth bump: 0 -> 1 -> 0
            var bump:Number = Math.sin(Math.PI * progress);
            var s:Number = _pulseBaseScale * (1 + (_pulseAmount * bump));
            this.scaleX = s;
            this.scaleY = s;
            
            if (progress >= 1.0) {
                var cb:Function = _pulseOnComplete;
                _pulseOnComplete = null;
                
                stopPulseTimer(false);
                this.scaleX = _pulseBaseScale;
                this.scaleY = _pulseBaseScale;
                _isAnimating = false;
                if (cb != null) cb();
            }
        }
        
        /**
         * Create a gear-shaped sprite
         */
        private function createGearShape(size:Number):Shape {
            var gear:Shape = new Shape();
            var g:* = gear.graphics;
            var teeth:int = 8;
            var innerRadius:Number = size * 0.5;
            var outerRadius:Number = size;
            
            g.beginFill(0x8B7355); // Bronze/gear color
            g.lineStyle(2, 0x5D4E37);
            
            for (var i:int = 0; i < teeth * 2; i++) {
                var angle:Number = (i / (teeth * 2)) * Math.PI * 2;
                var radius:Number = (i % 2 == 0) ? outerRadius : innerRadius;
                var px:Number = Math.cos(angle) * radius;
                var py:Number = Math.sin(angle) * radius;
                
                if (i == 0) {
                    g.moveTo(px, py);
                } else {
                    g.lineTo(px, py);
                }
            }
            g.endFill();
            
            // Center hole
            g.beginFill(0x3D3D3D);
            g.drawCircle(0, 0, size * 0.2);
            g.endFill();
            
            return gear;
        }
        
        /**
         * Quadratic ease out
         */
        private function easeOutQuad(t:Number):Number {
            return t * (2 - t);
        }
        
        // Getters
        public function get towerId():String { return _towerId; }
        public function get batch():int { return _batch; }
        public function get side():String { return _side; }
        public function get currentScale():Number { return _currentScale; }
        public function get maxScale():Number { return _maxScale; }
        public function get isLoaded():Boolean { return _isLoaded; }
        
        /**
         * Threshold below which this tower is considered destroyed by siege.
         * We make it relative to initial scale with a safe minimum to avoid tiny, invisible towers.
         */
        public function get destroyThreshold():Number { return Math.max(0.15, _initialScale * 0.6); }
        public function get baseY():Number { return _baseY; }
        public function get isAnimating():Boolean { return _isAnimating; }
        
        /**
         * Dispose tower
         */
        public function dispose():void {
            stopPopupTimer();
            stopShrinkTimer();
            stopPulseTimer();
            stopRemovalTimer();
            if (_bitmap && contains(_bitmap)) {
                removeChild(_bitmap);
            }
            _bitmap = null;
            _isLoaded = false;
        }
    }
}
