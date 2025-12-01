package {
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.system.Capabilities;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import generation.SequenceGenerator;
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
            
            // 3. Initialize components - start with menu
            initializeMenu();

            if (DEBUG) {
                trace("===== COGNITIVE CASTLE STARTED =====");
                trace("Platform: " + Capabilities.version);
                trace("Stage Size: " + stage.stageWidth + "x" + stage.stageHeight);
                trace("====================================");
            }
        }

        private function onStageResize(event:Event):void {
            if (DEBUG) {
                trace("Stage resized to: " + stage.stageWidth + "x" + stage.stageHeight);
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
            
            // Show trial popup with current difficulty
            _trialPopup.setDifficulty(_currentDifficulty);
            _trialPopup.show(_currentDifficulty);
        }
        
        /**
         * Handle trial success
         * Flow:
         * - Correct 1-2x: Enlarge random block
         * - Correct 3x: Add new block (reset streak)
         */
        private function onTrialSuccess(event:Event):void {
            _correctStreak++;
            _wrongStreak = 0; // Reset wrong streak
            
            if (DEBUG) {
                trace("[Main] Trial SUCCESS! Correct streak: " + _correctStreak);
            }
            
            var center:Object = _gameScreen.getCastleCenter();
            
            if (_correctStreak >= 3) {
                // Third correct in a row - add new block
                _gameScreen.addNewBlock();
                _correctStreak = 0; // Reset streak
                
                if (DEBUG) {
                    trace("[Main] Added new block! Streak reset. Total blocks: " + _gameScreen.getBlockCount());
                }
                
                // Show big effect for adding new block
                _effectsManager.playStreakEffect(center.x, center.y - 40, 3);
                _gameScreen.showUpgradeAlert("New Block Added!");
            } else {
                // First or second correct - enlarge random block
                _gameScreen.enlargeRandomBlock();
                
                if (DEBUG) {
                    trace("[Main] Enlarged random block. Streak: " + _correctStreak);
                }
                
                // Show effect
                _effectsManager.playCorrectEffect(center.x, center.y, _correctStreak * 10);
            }
        }
        
        /**
         * Handle trial fail
         * Flow:
         * - Wrong 1-2x: Shrink random block
         * - Wrong 3x: Remove random block (reset streak)
         */
        private function onTrialFail(event:Event):void {
            _wrongStreak++;
            _correctStreak = 0; // Reset correct streak
            
            if (DEBUG) {
                trace("[Main] Trial FAIL! Wrong streak: " + _wrongStreak);
            }
            
            var center:Object = _gameScreen.getCastleCenter();
            
            if (_wrongStreak >= 3) {
                // Third wrong in a row - remove random block
                var removed:Boolean = _gameScreen.removeRandomBlock();
                _wrongStreak = 0; // Reset streak
                
                if (removed) {
                    if (DEBUG) {
                        trace("[Main] Removed random block! Streak reset. Total blocks: " + _gameScreen.getBlockCount());
                    }
                    _gameScreen.showUpgradeAlert("Block Removed!");
                } else {
                    if (DEBUG) {
                        trace("[Main] Cannot remove - only 1 block left");
                    }
                }
                
            } else {
                // First or second wrong - shrink random block
                _gameScreen.shrinkRandomBlock();
                
                if (DEBUG) {
                    trace("[Main] Shrunk random block. Wrong streak: " + _wrongStreak);
                }
            }
            
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