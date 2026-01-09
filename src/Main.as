package {
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.media.Video;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.NetStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.net.URLRequest;
    import flash.filesystem.File;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.getTimer;
    
    import config.StimulusConfig;
    import castle.EffectsManager;
    import castle.CastleState;
    import game.ProgressionManager;
    import game.ProgressionResult;
    import services.AudioManager;
    import services.SaveSystem;
    import core.ServiceLocator;
    
    import ui.MainMenu;
    import ui.SettingsMenu;
    import ui.AboutUsPanel;
    import ui.LessonsPanel;
    import ui.GameScreen;
    import ui.UpgradePopup;
    
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
        private var _netConnection:NetConnection;
        private var _netStream:NetStream;
        private var _skipBtn:Sprite;
        private var _skipBtnWidth:Number = 140;
        private var _skipBtnHeight:Number = 56;
        private var _skipHoverScale:Number = 0.96;
        private var _skipNormalScale:Number = 1.0;
        private var _skipBaseX:Number = 0;
        private var _skipBaseY:Number = 0;
        private var _videoStartTime:Number = 0;
        private var _currentVideoPath:String;
        private var _currentVideoCallback:Function;
        private var _videoCompleted:Boolean = false;
        private var _skipDelayMs:int = 2000;
        private const PRELOAD_ASSETS:Array = [
            "assets/images/Game/background.png",
            "assets/images/Game/horde.png",
            "assets/images/Game/cloud1.png",
            "assets/images/Game/cloud2.png",
            "assets/images/Game/cloud3.png"
        ];
        private var _gateAssetsReady:Boolean = false;
        private var _gateVideoDone:Boolean = false;
        private var _pendingSavedState:CastleState;
        private var _pendingSavedCastleScale:Number = NaN;
        private var _preloadIndex:int = 0;
        private var _currentPreloadLoader:Loader;
        
        // UI
        private var _mainMenu:MainMenu;
        private var _settingsMenu:SettingsMenu;
        private var _aboutUs:AboutUsPanel;
        private var _lessons:LessonsPanel;
        private var _gameScreen:GameScreen;
        private var _upgradePopup:UpgradePopup;
        
        // Game State
        private var _isInGame:Boolean = false;
        private var _correctStreak:int = 0;
        private var _wrongStreak:int = 0;
        
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
            startVideoPlayback("assets/videoOpening.mp4", onIntroComplete, 2000);
        }
        
        private function onIntroComplete():void { initializeMenu(); }
        
        private function layoutIntroVideo():void {
            if (!_video) return;
            var scale:Number = Math.max(stage.stageWidth / 1280, stage.stageHeight / 720);
            _video.width = 1280 * scale;
            _video.height = 720 * scale;
            _video.x = (stage.stageWidth - _video.width) / 2;
            _video.y = (stage.stageHeight - _video.height) / 2;
        }
        
        private function checkSkip(e:Event):void {
            if (getTimer() - _videoStartTime > _skipDelayMs) {
                removeEventListener(Event.ENTER_FRAME, checkSkip);
                createSkipButton();
            }
        }
        
        private function createSkipButton():void {
            if (_skipBtn) return;
            _skipBtn = new Sprite();
            _skipBtn.buttonMode = true;
            
            _skipBaseX = stage.stageWidth - (_skipBtnWidth + 20);
            _skipBaseY = stage.stageHeight - (_skipBtnHeight + 20);
            applySkipScale(_skipNormalScale);
            
            _skipBtn.addEventListener(MouseEvent.CLICK, function(e:Event):void { finishVideoPlayback(); });
            _skipBtn.addEventListener(MouseEvent.MOUSE_OVER, onSkipOver);
            _skipBtn.addEventListener(MouseEvent.MOUSE_OUT, onSkipOut);
            addChild(_skipBtn);
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = e.target.content as Bitmap;
                bmp.smoothing = true;
                bmp.width = _skipBtnWidth;
                bmp.height = _skipBtnHeight;
                _skipBtn.addChild(bmp);
                applySkipScale(_skipNormalScale);
            });
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void {
                _skipBtn.graphics.beginFill(0x000000, 0.5);
                _skipBtn.graphics.drawRect(0, 0, _skipBtnWidth, _skipBtnHeight);
                
                var tf:TextField = new TextField();
                var fmt:TextFormat = new TextFormat("Arial", 14, 0xFFFFFF, true);
                tf.defaultTextFormat = fmt;
                tf.text = "SKIP >>";
                tf.autoSize = "left";
                tf.x = (_skipBtnWidth - tf.width) / 2;
                tf.y = (_skipBtnHeight - tf.height) / 2;
                _skipBtn.addChild(tf);
                applySkipScale(_skipNormalScale);
            });
            
            try { loader.load(new URLRequest("assets/Gambar/Skip.png")); } catch(err:Error) {}
        }
        
        private function applySkipScale(scale:Number):void {
            if (!_skipBtn) return;
            _skipBtn.scaleX = _skipBtn.scaleY = scale;
            _skipBtn.x = _skipBaseX + (_skipBtnWidth * (1 - scale) / 2);
            _skipBtn.y = _skipBaseY + (_skipBtnHeight * (1 - scale) / 2);
        }
        
        private function onSkipOver(e:MouseEvent):void {
            applySkipScale(_skipHoverScale);
        }
        
        private function onSkipOut(e:MouseEvent):void {
            applySkipScale(_skipNormalScale);
        }
        
        private function startVideoPlayback(path:String, onComplete:Function, skipDelayMs:int = 2000):void {
            _currentVideoPath = path;
            _currentVideoCallback = onComplete;
            _skipDelayMs = skipDelayMs;
            _videoCompleted = false;
            cleanupVideoVisuals();
            
            _netConnection = new NetConnection();
            _netConnection.connect(null);
            _netStream = new NetStream(_netConnection);
            _netStream.client = { onMetaData: function(o:Object):void{} };
            _netStream.addEventListener(NetStatusEvent.NET_STATUS, onVideoStatus);
            
            _video = new Video(1280, 720);
            _video.attachNetStream(_netStream);
            _video.smoothing = true;
            
            _videoContainer = new Sprite();
            _videoContainer.addChild(_video);
            addChild(_videoContainer);
            layoutIntroVideo();
            
            var f:File = File.applicationDirectory.resolvePath(path);
            if (f.exists) {
                _netStream.play(f.url);
                _videoStartTime = getTimer();
                addEventListener(Event.ENTER_FRAME, checkSkip);
            } else {
                finishVideoPlayback();
            }
        }

        private function onVideoStatus(e:NetStatusEvent):void {
            if (e.info && e.info.code == "NetStream.Play.Stop") {
                finishVideoPlayback();
            }
        }

        private function finishVideoPlayback():void {
            if (_videoCompleted) return;
            _videoCompleted = true;
            removeEventListener(Event.ENTER_FRAME, checkSkip);
            if (_netStream) {
                _netStream.removeEventListener(NetStatusEvent.NET_STATUS, onVideoStatus);
                _netStream.close();
                _netStream = null;
            }
            if (_netConnection) { _netConnection.close(); _netConnection = null; }
            cleanupVideoVisuals();
            var cb:Function = _currentVideoCallback;
            _currentVideoCallback = null;
            if (cb != null) cb();
        }

        private function cleanupVideoVisuals():void {
            if (_videoContainer && contains(_videoContainer)) removeChild(_videoContainer);
            _videoContainer = null;
            _video = null;
            if (_skipBtn) {
                _skipBtn.removeEventListener(MouseEvent.MOUSE_OVER, onSkipOver);
                _skipBtn.removeEventListener(MouseEvent.MOUSE_OUT, onSkipOut);
                if (contains(_skipBtn)) removeChild(_skipBtn);
            }
            _skipBtn = null;
        }

        // --- Play gate video + preload assets ---
        private function startPreGameGate(savedState:CastleState, savedCastleScale:Number):void {
            _pendingSavedState = savedState;
            _pendingSavedCastleScale = savedCastleScale;
            _gateAssetsReady = false;
            _gateVideoDone = false;
            beginAssetPreload();
            startVideoPlayback("assets/videoKedua.mp4", onGateVideoComplete, 1500);
        }

        private function onGateVideoComplete():void {
            _gateVideoDone = true;
            maybeStartGameAfterGate();
        }

        private function beginAssetPreload():void {
            _preloadIndex = 0;
            loadNextAsset();
        }

        private function loadNextAsset():void {
            if (_preloadIndex >= PRELOAD_ASSETS.length) { onAssetsPreloaded(); return; }
            var path:String = PRELOAD_ASSETS[_preloadIndex++];
            _currentPreloadLoader = new Loader();
            _currentPreloadLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onAssetLoadComplete);
            _currentPreloadLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onAssetLoadComplete);
            try { _currentPreloadLoader.load(new URLRequest(path)); } catch (err:Error) { onAssetLoadComplete(null); }
        }

        private function onAssetLoadComplete(e:Event):void {
            if (_currentPreloadLoader) {
                _currentPreloadLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onAssetLoadComplete);
                _currentPreloadLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onAssetLoadComplete);
            }
            _currentPreloadLoader = null;
            loadNextAsset();
        }

        private function onAssetsPreloaded():void {
            _gateAssetsReady = true;
            maybeStartGameAfterGate();
        }

        private function maybeStartGameAfterGate():void {
            if (!_gateAssetsReady || !_gateVideoDone) return;
            initializeGame(_pendingSavedState, _pendingSavedCastleScale);
            _pendingSavedState = null;
            _pendingSavedCastleScale = NaN;
        }
        
        // ==========================================
        // MENU SYSTEM LOGIC
        // ==========================================
        
        private function initializeMenu():void {
            var audioManager:AudioManager = AudioManager.getInstance();
            if (!ServiceLocator.getInstance().has("AudioManager")) {
                ServiceLocator.getInstance().register("AudioManager", audioManager);
            }
            
            // Load saved settings and apply volume to AudioManager
            var saveSystem:SaveSystem = SaveSystem.getInstance();
            saveSystem.loadState();
            if (saveSystem.data && saveSystem.data.settings) {
                var savedMasterVolume:Number = saveSystem.data.settings.masterVolume;
                if (!isNaN(savedMasterVolume) && savedMasterVolume >= 0 && savedMasterVolume <= 1) {
                    var volumeLevel:int = Math.round(savedMasterVolume * 10);
                    audioManager.setMasterLevel(volumeLevel);
                    if (DEBUG) trace("[Main] Applied saved volume level: " + volumeLevel);
                }
            }
            
            if (DEBUG) trace("[Main] AudioManager initialized");
            
            _mainMenu = new MainMenu();
            _settingsMenu = new SettingsMenu();
            _aboutUs = new AboutUsPanel();
            _lessons = new LessonsPanel();
            
            _mainMenu.initialize(stage.stageWidth, stage.stageHeight);
            _settingsMenu.initialize(stage.stageWidth, stage.stageHeight);
            _aboutUs.initialize(stage.stageWidth, stage.stageHeight);
            _lessons.initialize(stage.stageWidth, stage.stageHeight);
            
            addChild(_mainMenu);
            addChild(_settingsMenu);
            addChild(_aboutUs);
            addChild(_lessons);
            
            _settingsMenu.hide();
            _aboutUs.hide();
            _lessons.hide();
            
            _settingsMenu.setPlusButtonPosition(335, -45);
            _settingsMenu.setMinButtonPosition(-430, -45);
            
            _mainMenu.addEventListener(MainMenu.PLAY_CLICKED, onPlayClicked);
            _mainMenu.addEventListener(MainMenu.SETTINGS_CLICKED, onSettingsClicked);
            _settingsMenu.addEventListener(SettingsMenu.CLOSE_CLICKED, onSettingsClose);
            _mainMenu.addEventListener(MainMenu.ABOUT_US_CLICKED, onAboutUsClicked);
            _aboutUs.addEventListener(AboutUsPanel.CLOSE_CLICKED, onAboutUsClose);
            _mainMenu.addEventListener(MainMenu.LESSONS_CLICKED, onLessonsClicked);
            _lessons.addEventListener(LessonsPanel.CLOSE_CLICKED, onLessonsClose);
            
            audioManager.playBgm("Bgmlobby");
        }
        
        private function onPlayClicked(event:Event):void {
            if (_mainMenu) _mainMenu.hide();
            if (_settingsMenu) _settingsMenu.hide();
            if (_aboutUs) _aboutUs.hide();
            if (_lessons) _lessons.hide();
            
            var audioManager:AudioManager = AudioManager.getInstance();
            if (audioManager) {
                audioManager.stopBgm();
            }
            
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

            startPreGameGate(savedState, savedCastleScale);
        }
        
        private function onSettingsClicked(event:Event):void {
            _settingsMenu.show();
        }
        
        private function onSettingsClose(event:Event):void {
            _settingsMenu.hide();
        }
        
        private function onAboutUsClicked(event:Event):void {
            _mainMenu.hide();
            _aboutUs.show();
        }
        
        private function onAboutUsClose(event:Event):void {
            _aboutUs.hide();
            _mainMenu.show();
        }
        
        private function onLessonsClicked(event:Event):void {
            _mainMenu.hide();
            _lessons.show();
        }
        
        private function onLessonsClose(event:Event):void {
            _lessons.hide();
            _mainMenu.show();
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
            
            _gameScreen = new GameScreen();
            _gameScreen.initialize(stage.stageWidth, stage.stageHeight);
            if (savedState) {
                _gameScreen.applySavedState(savedState, savedCastleScale);
            }
            _gameScreen.addEventListener(GameScreen.UPGRADE_CLICKED, onUpgradeClicked);
            _gameScreen.addEventListener("goToMainMenu", onGoToMainMenu);
            _gameScreen.addEventListener("retryGame", onRetryGame);
            addChild(_gameScreen);
            
            _upgradePopup = new UpgradePopup();
            _upgradePopup.initialize(stage.stageWidth, stage.stageHeight);
            _upgradePopup.addEventListener(UpgradePopup.CHALLENGE_STARTED, onChallengeStarted);
            _upgradePopup.addEventListener(UpgradePopup.CHALLENGE_SUCCESS, onChallengeSuccess);
            _upgradePopup.addEventListener(UpgradePopup.CHALLENGE_FAIL, onChallengeFail);
            _upgradePopup.addEventListener(UpgradePopup.POPUP_CLOSED, onPopupClosed);
            addChild(_upgradePopup);
            
            EffectsManager.getInstance().setParent(this);
        }
        
        private function onUpgradeClicked(event:Event):void {
            if (DEBUG) trace("[Main] Upgrade clicked - showing upgrade popup");
            if (_gameScreen) _gameScreen.setUpgradeButtonEnabled(false);
            
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
                _gameScreen.processUpgradeResult(progressionResult);
                
                if (progressionResult.wasCorrect) {
                    EffectsManager.getInstance().playCorrectEffect(center.x, center.y, _correctStreak * 10);
                } else {
                    EffectsManager.getInstance().playWrongEffect(center.x, center.y);
                    
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
            
            cleanupGame();
            
            if (_mainMenu) _mainMenu.show();
            var audioManager:AudioManager = AudioManager.getInstance();
            if (audioManager) {
                // Restore saved volume before playing BGM
                var saveSystem:SaveSystem = SaveSystem.getInstance();
                if (saveSystem.data && saveSystem.data.settings) {
                    var savedVolume:Number = saveSystem.data.settings.masterVolume;
                    if (!isNaN(savedVolume) && savedVolume >= 0 && savedVolume <= 1) {
                        audioManager.setMasterLevel(Math.round(savedVolume * 10));
                    }
                }
                audioManager.playBgm("Bgmlobby");
            }
        }
        
        private function onRetryGame(event:Event):void {
            if (DEBUG) trace("[Main] Retrying game");
            
            cleanupGame();
            initializeGame();
        }
        
        private function cleanupGame():void {
            _isInGame = false;
            
            var audioManager:AudioManager = AudioManager.getInstance();
            if (audioManager) {
                audioManager.stopBgm();
            }
            
            if (_gameScreen) {
                _gameScreen.removeEventListener(GameScreen.UPGRADE_CLICKED, onUpgradeClicked);
                _gameScreen.removeEventListener("goToMainMenu", onGoToMainMenu);
                _gameScreen.removeEventListener("retryGame", onRetryGame);
                if (contains(_gameScreen)) removeChild(_gameScreen);
                _gameScreen = null;
            }
            
            if (_upgradePopup) {
                _upgradePopup.removeEventListener(UpgradePopup.CHALLENGE_STARTED, onChallengeStarted);
                _upgradePopup.removeEventListener(UpgradePopup.CHALLENGE_SUCCESS, onChallengeSuccess);
                _upgradePopup.removeEventListener(UpgradePopup.CHALLENGE_FAIL, onChallengeFail);
                _upgradePopup.removeEventListener(UpgradePopup.POPUP_CLOSED, onPopupClosed);
                if (contains(_upgradePopup)) removeChild(_upgradePopup);
                _upgradePopup = null;
            }
            
            _correctStreak = 0;
            _wrongStreak = 0;
        }
        
        private function onResize(e:Event):void {
            StimulusConfig.updateForStageSize(stage.stageWidth, stage.stageHeight);
            
            if (_video) {
                layoutIntroVideo();
            }
            if (_skipBtn) {
                _skipBaseX = stage.stageWidth - (_skipBtnWidth + 20);
                _skipBaseY = stage.stageHeight - (_skipBtnHeight + 20);
                applySkipScale(_skipBtn.scaleX);
            }
            
            if (_mainMenu) _mainMenu.resize(stage.stageWidth, stage.stageHeight);
            if (_settingsMenu) _settingsMenu.resize(stage.stageWidth, stage.stageHeight);
            if (_aboutUs) _aboutUs.resize(stage.stageWidth, stage.stageHeight);
            if (_lessons) _lessons.initialize(stage.stageWidth, stage.stageHeight);
            
            if (_isInGame) {
                if (_gameScreen) _gameScreen.onResize(stage.stageWidth, stage.stageHeight);
                if (_upgradePopup) _upgradePopup.onResize(stage.stageWidth, stage.stageHeight);
            }
        }
    }
}
