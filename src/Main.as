package {
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.AsyncErrorEvent;
    import flash.events.NetStatusEvent;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.media.Video;
    import flash.media.StageVideo;
    import flash.geom.Rectangle;
    import flash.filesystem.File;
    import flash.utils.getTimer;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.system.Capabilities;
    
    // Import Game Components
    import config.StimulusConfig;
    import castle.EffectsManager;
    import game.GameController;
    
    // Import UI Classes (Yang baru diperbarui)
    import ui.MainMenu;
    import ui.SettingsMenu;
    import ui.AboutUsPanel;
    import ui.GameScreen;
    import ui.TrialPopup;
    import ui.HUD; 
    
    /**
     * Main - Application Entry Point
     * Mengatur Video Intro, Navigasi Menu, dan Inisialisasi Game.
     */
    public class Main extends Sprite {
        
        // Debug flag
        private static const DEBUG:Boolean = true;
        
        // Video Components
        private var _videoContainer:Sprite;
        private var _video:Video;
        private var _stageVideo:StageVideo;
        private var _useStageVideo:Boolean = false;
        private var _netConnection:NetConnection;
        private var _netStream:NetStream;
        private var _videoCompleted:Boolean = false;
        private var _skipButton:Sprite;
        private var _skipButtonVisible:Boolean = false;
        private var _videoStartTime:Number = 0;
        private var _videoDuration:Number = 0;
        private var _videoOriginalWidth:Number = 0;
        private var _videoOriginalHeight:Number = 0;

        // UI Components
        private var _mainMenu:MainMenu;
        private var _settingsMenu:SettingsMenu;
        private var _aboutUsPanel:AboutUsPanel;
        
        // Game Screens
        private var _gameScreen:GameScreen;
        private var _trialPopup:TrialPopup;
        private var _effectsManager:EffectsManager;
        
        // Game State
        private var _isInGame:Boolean = false;
        private var _currentDifficulty:int = 1;
        private var _correctStreak:int = 0;
        private var _wrongStreak:int = 0;

        public function Main() {
            // 1. Setup stage
            if (stage) {
                init();
            } else {
                addEventListener(Event.ADDED_TO_STAGE, init);
            }
        }
        
        private function init(e:Event = null):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.addEventListener(Event.RESIZE, onStageResize);

            // 2. Update config
            StimulusConfig.updateForStageSize(stage.stageWidth, stage.stageHeight);

            if (DEBUG) {
                trace("===== COGNITIVE CASTLE STARTED =====");
                trace("Stage Size: " + stage.stageWidth + "x" + stage.stageHeight);
            }
            
            // 3. Play opening video first
            playOpeningVideo();
        }
        
        // ==========================================
        // VIDEO PLAYER LOGIC
        // ==========================================
        
        private function playOpeningVideo():void {
            if (DEBUG) trace("[Main] Playing opening video...");
            _netConnection = new NetConnection();
            _netConnection.connect(null);
            
            _netStream = new NetStream(_netConnection);
            _netStream.addEventListener(NetStatusEvent.NET_STATUS, onVideoStatus);
            _netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onVideoError);
            
            var client:Object = {};
            client.onMetaData = onVideoMetaData;
            client.onCuePoint = function(info:Object):void {};
            client.onPlayStatus = function(info:Object):void {};
            _netStream.client = client;
            
            _video = new Video(1280, 720);
            _video.width = stage.stageWidth;
            _video.height = stage.stageHeight;
            _video.smoothing = true;
            _video.attachNetStream(_netStream);

            _videoContainer = new Sprite();
            _videoContainer.addChild(_video);
            addChild(_videoContainer);
            
            // File video assets/videoOpening.mp4
            var videoFile:File = File.applicationDirectory.resolvePath("assets/videoOpening.mp4");
            
            if (!videoFile.exists) {
                trace("[Main] ERROR: Video file not found! Skipping to menu.");
                onVideoComplete(); // Langsung ke menu jika video tidak ada
                return;
            }
            
            _netStream.play(videoFile.url);
            _videoStartTime = getTimer();
            createSkipButton();
            addEventListener(Event.ENTER_FRAME, onVideoEnterFrame);
        }
        
        private function createSkipButton():void {
            _skipButton = new Sprite();
            _skipButton.graphics.beginFill(0x000000, 0.7);
            _skipButton.graphics.lineStyle(2, 0xFFFFFF);
            _skipButton.graphics.drawRoundRect(0, 0, 120, 40, 10, 10);
            _skipButton.graphics.endFill();
            
            var skipText:TextField = new TextField();
            var format:TextFormat = new TextFormat("Arial", 18, 0xFFFFFF, true);
            format.align = "center";
            skipText.defaultTextFormat = format;
            skipText.text = "Skip ▶▶";
            skipText.width = 120;
            skipText.height = 30;
            skipText.y = 8;
            skipText.selectable = false;
            skipText.mouseEnabled = false;
            _skipButton.addChild(skipText);
            
            _skipButton.x = stage.stageWidth - 140;
            _skipButton.y = stage.stageHeight - 60;
            _skipButton.visible = false;
            _skipButton.alpha = 0;
            _skipButton.buttonMode = true;
            _skipButton.addEventListener(MouseEvent.CLICK, onSkipButtonClick);
            
            _videoContainer.addChild(_skipButton);
        }
        
        private function onVideoEnterFrame(event:Event):void {
            if (_videoCompleted) return;
            var elapsedTime:Number = (getTimer() - _videoStartTime) / 1000;
            // Munculkan tombol skip setelah 2 detik
            if (!_skipButtonVisible && elapsedTime >= 2) {
                _skipButtonVisible = true;
                _skipButton.visible = true;
                _skipButton.alpha = 1; // Simplifikasi fade in
            }
        }
        
        private function onSkipButtonClick(event:MouseEvent):void {
            event.stopPropagation();
            onVideoComplete();
        }
        
        private function onVideoMetaData(info:Object):void {
            _videoDuration = info.duration || 0;
            _videoOriginalWidth = info.width || 1280;
            _videoOriginalHeight = info.height || 720;
            resizeVideo();
        }
        
        private function resizeVideo():void {
            if (_videoCompleted || !_video) return;
            if (_videoOriginalWidth == 0 || _videoOriginalHeight == 0) return;
            
            var scale:Number = Math.max(stage.stageWidth / _videoOriginalWidth, stage.stageHeight / _videoOriginalHeight);
            var scaledWidth:Number = _videoOriginalWidth * scale;
            var scaledHeight:Number = _videoOriginalHeight * scale;
            
            _video.width = scaledWidth;
            _video.height = scaledHeight;
            _video.x = (stage.stageWidth - scaledWidth) / 2;
            _video.y = (stage.stageHeight - scaledHeight) / 2;
            
            if (_skipButton) {
                _skipButton.x = stage.stageWidth - 140;
                _skipButton.y = stage.stageHeight - 60;
            }
        }
        
        private function onVideoStatus(event:NetStatusEvent):void {
            if (event.info.code == "NetStream.Play.Stop" || event.info.code == "NetStream.Play.Failed") {
                onVideoComplete();
            }
        }
        
        private function onVideoError(event:AsyncErrorEvent):void {
            onVideoComplete();
        }
        
        private function onVideoComplete():void {
            if (_videoCompleted) return;
            _videoCompleted = true;

            if (DEBUG) trace("[Main] Video complete - showing menu");
            
            removeEventListener(Event.ENTER_FRAME, onVideoEnterFrame);
            
            if (_netStream) {
                _netStream.close();
                _netStream = null;
            }
            
            if (_videoContainer && contains(_videoContainer)) {
                removeChild(_videoContainer);
                _videoContainer = null;
            }
            
            _video = null;
            
            // Masuk ke Menu Utama
            initializeMenu();
        }

        // ==========================================
        // MENU SYSTEM LOGIC
        // ==========================================
        
        private function initializeMenu():void {
            // 1. Create Main Menu
            _mainMenu = new MainMenu();
            _mainMenu.initialize(stage.stageWidth, stage.stageHeight);
            _mainMenu.addEventListener(MainMenu.PLAY_CLICKED, onPlayClicked);
            _mainMenu.addEventListener(MainMenu.SETTINGS_CLICKED, onSettingsClicked);
            _mainMenu.addEventListener(MainMenu.ABOUT_US_CLICKED, onAboutUsClicked);
            addChild(_mainMenu);
            
            // 2. Create Settings Menu (Hidden by default)
            _settingsMenu = new SettingsMenu();
            _settingsMenu.initialize(stage.stageWidth, stage.stageHeight);
            _settingsMenu.addEventListener(SettingsMenu.CLOSE_CLICKED, onSettingsClose);
            addChild(_settingsMenu);
            
            // 3. Create About Us Panel (Hidden by default)
            _aboutUsPanel = new AboutUsPanel();
            _aboutUsPanel.initialize(stage.stageWidth, stage.stageHeight);
            _aboutUsPanel.addEventListener(AboutUsPanel.CLOSE_CLICKED, onAboutUsClose);
            addChild(_aboutUsPanel);
            
            if (DEBUG) trace("[Main] Menu system initialized");
        }
        
        // --- Navigation Handlers ---

        private function onPlayClicked(event:Event):void {
            if (DEBUG) trace("[Main] Play clicked - STARTING GAME");
            
            // Sembunyikan dan nonaktifkan menu
            _mainMenu.visible = false;
            
            // Mulai Game
            initializeGame();
        }
        
        private function onSettingsClicked(event:Event):void {
            // Sembunyikan Main Menu, Tampilkan Settings
            _mainMenu.visible = false;
            _settingsMenu.show();
        }
        
        private function onSettingsClose(event:Event):void {
            // Sembunyikan Settings, Tampilkan Main Menu
            _settingsMenu.hide();
            _mainMenu.visible = true;
        }
        
        private function onAboutUsClicked(event:Event):void {
            // Sembunyikan Main Menu, Tampilkan About Us
            _mainMenu.visible = false;
            _aboutUsPanel.show();
        }
        
        private function onAboutUsClose(event:Event):void {
            // Sembunyikan About Us, Tampilkan Main Menu
            _aboutUsPanel.hide();
            _mainMenu.visible = true;
        }

        // ==========================================
        // GAME LOGIC
        // ==========================================

        private function initializeGame():void {
            _isInGame = true;
            
            // 1. Create Game Screen (Visuals + HUD)
            _gameScreen = new GameScreen();
            _gameScreen.initialize(stage.stageWidth, stage.stageHeight);
            _gameScreen.addEventListener(GameScreen.UPGRADE_CLICKED, onUpgradeClicked);
            addChild(_gameScreen);
            
            // 2. Create Popup
            _trialPopup = new TrialPopup();
            _trialPopup.initialize(stage.stageWidth, stage.stageHeight);
            _trialPopup.addEventListener(TrialPopup.TRIAL_SUCCESS, onTrialSuccess);
            _trialPopup.addEventListener(TrialPopup.TRIAL_FAIL, onTrialFail);
            _trialPopup.addEventListener(TrialPopup.TRIAL_CLOSED, onTrialClosed);
            addChild(_trialPopup);
            
            // 3. Setup Effects
            _effectsManager = EffectsManager.getInstance();
            _effectsManager.setParent(this);
            
            // 4. Start Game Controller
            if (_gameScreen.hud) {
                var gameCtrl:GameController = GameController.getInstance();
                gameCtrl.initialize(_gameScreen.hud);
                gameCtrl.startNextTrial();
                if (DEBUG) trace("[Main] GameController initialized & First Trial Started");
            } else {
                trace("[Main] ERROR: HUD property not found in GameScreen!");
            }
        }
        
        private function onUpgradeClicked(event:Event):void {
            _gameScreen.setUpgradeButtonEnabled(false);
            _trialPopup.show();
        }
        
        private function onTrialSuccess(event:Event):void {
            _correctStreak++;
            _wrongStreak = 0;
            _gameScreen.showUpgradeAlert("Castle Upgraded!");
        }
        
        private function onTrialFail(event:Event):void {
            _wrongStreak++;
            _correctStreak = 0;
        }
        
        private function onTrialClosed(event:Event):void {
            var center:Object = _gameScreen.getCastleCenter();
            var wasSuccess:Boolean = _trialPopup.getLastTrialResult();
            
            if (wasSuccess) {
                _gameScreen.processUpgrade(_correctStreak);
                _effectsManager.playCorrectEffect(center.x, center.y, _correctStreak * 10);
            } else {
                if (_wrongStreak >= 3 && _gameScreen.hasSideTowers()) {
                    _gameScreen.removeSideTower();
                    _wrongStreak = 0;
                } else {
                    _gameScreen.processWrong();
                }
                _effectsManager.playWrongEffect(center.x, center.y);
            }
            
            _gameScreen.hideUpgradeAlert();
            _gameScreen.setUpgradeButtonEnabled(true);
        }

        private function onStageResize(event:Event):void {
            if (!_videoCompleted && _video) {
                resizeVideo();
            }
            
            // Update UI components if they exist
            if (_mainMenu) _mainMenu.resize(stage.stageWidth, stage.stageHeight);
            if (_settingsMenu) _settingsMenu.resize(stage.stageWidth, stage.stageHeight);
            if (_aboutUsPanel) _aboutUsPanel.resize(stage.stageWidth, stage.stageHeight);
            
            // Update Game components if in game
            if (_isInGame) {
                if (_gameScreen) _gameScreen.onResize(stage.stageWidth, stage.stageHeight);
                if (_trialPopup) _trialPopup.resize(stage.stageWidth, stage.stageHeight);
            }
        }
    }
}