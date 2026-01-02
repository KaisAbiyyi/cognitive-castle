package ui.game {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.utils.Dictionary;
    
    /**
     * OrbHUD - Win charge orb display (3 orbs).
     */
    public class OrbHUD extends Sprite {
        
        private static const DEBUG:Boolean = true;
        private static const ORB_COUNT:int = 3;
        private static const ORB_FILL_PULSE_AMOUNT:Number = 0.18;
        private static const ORB_FILL_PULSE_MS:int = 160;
        private static const ORB_FULL_PULSE_AMOUNT:Number = 0.22;
        private static const ORB_FULL_PULSE_MS:int = 220;
        
        private var _orbSprites:Vector.<Sprite>;
        private var _orbBitmaps:Vector.<Bitmap>;
        private var _orbEmptyData:BitmapData;
        private var _orbFilledData:BitmapData;
        private var _orbCharge:int = 0;
        private var _orbDesiredHeight:Number = 24;
        private var _orbGap:Number = 10;
        private var _orbTopPadding:Number = 18;
        private var _orbPulseBySprite:Dictionary;
        private var _orbPulseByTimer:Dictionary;
        private var _orbResetTimer:Timer;
        private var _stageWidth:Number;
        
        public function OrbHUD() {
            mouseEnabled = false;
            mouseChildren = false;
            _orbPulseBySprite = new Dictionary(true);
            _orbPulseByTimer = new Dictionary(true);
            _orbSprites = new Vector.<Sprite>();
            _orbBitmaps = new Vector.<Bitmap>();
        }
        
        public function initialize(stageW:Number):void {
            _stageWidth = stageW;
            
            for (var i:int = 0; i < ORB_COUNT; i++) {
                var orb:Sprite = new Sprite();
                orb.mouseEnabled = false;
                
                var bmp:Bitmap = new Bitmap();
                bmp.smoothing = true;
                orb.addChild(bmp);
                
                addChild(orb);
                _orbSprites.push(orb);
                _orbBitmaps.push(bmp);
            }
            
            loadOrbAssets();
            layout();
            setCharge(0, false);
        }
        
        private function loadOrbAssets():void {
            if (_orbEmptyData && _orbFilledData) { applyOrbVisuals(); return; }
            
            var emptyLoader:Loader = new Loader();
            emptyLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = Bitmap(e.target.content);
                _orbEmptyData = bmp.bitmapData;
                finalizeIfReady();
            });
            emptyLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
                _orbEmptyData = createFallbackOrbBitmap(false);
                finalizeIfReady();
            });
            emptyLoader.load(new URLRequest("assets/images/Game/orb.png"));
            
            var filledLoader:Loader = new Loader();
            filledLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = Bitmap(e.target.content);
                _orbFilledData = bmp.bitmapData;
                finalizeIfReady();
            });
            filledLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
                _orbFilledData = createFallbackOrbBitmap(true);
                finalizeIfReady();
            });
            filledLoader.load(new URLRequest("assets/images/Game/orbFilled.png"));
        }
        
        private function finalizeIfReady():void {
            if (!_orbEmptyData || !_orbFilledData) return;
            applyOrbVisuals();
        }
        
        private function applyOrbVisuals():void {
            if (!_orbBitmaps || _orbBitmaps.length != ORB_COUNT) return;
            
            for (var i:int = 0; i < ORB_COUNT; i++) {
                var bmp:Bitmap = _orbBitmaps[i];
                bmp.smoothing = true;
                bmp.bitmapData = (i < _orbCharge) ? _orbFilledData : _orbEmptyData;
                bmp.x = -bmp.bitmapData.width / 2;
                bmp.y = -bmp.bitmapData.height / 2;
            }
            layout();
        }
        
        public function layout():void {
            stopAllPulses();
            
            var baseW:Number = _orbEmptyData ? _orbEmptyData.width : 64;
            var baseH:Number = _orbEmptyData ? _orbEmptyData.height : 64;
            var baseScale:Number = (baseH > 0) ? (_orbDesiredHeight / baseH) : 1.0;
            
            for each (var orb:Sprite in _orbSprites) {
                orb.scaleX = baseScale;
                orb.scaleY = baseScale;
            }
            
            var orbWidth:Number = baseW * baseScale;
            var step:Number = orbWidth + _orbGap;
            var startX:Number = -((ORB_COUNT - 1) * step) / 2;
            
            for (var i:int = 0; i < ORB_COUNT; i++) {
                _orbSprites[i].x = startX + (i * step);
                _orbSprites[i].y = 0;
            }
            
            x = _stageWidth / 2;
            y = _orbTopPadding;
        }
        
        public function setCharge(charge:int, animateFill:Boolean):void {
            var clamped:int = Math.max(0, Math.min(ORB_COUNT, charge));
            var prev:int = _orbCharge;
            _orbCharge = clamped;
            
            if (!_orbEmptyData || !_orbFilledData || !_orbBitmaps) return;
            
            for (var i:int = 0; i < ORB_COUNT; i++) {
                var bmp:Bitmap = _orbBitmaps[i];
                bmp.bitmapData = (i < _orbCharge) ? _orbFilledData : _orbEmptyData;
                bmp.x = -bmp.bitmapData.width / 2;
                bmp.y = -bmp.bitmapData.height / 2;
            }
            
            if (animateFill && _orbCharge > prev) {
                for (var j:int = prev; j < _orbCharge; j++) {
                    pulseOrb(_orbSprites[j], ORB_FILL_PULSE_AMOUNT, ORB_FILL_PULSE_MS);
                }
            }
        }
        
        public function reset():void {
            stopResetTimer();
            stopAllPulses();
            setCharge(0, false);
        }
        
        public function showFullAndReset():void {
            stopResetTimer();
            stopAllPulses();
            setCharge(ORB_COUNT, false);
            
            for (var i:int = 0; i < ORB_COUNT; i++) {
                pulseOrb(_orbSprites[i], ORB_FULL_PULSE_AMOUNT, ORB_FULL_PULSE_MS);
            }
            
            _orbResetTimer = new Timer(ORB_FULL_PULSE_MS, 1);
            _orbResetTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
                stopResetTimer();
                setCharge(0, false);
            });
            _orbResetTimer.start();
        }
        
        private function stopResetTimer():void {
            if (_orbResetTimer) {
                _orbResetTimer.stop();
                _orbResetTimer = null;
            }
        }
        
        private function pulseOrb(orb:Sprite, amount:Number, durationMs:int):void {
            if (!orb) return;
            stopPulse(orb);
            
            var timer:Timer = new Timer(16);
            var state:Object = {
                orb: orb,
                startMs: new Date().time,
                baseScale: orb.scaleX,
                amount: amount,
                durationMs: durationMs
            };
            
            _orbPulseBySprite[orb] = timer;
            _orbPulseByTimer[timer] = state;
            
            timer.addEventListener(TimerEvent.TIMER, onPulseTick);
            timer.start();
        }
        
        private function onPulseTick(e:TimerEvent):void {
            var timer:Timer = e.target as Timer;
            if (!timer) return;
            
            var state:Object = _orbPulseByTimer[timer];
            if (!state) return;
            
            var orb:Sprite = state.orb as Sprite;
            if (!orb) { stopPulseTimer(timer); return; }
            
            var elapsed:Number = new Date().time - Number(state.startMs);
            var t:Number = Math.min(elapsed / Math.max(1, Number(state.durationMs)), 1.0);
            
            var bump:Number = Math.sin(Math.PI * t);
            var s:Number = Number(state.baseScale) * (1 + (Number(state.amount) * bump));
            orb.scaleX = s;
            orb.scaleY = s;
            
            if (t >= 1.0) {
                orb.scaleX = Number(state.baseScale);
                orb.scaleY = Number(state.baseScale);
                stopPulseTimer(timer);
            }
        }
        
        private function stopPulse(orb:Sprite):void {
            if (!orb) return;
            var timer:Timer = _orbPulseBySprite[orb] as Timer;
            if (timer) stopPulseTimer(timer);
        }
        
        private function stopPulseTimer(timer:Timer):void {
            if (!timer) return;
            var state:Object = _orbPulseByTimer[timer];
            if (state && state.orb) {
                state.orb.scaleX = Number(state.baseScale);
                state.orb.scaleY = Number(state.baseScale);
                delete _orbPulseBySprite[state.orb];
            }
            delete _orbPulseByTimer[timer];
            timer.stop();
            timer.removeEventListener(TimerEvent.TIMER, onPulseTick);
        }
        
        private function stopAllPulses():void {
            if (!_orbPulseByTimer) return;
            var timers:Array = [];
            for (var key:* in _orbPulseByTimer) timers.push(key);
            for each (var t:Timer in timers) stopPulseTimer(t);
        }
        
        private function createFallbackOrbBitmap(filled:Boolean):BitmapData {
            var size:int = 64;
            var s:Shape = new Shape();
            var g:* = s.graphics;
            g.clear();
            if (filled) {
                g.beginFill(0xFFD54A);
                g.drawCircle(size / 2, size / 2, (size / 2) - 4);
                g.endFill();
            } else {
                g.lineStyle(6, 0xFFD54A);
                g.drawCircle(size / 2, size / 2, (size / 2) - 6);
            }
            var bmd:BitmapData = new BitmapData(size, size, true, 0x00000000);
            bmd.draw(s);
            return bmd;
        }
        
        public function updateResponsive(scale:Number):void {
            _orbDesiredHeight = Math.max(18, Math.min(34, 26 * scale));
            _orbGap = Math.max(8, 12 * scale);
            _orbTopPadding = Math.max(10, 18 * scale);
        }
        
        public function onResize(stageW:Number):void {
            _stageWidth = stageW;
            layout();
        }
        
        public function get charge():int { return _orbCharge; }
        
        public function dispose():void {
            stopResetTimer();
            stopAllPulses();
        }
    }
}
