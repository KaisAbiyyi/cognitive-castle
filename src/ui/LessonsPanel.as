package ui {
    import flash.display.*;
    import flash.events.*;
    import flash.media.Video;
    import flash.net.*;
    import flash.utils.Timer;
    import flash.filesystem.File;
    import flash.text.TextField;
    import services.AudioManager;
    import services.SaveSystem;
    import ui.components.VideoControls;

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
        
        // Video Controls
        private var _videoControls:VideoControls;
        private var _videoDuration:Number = 0;
        private var _autoHideTimer:Timer;
        private var _controlsVisible:Boolean = true;

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
            // Pause BGM instead of fading to 0
            AudioManager.getInstance().pauseBgm();
            stopVideo(false);

            _videoContainer = new Sprite();
            var bg:Shape = new Shape();
            bg.graphics.beginFill(0x000000, 1.0);
            bg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            _videoContainer.addChild(bg);
            
            // Click on video area to toggle play/pause
            bg.addEventListener(MouseEvent.CLICK, onVideoAreaClick);

            // Full screen video
            var videoWidth:Number = stage.stageWidth;
            var videoHeight:Number = stage.stageHeight;
            var controlsY:Number = stage.stageHeight - 60; // Controls at bottom
            
            _video = new Video(videoWidth, videoHeight);
            _video.x = 0;
            _video.y = 0;
            _video.smoothing = true;
            _videoContainer.addChild(_video);
            stage.addChild(_videoContainer);

            _nc = new NetConnection(); _nc.connect(null);
            _ns = new NetStream(_nc);
            
            // Handle metadata to get video duration
            var self:LessonsPanel = this;
            _ns.client = { 
                onMetaData: function(meta:Object):void {
                    self.onVideoMetaData(meta);
                }
            };
            
            _ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
            _video.attachNetStream(_ns);
            _ns.play(path);
            
            // Create video controls at bottom of screen
            createVideoControls(20, controlsY, videoWidth - 40);
            
            createBackButton();
            
            // Setup auto-hide for controls
            setupControlsAutoHide();
        }
        
        private function onVideoAreaClick(e:MouseEvent):void {
            if (_videoControls) {
                if (_videoControls.isPlaying) {
                    _videoControls.pause();
                } else {
                    _videoControls.play();
                }
            }
        }
        
        private function onVideoMetaData(meta:Object):void {
            if (meta.duration) {
                _videoDuration = meta.duration;
                if (_videoControls) {
                    _videoControls.setDuration(_videoDuration);
                }
            }
        }
        
        private function onNetStatus(e:NetStatusEvent):void {
            switch(e.info.code) {
                case "NetStream.Play.Stop":
                    // Video ended - reset controls
                    if (_videoControls) {
                        _videoControls.pause();
                    }
                    break;
                case "NetStream.Play.Start":
                    // Video started playing
                    if (_videoControls) {
                        _videoControls.play();
                    }
                    break;
            }
        }
        
        private function createVideoControls(xPos:Number, yPos:Number, width:Number):void {
            _videoControls = new VideoControls(width);
            _videoControls.x = xPos;
            _videoControls.y = yPos;
            _videoControls.setNetStream(_ns);
            
            _videoControls.addEventListener(VideoControls.PLAY_CLICKED, onControlPlay);
            _videoControls.addEventListener(VideoControls.PAUSE_CLICKED, onControlPause);
            
            stage.addChild(_videoControls);
        }
        
        private function onControlPlay(e:Event):void {
            if (_ns) {
                _ns.resume();
            }
        }
        
        private function onControlPause(e:Event):void {
            if (_ns) {
                _ns.pause();
            }
        }
        
        private function setupControlsAutoHide():void {
            if (_autoHideTimer) {
                _autoHideTimer.stop();
            }
            _autoHideTimer = new Timer(3000, 1);
            _autoHideTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onControlsAutoHide);
            
            // Add mouse move listener to show controls
            if (_videoContainer) {
                _videoContainer.addEventListener(MouseEvent.MOUSE_MOVE, onVideoMouseMove);
            }
        }
        
        private function onVideoMouseMove(e:MouseEvent):void {
            showVideoControls();
            resetAutoHideTimer();
        }
        
        private function resetAutoHideTimer():void {
            if (_autoHideTimer) {
                _autoHideTimer.reset();
                if (_videoControls && _videoControls.isPlaying) {
                    _autoHideTimer.start();
                }
            }
        }
        
        private function onControlsAutoHide(e:TimerEvent):void {
            if (_videoControls && _videoControls.isPlaying) {
                hideVideoControls();
            }
        }
        
        private function showVideoControls():void {
            if (!_controlsVisible) {
                _controlsVisible = true;
                if (_videoControls) _videoControls.alpha = 1;
                if (_backBtn) _backBtn.alpha = 1;
            }
        }
        
        private function hideVideoControls():void {
            if (_controlsVisible) {
                _controlsVisible = false;
                if (_videoControls) _videoControls.alpha = 0.3;
                if (_backBtn) _backBtn.alpha = 0.3;
            }
        }

        private function stopVideo(resumeBgm:Boolean = true):void {
            // Clean up auto-hide timer
            if (_autoHideTimer) {
                _autoHideTimer.stop();
                _autoHideTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onControlsAutoHide);
                _autoHideTimer = null;
            }
            
            // Clean up video controls
            if (_videoControls) {
                _videoControls.removeEventListener(VideoControls.PLAY_CLICKED, onControlPlay);
                _videoControls.removeEventListener(VideoControls.PAUSE_CLICKED, onControlPause);
                _videoControls.dispose();
                try { if (stage && stage.contains(_videoControls)) stage.removeChild(_videoControls); } catch(err:Error) {}
                _videoControls = null;
            }
            
            // Clean up video container mouse listener
            if (_videoContainer) {
                _videoContainer.removeEventListener(MouseEvent.MOUSE_MOVE, onVideoMouseMove);
            }
            
            if (_ns) { 
                _ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
                _ns.close(); 
                _ns = null; 
            }
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
            
            _videoDuration = 0;
            _controlsVisible = true;
            
            if (resumeBgm) {
                // Resume paused BGM or play if not started
                if (!AudioManager.getInstance().resumeBgm()) {
                    // If resume failed (no paused BGM), play from start
                    var saveSystem:SaveSystem = SaveSystem.getInstance();
                    var savedVolume:Number = 0.7; // default
                    if (saveSystem.data && saveSystem.data.settings) {
                        savedVolume = saveSystem.data.settings.masterVolume;
                        if (isNaN(savedVolume)) savedVolume = 0.7;
                    }
                    AudioManager.getInstance().setMasterLevel(Math.round(savedVolume * 10));
                    AudioManager.getInstance().playBgm("Bgmlobby");
                }
            }
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