package ui {
    import flash.display.*;
    import flash.events.*;
    import flash.media.Video;
    import flash.net.*;
    import flash.utils.Timer;
    import flash.filesystem.File;
    import flash.text.TextField;
    import services.AudioManager;

    public class LessonsPanel extends MovieClip {
        public static const CLOSE_CLICKED:String = "closeClicked";
        public var btnClose:SimpleButton;
        public var btnL1:SimpleButton, btnL2:SimpleButton, btnL3:SimpleButton;
        public var btnL4:SimpleButton, btnL5:SimpleButton, btnL6:SimpleButton;
        
        private var _nc:NetConnection;
        private var _ns:NetStream;
        private var _video:Video;
        private var _videoContainer:Sprite;
        private var _backBtn:Sprite;
        private var _backBtnWidth:Number = 140;
        private var _backBtnHeight:Number = 56;
        private var _backHoverScale:Number = 0.96;
        private var _backNormalScale:Number = 1.0;
        private var _backBaseX:Number = 0;
        private var _backBaseY:Number = 0;
        private var _fadeTimer:Timer;
        private var _prevBgVolume:Number = 1.0;

        public function LessonsPanel() {
            visible = false;
            if (stage) setupButtons(); else addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void { setupButtons(); });
        }

        public function initialize(w:Number, h:Number):void { x = 0; y = 0; }

        private function setupButtons():void {
            if (btnClose) btnClose.addEventListener(MouseEvent.CLICK, onCloseClick);
            
            if (btnL1) btnL1.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { playVideo("assets/videoOpening.mp4"); });
            if (btnL2) btnL2.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { playVideo("assets/videoKedua.mp4"); });
            if (btnL3) btnL3.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { playVideo("assets/M1.mp4"); });
            if (btnL4) btnL4.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { playVideo("assets/M2.mp4"); });
            if (btnL5) btnL5.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { playVideo("assets/M3.mp4"); });
            if (btnL6) btnL6.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { playVideo("assets/M4.mp4"); });
        }

        private function onCloseClick(e:MouseEvent):void {
            dispatchEvent(new Event(CLOSE_CLICKED));
        }
        
        public function show():void { visible = true; }
        public function hide():void { visible = false; stopVideo(); }

        private function playVideo(path:String):void {
            fadeBgm(0); 
            stopVideo(false);

            _videoContainer = new Sprite();
            var bg:Shape = new Shape();
            bg.graphics.beginFill(0x000000, 0.85);
            bg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            _videoContainer.addChild(bg);
            bg.addEventListener(MouseEvent.CLICK, function(e:Event):void { stopVideo(); });

            _video = new Video(stage.stageWidth, stage.stageHeight);
            _video.smoothing = true;
            _videoContainer.addChild(_video);
            stage.addChild(_videoContainer);

            _nc = new NetConnection(); _nc.connect(null);
            _ns = new NetStream(_nc);
            _ns.client = { onMetaData: function(o:Object):void{} };
            _ns.addEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent):void { if(e.info.code == "NetStream.Play.Stop") stopVideo(); });
            _video.attachNetStream(_ns);
            _ns.play(path);

            createBackButton();
        }

        private function stopVideo(resumeBgm:Boolean = true):void {
            if (_ns) { _ns.close(); _ns = null; }
            if (_nc) { _nc.close(); _nc = null; }
            if (_video) { _video.attachNetStream(null); _video = null; }
            if (_videoContainer && stage.contains(_videoContainer)) stage.removeChild(_videoContainer);
            if (_backBtn) {
                try {
                    _backBtn.removeEventListener(MouseEvent.CLICK, function(e:Event):void { stopVideo(); });
                    _backBtn.removeEventListener(MouseEvent.MOUSE_OVER, onBackOver);
                    _backBtn.removeEventListener(MouseEvent.MOUSE_OUT, onBackOut);
                } catch(err:Error) {}
                try { if (stage && stage.contains(_backBtn)) stage.removeChild(_backBtn); } catch(err:Error) {}
            }
            
            if (resumeBgm) {
                AudioManager.getInstance().play("Bgmlobby", 0, 9999);
                fadeBgm(_prevBgVolume);
            }
        }

        private function fadeBgm(targetVol:Number):void {
            if (_fadeTimer) { _fadeTimer.stop(); _fadeTimer = null; }
            if (targetVol == 0) _prevBgVolume = AudioManager.getInstance().getMusicVolume();
            
            _fadeTimer = new Timer(50, 8);
            var step:Number = (targetVol - AudioManager.getInstance().getMusicVolume()) / 8;
            
            _fadeTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
                AudioManager.getInstance().setMusicVolume(AudioManager.getInstance().getMusicVolume() + step);
            });
            _fadeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
                AudioManager.getInstance().setMusicVolume(targetVol);
            });
            _fadeTimer.start();
        }

        private function createBackButton():void {
            _backBtn = new Sprite();
            _backBtn.graphics.beginFill(0, 0); _backBtn.graphics.drawRect(0, 0, 140, 56);
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = e.target.content as Bitmap;
                bmp.width = _backBtnWidth; bmp.height = _backBtnHeight; bmp.smoothing = true;
                _backBtn.addChild(bmp);
                // ensure normal scale/position after image added
                applyBackScale(_backNormalScale);
            });
            // Fallback sederhana jika error, gambar kotak
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void {
                _backBtn.graphics.beginFill(0x000000, 0.5); _backBtn.graphics.lineStyle(2,0xFFFFFF);
                _backBtn.graphics.drawRect(0,0,140,56);
            });
            
            try { loader.load(new URLRequest("assets/Gambar/backV.png")); } catch(e:Error){}
            
            // store base position (20px margin from right/top)
            _backBaseX = stage.stageWidth - (_backBtnWidth + 20);
            _backBaseY = 20;
            // apply normal position/scale
            applyBackScale(_backNormalScale);

            _backBtn.buttonMode = true;
            _backBtn.addEventListener(MouseEvent.CLICK, function(e:Event):void { stopVideo(); });
            _backBtn.addEventListener(MouseEvent.MOUSE_OVER, onBackOver);
            _backBtn.addEventListener(MouseEvent.MOUSE_OUT, onBackOut);
            stage.addChild(_backBtn);
        }

        private function applyBackScale(s:Number):void {
            try {
                if (!_backBtn) return;
                _backBtn.scaleX = _backBtn.scaleY = s;
                _backBtn.x = _backBaseX + (_backBtnWidth * (1 - s) / 2);
                _backBtn.y = _backBaseY + (_backBtnHeight * (1 - s) / 2);
            } catch(err:Error) {}
        }

        private function onBackOver(e:MouseEvent):void {
            try { applyBackScale(_backHoverScale); } catch(err:Error) {}
        }

        private function onBackOut(e:MouseEvent):void {
            try { applyBackScale(_backNormalScale); } catch(err:Error) {}
        }
        
        public function dispose():void { stopVideo(); }
    }
}