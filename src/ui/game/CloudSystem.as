package ui.game {
    
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    /**
     * CloudSystem - Handles parallax cloud animation.
     */
    public class CloudSystem extends Sprite {
        
        private var _clouds:Vector.<Object>;
        private var _cloudTimer:Timer;
        private var _stageWidth:Number;
        private var _isPaused:Boolean = false;
        
        public function CloudSystem() {
            _clouds = new Vector.<Object>();
        }
        
        public function initialize(stageWidth:Number):void {
            _stageWidth = stageWidth;
            
            var cloudConfigs:Array = [
                { file: "cloud1.png", count: 2, speed: 0.2, yRange: [80, 150], scale: 0.6 },
                { file: "cloud2.png", count: 2, speed: 0.4, yRange: [120, 180], scale: 0.8 },
                { file: "cloud3.png", count: 2, speed: 0.7, yRange: [100, 160], scale: 1.0 },
                { file: "cloud4.png", count: 2, speed: 1.0, yRange: [50, 120], scale: 0.7 }
            ];
            
            for (var i:int = 0; i < cloudConfigs.length; i++) {
                var config:Object = cloudConfigs[i];
                for (var j:int = 0; j < config.count; j++) {
                    loadCloud(config, j);
                }
            }
            
            _cloudTimer = new Timer(33);
            _cloudTimer.addEventListener(TimerEvent.TIMER, onCloudTick);
            _cloudTimer.start();
        }
        
        private function loadCloud(config:Object, index:int):void {
            var loader:Loader = new Loader();
            var cloudData:Object = {
                loader: loader,
                speed: config.speed,
                yRange: config.yRange,
                scale: config.scale,
                index: index,
                loaded: false
            };
            
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bitmap:Bitmap = Bitmap(e.target.content);
                bitmap.smoothing = true;
                bitmap.scaleX = cloudData.scale;
                bitmap.scaleY = cloudData.scale;
                bitmap.x = Math.random() * (_stageWidth + 200) - 100;
                bitmap.y = cloudData.yRange[0] + Math.random() * (cloudData.yRange[1] - cloudData.yRange[0]);
                bitmap.alpha = 0.7 + Math.random() * 0.3;
                
                cloudData.bitmap = bitmap;
                cloudData.loaded = true;
                _clouds.push(cloudData);
                addChild(bitmap);
            });
            
            loader.load(new URLRequest("assets/images/Game/" + config.file));
        }
        
        private function onCloudTick(e:TimerEvent):void {
            if (_isPaused) return;
            
            for (var i:int = 0; i < _clouds.length; i++) {
                var cloud:Object = _clouds[i];
                if (!cloud.loaded || !cloud.bitmap) continue;
                
                cloud.bitmap.x += cloud.speed;
                
                if (cloud.bitmap.x > _stageWidth + 50) {
                    cloud.bitmap.x = -cloud.bitmap.width - 50;
                    cloud.bitmap.y = cloud.yRange[0] + Math.random() * (cloud.yRange[1] - cloud.yRange[0]);
                }
            }
        }
        
        public function set paused(value:Boolean):void { _isPaused = value; }
        public function get paused():Boolean { return _isPaused; }
        
        public function dispose():void {
            if (_cloudTimer) {
                _cloudTimer.stop();
                _cloudTimer.removeEventListener(TimerEvent.TIMER, onCloudTick);
                _cloudTimer = null;
            }
            _clouds = null;
        }
    }
}
