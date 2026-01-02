package ui.game {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    /**
     * PauseSystem - Handles pause overlay, popup, and related buttons.
     */
    public class PauseSystem extends Sprite {
        
        private static const DEBUG:Boolean = true;
        private static const HOVER_SCALE:Number = 1.15;
        
        // Events
        public static const MAIN_MENU_CLICKED:String = "goToMainMenu";
        public static const RETRY_CLICKED:String = "retryGame";
        public static const SAVE_CLICKED:String = "saveGame";
        
        // Visual components
        private var _pauseOverlay:Shape;
        private var _pausePopup:Sprite;
        private var _pausePopupBitmap:Bitmap;
        private var _pauseXButton:Sprite;
        private var _mainMenuButton:Sprite;
        private var _retryButton:Sprite;
        private var _saveButton:Sprite;
        
        // Save notification
        private var _saveNotificationBg:Sprite;
        private var _saveNotificationTimer:Timer;
        
        // State
        private var _isPaused:Boolean = false;
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Callbacks
        private var _onPauseChanged:Function;
        private var _onSave:Function;
        
        public function PauseSystem() {}
        
        public function initialize(stageW:Number, stageH:Number, callbacks:Object):void {
            _stageWidth = stageW;
            _stageHeight = stageH;
            _onPauseChanged = callbacks.onPauseChanged;
            _onSave = callbacks.onSave;
            
            createPauseOverlay();
            createSaveNotification();
        }
        
        private function createPauseOverlay():void {
            _pauseOverlay = new Shape();
            drawPauseOverlay();
            _pauseOverlay.visible = false;
            addChild(_pauseOverlay);
            
            _pausePopup = new Sprite();
            _pausePopup.visible = false;
            addChild(_pausePopup);
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPausePopupLoaded);
            loader.load(new URLRequest("assets/images/Game/pausePopup.png"));
        }
        
        private function drawPauseOverlay():void {
            var g:* = _pauseOverlay.graphics;
            g.clear();
            g.beginFill(0x000000, 0.7);
            g.drawRect(0, 0, _stageWidth, _stageHeight);
            g.endFill();
        }
        
        private function onPausePopupLoaded(e:Event):void {
            _pausePopupBitmap = Bitmap(e.target.content);
            _pausePopupBitmap.smoothing = true;
            
            var maxWidth:Number = _stageWidth * 0.6;
            if (_pausePopupBitmap.width > maxWidth) {
                var scale:Number = maxWidth / _pausePopupBitmap.width;
                _pausePopupBitmap.scaleX = scale;
                _pausePopupBitmap.scaleY = scale;
            }
            
            _pausePopup.addChild(_pausePopupBitmap);
            _pausePopup.x = (_stageWidth - _pausePopupBitmap.width) / 2;
            _pausePopup.y = (_stageHeight - _pausePopupBitmap.height) / 2;
            
            createPausePopupButtons();
        }
        
        private function createPausePopupButtons():void {
            loadPausePopupButton("xButton.png", function(btn:Sprite, bmp:Bitmap):void {
                _pauseXButton = btn;
                btn.x = _pausePopupBitmap.width - bmp.width / 2 - 20;
                btn.y = bmp.height / 2 + 20;
                btn.addEventListener(MouseEvent.CLICK, onPauseXClick);
            }, 120);
            
            loadPausePopupButton("saveButton.png", function(btn:Sprite, bmp:Bitmap):void {
                _saveButton = btn;
                btn.x = _pausePopupBitmap.width / 2;
                btn.y = _pausePopupBitmap.height * 0.35;
                btn.addEventListener(MouseEvent.CLICK, onSaveClick);
            }, 320);
            
            loadPausePopupButton("retryButton.png", function(btn:Sprite, bmp:Bitmap):void {
                _retryButton = btn;
                btn.x = _pausePopupBitmap.width / 2;
                btn.y = _pausePopupBitmap.height * 0.52;
                btn.addEventListener(MouseEvent.CLICK, onRetryClick);
            }, 320);
            
            loadPausePopupButton("mainMenuButton.png", function(btn:Sprite, bmp:Bitmap):void {
                _mainMenuButton = btn;
                btn.x = _pausePopupBitmap.width / 2;
                btn.y = _pausePopupBitmap.height * 0.69;
                btn.addEventListener(MouseEvent.CLICK, onMainMenuClick);
            }, 320);
        }
        
        private function loadPausePopupButton(filename:String, setupCallback:Function, targetWidth:Number):void {
            var btn:Sprite = new Sprite();
            var loader:Loader = new Loader();
            
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = Bitmap(e.target.content);
                bmp.smoothing = true;
                
                var scale:Number = targetWidth / bmp.width;
                bmp.scaleX = scale;
                bmp.scaleY = scale;
                bmp.x = -bmp.width / 2;
                bmp.y = -bmp.height / 2;
                
                btn.addChild(bmp);
                btn.buttonMode = true;
                btn.useHandCursor = true;
                
                btn.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
                    btn.scaleX = HOVER_SCALE;
                    btn.scaleY = HOVER_SCALE;
                });
                btn.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
                    btn.scaleX = 1.0;
                    btn.scaleY = 1.0;
                });
                
                setupCallback(btn, bmp);
                _pausePopup.addChild(btn);
            });
            
            loader.load(new URLRequest("assets/images/Game/" + filename));
        }
        
        private function onPauseXClick(e:MouseEvent):void { hide(); }
        
        private function onMainMenuClick(e:MouseEvent):void {
            hide();
            dispatchEvent(new Event(MAIN_MENU_CLICKED));
        }
        
        private function onRetryClick(e:MouseEvent):void {
            hide();
            dispatchEvent(new Event(RETRY_CLICKED));
        }
        
        private function onSaveClick(e:MouseEvent):void {
            if (_onSave != null) _onSave();
        }
        
        public function show():void {
            _isPaused = true;
            _pauseOverlay.visible = true;
            _pausePopup.visible = true;
            if (_onPauseChanged != null) _onPauseChanged(true);
            if (DEBUG) trace("[PauseSystem] PAUSED");
        }
        
        public function hide():void {
            _isPaused = false;
            _pauseOverlay.visible = false;
            _pausePopup.visible = false;
            if (_onPauseChanged != null) _onPauseChanged(false);
            if (DEBUG) trace("[PauseSystem] RESUMED");
        }
        
        // Save notification
        private function createSaveNotification():void {
            _saveNotificationBg = new Sprite();
            _saveNotificationBg.visible = false;
            addChild(_saveNotificationBg);
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var notifBitmap:Bitmap = Bitmap(e.target.content);
                notifBitmap.smoothing = true;
                _saveNotificationBg.addChild(notifBitmap);
            });
            loader.load(new URLRequest("assets/images/Game/savedNotif.png"));
            
            _saveNotificationTimer = new Timer(2000, 1);
            _saveNotificationTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
                _saveNotificationBg.visible = false;
            });
        }
        
        public function showSaveNotification():void {
            if (_saveNotificationBg && _saveNotificationBg.numChildren > 0) {
                var notifBitmap:Bitmap = _saveNotificationBg.getChildAt(0) as Bitmap;
                if (notifBitmap) {
                    notifBitmap.scaleX = 0.3;
                    notifBitmap.scaleY = 0.3;
                    _saveNotificationBg.x = 20;
                    _saveNotificationBg.y = 20;
                }
            }
            _saveNotificationBg.visible = true;
            _saveNotificationBg.alpha = 1.0;
            _saveNotificationTimer.reset();
            _saveNotificationTimer.start();
        }
        
        public function onResize(stageW:Number, stageH:Number):void {
            _stageWidth = stageW;
            _stageHeight = stageH;
            drawPauseOverlay();
            if (_pausePopup && _pausePopupBitmap) {
                _pausePopup.x = (_stageWidth - _pausePopupBitmap.width) / 2;
                _pausePopup.y = (_stageHeight - _pausePopupBitmap.height) / 2;
            }
        }
        
        public function bringToFront():void {
            if (parent) {
                if (parent.contains(_pauseOverlay)) parent.setChildIndex(this, parent.numChildren - 1);
            }
        }
        
        public function get isPaused():Boolean { return _isPaused; }
        public function get saveNotificationBg():Sprite { return _saveNotificationBg; }
        
        public function dispose():void {
            if (_saveNotificationTimer) { _saveNotificationTimer.stop(); _saveNotificationTimer = null; }
        }
    }
}
