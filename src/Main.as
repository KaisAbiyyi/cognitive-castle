package {
    import flash.display.*;
    import flash.events.*;
    import flash.net.*;
    import flash.media.Video;
    import flash.filesystem.File;
    import flash.utils.getTimer;
    import flash.text.TextField;
    import flash.text.TextFormat;
    
    import config.StimulusConfig;
    import castle.EffectsManager;
    import game.GameController;
    import services.AudioManager;
    import ui.*;

    public class Main extends Sprite {
        private var _videoContainer:Sprite;
        private var _skipBtn:Sprite;
        private var _ns:NetStream;
        private var _videoStart:Number;
        private var _skipBtnWidth:Number = 140;
        private var _skipBtnHeight:Number = 56;
        private var _skipHoverScale:Number = 0.96;
        private var _skipNormalScale:Number = 1.0;
        private var _skipBaseX:Number = 0;
        private var _skipBaseY:Number = 0;
        
        // UI
        private var _mainMenu:MainMenu;
        private var _settingsMenu:SettingsMenu;
        private var _aboutUs:AboutUsPanel;
        private var _lessons:LessonsPanel;
        private var _gameScreen:GameScreen;
        private var _trialPopup:TrialPopup;

        public function Main() {
            stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        private function init(e:Event = null):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            stage.scaleMode = StageScaleMode.NO_SCALE; 
            stage.align = StageAlign.TOP_LEFT;
            stage.addEventListener(Event.RESIZE, onResize);
            StimulusConfig.updateForStageSize(stage.stageWidth, stage.stageHeight);
            
            playIntro();
        }

        // --- Video Logic ---
        private function playIntro():void {
            var nc:NetConnection = new NetConnection(); nc.connect(null);
            _ns = new NetStream(nc);
            _ns.client = { onMetaData: function(o:Object):void{} };
            _ns.addEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent):void { if(e.info.code == "NetStream.Play.Stop") endIntro(); });

            var vid:Video = new Video(1280, 720); vid.attachNetStream(_ns); vid.smoothing = true;
            _videoContainer = new Sprite(); _videoContainer.addChild(vid); addChild(_videoContainer);
            
            // Resize logic simple
            var scale:Number = Math.max(stage.stageWidth/1280, stage.stageHeight/720);
            vid.width = 1280*scale; vid.height = 720*scale;
            vid.x = (stage.stageWidth-vid.width)/2; vid.y = (stage.stageHeight-vid.height)/2;

            var f:File = File.applicationDirectory.resolvePath("assets/videoOpening.mp4");
            if(f.exists) { _ns.play(f.url); _videoStart = getTimer(); addEventListener(Event.ENTER_FRAME, checkSkip); } 
            else endIntro();
        }

        private function checkSkip(e:Event):void {
            // Tampilkan tombol skip setelah 2 detik
            if (getTimer() - _videoStart > 2000) {
                removeEventListener(Event.ENTER_FRAME, checkSkip);
                createSkipButton();
            }
        }

        private function createSkipButton():void {
            _skipBtn = new Sprite();
            _skipBtn.buttonMode = true;

            // gunakan variabel kelas agar bisa dipakai oleh efek
            var btnWidth:Number = _skipBtnWidth;
            var btnHeight:Number = _skipBtnHeight;

            // Simpan base position (pojok kanan bawah)
            _skipBaseX = stage.stageWidth - (btnWidth + 20);
            _skipBaseY = stage.stageHeight - (btnHeight + 20);

            // apply normal scale and position
            applySkipScale(_skipNormalScale);

            _skipBtn.addEventListener(MouseEvent.CLICK, function(e:Event):void { endIntro(); });
            _skipBtn.addEventListener(MouseEvent.MOUSE_OVER, onSkipOver);
            _skipBtn.addEventListener(MouseEvent.MOUSE_OUT, onSkipOut);
            addChild(_skipBtn);

            // 1. Coba Load Gambar
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = e.target.content as Bitmap;
                bmp.smoothing = true;

                // --- PAKSA UKURAN GAMBAR AGAR KECIL ---
                bmp.width = btnWidth;
                bmp.height = btnHeight;

                _skipBtn.addChild(bmp);
                // pastikan posisi/scale tetap
                applySkipScale(_skipNormalScale);
            });

            // 2. Fallback (Jika gambar gagal dimuat)
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void {
                _skipBtn.graphics.beginFill(0x000000, 0.5);
                _skipBtn.graphics.drawRect(0, 0, btnWidth, btnHeight); // Gunakan ukuran yg sama

                var tf:TextField = new TextField();
                var fmt:TextFormat = new TextFormat("Arial", 14, 0xFFFFFF, true); // Font size diperkecil (14)
                tf.defaultTextFormat = fmt;
                tf.text = "SKIP >>";
                tf.autoSize = "left";
                tf.x = (btnWidth - tf.width) / 2;
                tf.y = (btnHeight - tf.height) / 2;
                _skipBtn.addChild(tf);
                applySkipScale(_skipNormalScale);
            });

            // Mulai load
            try { loader.load(new URLRequest("assets/Gambar/Skip.png")); } catch(e:Error) {}
        }

        private function endIntro():void {
            if(_ns) _ns.close();
            if(_videoContainer && contains(_videoContainer)) removeChild(_videoContainer);
            if(_skipBtn) {
                try {
                    _skipBtn.removeEventListener(MouseEvent.MOUSE_OVER, onSkipOver);
                    _skipBtn.removeEventListener(MouseEvent.MOUSE_OUT, onSkipOut);
                    _skipBtn.removeEventListener(MouseEvent.CLICK, endIntro);
                } catch(err:Error) {}
                if (contains(_skipBtn)) removeChild(_skipBtn);
            }
            initMenu();
        }

        // --- Menu Logic ---
        private function initMenu():void {
            AudioManager.getInstance().init();
            
            _mainMenu = new MainMenu();
            _settingsMenu = new SettingsMenu();
            _aboutUs = new AboutUsPanel();
            _lessons = new LessonsPanel();
            
            var addUI:Function = function(ui:*):void { 
                var uiObj:Object = ui; 
                if(uiObj.hasOwnProperty("initialize")) {
                    uiObj.initialize(stage.stageWidth, stage.stageHeight); 
                }
                addChild(ui as DisplayObject); 
            };
            
            addUI(_mainMenu); addUI(_settingsMenu); addUI(_aboutUs); addUI(_lessons);

            // Wiring Events
            _mainMenu.addEventListener(MainMenu.PLAY_CLICKED, function(e:Event):void {
                _mainMenu.visible = false;
                AudioManager.getInstance().stopMusic(); 
                startGame();
            });
            
            // Navigasi
            var openPanel:Function = function(panel:MovieClip):void { _mainMenu.visible = false; panel.show(); };
            var closePanel:Function = function(e:Event):void { (e.target as MovieClip).hide(); _mainMenu.visible = true; };

            _mainMenu.addEventListener(MainMenu.SETTINGS_CLICKED, function(e:Event):void { _settingsMenu.show(); });
            _settingsMenu.addEventListener(SettingsMenu.CLOSE_CLICKED, function(e:Event):void { _settingsMenu.hide(); });

            _mainMenu.addEventListener(MainMenu.ABOUT_US_CLICKED, function(e:Event):void { openPanel(_aboutUs); });
            _aboutUs.addEventListener(AboutUsPanel.CLOSE_CLICKED, closePanel);

            _mainMenu.addEventListener(MainMenu.LESSONS_CLICKED, function(e:Event):void { openPanel(_lessons); });
            _lessons.addEventListener(LessonsPanel.CLOSE_CLICKED, closePanel);
            
            _settingsMenu.setPlusButtonPosition(335, -45);
            _settingsMenu.setMinButtonPosition(-430, -45);
            
            AudioManager.getInstance().playMusic("Bgmlobby");
        }

        // --- Game Logic ---
        private function startGame():void {
            _gameScreen = new GameScreen(); _gameScreen.initialize(stage.stageWidth, stage.stageHeight);
            addChild(_gameScreen);
            
            _trialPopup = new TrialPopup(); _trialPopup.initialize(stage.stageWidth, stage.stageHeight);
            addChild(_trialPopup);
            
            GameController.getInstance().initialize(_gameScreen.hud);
            GameController.getInstance().startNextTrial();
            
            _gameScreen.addEventListener(GameScreen.UPGRADE_CLICKED, function(e:Event):void { _trialPopup.show(); });
            _trialPopup.addEventListener(TrialPopup.TRIAL_CLOSED, function(e:Event):void {
               var center:Object = _gameScreen.getCastleCenter();
               if (_trialPopup.getLastTrialResult()) {
                   _gameScreen.processUpgrade(0);
                   EffectsManager.getInstance().playCorrectEffect(center.x, center.y, 10);
               } else {
                   _gameScreen.processWrong();
                   EffectsManager.getInstance().playWrongEffect(center.x, center.y);
               }
            });
            EffectsManager.getInstance().setParent(this);
        }

        private function onResize(e:Event):void {
            if (_mainMenu) _mainMenu.resize(stage.stageWidth, stage.stageHeight);
            if (_settingsMenu) _settingsMenu.resize(stage.stageWidth, stage.stageHeight);
            if (_gameScreen) _gameScreen.onResize(stage.stageWidth, stage.stageHeight);
        }

        // --- Skip button hover helpers (shrink centered) ---
        private function applySkipScale(s:Number):void {
            try {
                if (!_skipBtn) return;
                _skipBtn.scaleX = _skipBtn.scaleY = s;
                _skipBtn.x = _skipBaseX + (_skipBtnWidth * (1 - s) / 2);
                _skipBtn.y = _skipBaseY + (_skipBtnHeight * (1 - s) / 2);
            } catch(err:Error) {}
        }

        private function onSkipOver(e:MouseEvent):void {
            try { applySkipScale(_skipHoverScale); } catch(err:Error) {}
        }

        private function onSkipOut(e:MouseEvent):void {
            try { applySkipScale(_skipNormalScale); } catch(err:Error) {}
        }
    }
}