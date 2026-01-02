package ui.game {
    
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.BlendMode;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    /**
     * UpgradeFX - Visual effects (lamp + gear icons) for upgrades.
     */
    public class UpgradeFX extends Sprite {
        
        private static const UPGRADE_FX_ICON_HEIGHT:Number = 40;
        
        private var _fxItems:Vector.<Object>;
        private var _fxTimer:Timer;
        private var _lampBitmapData:BitmapData;
        private var _gearBitmapData:BitmapData;
        private var _isPaused:Boolean = false;
        
        public function UpgradeFX() {
            mouseEnabled = false;
            mouseChildren = false;
            _fxItems = new Vector.<Object>();
            preloadAssets();
        }
        
        private function preloadAssets():void {
            loadBitmapData("assets/Gambar/Lampu1.png", function(bmd:BitmapData):void {
                _lampBitmapData = bmd;
            });
            loadBitmapData("assets/Gambar/Gear1.png", function(bmd:BitmapData):void {
                _gearBitmapData = bmd;
            });
        }
        
        private function loadBitmapData(path:String, callback:Function):void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = Bitmap(e.target.content);
                if (bmp && bmp.bitmapData != null) callback(bmp.bitmapData);
            });
            loader.load(new URLRequest(path));
        }
        
        public function playRiseEffect(baseX:Number, baseY:Number):void {
            if (!_lampBitmapData || !_gearBitmapData) return;
            
            spawnItem(true, baseX, baseY);
            spawnItem(false, baseX, baseY);
            spawnItem(true, baseX, baseY);
            spawnItem(false, baseX, baseY);
        }
        
        private function spawnItem(isLamp:Boolean, baseX:Number, baseY:Number):void {
            var bmd:BitmapData = isLamp ? _lampBitmapData : _gearBitmapData;
            if (!bmd) return;
            
            var bmp:Bitmap = new Bitmap(bmd);
            bmp.smoothing = true;
            
            var scale:Number = UPGRADE_FX_ICON_HEIGHT / bmp.height;
            bmp.scaleX = scale;
            bmp.scaleY = scale;
            bmp.x = -bmp.width / 2;
            bmp.y = -bmp.height / 2;
            
            var sprite:Sprite = new Sprite();
            sprite.mouseEnabled = false;
            if (isLamp) sprite.blendMode = BlendMode.ADD;
            sprite.addChild(bmp);
            
            sprite.x = baseX + (Math.random() - 0.5) * 90;
            sprite.y = baseY + (Math.random() - 0.5) * 40;
            sprite.alpha = 0;
            
            addChild(sprite);
            
            _fxItems.push({
                sprite: sprite,
                vx: (Math.random() - 0.5) * 0.6,
                vy: -(1.8 + Math.random() * 1.2),
                rot: isLamp ? ((Math.random() - 0.5) * 0.6) : ((Math.random() > 0.5 ? 1 : -1) * (2.5 + Math.random() * 3.0)),
                age: 0,
                life: 900 + Math.random() * 400,
                baseAlpha: isLamp ? 0.55 : 0.45
            });
            
            ensureTimer();
        }
        
        private function ensureTimer():void {
            if (_fxTimer) return;
            _fxTimer = new Timer(33);
            _fxTimer.addEventListener(TimerEvent.TIMER, onTick);
            _fxTimer.start();
        }
        
        private function onTick(e:TimerEvent):void {
            if (_isPaused) return;
            if (!_fxItems || _fxItems.length == 0) { stopTimer(); return; }
            
            var frameMs:Number = 33;
            
            for (var i:int = _fxItems.length - 1; i >= 0; i--) {
                var item:Object = _fxItems[i];
                item.age += frameMs;
                
                var sprite:Sprite = item.sprite as Sprite;
                if (!sprite) { _fxItems.splice(i, 1); continue; }
                
                sprite.x += item.vx;
                sprite.y += item.vy;
                sprite.rotation += item.rot;
                
                var alpha:Number = item.baseAlpha;
                alpha *= Math.min(1, item.age / 120);
                
                var fadeOutStart:Number = item.life - 250;
                if (item.age >= fadeOutStart) {
                    alpha *= (1 - Math.min(1, (item.age - fadeOutStart) / 250));
                }
                sprite.alpha = alpha;
                
                if (item.age >= item.life) {
                    if (sprite.parent) sprite.parent.removeChild(sprite);
                    _fxItems.splice(i, 1);
                }
            }
            
            if (_fxItems.length == 0) stopTimer();
        }
        
        private function stopTimer():void {
            if (_fxTimer) {
                _fxTimer.stop();
                _fxTimer.removeEventListener(TimerEvent.TIMER, onTick);
                _fxTimer = null;
            }
        }
        
        public function clear():void {
            stopTimer();
            if (_fxItems) _fxItems.length = 0;
            while (numChildren > 0) removeChildAt(0);
        }
        
        public function set paused(value:Boolean):void { _isPaused = value; }
        
        public function dispose():void {
            clear();
        }
    }
}
