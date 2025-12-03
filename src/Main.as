package {
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.system.Capabilities;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.AsyncErrorEvent;
    import flash.events.NetStatusEvent;
    import flash.events.StageVideoAvailabilityEvent;
    import flash.events.StageVideoEvent;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.media.Video;
    import flash.media.StageVideo;
    import flash.geom.Rectangle;
    import flash.filesystem.File;
    import flash.utils.getTimer;
    import generation.QuestionGenerator;
    import generation.NumberQuestion;
    import input.InputManager;
    import domain.StimulusItem;
    import domain.TrialResult;
    import config.StimulusConfig;
    import ui.GameScreen;
    import ui.TrialPopup;
    import ui.MainMenu;
    import ui.SettingsMenu;
    import ui.AboutUsPanel;
    import castle.EffectsManager;

    /**
     * Main - Application entry point with new UI layout.
     * 
     * Block Castle Mechanics:
     * - Correct 1-2x streak: Enlarge random existing block
     * - Correct 3x streak: Add new block (reset streak)
     * - Wrong 1-2x streak: Shrink random existing block
     * - Wrong 3x streak: Remove random block (reset streak)
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
        private var _gameScreen:GameScreen;
        private var _trialPopup:TrialPopup;
        private var _effectsManager:EffectsManager;
        
        // Game Logic
        private var _currentDifficulty:int = 1;
        private var _correctStreak:int = 0;
        private var _wrongStreak:int = 0;
        
        // State
        private var _isInGame:Boolean = false;

        public function Main() {
            // 1. Setup stage
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.addEventListener(Event.RESIZE, onStageResize);

            // 2. Update config
            StimulusConfig.updateForStageSize(stage.stageWidth, stage.stageHeight);
            
            // 3. Play opening video first
            playOpeningVideo();

            if (DEBUG) {
                trace("===== COGNITIVE CASTLE STARTED =====");
                trace("Platform: " + Capabilities.version);
                trace("Stage Size: " + stage.stageWidth + "x" + stage.stageHeight);
                trace("====================================");
            }
        }
        
        /**
         * Play opening video before showing menu
         */
        private function playOpeningVideo():void {
            if (DEBUG) {
                trace("[Main] Playing opening video...");
            }
            
            // Setup net connection FIRST
            _netConnection = new NetConnection();
            _netConnection.connect(null);
            
            // Setup net stream
            _netStream = new NetStream(_netConnection);
            _netStream.addEventListener(NetStatusEvent.NET_STATUS, onVideoStatus);
            _netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onVideoError);
            
            // Client object for metadata - MUST be set before play
            var client:Object = {};
            client.onMetaData = onVideoMetaData;
            client.onCuePoint = function(info:Object):void {};
            client.onPlayStatus = function(info:Object):void {
                if (DEBUG) trace("[Main] onPlayStatus: " + info.code);
            };
            _netStream.client = client;
            
            // Create Video object FIRST with explicit size
            _video = new Video(1280, 720);
            _video.width = stage.stageWidth;
            _video.height = stage.stageHeight;
            _video.x = 0;
            _video.y = 0;
            _video.smoothing = true;
            
            // Attach stream to video
            _video.attachNetStream(_netStream);
            
            // Create container and add video
            _videoContainer = new Sprite();
            _videoContainer.addChild(_video);
            addChild(_videoContainer);
            
            // Make sure video is on top
            setChildIndex(_videoContainer, numChildren - 1);
            
            if (DEBUG) {
                trace("[Main] Video object created: " + _video.width + "x" + _video.height);
                trace("[Main] Video container children: " + _videoContainer.numChildren);
            }
            
            // Get video file path
            var videoFile:File = File.applicationDirectory.resolvePath("assets/videoOpening.mp4");
            if (DEBUG) {
                trace("[Main] Video file URL: " + videoFile.url);
                trace("[Main] Video file exists: " + videoFile.exists);
            }
            
            if (!videoFile.exists) {
                trace("[Main] ERROR: Video file not found!");
                initializeMenu();
                return;
            }
            
            // Play video - use URL
            _netStream.play(videoFile.url);
            
            if (DEBUG) {
                trace("[Main] NetStream.play() called");
            }
            
            // Record video start time
            _videoStartTime = getTimer();
            
            // Create skip button after a short delay
            createSkipButton();
            
            // Start checking for skip button visibility
            addEventListener(Event.ENTER_FRAME, onVideoEnterFrame);
        }
        
        /**
         * Handle StageVideo render state changes (not used but kept for reference)
         */
        private function onStageVideoRenderState(event:StageVideoEvent):void {
            if (DEBUG) {
                trace("[Main] StageVideo render state: " + event.status);
            }
        }
        
        /**
         * Create skip button in bottom right corner
         */
        private function createSkipButton():void {
            _skipButton = new Sprite();
            
            // Button background
            _skipButton.graphics.beginFill(0x000000, 0.7);
            _skipButton.graphics.lineStyle(2, 0xFFFFFF);
            _skipButton.graphics.drawRoundRect(0, 0, 120, 40, 10, 10);
            _skipButton.graphics.endFill();
            
            // Button text
            var skipText:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 18;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = "center";
            
            skipText.defaultTextFormat = format;
            skipText.text = "Skip ▶▶";
            skipText.width = 120;
            skipText.height = 30;
            skipText.y = 8;
            skipText.selectable = false;
            skipText.mouseEnabled = false;
            _skipButton.addChild(skipText);
            
            // Position in bottom right corner with padding
            _skipButton.x = stage.stageWidth - 140;
            _skipButton.y = stage.stageHeight - 60;
            
            // Initially hidden
            _skipButton.visible = false;
            _skipButton.alpha = 0;
            _skipButton.buttonMode = true;
            _skipButton.useHandCursor = true;
            
            // Add click handler
            _skipButton.addEventListener(MouseEvent.CLICK, onSkipButtonClick);
            _skipButton.addEventListener(MouseEvent.ROLL_OVER, onSkipButtonOver);
            _skipButton.addEventListener(MouseEvent.ROLL_OUT, onSkipButtonOut);
            
            _videoContainer.addChild(_skipButton);
        }
        
        /**
         * Check if skip button should be visible (after 10 seconds)
         */
        private function onVideoEnterFrame(event:Event):void {
            if (_videoCompleted) return;
            
            var elapsedTime:Number = (getTimer() - _videoStartTime) / 1000; // Convert to seconds
            
            // Show skip button after 10 seconds
            if (!_skipButtonVisible && elapsedTime >= 10) {
                _skipButtonVisible = true;
                _skipButton.visible = true;
                
                // Fade in animation
                addEventListener(Event.ENTER_FRAME, fadeInSkipButton);
                
                if (DEBUG) {
                    trace("[Main] Skip button now visible (elapsed: " + elapsedTime.toFixed(1) + "s)");
                }
            }
        }
        
        /**
         * Fade in skip button
         */
        private function fadeInSkipButton(event:Event):void {
            if (_skipButton.alpha < 1) {
                _skipButton.alpha += 0.1;
            } else {
                _skipButton.alpha = 1;
                removeEventListener(Event.ENTER_FRAME, fadeInSkipButton);
            }
        }
        
        /**
         * Skip button hover effect
         */
        private function onSkipButtonOver(event:MouseEvent):void {
            _skipButton.scaleX = 1.05;
            _skipButton.scaleY = 1.05;
        }
        
        private function onSkipButtonOut(event:MouseEvent):void {
            _skipButton.scaleX = 1;
            _skipButton.scaleY = 1;
        }
        
        /**
         * Handle skip button click
         */
        private function onSkipButtonClick(event:MouseEvent):void {
            event.stopPropagation(); // Prevent event bubbling
            if (DEBUG) {
                trace("[Main] Skip button clicked");
            }
            onVideoComplete();
        }
        
        /**
         * Handle video metadata
         */
        private function onVideoMetaData(info:Object):void {
            if (DEBUG) {
                trace("[Main] Video metadata - duration: " + info.duration + "s, size: " + info.width + "x" + info.height);
            }
            
            // Store duration
            _videoDuration = info.duration ? info.duration : 0;
            
            // Store original video dimensions
            _videoOriginalWidth = info.width ? info.width : 1280;
            _videoOriginalHeight = info.height ? info.height : 720;
            
            // Apply responsive sizing
            resizeVideo();
        }
        
        /**
         * Resize video to fit current stage size while maintaining aspect ratio
         */
        private function resizeVideo():void {
            if (_videoCompleted) return;
            if (_videoOriginalWidth == 0 || _videoOriginalHeight == 0) return;
            
            var stageWidth:Number = stage.stageWidth;
            var stageHeight:Number = stage.stageHeight;
            
            // Scale video to cover screen while maintaining aspect ratio
            var scaleX:Number = stageWidth / _videoOriginalWidth;
            var scaleY:Number = stageHeight / _videoOriginalHeight;
            var scale:Number = Math.max(scaleX, scaleY); // Cover the screen
            
            var scaledWidth:Number = _videoOriginalWidth * scale;
            var scaledHeight:Number = _videoOriginalHeight * scale;
            var xOffset:Number = (stageWidth - scaledWidth) / 2;
            var yOffset:Number = (stageHeight - scaledHeight) / 2;
            
            if (_useStageVideo && _stageVideo) {
                // Update StageVideo viewport
                _stageVideo.viewPort = new Rectangle(xOffset, yOffset, scaledWidth, scaledHeight);
            } else if (_video) {
                // Update regular Video object
                _video.width = scaledWidth;
                _video.height = scaledHeight;
                _video.x = xOffset;
                _video.y = yOffset;
            }
            
            // Update skip button position
            if (_skipButton) {
                _skipButton.x = stageWidth - 140;
                _skipButton.y = stageHeight - 60;
            }
            
            if (DEBUG) {
                trace("[Main] Video resized to: " + scaledWidth.toFixed(0) + "x" + scaledHeight.toFixed(0) + " at (" + xOffset.toFixed(0) + ", " + yOffset.toFixed(0) + ")");
            }
        }
        
        /**
         * Handle video status events
         */
        private function onVideoStatus(event:NetStatusEvent):void {
            if (DEBUG) {
                trace("[Main] Video status: " + event.info.code);
            }
            
            switch (event.info.code) {
                case "NetStream.Play.Stop":
                    // Video finished playing
                    onVideoComplete();
                    break;
                case "NetStream.Play.StreamNotFound":
                    // Video file not found - skip to menu
                    trace("[Main] WARNING: Video file not found, skipping to menu");
                    onVideoComplete();
                    break;
                case "NetStream.Play.NoSupportedTrackFound":
                    // Video codec not supported - skip to menu
                    trace("[Main] WARNING: Video codec not supported (need H.264/AAC), skipping to menu");
                    trace("[Main] Please convert video using: ffmpeg -i input.mp4 -c:v libx264 -c:a aac output.mp4");
                    onVideoComplete();
                    break;
                case "NetStream.Play.Failed":
                    trace("[Main] WARNING: Video playback failed, skipping to menu");
                    onVideoComplete();
                    break;
            }
        }
        
        /**
         * Handle video errors
         */
        private function onVideoError(event:AsyncErrorEvent):void {
            if (DEBUG) {
                trace("[Main] Video error: " + event.text);
            }
            // Skip to menu on error
            onVideoComplete();
        }
        
        /**
         * Clean up video and show menu
         */
        private function onVideoComplete():void {
            if (_videoCompleted) return; // Prevent multiple calls
            _videoCompleted = true;
            
            if (DEBUG) {
                trace("[Main] Video complete - showing menu");
            }
            
            // Remove enter frame listeners
            removeEventListener(Event.ENTER_FRAME, onVideoEnterFrame);
            removeEventListener(Event.ENTER_FRAME, fadeInSkipButton);
            
            // Stop and clean up video
            if (_netStream) {
                _netStream.removeEventListener(NetStatusEvent.NET_STATUS, onVideoStatus);
                _netStream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, onVideoError);
                _netStream.close();
            }
            
            // Clean up StageVideo
            if (_stageVideo) {
                _stageVideo.removeEventListener(StageVideoEvent.RENDER_STATE, onStageVideoRenderState);
                _stageVideo.attachNetStream(null);
                _stageVideo = null;
            }
            
            if (_videoContainer) {
                // Clean up skip button
                if (_skipButton) {
                    _skipButton.removeEventListener(MouseEvent.CLICK, onSkipButtonClick);
                    _skipButton.removeEventListener(MouseEvent.ROLL_OVER, onSkipButtonOver);
                    _skipButton.removeEventListener(MouseEvent.ROLL_OUT, onSkipButtonOut);
                    _videoContainer.removeChild(_skipButton);
                    _skipButton = null;
                }
                
                if (_video) {
                    _video.attachNetStream(null);
                    _videoContainer.removeChild(_video);
                }
                removeChild(_videoContainer);
            }
            
            // Clean up references
            _video = null;
            _netStream = null;
            _netConnection = null;
            _videoContainer = null;
            _skipButtonVisible = false;
            _useStageVideo = false;
            
            // Initialize menu
            initializeMenu();
        }

        private function onStageResize(event:Event):void {
            if (DEBUG) {
                trace("Stage resized to: " + stage.stageWidth + "x" + stage.stageHeight);
            }
            
            // Resize video if playing
            if (!_videoCompleted && _video) {
                resizeVideo();
            }
            
            // Resize menu components
            if (_mainMenu) {
                _mainMenu.resize(stage.stageWidth, stage.stageHeight);
            }
            if (_settingsMenu) {
                _settingsMenu.resize(stage.stageWidth, stage.stageHeight);
            }
            if (_aboutUsPanel) {
                _aboutUsPanel.resize(stage.stageWidth, stage.stageHeight);
            }
            
            // Resize game components
            if (_gameScreen) {
                _gameScreen.onResize(stage.stageWidth, stage.stageHeight);
            }
            if (_trialPopup) {
                _trialPopup.resize(stage.stageWidth, stage.stageHeight);
            }
        }
        
        /**
         * Initialize main menu system
         */
        private function initializeMenu():void {
            // Create main menu
            _mainMenu = new MainMenu();
            _mainMenu.initialize(stage.stageWidth, stage.stageHeight);
            _mainMenu.addEventListener(MainMenu.PLAY_CLICKED, onPlayClicked);
            _mainMenu.addEventListener(MainMenu.SETTINGS_CLICKED, onSettingsClicked);
            _mainMenu.addEventListener(MainMenu.ABOUT_US_CLICKED, onAboutUsClicked);
            addChild(_mainMenu);
            
            // Create settings menu (hidden)
            _settingsMenu = new SettingsMenu();
            _settingsMenu.initialize(stage.stageWidth, stage.stageHeight);
            _settingsMenu.addEventListener(SettingsMenu.CLOSE_CLICKED, onSettingsClose);
            _settingsMenu.addEventListener(SettingsMenu.SETTINGS_CHANGED, onSettingsChanged);
            addChild(_settingsMenu);
            
            // Create about us panel (hidden)
            _aboutUsPanel = new AboutUsPanel();
            _aboutUsPanel.initialize(stage.stageWidth, stage.stageHeight);
            _aboutUsPanel.addEventListener(AboutUsPanel.CLOSE_CLICKED, onAboutUsClose);
            addChild(_aboutUsPanel);
            
            if (DEBUG) {
                trace("[Main] Menu system initialized");
            }
        }
        
        /**
         * Handle Play button click
         */
        private function onPlayClicked(event:Event):void {
            if (DEBUG) {
                trace("[Main] Play clicked - starting game");
            }
            
            // Hide menu
            _mainMenu.hide();
            
            // Initialize game after menu animation
            _mainMenu.addEventListener(Event.ENTER_FRAME, checkMenuHidden);
        }
        
        private function checkMenuHidden(e:Event):void {
            if (_mainMenu.alpha <= 0) {
                _mainMenu.removeEventListener(Event.ENTER_FRAME, checkMenuHidden);
                initializeGame();
            }
        }
        
        /**
         * Handle Settings button click
         */
        private function onSettingsClicked(event:Event):void {
            if (DEBUG) {
                trace("[Main] Settings clicked");
            }
            // Hide main menu and show settings page
            _mainMenu.visible = false;
            _settingsMenu.show();
        }
        
        /**
         * Handle Settings close
         */
        private function onSettingsClose(event:Event):void {
            if (DEBUG) {
                trace("[Main] Settings closed - back to menu");
            }
            _settingsMenu.hide();
            // Show main menu again
            _mainMenu.visible = true;
            _mainMenu.alpha = 1;
        }
        
        /**
         * Handle Settings changed
         */
        private function onSettingsChanged(event:Event):void {
            if (DEBUG) {
                trace("[Main] Settings changed - Music: " + _settingsMenu.musicVolume + ", SFX: " + _settingsMenu.sfxVolume);
            }
            // TODO: Apply volume settings to sound system
        }
        
        /**
         * Handle About Us button click
         */
        private function onAboutUsClicked(event:Event):void {
            if (DEBUG) {
                trace("[Main] About Us clicked");
            }
            // Hide main menu and show about us page
            _mainMenu.visible = false;
            _aboutUsPanel.show();
        }
        
        /**
         * Handle About Us close
         */
        private function onAboutUsClose(event:Event):void {
            if (DEBUG) {
                trace("[Main] About Us closed - back to menu");
            }
            _aboutUsPanel.hide();
            // Show main menu again
            _mainMenu.visible = true;
            _mainMenu.alpha = 1;
        }

        /**
         * Initialize game components
         */
        private function initializeGame():void {
            _isInGame = true;
            
            // Create game screen
            _gameScreen = new GameScreen();
            _gameScreen.initialize(stage.stageWidth, stage.stageHeight);
            _gameScreen.addEventListener(GameScreen.UPGRADE_CLICKED, onUpgradeClicked);
            addChild(_gameScreen);
            
            // Create trial popup (hidden initially)
            _trialPopup = new TrialPopup();
            _trialPopup.initialize(stage.stageWidth, stage.stageHeight);
            _trialPopup.addEventListener(TrialPopup.TRIAL_SUCCESS, onTrialSuccess);
            _trialPopup.addEventListener(TrialPopup.TRIAL_FAIL, onTrialFail);
            _trialPopup.addEventListener(TrialPopup.TRIAL_CLOSED, onTrialClosed);
            addChild(_trialPopup);
            
            // Effects manager
            _effectsManager = EffectsManager.getInstance();
            _effectsManager.setParent(this);
            
            if (DEBUG) {
                trace("[Main] Game initialized");
            }
        }
        
        /**
         * Handle upgrade button click - show trial popup
         */
        private function onUpgradeClicked(event:Event):void {
            if (DEBUG) {
                trace("[Main] Upgrade clicked - showing trial popup");
            }
            
            // Disable upgrade button while trial is active
            _gameScreen.setUpgradeButtonEnabled(false);
            
            // Show trial popup - level progression is handled internally by TrialPopup
            _trialPopup.show();
        }
        
        /**
         * Handle trial success
         * NEW SYSTEM: Process upgrade based on streak (1-11)
         */
        private function onTrialSuccess(event:Event):void {
            _correctStreak++;
            _wrongStreak = 0; // Reset wrong streak
            
            if (DEBUG) {
                trace("[Main] Trial SUCCESS! Correct streak: " + _correctStreak);
            }
            
            var center:Object = _gameScreen.getCastleCenter();
            
            // Process upgrade based on streak (1-11 system)
            _gameScreen.processUpgrade(_correctStreak);
            
            // Show different alerts based on streak
            var alertMsg:String = "";
            switch (_correctStreak) {
                case 1:
                case 2:
                    alertMsg = "Tower Growing!";
                    _effectsManager.playCorrectEffect(center.x, center.y, _correctStreak * 10);
                    break;
                case 3:
                    alertMsg = "New Tower Added!";
                    _effectsManager.playStreakEffect(center.x, center.y - 40, 3);
                    break;
                case 4:
                case 5:
                    alertMsg = "Side Tower Growing!";
                    _effectsManager.playCorrectEffect(center.x, center.y, _correctStreak * 10);
                    break;
                case 6:
                    alertMsg = "Second Tower Added!";
                    _effectsManager.playStreakEffect(center.x, center.y - 40, 3);
                    break;
                case 7:
                case 8:
                    alertMsg = "Tower Expanding!";
                    _effectsManager.playCorrectEffect(center.x, center.y, _correctStreak * 10);
                    break;
                case 9:
                    alertMsg = "Roofs Added!";
                    _effectsManager.playStreakEffect(center.x, center.y - 40, 3);
                    break;
                case 10:
                case 11:
                    alertMsg = "Roofs Growing!";
                    _effectsManager.playCorrectEffect(center.x, center.y, _correctStreak * 10);
                    break;
                default:
                    alertMsg = "Castle Upgraded!";
                    _effectsManager.playCorrectEffect(center.x, center.y, 10);
            }
            
            _gameScreen.showUpgradeAlert(alertMsg);
            
            if (DEBUG) {
                trace("[Main] Upgrade processed. Streak: " + _correctStreak);
            }
        }
        
        /**
         * Handle trial fail
         * NEW SYSTEM: Shrink castle on wrong answer
         */
        private function onTrialFail(event:Event):void {
            _wrongStreak++;
            _correctStreak = 0; // Reset correct streak
            
            if (DEBUG) {
                trace("[Main] Trial FAIL! Wrong streak: " + _wrongStreak);
            }
            
            var center:Object = _gameScreen.getCastleCenter();
            
            // Process wrong - shrink castle
            _gameScreen.processWrong();
            
            // Show wrong effect
            _effectsManager.playWrongEffect(center.x, center.y);
        }
        
        /**
         * Handle trial closed
         */
        private function onTrialClosed(event:Event):void {
            if (DEBUG) {
                trace("[Main] Trial popup closed - castle changes visible");
            }
            
            // Hide alert after popup closes
            _gameScreen.hideUpgradeAlert();
            
            // Re-enable upgrade button
            _gameScreen.setUpgradeButtonEnabled(true);
        }
    }
}