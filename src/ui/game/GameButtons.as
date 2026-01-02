package ui.game {
    
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    /**
     * GameButtons - Manages upgrade and pause button UI.
     */
    public class GameButtons extends Sprite {
        
        private static const HOVER_SCALE:Number = 1.15;
        
        public static const UPGRADE_CLICKED:String = "upgradeClicked";
        public static const PAUSE_CLICKED:String = "pauseClicked";
        
        private var _upgradeButton:Sprite;
        private var _upgradeButtonBitmap:Bitmap;
        private var _pauseButton:Sprite;
        private var _pauseButtonBitmap:Bitmap;
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        public function GameButtons() {}
        
        public function initialize(stageW:Number, stageH:Number):void {
            _stageWidth = stageW;
            _stageHeight = stageH;
            createUpgradeButton();
            createPauseButton();
        }
        
        private function createUpgradeButton():void {
            _upgradeButton = new Sprite();
            addChild(_upgradeButton);
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _upgradeButtonBitmap = Bitmap(e.target.content);
                _upgradeButtonBitmap.smoothing = true;
                var scale:Number = 120 / _upgradeButtonBitmap.width;
                _upgradeButtonBitmap.scaleX = scale;
                _upgradeButtonBitmap.scaleY = scale;
                _upgradeButtonBitmap.x = -_upgradeButtonBitmap.width / 2;
                _upgradeButtonBitmap.y = -_upgradeButtonBitmap.height / 2;
                _upgradeButton.addChild(_upgradeButtonBitmap);
                positionUpgradeButton();
                
                _upgradeButton.buttonMode = true;
                _upgradeButton.useHandCursor = true;
                _upgradeButton.addEventListener(MouseEvent.CLICK, onUpgradeClick);
                _upgradeButton.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { animateScale(_upgradeButton, HOVER_SCALE); });
                _upgradeButton.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { animateScale(_upgradeButton, 1.0); });
            });
            loader.load(new URLRequest("assets/images/Game/upgradeButton.png"));
        }
        
        private function createPauseButton():void {
            _pauseButton = new Sprite();
            addChild(_pauseButton);
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _pauseButtonBitmap = Bitmap(e.target.content);
                _pauseButtonBitmap.smoothing = true;
                var scale:Number = 120 / _pauseButtonBitmap.width;
                _pauseButtonBitmap.scaleX = scale;
                _pauseButtonBitmap.scaleY = scale;
                _pauseButtonBitmap.x = -_pauseButtonBitmap.width / 2;
                _pauseButtonBitmap.y = -_pauseButtonBitmap.height / 2;
                _pauseButton.addChild(_pauseButtonBitmap);
                positionPauseButton();
                
                _pauseButton.buttonMode = true;
                _pauseButton.useHandCursor = true;
                _pauseButton.addEventListener(MouseEvent.CLICK, onPauseClick);
                _pauseButton.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { animateScale(_pauseButton, HOVER_SCALE); });
                _pauseButton.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { animateScale(_pauseButton, 1.0); });
            });
            loader.load(new URLRequest("assets/images/Game/pauseButton.png"));
        }
        
        private function onUpgradeClick(e:MouseEvent):void {
            dispatchEvent(new Event(UPGRADE_CLICKED));
        }
        
        private function onPauseClick(e:MouseEvent):void {
            dispatchEvent(new Event(PAUSE_CLICKED));
        }
        
        private function positionUpgradeButton():void {
            if (!_upgradeButton || !_upgradeButtonBitmap) return;
            _upgradeButton.x = _upgradeButtonBitmap.width / 2 + 40;
            _upgradeButton.y = _stageHeight - _upgradeButtonBitmap.height / 2 - 40;
        }
        
        private function positionPauseButton():void {
            if (!_pauseButton || !_pauseButtonBitmap) return;
            _pauseButton.x = _stageWidth - _pauseButtonBitmap.width / 2 - 30;
            _pauseButton.y = _pauseButtonBitmap.height / 2 + 30;
        }
        
        private function animateScale(target:Sprite, targetScale:Number):void {
            target.scaleX = targetScale;
            target.scaleY = targetScale;
        }
        
        public function setUpgradeVisible(visible:Boolean):void {
            if (_upgradeButton) _upgradeButton.visible = visible;
        }
        
        public function setUpgradeEnabled(enabled:Boolean):void {
            if (_upgradeButton) {
                _upgradeButton.mouseEnabled = enabled;
                _upgradeButton.alpha = enabled ? 1.0 : 0.5;
            }
        }
        
        public function onResize(stageW:Number, stageH:Number):void {
            _stageWidth = stageW;
            _stageHeight = stageH;
            positionUpgradeButton();
            positionPauseButton();
        }
        
        public function get upgradeButton():Sprite { return _upgradeButton; }
        public function get pauseButton():Sprite { return _pauseButton; }
    }
}
