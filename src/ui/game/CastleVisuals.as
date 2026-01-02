package ui.game {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.BlendMode;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.geom.Matrix;
    import flash.geom.ColorTransform;
    
    /**
     * CastleVisuals - Handles castle rendering, shadows, scaling animations.
     */
    public class CastleVisuals extends Sprite {
        
        private static const DEBUG:Boolean = true;
        
        // Shadow constants
        private static const SHADOW_COLOR:uint = 0x000000;
        private static const CASTLE_SHADOW_ALPHA:Number = 0.22;
        private static const CASTLE_SHADOW_FLATTEN:Number = 0.16;
        private static const CASTLE_SHADOW_STRETCH:Number = 1.08;
        private static const CASTLE_SHADOW_SKEW_DEG:Number = 28;
        private static const CASTLE_SHADOW_OFFSET_X:Number = 0;
        private static const CASTLE_SHADOW_OFFSET_Y:Number = -3;
        private static const CASTLE_CONTACT_ALPHA:Number = 0.28;
        private static const CASTLE_CONTACT_WIDTH_RATIO:Number = 0.95;
        private static const CONTACT_OFFSET_Y:Number = 0;
        private static const CASTLE_POP_DURATION_MS:int = 420;
        
        // Main castle
        private var _mainCastle:Sprite;
        private var _mainCastleBitmap:Bitmap;
        private var _castleScale:Number = 1.0;
        
        // Shadow
        private var _shadowLayer:Sprite;
        private var _castleShadow:Sprite;
        private var _castleShadowBitmap:Bitmap;
        private var _castleContactShadow:Shape;
        
        // Pop animation
        private var _castlePopTimer:Timer;
        private var _castlePopStartMs:Number = 0;
        private var _castlePopFromScale:Number = 0.7;
        private var _castlePopToScale:Number = 0.7;
        
        // Dimensions
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Callbacks
        private var _onCastleLoaded:Function;
        
        public function CastleVisuals() {
            _mainCastle = new Sprite();
            addChild(_mainCastle);
        }
        
        public function initialize(stageW:Number, stageH:Number, shadowLayer:Sprite):void {
            _stageWidth = stageW;
            _stageHeight = stageH;
            _shadowLayer = shadowLayer;
        }
        
        public function loadCastle(onComplete:Function = null):void {
            _onCastleLoaded = onComplete;
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onMainCastleLoaded);
            loader.load(new URLRequest("assets/images/Game/mainCastle.png"));
        }
        
        private function onMainCastleLoaded(e:Event):void {
            _mainCastleBitmap = Bitmap(e.target.content);
            _mainCastleBitmap.smoothing = true;
            _mainCastleBitmap.x = -_mainCastleBitmap.width / 2;
            _mainCastleBitmap.y = -_mainCastleBitmap.height;
            
            _mainCastle.addChild(_mainCastleBitmap);
            applyScale(_castleScale);
            updatePosition();
            createCastleShadow();
            
            if (DEBUG) trace("[CastleVisuals] Castle loaded: " + _mainCastleBitmap.width + "x" + _mainCastleBitmap.height);
            if (_onCastleLoaded != null) _onCastleLoaded();
        }
        
        public function updatePosition():void {
            if (!_mainCastle || !_mainCastleBitmap) return;
            _mainCastle.x = _stageWidth / 2;
            _mainCastle.y = (_stageHeight / 2) + 180;
            updateCastleShadow(_mainCastle.scaleX);
        }
        
        public function applyScale(scale:Number):void {
            _castleScale = scale;
            if (_mainCastle) {
                _mainCastle.scaleX = scale;
                _mainCastle.scaleY = scale;
            }
            updateCastleShadow(scale);
        }
        
        public function animatePopScale(fromScale:Number, toScale:Number):void {
            if (!_mainCastle) return;
            stopCastlePopAnimation();
            _castlePopFromScale = fromScale;
            _castlePopToScale = toScale;
            _castlePopStartMs = new Date().time;
            
            _castlePopTimer = new Timer(33);
            _castlePopTimer.addEventListener(TimerEvent.TIMER, onCastlePopTick);
            _castlePopTimer.start();
        }
        
        public function animateShrinkScale(fromScale:Number, toScale:Number, onComplete:Function = null):void {
            var startTime:Number = new Date().getTime();
            var duration:Number = 400;
            var self:CastleVisuals = this;
            
            var shrinkTimer:Timer = new Timer(16);
            shrinkTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
                var elapsed:Number = new Date().getTime() - startTime;
                var progress:Number = Math.min(elapsed / duration, 1.0);
                var easedProgress:Number = 1 - Math.pow(1 - progress, 2);
                var currentScale:Number = fromScale + (toScale - fromScale) * easedProgress;
                self.applyScale(currentScale);
                
                if (progress >= 1.0) {
                    shrinkTimer.stop();
                    self.applyScale(toScale);
                    if (onComplete != null) onComplete();
                }
            });
            shrinkTimer.start();
        }
        
        private function onCastlePopTick(e:TimerEvent):void {
            if (!_mainCastle) { stopCastlePopAnimation(); return; }
            
            var elapsed:Number = new Date().time - _castlePopStartMs;
            var t:Number = elapsed / CASTLE_POP_DURATION_MS;
            
            if (t >= 1) {
                applyScale(_castlePopToScale);
                _castleScale = _castlePopToScale;
                stopCastlePopAnimation();
                return;
            }
            
            var eased:Number = easeOutBack(Math.max(0, Math.min(1, t)));
            var visualScale:Number = _castlePopFromScale + (_castlePopToScale - _castlePopFromScale) * eased;
            applyScale(Math.max(0, visualScale));
        }
        
        public function stopCastlePopAnimation():void {
            if (_castlePopTimer) {
                _castlePopTimer.stop();
                _castlePopTimer.removeEventListener(TimerEvent.TIMER, onCastlePopTick);
                _castlePopTimer = null;
            }
        }
        
        private function easeOutBack(t:Number, s:Number = 1.70158):Number {
            t -= 1;
            return (t * t * ((s + 1) * t + s) + 1);
        }
        
        // Shadow methods
        private function createCastleShadow():void {
            if (!_mainCastle || !_mainCastleBitmap || !_shadowLayer) return;
            ensureCastleContactShadow();
            
            if (_castleShadow && _castleShadow.parent) _castleShadow.parent.removeChild(_castleShadow);
            
            _castleShadow = new Sprite();
            _castleShadow.mouseEnabled = false;
            _castleShadow.cacheAsBitmap = true;
            _castleShadow.blendMode = BlendMode.MULTIPLY;
            
            _castleShadowBitmap = new Bitmap(_mainCastleBitmap.bitmapData);
            _castleShadowBitmap.smoothing = true;
            _castleShadowBitmap.x = -_mainCastleBitmap.width / 2;
            _castleShadowBitmap.y = -_mainCastleBitmap.height;
            tintToSingleColor(_castleShadowBitmap, SHADOW_COLOR);
            _castleShadow.addChild(_castleShadowBitmap);
            _castleShadow.alpha = CASTLE_SHADOW_ALPHA;
            
            _shadowLayer.addChild(_castleShadow);
            if (_castleContactShadow) _shadowLayer.setChildIndex(_castleContactShadow, _shadowLayer.numChildren - 1);
            updateCastleShadow(_mainCastle.scaleX);
        }
        
        public function updateCastleShadow(currentScale:Number):void {
            if (!_castleShadow || !_mainCastle) return;
            updateCastleContactShadow(currentScale);
            _castleShadow.visible = currentScale > 0.001;
            if (!_castleShadow.visible) return;
            
            var sx:Number = currentScale * CASTLE_SHADOW_STRETCH;
            var sy:Number = currentScale * CASTLE_SHADOW_FLATTEN;
            var skewRad:Number = CASTLE_SHADOW_SKEW_DEG * (Math.PI / 180);
            
            var m:Matrix = new Matrix();
            m.a = sx;
            m.c = -sy * Math.tan(skewRad);
            m.d = -sy;
            m.tx = _mainCastle.x + CASTLE_SHADOW_OFFSET_X;
            m.ty = _mainCastle.y + CASTLE_SHADOW_OFFSET_Y;
            
            _castleShadow.transform.matrix = m;
        }
        
        private function ensureCastleContactShadow():void {
            if (_castleContactShadow || !_shadowLayer) return;
            _castleContactShadow = new Shape();
            _castleContactShadow.blendMode = BlendMode.MULTIPLY;
            _castleContactShadow.alpha = CASTLE_CONTACT_ALPHA;
            _shadowLayer.addChild(_castleContactShadow);
        }
        
        private function updateCastleContactShadow(currentScale:Number):void {
            if (!_castleContactShadow || !_mainCastleBitmap || !_mainCastle) return;
            _castleContactShadow.visible = currentScale > 0.001;
            if (!_castleContactShadow.visible) return;
            
            var w:Number = _mainCastleBitmap.width * currentScale * CASTLE_CONTACT_WIDTH_RATIO;
            var h:Number = Math.max(8, w * 0.10);
            
            var g:* = _castleContactShadow.graphics;
            g.clear();
            g.beginFill(SHADOW_COLOR, 1);
            g.drawEllipse(-w / 2, -h / 2, w, h);
            g.endFill();
            
            _castleContactShadow.x = _mainCastle.x;
            _castleContactShadow.y = _mainCastle.y + CONTACT_OFFSET_Y;
        }
        
        private function tintToSingleColor(target:*, color:uint):void {
            var r:int = (color >> 16) & 0xFF;
            var g:int = (color >> 8) & 0xFF;
            var b:int = color & 0xFF;
            target.transform.colorTransform = new ColorTransform(0, 0, 0, 1, r, g, b, 0);
        }
        
        // Getters
        public function get mainCastle():Sprite { return _mainCastle; }
        public function get mainCastleBitmap():Bitmap { return _mainCastleBitmap; }
        public function get castleScale():Number { return _castleScale; }
        public function set castleScale(v:Number):void { _castleScale = v; }
        public function get isLoaded():Boolean { return _mainCastleBitmap != null; }
        public function get castleX():Number { return _mainCastle ? _mainCastle.x : 0; }
        public function get castleY():Number { return _mainCastle ? _mainCastle.y : 0; }
        
        public function onResize(stageW:Number, stageH:Number):void {
            _stageWidth = stageW;
            _stageHeight = stageH;
            updatePosition();
        }
        
        public function dispose():void {
            stopCastlePopAnimation();
            if (_castleShadow && _castleShadow.parent) _castleShadow.parent.removeChild(_castleShadow);
        }
    }
}
