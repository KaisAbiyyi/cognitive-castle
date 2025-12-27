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
    import castle.CastleState;
    import game.GameController;
    import game.ProgressionManager;
    import game.ProgressionResult;
    import services.AudioManager;
    import services.SaveSystem;
    import core.ServiceLocator;
    
    // Import UI Classes (Yang baru diperbarui)
    import ui.MainMenu;
    import ui.SettingsMenu;
    import ui.AboutUsPanel;
    import ui.GameScreen;
    import ui.UpgradePopup;
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
        private var _upgradePopup:UpgradePopup;
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
            // Initialize AudioManager service
            var audioManager:AudioManager = new AudioManager();
            ServiceLocator.getInstance().register("AudioManager", audioManager);
            
            if (DEBUG) trace("[Main] AudioManager initialized");
            
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
            
            // Load save if available, then start game
            var savedState:CastleState = null;
            var savedCastleScale:Number = NaN;
            var saveSystem:SaveSystem = SaveSystem.getInstance();
            if (saveSystem.loadState() && saveSystem.data && saveSystem.data.castleState) {
                savedState = CastleState.fromObject(saveSystem.data.castleState);
                savedCastleScale = saveSystem.data.castleScale;
                if (DEBUG) trace("[Main] Save loaded - resuming last game");
            } else if (DEBUG) {
                trace("[Main] No save found - starting new game");
            }
            
            initializeGame(savedState, savedCastleScale);
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

        private function initializeGame(savedState:CastleState = null, savedCastleScale:Number = NaN):void {
            _isInGame = true;
            
            var progressionManager:ProgressionManager = ProgressionManager.getInstance();
            if (savedState) {
                progressionManager.initializeWithState(savedState);
            } else {
                progressionManager.reset();
            }
            
            // 1. Create Game Screen (Visuals + HUD)
            _gameScreen = new GameScreen();
            _gameScreen.initialize(stage.stageWidth, stage.stageHeight);
            if (savedState) {
                _gameScreen.applySavedState(savedState, savedCastleScale);
            }
            _gameScreen.addEventListener(GameScreen.UPGRADE_CLICKED, onUpgradeClicked);
            _gameScreen.addEventListener("goToMainMenu", onGoToMainMenu);
            _gameScreen.addEventListener("retryGame", onRetryGame);
            addChild(_gameScreen);
            
            // 2. Create Popup
            _upgradePopup = new UpgradePopup();
            _upgradePopup.initialize(stage.stageWidth, stage.stageHeight);
            _upgradePopup.addEventListener(UpgradePopup.CHALLENGE_STARTED, onChallengeStarted);
            _upgradePopup.addEventListener(UpgradePopup.CHALLENGE_SUCCESS, onChallengeSuccess);
            _upgradePopup.addEventListener(UpgradePopup.CHALLENGE_FAIL, onChallengeFail);
            _upgradePopup.addEventListener(UpgradePopup.POPUP_CLOSED, onPopupClosed);
            addChild(_upgradePopup);
            
            // 3. Setup Effects
            _effectsManager = EffectsManager.getInstance();
            _effectsManager.setParent(this);
            
            if (DEBUG) {
                trace("[Main] Game initialized");
            }
        }
        
        private function onUpgradeClicked(event:Event):void {
            if (DEBUG) trace("[Main] Upgrade clicked - showing upgrade popup");
            _gameScreen.setUpgradeButtonEnabled(false);
            
            // Bring popup to front so it's visible above everything
            if (_upgradePopup && contains(_upgradePopup)) {
                setChildIndex(_upgradePopup, numChildren - 1);
            }
            
            _upgradePopup.show();
        }
        
        private function onChallengeSuccess(event:Event):void {
            _correctStreak++;
            _wrongStreak = 0;
            if (_gameScreen) _gameScreen.resetHordeTimer();
        }
        
        private function onChallengeFail(event:Event):void {
            _wrongStreak++;
            _correctStreak = 0;
            if (_gameScreen) _gameScreen.resetHordeTimer();
        }
        
        private function onChallengeStarted(event:Event):void {
            if (_gameScreen) _gameScreen.resetHordeTimer();
        }
        
        private function onPopupClosed(event:Event):void {
            var center:Object = _gameScreen.getCastleCenter();
            var progressionResult:ProgressionResult = _upgradePopup.getLastProgressionResult();
            
            if (progressionResult) {
                // Always process the result (handles both correct and wrong)
                _gameScreen.processUpgradeResult(progressionResult);
                
                if (progressionResult.wasCorrect) {
                    _effectsManager.playCorrectEffect(center.x, center.y, _correctStreak * 10);
                } else {
                    _effectsManager.playWrongEffect(center.x, center.y);
                    
                    if (DEBUG) {
                        trace("[Main] Wrong answer - wrongStreak=" + progressionResult.wrongStreak + 
                              ", type=" + progressionResult.upgradeType);
                    }
                }
            }
            
            _gameScreen.setUpgradeButtonEnabled(true);
        }
        
        private function onGoToMainMenu(event:Event):void {
            if (DEBUG) trace("[Main] Returning to main menu");
            
            // Clean up game
            cleanupGame();
            
            // Show main menu
            _mainMenu.visible = true;
        }
        
        private function onRetryGame(event:Event):void {
            if (DEBUG) trace("[Main] Retrying game");
            
            // Clean up current game
            cleanupGame();
            
            // Start fresh game
            initializeGame();
        }
        
        private function cleanupGame():void {
            _isInGame = false;
            
            var audioManager:AudioManager = ServiceLocator.get("AudioManager") as AudioManager;
            if (audioManager) {
                audioManager.stopBgm();
            }

            // Remove game screen
            if (_gameScreen) {
                _gameScreen.removeEventListener(GameScreen.UPGRADE_CLICKED, onUpgradeClicked);
                _gameScreen.removeEventListener("goToMainMenu", onGoToMainMenu);
                _gameScreen.removeEventListener("retryGame", onRetryGame);
                if (contains(_gameScreen)) removeChild(_gameScreen);
                _gameScreen = null;
            }
            
            // Remove upgrade popup
            if (_upgradePopup) {
                _upgradePopup.removeEventListener(UpgradePopup.CHALLENGE_STARTED, onChallengeStarted);
                _upgradePopup.removeEventListener(UpgradePopup.CHALLENGE_SUCCESS, onChallengeSuccess);
                _upgradePopup.removeEventListener(UpgradePopup.CHALLENGE_FAIL, onChallengeFail);
                _upgradePopup.removeEventListener(UpgradePopup.POPUP_CLOSED, onPopupClosed);
                if (contains(_upgradePopup)) removeChild(_upgradePopup);
                _upgradePopup = null;
            }
            
            // Reset streaks
            _correctStreak = 0;
            _wrongStreak = 0;
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
                if (_upgradePopup) _upgradePopup.onResize(stage.stageWidth, stage.stageHeight);
            }
        }
    }
}
