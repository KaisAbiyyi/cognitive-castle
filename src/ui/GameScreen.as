package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.DisplayObject;
    import flash.display.BlendMode;
    import flash.net.URLRequest;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.events.IOErrorEvent;
    import flash.utils.Timer;
    import flash.utils.Dictionary;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.geom.ColorTransform;
    import castle.AdditionTower;
    import castle.CastleState;
    import castle.TowerCastle;
    import castle.TowerAddition;
    import game.ProgressionManager;
    import game.ProgressionResult;
    import services.AudioManager;
    import services.SaveSystem;
    import core.ServiceLocator;
    
    /**
     * GameScreen - Main game screen with FULL WINDOW castle view and upgrade button.
     * Auto-resizing layout that adapts to any window size.
     * * Layout:
     * - Window frame (black border) - scales with window
     * - Castle FULL WINDOW (using TowerCastle) - fills available space
     * - Upgrade button (bottom left) - responsive size and position
     * - Alert upgrade popup - centered
     */
    public class GameScreen extends Sprite {
        
        // Debug
        private static const DEBUG:Boolean = true;
        
        // Events
        public static const UPGRADE_CLICKED:String = "upgradeClicked";
        public static const TRIAL_COMPLETE:String = "trialComplete";
        
        // Dimensions
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Layout constants (responsive)
        private var _margin:Number = 20;
        private var _frameMargin:Number = 40;
        private var _buttonSize:Number = 50;
        private var _cornerRadius:Number = 30;
        
        // Visual components
        private var _gradientBackground:Shape;
        private var _cloudsContainer:Sprite;
        private var _clouds:Vector.<Object>;
        private var _cloudTimer:Timer;
        private var _backgroundBitmap:Bitmap;
        private var _towerCastle:TowerCastle;
        private var _mainCastle:Sprite;
        private var _mainCastleBitmap:Bitmap;
        private var _castleScale:Number = 1.0; // Start at full integrity (stage 5)
        private var _pendingSavedState:CastleState;
        private var _pendingSavedCastleScale:Number = NaN;
        
        // Tower additions
        private var _towerAdditions:Vector.<TowerAddition>;
        private var _towerContainer:Sprite;
        private var _progressionManager:ProgressionManager;
        
        private var _shadowLayer:Sprite;
        private var _castleShadow:Sprite;
        private var _castleShadowBitmap:Bitmap;
        private var _castleContactShadow:Shape;
        private var _hordeShadow:Sprite;
        private var _hordeShadowBitmap:Bitmap;
        private var _hordeContactShadow:Shape;
        private var _horde:Sprite;
        private var _hordeBitmap:Bitmap;
        private var _hordeTimer:Timer;
        private var _hordeDueAtMs:Number = 0;
        private var _hordeRemainingMs:Number = 0;
        private var _hordeAttackActive:Boolean = false;
        private var _hordeForceRetreat:Boolean = false;
        private var _hordeDustLayer:Sprite;
        private var _hordeDustParticles:Vector.<Object>;
        private var _hordeDustSpawnRemainder:Number = 0;
        private var _hordeDamageTimer:Timer;
        private var _hordeShrinkTimer:Timer;
        private var _hordeDamagePerSecond:Number = 0.04; // 4% scale loss per second while shrinking
        private var _hordeAttackDuration:Number = 2500; // Shrink for 2.5 seconds after collision
        private var _hordeCastleOverlapPx:Number = 30; // How deep the horde overlaps into the castle on hit
        private var _hordeDamageStepIntervalMs:Number = 180; // Damage happens in steps (ms)
        private var _hordeDamagePopAmount:Number = 0.035; // Pop-up amount per step (3.5%)
        private var _hordeDamageStepAccumMs:Number = 0;
        private var _hordeDamagePulseMs:Number = 0;
        private var _castleDestructionThreshold:Number = 0.45; // Castle destroyed below this
        
        // Horde target tracking
        private var _hordeTargetTower:TowerAddition = null; // If not null, horde is attacking this tower
        private var _hordeFromRight:Boolean = false;
        
        // Siege / horde timer (player idle 2-3 minutes)
        private static const HORDE_MIN_DELAY_MS:Number = 120000;  // 2 minutes
        private static const HORDE_MAX_DELAY_MS:Number = 180000;  // 3 minutes
        
        // Upgrade visuals
        private static const CASTLE_POP_DURATION_MS:int = 420;
        private static const UPGRADE_FX_ICON_HEIGHT:Number = 40;
        private static const SHADOW_COLOR:uint = 0x000000;
        private static const CASTLE_SHADOW_ALPHA:Number = 0.22;
        private static const HORDE_SHADOW_ALPHA:Number = 0.20;
        private static const CASTLE_SHADOW_FLATTEN:Number = 0.16;
        private static const HORDE_SHADOW_FLATTEN:Number = 0.15;
        private static const CASTLE_SHADOW_STRETCH:Number = 1.08;
        private static const HORDE_SHADOW_STRETCH:Number = 1.05;
        private static const CASTLE_SHADOW_SKEW_DEG:Number = 28;
        private static const HORDE_SHADOW_SKEW_DEG:Number = 26;
        private static const CASTLE_SHADOW_OFFSET_X:Number = 0;
        private static const CASTLE_SHADOW_OFFSET_Y:Number = -3;
        private static const HORDE_SHADOW_OFFSET_X:Number = 0;
        private static const HORDE_SHADOW_OFFSET_Y:Number = -3;
        private static const CASTLE_CONTACT_ALPHA:Number = 0.28;
        private static const HORDE_CONTACT_ALPHA:Number = 0.26;
        private static const CASTLE_CONTACT_WIDTH_RATIO:Number = 0.95;
        private static const HORDE_CONTACT_WIDTH_RATIO:Number = 0.90;
        private static const CONTACT_OFFSET_Y:Number = 0;
        private var _upgradeButton:Sprite;
        private var _upgradeButtonBitmap:Bitmap;
        private var _pauseButton:Sprite;
        private var _pauseButtonBitmap:Bitmap;
        private var _pauseOverlay:Shape;
        private var _pausePopup:Sprite;
        private var _pausePopupBitmap:Bitmap;
        private var _pauseXButton:Sprite;
        private var _mainMenuButton:Sprite;
        private var _retryButton:Sprite;
        private var _saveButton:Sprite;
        private var _isPaused:Boolean = false;
        private var _isUpgradePopupOpen:Boolean = false;
        
        // Upgrade pop animation
        private var _castlePopTimer:Timer;
        private var _castlePopStartMs:Number = 0;
        private var _castlePopFromScale:Number = 0.7;
        private var _castlePopToScale:Number = 0.7;
        
        // Upgrade FX (lamp + gear rising behind castle)
        private var _upgradeFxLayer:Sprite;
        private var _upgradeFxItems:Vector.<Object>;
        private var _upgradeFxTimer:Timer;
        private var _upgradeLampBitmapData:BitmapData;
        private var _upgradeGearBitmapData:BitmapData;
        
        // Save notification
        private var _saveNotification:TextField;
        private var _saveNotificationBg:Sprite;
        private var _saveNotificationTimer:Timer;

        // Win charge HUD (3 orbs)
        private static const ORB_COUNT:int = 3;
        private static const ORB_FILL_PULSE_AMOUNT:Number = 0.18;
        private static const ORB_FILL_PULSE_MS:int = 160;
        private static const ORB_FULL_PULSE_AMOUNT:Number = 0.22;
        private static const ORB_FULL_PULSE_MS:int = 220;
        
        private var _orbHud:Sprite;
        private var _orbSprites:Vector.<Sprite>;
        private var _orbBitmaps:Vector.<Bitmap>;
        private var _orbEmptyData:BitmapData;
        private var _orbFilledData:BitmapData;
        private var _orbCharge:int = 0;
        private var _orbDesiredHeight:Number = 24;
        private var _orbGap:Number = 10;
        private var _orbTopPadding:Number = 18;
        private var _orbPulseBySprite:Dictionary;
        private var _orbPulseByTimer:Dictionary;
        private var _orbResetTimer:Timer;
        
        // Hover animation constants
        private static const HOVER_SCALE:Number = 1.15;
        private static const HOVER_DURATION:Number = 150; // ms
        
        /**
         * Constructor
         */
        public function GameScreen() {
            _upgradeFxItems = new Vector.<Object>();
            _towerAdditions = new Vector.<TowerAddition>();
            _progressionManager = ProgressionManager.getInstance();
            _orbPulseBySprite = new Dictionary(true);
            _orbPulseByTimer = new Dictionary(true);
        }
        
        /**
         * Initialize the screen
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            // Calculate responsive values
            updateResponsiveValues();
            
            loadBackground();
            createClouds();
            createShadowLayer();
            createUpgradeFxLayer();
            preloadUpgradeFxAssets();
            createTower();
            startRandomHordeTimer();
            createUpgradeButton();
            createPauseButton();
            createPauseOverlay();
            createSaveNotification();
            createOrbHud();

            // Start in-game background music only when entering the game screen
            var audioManager:AudioManager = getAudioManager();
            if (audioManager) {
                audioManager.playBgm("bgmGame");
            }
            
            if (DEBUG) {
                trace("[GameScreen] Initialized with size: " + stageWidth + "x" + stageHeight);
            }
        }

        public function applySavedState(savedState:CastleState, castleScale:Number = NaN):void {
            _pendingSavedState = savedState;
            _pendingSavedCastleScale = castleScale;
            applySavedStateIfReady();
        }

        private function applySavedStateIfReady():void {
            if (!_pendingSavedState) return;
            if (!_mainCastle || !_mainCastleBitmap) return;
            
            var state:CastleState = _pendingSavedState;
            var targetScale:Number = _pendingSavedCastleScale;
            if (isNaN(targetScale)) {
                var growthScale:Number = 0.7 + (state.mainCastleSizeLevel * 0.1);
                var integrityScale:Number = state.getMainCastleIntegrityScale();
                targetScale = Math.max(growthScale, integrityScale);
            }
            
            _castleScale = Math.max(0, targetScale);
            applyCastleScale(_castleScale);
            updateTowerPosition();
            
            rebuildTowersFromState(state);
            resetOrbChargeHud();
            setOrbCharge(state.winStreak % ORB_COUNT, false);
            
            _pendingSavedState = null;
            _pendingSavedCastleScale = NaN;
        }
        
        /**
         * Start random timer for horde attacks
         */
        private function startRandomHordeTimer():void {
            _hordeRemainingMs = getRandomHordeDelayMs();
            
            if (shouldHordeCountdownRun()) {
                startHordeCountdown(_hordeRemainingMs);
                return;
            }
            
            // Timer is "paused" (upgrade open / pause menu), keep remaining for resume.
            disposeHordeTimer();
        }
        
        private function getRandomHordeDelayMs():Number {
            return HORDE_MIN_DELAY_MS + Math.random() * (HORDE_MAX_DELAY_MS - HORDE_MIN_DELAY_MS);
        }
        
        private function shouldHordeCountdownRun():Boolean {
            return !_isPaused && !_isUpgradePopupOpen;
        }
        
        private function startHordeCountdown(delayMs:Number):void {
            disposeHordeTimer();
            
            var clampedDelay:Number = Math.max(1, delayMs);
            _hordeRemainingMs = clampedDelay;
            _hordeDueAtMs = new Date().time + clampedDelay;
            
            _hordeTimer = new Timer(clampedDelay, 1);
            _hordeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onHordeAttackTrigger);
            _hordeTimer.start();
        }
        
        private function disposeHordeTimer():void {
            if (_hordeTimer) {
                _hordeTimer.stop();
                _hordeTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onHordeAttackTrigger);
                _hordeTimer = null;
            }
        }
        
        private function pauseHordeCountdown():void {
            if (_hordeTimer && _hordeTimer.running) {
                var now:Number = new Date().time;
                _hordeRemainingMs = Math.max(1, _hordeDueAtMs - now);
            }
            
            _hordeDueAtMs = 0;
            disposeHordeTimer();
        }
        
        private function resumeHordeCountdown():void {
            if (!shouldHordeCountdownRun()) return;
            if (_hordeTimer && _hordeTimer.running) return;
            
            if (_hordeRemainingMs <= 0) {
                _hordeRemainingMs = getRandomHordeDelayMs();
            }
            
            startHordeCountdown(_hordeRemainingMs);
        }
        
        private function onHordeAttackTrigger(e:TimerEvent):void {
            _hordeRemainingMs = 0;
            _hordeDueAtMs = 0;
            
            if (!_isPaused && !_isUpgradePopupOpen && _castleScale > 0.1) {
                triggerHordeAttack();
            }
            // Schedule next attack
            startRandomHordeTimer();
        }
        
        /**
         * Public hook to reset the siege countdown (e.g., after player activity)
         */
        public function resetHordeTimer():void {
            startRandomHordeTimer();
        }
        
        /**
         * Trigger horde attack
         */
        private function triggerHordeAttack():void {
            if (_hordeAttackActive) return; // Prevent multiple hordes
            
            _hordeAttackActive = true;
            _horde = new Sprite();
            addChild(_horde);
            syncTopUiLayering();
            ensureHordeDustLayer();
            clearHordeDust();
            clearHordeShadow();
            
            // Determine attack direction based on tower configuration
            var fromRight:Boolean = determineHordeDirection();
            _hordeFromRight = fromRight;
            
            // Find target: NEWEST tower (priority), or main castle if no towers
            _hordeTargetTower = findNewestTower();
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _hordeBitmap = Bitmap(e.target.content);
                _hordeBitmap.smoothing = true;
                
                // Scale horde smaller (100px height)
                var targetHeight:Number = 100;
                var scale:Number = targetHeight / _hordeBitmap.height;
                _hordeBitmap.scaleX = scale;
                 _hordeBitmap.scaleY = scale;
                 
                 _horde.addChild(_hordeBitmap);
                 
                 // Center bitmap so sprite origin is in the middle (prevents flip-jumps and fixes collision math)
                 _hordeBitmap.x = -_hordeBitmap.width / 2;
                 _hordeBitmap.y = -_hordeBitmap.height / 2;
                 
                 var hordeHalfWidth:Number = _hordeBitmap.width / 2;
                 var hordeHalfHeight:Number = _hordeBitmap.height / 2;
                 var offscreenPadding:Number = 100;
                 
                 if (fromRight) {
                     _horde.x = _stageWidth + hordeHalfWidth + offscreenPadding;
                     _horde.scaleX = 1; // Normal
                 } else {
                     _horde.x = -hordeHalfWidth - offscreenPadding;
                     _horde.scaleX = -1; // Flip
                 }
                 
                 // Position horde (keep previous top alignment relative to the castle)
                 var desiredTop:Number = _mainCastle.y - 80;
                 _horde.y = desiredTop + hordeHalfHeight;
                
                createHordeShadow();
                 
                 // Start movement with collision detection
                 startHordeMovement(fromRight);
                
                if (DEBUG) {
                    trace("[GameScreen] Horde attack triggered from " + (fromRight ? "right" : "left") + 
                          ", target: " + (_hordeTargetTower ? "tower " + _hordeTargetTower.towerId : "main castle"));
                }
            });
            
            loader.load(new URLRequest("assets/images/Game/horde.png"));
        }
        
        /**
         * Determine horde direction based on newest tower:
         * - No towers: random direction (attack main castle)
         * - Has towers: attack from the side where the NEWEST tower is
         * 
         * This ensures horde always targets the newest tower first.
         */
        private function determineHordeDirection():Boolean {
            if (_progressionManager && _progressionManager.state) {
                var stateTower:AdditionTower = _progressionManager.state.getNewestTower();
                if (stateTower) {
                    return stateTower.side == CastleState.SIDE_RIGHT;
                }
            }
            
            var newestTower:TowerAddition = findNewestTower();
            if (!newestTower) {
                // No towers - random direction to attack main castle
                return Math.random() > 0.5;
            }
            
            // Attack from the side where the newest tower is
            return newestTower.side == "right";
        }
        
        /**
         * Animate horde movement towards castle with collision detection
         */
        private function startHordeMovement(fromRight:Boolean):void {
            var duration:Number = 3000; // 3 seconds to reach castle
            var startTime:Number = new Date().getTime();
            var startX:Number = _horde.x;
            var targetX:Number = _mainCastle.x; // Target is castle center, but collision check will stop it before reaching
            var hasCollided:Boolean = false;
            var damageStartTime:Number = 0;
            var retreatStartTime:Number = 0;
            var phase:String = "approach"; // approach | damaging | retreating
            
            // Get AudioManager once at function scope to avoid duplicate declarations
            var audioManager:AudioManager = getAudioManager();
            
            var frameMs:Number = 33;
            var moveTimer:Timer = new Timer(frameMs); // ~30fps
            moveTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
                if (!_hordeAttackActive || !_horde) {
                    moveTimer.stop();
                    return;
                }
                
                tickHordeDust(frameMs, fromRight, phase == "approach");
                
                // If castle gets destroyed mid-attack, force the horde to retreat (don't disappear instantly)
                if (_hordeForceRetreat && phase != "retreating") {
                    _hordeForceRetreat = false;
                    phase = "retreating";
                    retreatStartTime = new Date().getTime();
                    
                    if (_horde) {
                        _horde.scaleX *= -1; // Face retreat direction
                    }
                    if (_hordeShrinkTimer) {
                        _hordeShrinkTimer.stop();
                    }
                    
                    // Stop enemy attack sound (use audioManager from function scope)
                    if (audioManager) {
                        audioManager.stopRepeatingSfx();
                    }
                    
                    if (DEBUG) {
                        trace("[GameScreen] Castle destroyed - forcing horde retreat...");
                    }
                }
                
                if (phase == "approach") {
                    // Moving towards castle
                    var elapsed:Number = new Date().getTime() - startTime;
                    var progress:Number = Math.min(elapsed / duration, 1.0);
                    _horde.x = startX + (targetX - startX) * progress;
                    
                    // Debug info
                    if (DEBUG && elapsed % 500 < 33) { // Print every ~500ms
                        var castleWidth:Number = _mainCastleBitmap ? _mainCastleBitmap.width * _castleScale : 0;
                        var hordeWidth:Number = _hordeBitmap ? _hordeBitmap.width * Math.abs(_horde.scaleX) : 0;
                        var distance:Number = Math.abs(_horde.x - _mainCastle.x);
                        trace("[GameScreen] Horde approach - distance to castle: " + Math.round(distance) + "px, progress: " + Math.round(progress * 100) + "%");
                    }
                    
                    // Check for collision with castle
                    if (checkHordeCastleCollision(fromRight)) {
                        phase = "damaging";
                        damageStartTime = new Date().getTime();
                        
                        // Start castle damage/shrinking timer
                        startHordeDamage();
                        
                        if (DEBUG) {
                            trace("[GameScreen] Horde collision! Starting damage timer for " + _hordeAttackDuration + "ms...");
                        }
                    }
                } else if (phase == "damaging") {
                    // Stay in place while castle shrinks
                    var damageElapsed:Number = new Date().getTime() - damageStartTime;
                    
                    // Check if damage duration has finished
                    if (damageElapsed >= _hordeAttackDuration) {
                        // Damage phase complete - start retreat
                        phase = "retreating";
                        retreatStartTime = new Date().getTime();
                        
                        // Flip horde sprite for retreat
                        if (_horde) {
                            _horde.scaleX *= -1; // Flip horizontally
                        }
                        
                        if (_hordeShrinkTimer) {
                            _hordeShrinkTimer.stop();
                        }
                        applyCastleScale(_castleScale);
                        
                        // Stop enemy attack sound (use audioManager from function scope)
                        if (audioManager) {
                            audioManager.stopRepeatingSfx();
                        }
                        
                        if (DEBUG) {
                            trace("[GameScreen] Damage duration finished. Horde now retreating...");
                        }
                    }
                } else if (phase == "retreating") {
                    // Moving back out after collision
                    var retreatElapsed:Number = new Date().getTime() - retreatStartTime;
                    var retreatDuration:Number = 2000; // 2 seconds to retreat
                    var retreatProgress:Number = Math.min(retreatElapsed / retreatDuration, 1.0);
                    
                     // Start from current horde position and move to edge
                     var currentHordeX:Number = _horde.x;
                     var offscreenPadding:Number = 100;
                     var halfWidth:Number = _hordeBitmap ? _hordeBitmap.width / 2 : 0;
                     var retreatTargetX:Number = fromRight ? _stageWidth + halfWidth + offscreenPadding : -halfWidth - offscreenPadding;
                     
                     _horde.x = currentHordeX + (retreatTargetX - currentHordeX) * retreatProgress;
                    
                    if (retreatProgress >= 1.0) {
                        if (DEBUG) {
                            trace("[GameScreen] Horde retreat complete. Attack ended.");
                        }
                        endHordeAttack();
                        moveTimer.stop();
                    }
                }
                
                updateHordeShadow();
            });
            moveTimer.start();
        }
        
        /**
         * Check collision between horde and its target (tower or castle) - edge to edge collision
         */
        private function checkHordeCastleCollision(fromRight:Boolean):Boolean {
            if (!_horde) return false;
            
            var hordeBounds:Rectangle = _horde.getBounds(this);
            var targetBounds:Rectangle;
            
            // If we have a target tower, check collision with it first
            if (_hordeTargetTower && _hordeTargetTower.isLoaded) {
                targetBounds = _hordeTargetTower.getBounds(this);
            } else if (_mainCastle) {
                targetBounds = _mainCastle.getBounds(this);
            } else {
                return false;
            }
            
            // Require some vertical overlap to avoid false positives
            var yOverlaps:Boolean = (hordeBounds.bottom >= targetBounds.top && hordeBounds.top <= targetBounds.bottom);
            if (!yOverlaps) return false;
            
            var isColliding:Boolean;
            if (fromRight) {
                // Horde approaches from the right: its left edge should meet target's right edge
                var desiredHordeLeft:Number = targetBounds.right - _hordeCastleOverlapPx;
                isColliding = (hordeBounds.left <= desiredHordeLeft);
                if (isColliding) {
                    // Clamp so it visually touches (no early stop / gap)
                    _horde.x += (desiredHordeLeft - hordeBounds.left);
                }
            } else {
                // Horde approaches from the left: its right edge should meet target's left edge
                var desiredHordeRight:Number = targetBounds.left + _hordeCastleOverlapPx;
                isColliding = (hordeBounds.right >= desiredHordeRight);
                if (isColliding) {
                    _horde.x += (desiredHordeRight - hordeBounds.right);
                }
            }
            
            if (DEBUG && !isColliding) {
                var gap:Number = fromRight
                    ? (hordeBounds.left - (targetBounds.right - _hordeCastleOverlapPx))
                    : ((targetBounds.left + _hordeCastleOverlapPx) - hordeBounds.right);
                trace("[Collision Debug] gap: " + Math.round(gap) + "px, target: " + (_hordeTargetTower ? "tower" : "castle"));
            }
            
            return isColliding;
        }
        
        private function createShadowLayer():void {
            if (_shadowLayer) return;
            
            _shadowLayer = new Sprite();
            _shadowLayer.mouseEnabled = false;
            _shadowLayer.mouseChildren = false;
            addChild(_shadowLayer);
        }
        
        private function createUpgradeFxLayer():void {
            if (_upgradeFxLayer) return;
            
            _upgradeFxLayer = new Sprite();
            _upgradeFxLayer.mouseEnabled = false;
            _upgradeFxLayer.mouseChildren = false;
            addChild(_upgradeFxLayer);
            
            syncUpgradeFxLayerIndex();
        }
        
        private function syncUpgradeFxLayerIndex():void {
            if (!_upgradeFxLayer || !contains(_upgradeFxLayer)) return;
            
            // Keep it behind the castle (but above shadows) so FX appears "from behind"
            if (_mainCastle && contains(_mainCastle)) {
                setChildIndex(_upgradeFxLayer, getChildIndex(_mainCastle));
                return;
            }
            
            if (_shadowLayer && contains(_shadowLayer)) {
                var idx:int = Math.min(numChildren - 1, getChildIndex(_shadowLayer) + 1);
                setChildIndex(_upgradeFxLayer, idx);
            }
        }
        
        private function preloadUpgradeFxAssets():void {
            if (_upgradeLampBitmapData && _upgradeGearBitmapData) return;
            
            loadUpgradeFxBitmapData("assets/Gambar/Lampu1.png", function(bmd:BitmapData):void {
                _upgradeLampBitmapData = bmd;
            });
            
            loadUpgradeFxBitmapData("assets/Gambar/Gear1.png", function(bmd:BitmapData):void {
                _upgradeGearBitmapData = bmd;
            });
        }
        
        private function loadUpgradeFxBitmapData(path:String, callback:Function):void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = Bitmap(e.target.content);
                if (bmp && bmp.bitmapData != null) {
                    callback(bmp.bitmapData);
                }
            });
            loader.load(new URLRequest(path));
        }
        
        private function tintToSingleColor(target:DisplayObject, color:uint):void {
            var r:int = (color >> 16) & 0xFF;
            var g:int = (color >> 8) & 0xFF;
            var b:int = color & 0xFF;
            target.transform.colorTransform = new ColorTransform(0, 0, 0, 1, r, g, b, 0);
        }
        
        private function createCastleShadow():void {
            if (!_mainCastle || !_mainCastleBitmap) return;
            createShadowLayer();
            ensureCastleContactShadow();
            
            if (_castleShadow && _castleShadow.parent) {
                _castleShadow.parent.removeChild(_castleShadow);
            }
            
            _castleShadow = new Sprite();
            _castleShadow.mouseEnabled = false;
            _castleShadow.mouseChildren = false;
            _castleShadow.cacheAsBitmap = true;
            _castleShadow.blendMode = BlendMode.MULTIPLY;
            
            // Duplicate bitmap, tint to single color, then project it onto the ground using a skewed matrix
            _castleShadowBitmap = new Bitmap(_mainCastleBitmap.bitmapData);
            _castleShadowBitmap.smoothing = true;
            _castleShadowBitmap.x = -_mainCastleBitmap.width / 2;
            _castleShadowBitmap.y = -_mainCastleBitmap.height;
            tintToSingleColor(_castleShadowBitmap, SHADOW_COLOR);
            _castleShadow.addChild(_castleShadowBitmap);
            _castleShadow.alpha = CASTLE_SHADOW_ALPHA;
            
            _shadowLayer.addChild(_castleShadow);
            if (_castleContactShadow) {
                _shadowLayer.setChildIndex(_castleContactShadow, _shadowLayer.numChildren - 1);
            }
            updateCastleShadow(_mainCastle.scaleX);
        }
        
        private function updateCastleShadow(currentScale:Number):void {
            if (!_castleShadow || !_mainCastle) return;
            updateCastleContactShadow(currentScale);
            _castleShadow.visible = currentScale > 0.001;
            if (!_castleShadow.visible) return;
            
            var sx:Number = currentScale * CASTLE_SHADOW_STRETCH;
            var sy:Number = currentScale * CASTLE_SHADOW_FLATTEN;
            var skewRad:Number = CASTLE_SHADOW_SKEW_DEG * (Math.PI / 180);
            
            var m:Matrix = new Matrix();
            m.a = sx;
            m.b = 0;
            m.c = -sy * Math.tan(skewRad);
            m.d = -sy;
            m.tx = _mainCastle.x + CASTLE_SHADOW_OFFSET_X;
            m.ty = _mainCastle.y + CASTLE_SHADOW_OFFSET_Y;
            
            _castleShadow.transform.matrix = m;
        }
        
        private function createHordeShadow():void {
            if (!_hordeBitmap) return;
            createShadowLayer();
            clearHordeShadow();
            ensureHordeContactShadow();
            
            _hordeShadow = new Sprite();
            _hordeShadow.mouseEnabled = false;
            _hordeShadow.mouseChildren = false;
            _hordeShadow.cacheAsBitmap = true;
            _hordeShadow.blendMode = BlendMode.MULTIPLY;
            
            _hordeShadowBitmap = new Bitmap(_hordeBitmap.bitmapData);
            _hordeShadowBitmap.smoothing = true;
            _hordeShadowBitmap.x = -_hordeShadowBitmap.width / 2;
            _hordeShadowBitmap.y = -_hordeShadowBitmap.height;
            
            tintToSingleColor(_hordeShadowBitmap, SHADOW_COLOR);
            _hordeShadow.addChild(_hordeShadowBitmap);
            _hordeShadow.alpha = HORDE_SHADOW_ALPHA;
            
            _shadowLayer.addChild(_hordeShadow);
            if (_hordeContactShadow) {
                _shadowLayer.setChildIndex(_hordeContactShadow, _shadowLayer.numChildren - 1);
            }
            updateHordeShadow();
        }
        
        private function updateHordeShadow():void {
            if (!_hordeShadow || !_hordeBitmap) return;
            if (!_horde || !_hordeAttackActive) return;
            
            // Base is the horde's "feet" on the ground
            var bounds:Rectangle = _hordeBitmap.getBounds(this);
            var baseX:Number = bounds.x + (bounds.width / 2);
            var baseY:Number = bounds.bottom;
            
            var hordeScaleX:Number = _hordeBitmap.scaleX * (_horde ? _horde.scaleX : 1);
            var hordeScaleY:Number = _hordeBitmap.scaleY * (_horde ? _horde.scaleY : 1);
            
            var sx:Number = hordeScaleX * HORDE_SHADOW_STRETCH;
            var sy:Number = hordeScaleY * HORDE_SHADOW_FLATTEN;
            var skewRad:Number = HORDE_SHADOW_SKEW_DEG * (Math.PI / 180);
            
            var m:Matrix = new Matrix();
            m.a = sx;
            m.b = 0;
            m.c = -sy * Math.tan(skewRad);
            m.d = -sy;
            m.tx = baseX + HORDE_SHADOW_OFFSET_X;
            m.ty = baseY + HORDE_SHADOW_OFFSET_Y;
            
            _hordeShadow.transform.matrix = m;
            updateHordeContactShadow(bounds);
        }
        
        private function clearHordeShadow():void {
            if (_hordeShadow && _hordeShadow.parent) {
                _hordeShadow.parent.removeChild(_hordeShadow);
            }
            _hordeShadow = null;
            _hordeShadowBitmap = null;
            
            if (_hordeContactShadow) {
                _hordeContactShadow.visible = false;
                _hordeContactShadow.graphics.clear();
            }
        }
        
        private function ensureCastleContactShadow():void {
            if (_castleContactShadow) return;
            
            _castleContactShadow = new Shape();
            _castleContactShadow.blendMode = BlendMode.MULTIPLY;
            _castleContactShadow.alpha = CASTLE_CONTACT_ALPHA;
            _shadowLayer.addChild(_castleContactShadow);
        }
        
        private function updateCastleContactShadow(currentScale:Number):void {
            if (!_castleContactShadow || !_mainCastleBitmap || !_mainCastle) return;
            
            _castleContactShadow.visible = currentScale > 0.001;
            if (!_castleContactShadow.visible) return;
            
            var w:Number = _mainCastleBitmap.width * currentScale * CASTLE_CONTACT_WIDTH_RATIO;
            var h:Number = Math.max(8, w * 0.10);
            
            var g:* = _castleContactShadow.graphics;
            g.clear();
            g.beginFill(SHADOW_COLOR, 1);
            g.drawEllipse(-w / 2, -h / 2, w, h);
            g.endFill();
            
            _castleContactShadow.x = _mainCastle.x;
            _castleContactShadow.y = _mainCastle.y + CONTACT_OFFSET_Y;
        }
        
        private function ensureHordeContactShadow():void {
            if (_hordeContactShadow) return;
            
            _hordeContactShadow = new Shape();
            _hordeContactShadow.blendMode = BlendMode.MULTIPLY;
            _hordeContactShadow.alpha = HORDE_CONTACT_ALPHA;
            _hordeContactShadow.visible = false;
            _shadowLayer.addChild(_hordeContactShadow);
        }
        
        private function updateHordeContactShadow(bounds:Rectangle):void {
            if (!_hordeContactShadow) return;
            
            _hordeContactShadow.visible = true;
            
            var w:Number = bounds.width * HORDE_CONTACT_WIDTH_RATIO;
            var h:Number = Math.max(6, bounds.height * 0.10);
            var x:Number = bounds.x + (bounds.width / 2);
            var y:Number = bounds.bottom + CONTACT_OFFSET_Y;
            
            var g:* = _hordeContactShadow.graphics;
            g.clear();
            g.beginFill(SHADOW_COLOR, 1);
            g.drawEllipse(-w / 2, -h / 2, w, h);
            g.endFill();
            
            _hordeContactShadow.x = x;
            _hordeContactShadow.y = y;
        }
        
        private function ensureHordeDustLayer():void {
            if (!_hordeDustLayer) {
                _hordeDustLayer = new Sprite();
                _hordeDustLayer.mouseEnabled = false;
                _hordeDustLayer.mouseChildren = false;
            }
            if (!_hordeDustParticles) {
                _hordeDustParticles = new Vector.<Object>();
            }
            if (!contains(_hordeDustLayer)) {
                addChild(_hordeDustLayer);
            }
            
            // Keep dust under the horde visually
            if (_horde && contains(_horde)) {
                var hordeIndex:int = getChildIndex(_horde);
                var desiredIndex:int = Math.max(0, hordeIndex - 1);
                setChildIndex(_hordeDustLayer, desiredIndex);
            }
        }
        
        private function clearHordeDust():void {
            _hordeDustSpawnRemainder = 0;
            if (_hordeDustParticles) {
                _hordeDustParticles.length = 0;
            }
            if (_hordeDustLayer) {
                while (_hordeDustLayer.numChildren > 0) {
                    _hordeDustLayer.removeChildAt(0);
                }
            }
        }
        
        private function tickHordeDust(frameMs:Number, fromRight:Boolean, shouldSpawn:Boolean):void {
            if (!_hordeDustLayer || !_hordeDustParticles) return;
            
            // Emit small "walking cloud" puffs under the horde while approaching
            if (shouldSpawn && _horde) {
                var puffsPerSecond:Number = 18;
                _hordeDustSpawnRemainder += (puffsPerSecond * frameMs) / 1000;
                
                var spawnCount:int = int(_hordeDustSpawnRemainder);
                _hordeDustSpawnRemainder -= spawnCount;
                
                for (var s:int = 0; s < spawnCount; s++) {
                    spawnHordeDust(fromRight);
                }
            }
            
            // Update + fade out existing puffs
            for (var i:int = _hordeDustParticles.length - 1; i >= 0; i--) {
                var dust:Object = _hordeDustParticles[i];
                dust.age += frameMs;
                
                var t:Number = dust.age / dust.life;
                if (t >= 1) {
                    if (dust.sprite && dust.sprite.parent) {
                        dust.sprite.parent.removeChild(dust.sprite);
                    }
                    _hordeDustParticles.splice(i, 1);
                    continue;
                }
                
                var sprite:Sprite = dust.sprite as Sprite;
                if (!sprite) {
                    _hordeDustParticles.splice(i, 1);
                    continue;
                }
                
                sprite.x += dust.vx * frameMs;
                sprite.y += dust.vy * frameMs;
                
                var fade:Number = 1 - t;
                sprite.alpha = dust.baseAlpha * fade;
                
                var scale:Number = dust.startScale + (dust.endScale - dust.startScale) * t;
                sprite.scaleX = scale;
                sprite.scaleY = scale;
            }
        }
        
        private function spawnHordeDust(fromRight:Boolean):void {
            if (!_hordeDustLayer || !_horde) return;
            
            var hordeBounds:Rectangle = _horde.getBounds(this);
            if (hordeBounds.width <= 0 || hordeBounds.height <= 0) return;
            
            // Spawn point under the horde, slightly biased to the "back" side
            var bias:Number = fromRight ? 0.78 : 0.22;
            var xJitter:Number = (Math.random() - 0.5) * hordeBounds.width * 0.25;
            var yJitter:Number = (Math.random() - 0.5) * 6;
            var spawnX:Number = hordeBounds.left + (hordeBounds.width * bias) + xJitter;
            var spawnY:Number = hordeBounds.bottom - 6 + yJitter;
            
            var puff:Shape = new Shape();
            var g:* = puff.graphics;
            g.beginFill(0xFFFFFF, 1);
            var r:Number = 6 + Math.random() * 6;
            g.drawCircle(0, 0, r);
            g.drawCircle(r * 0.6, -r * 0.25, r * 0.7);
            g.drawCircle(-r * 0.65, -r * 0.15, r * 0.6);
            g.endFill();
            
            var sprite:Sprite = new Sprite();
            sprite.mouseEnabled = false;
            sprite.mouseChildren = false;
            sprite.addChild(puff);
            sprite.x = spawnX;
            sprite.y = spawnY;
            
            var startScale:Number = 0.16 + Math.random() * 0.18;
            var endScale:Number = startScale * (1.7 + Math.random() * 0.5);
            sprite.scaleX = startScale;
            sprite.scaleY = startScale;
            
            sprite.alpha = 0.25 + Math.random() * 0.25;
            _hordeDustLayer.addChild(sprite);
            
            var life:Number = 420 + Math.random() * 320;
            var drift:Number = fromRight ? 1 : -1; // drift "behind" the movement
            var vx:Number = (((12 + Math.random() * 28) / 1000) * drift) + (((Math.random() - 0.5) * 12) / 1000);
            var vy:Number = -((10 + Math.random() * 25) / 1000);
            
            _hordeDustParticles.push({
                sprite: sprite,
                vx: vx,
                vy: vy,
                age: 0,
                life: life,
                startScale: startScale,
                endScale: endScale,
                baseAlpha: sprite.alpha
            });
        }
        
        private function applyCastleScale(scale:Number):void {
            if (_mainCastle) {
                _mainCastle.scaleX = scale;
                _mainCastle.scaleY = scale;
            }
            
            updateCastleShadow(scale);
        }
        
        private function stopCastlePopAnimation():void {
            if (_castlePopTimer) {
                _castlePopTimer.stop();
                _castlePopTimer.removeEventListener(TimerEvent.TIMER, onCastlePopTick);
                _castlePopTimer = null;
            }
        }
        
        private function startCastlePopAnimation(fromScale:Number, toScale:Number):void {
            if (!_mainCastle) return;
            
            stopCastlePopAnimation();
            _castlePopFromScale = fromScale;
            _castlePopToScale = toScale;
            _castlePopStartMs = new Date().time;
            
            _castlePopTimer = new Timer(33);
            _castlePopTimer.addEventListener(TimerEvent.TIMER, onCastlePopTick);
            _castlePopTimer.start();
        }
        
        private function onCastlePopTick(e:TimerEvent):void {
            if (!_mainCastle) {
                stopCastlePopAnimation();
                return;
            }
            
            var elapsed:Number = new Date().time - _castlePopStartMs;
            var t:Number = elapsed / CASTLE_POP_DURATION_MS;
            
            if (t >= 1) {
                applyCastleScale(_castlePopToScale);
                stopCastlePopAnimation();
                return;
            }
            
            var eased:Number = easeOutBack(Math.max(0, Math.min(1, t)));
            var visualScale:Number = _castlePopFromScale + (_castlePopToScale - _castlePopFromScale) * eased;
            applyCastleScale(Math.max(0, visualScale));
        }
        
        private function easeOutBack(t:Number, s:Number = 1.70158):Number {
            t -= 1;
            return (t * t * ((s + 1) * t + s) + 1);
        }
        
        private function playUpgradeRiseFx():void {
            if (!_mainCastle) return;
            if (!_upgradeFxLayer) createUpgradeFxLayer();
            syncUpgradeFxLayerIndex();
            
            if (!_upgradeLampBitmapData || !_upgradeGearBitmapData) return;
            
            var castleHeight:Number = _mainCastleBitmap ? (_mainCastleBitmap.height * _mainCastle.scaleY) : 300;
            var baseX:Number = _mainCastle.x;
            var baseY:Number = _mainCastle.y - (castleHeight * 0.55);
            
            // Spawn a few tiny icons (lamp + gear) rising upward behind the castle
            spawnUpgradeFxItem(true, baseX, baseY);
            spawnUpgradeFxItem(false, baseX, baseY);
            spawnUpgradeFxItem(true, baseX, baseY);
            spawnUpgradeFxItem(false, baseX, baseY);
        }
        
        private function spawnUpgradeFxItem(isLamp:Boolean, baseX:Number, baseY:Number):void {
            if (!_upgradeFxLayer) return;
            
            var bmd:BitmapData = isLamp ? _upgradeLampBitmapData : _upgradeGearBitmapData;
            if (!bmd) return;
            
            var bmp:Bitmap = new Bitmap(bmd);
            bmp.smoothing = true;
            
            var scale:Number = UPGRADE_FX_ICON_HEIGHT / bmp.height;
            bmp.scaleX = scale;
            bmp.scaleY = scale;
            bmp.x = -bmp.width / 2;
            bmp.y = -bmp.height / 2;
            
            var sprite:Sprite = new Sprite();
            sprite.mouseEnabled = false;
            sprite.mouseChildren = false;
            if (isLamp) {
                sprite.blendMode = BlendMode.ADD;
            }
            sprite.addChild(bmp);
            
            sprite.x = baseX + (Math.random() - 0.5) * 90;
            sprite.y = baseY + (Math.random() - 0.5) * 40;
            sprite.alpha = 0;
            
            _upgradeFxLayer.addChild(sprite);
            
            var item:Object = {
                sprite: sprite,
                vx: (Math.random() - 0.5) * 0.6,
                vy: -(1.8 + Math.random() * 1.2),
                rot: isLamp ? ((Math.random() - 0.5) * 0.6) : ((Math.random() > 0.5 ? 1 : -1) * (2.5 + Math.random() * 3.0)),
                age: 0,
                life: 900 + Math.random() * 400,
                baseAlpha: isLamp ? 0.55 : 0.45
            };
            
            _upgradeFxItems.push(item);
            ensureUpgradeFxTimer();
        }
        
        private function ensureUpgradeFxTimer():void {
            if (_upgradeFxTimer) return;
            
            _upgradeFxTimer = new Timer(33);
            _upgradeFxTimer.addEventListener(TimerEvent.TIMER, onUpgradeFxTick);
            _upgradeFxTimer.start();
        }
        
        private function onUpgradeFxTick(e:TimerEvent):void {
            if (_isPaused) return;
            if (!_upgradeFxItems || _upgradeFxItems.length == 0) {
                stopUpgradeFxTimer();
                return;
            }
            
            var frameMs:Number = 33;
            
            for (var i:int = _upgradeFxItems.length - 1; i >= 0; i--) {
                var item:Object = _upgradeFxItems[i];
                item.age += frameMs;
                
                var sprite:Sprite = item.sprite as Sprite;
                if (!sprite) {
                    _upgradeFxItems.splice(i, 1);
                    continue;
                }
                
                sprite.x += item.vx;
                sprite.y += item.vy;
                sprite.rotation += item.rot;
                
                // Fade in/out
                var alpha:Number = item.baseAlpha;
                alpha *= Math.min(1, item.age / 120);
                
                var fadeOutStart:Number = item.life - 250;
                if (item.age >= fadeOutStart) {
                    alpha *= (1 - Math.min(1, (item.age - fadeOutStart) / 250));
                }
                
                sprite.alpha = alpha;
                
                if (item.age >= item.life) {
                    if (sprite.parent) sprite.parent.removeChild(sprite);
                    _upgradeFxItems.splice(i, 1);
                }
            }
            
            if (_upgradeFxItems.length == 0) {
                stopUpgradeFxTimer();
            }
        }
        
        private function stopUpgradeFxTimer():void {
            if (_upgradeFxTimer) {
                _upgradeFxTimer.stop();
                _upgradeFxTimer.removeEventListener(TimerEvent.TIMER, onUpgradeFxTick);
                _upgradeFxTimer = null;
            }
        }
        
        private function clearUpgradeFx():void {
            stopUpgradeFxTimer();
            if (_upgradeFxItems) {
                _upgradeFxItems.length = 0;
            }
            if (_upgradeFxLayer) {
                while (_upgradeFxLayer.numChildren > 0) {
                    _upgradeFxLayer.removeChildAt(0);
                }
            }
        }
        
        private function applyHordeDamageStep():void {
            // Damage amount per step to preserve the original "per second" behavior
            var stepDamage:Number = _hordeDamagePerSecond * (_hordeDamageStepIntervalMs / 1000);
            
            // If attacking a tower, damage that tower first
            if (_hordeTargetTower && _hordeTargetTower.isLoaded) {
                applyTowerDamageStep(_hordeTargetTower, stepDamage);
            } else {
                // No tower target - damage main castle
                _castleScale -= stepDamage;
                _castleScale = Math.max(0, _castleScale);
                
                // Restart pop animation on each step
                _hordeDamagePulseMs = 0;
                
                // Handle destruction threshold immediately (no extra frame delay)
                if (_castleScale <= _castleDestructionThreshold) {
                    _castleScale = 0;
                    applyCastleScale(0);
                    
                    if (_hordeShrinkTimer) {
                        _hordeShrinkTimer.stop();
                    }
                    
                    // Play castle destroyed sound
                    var audioManager:AudioManager = getAudioManager();
                    if (audioManager) {
                        audioManager.playSfx("castleDestroyed");
                        audioManager.stopRepeatingSfx(); // Stop attack sound
                    }
                    
                    if (DEBUG) {
                        trace("[GameScreen] Castle destroyed by horde!");
                    }
                    
                    // Keep the horde visible and make it retreat immediately
                    _hordeForceRetreat = true;
                }
            }
        }
        
        /**
         * Apply damage to a tower with animation (same as main castle damage)
         */
        private function applyTowerDamageStep(tower:TowerAddition, damage:Number):void {
            var currentScale:Number = tower.currentScale;
            var newScale:Number = currentScale - damage;
            
            // Restart pop animation on each step
            _hordeDamagePulseMs = 0;
            
            // Check if tower should be destroyed (scale below 30% of initial 0.5 = 0.15)
            var towerDestructionThreshold:Number = 0.15;
            if (newScale <= towerDestructionThreshold) {
                // Tower destroyed - remove it with animation
                if (DEBUG) {
                    trace("[GameScreen] Tower " + tower.towerId + " destroyed by horde!");
                }
                
                // Remove tower visually
                tower.playRemovalAnimation(function():void {
                    // Remove from display and array
                    if (_towerContainer && _towerContainer.contains(tower)) {
                        _towerContainer.removeChild(tower);
                    }
                    
                    var index:int = _towerAdditions.indexOf(tower);
                    if (index >= 0) {
                        _towerAdditions.splice(index, 1);
                    }
                    
                    tower.dispose();
                    repositionAllTowers();
                });
                
                // Play castle destroyed sound for tower
                var audioManager:AudioManager = getAudioManager();
                if (audioManager) {
                    audioManager.playSfx("castleDestroyed");
                }
                
                // Clear target so next damage goes to castle or next tower
                _hordeTargetTower = null;
                
                // If horde is still attacking, find new target
                if (_hordeAttackActive && _hordeShrinkTimer && _hordeShrinkTimer.running) {
                    // Find new target: next NEWEST tower, or main castle
                    _hordeTargetTower = findNewestTower();
                    
                    if (DEBUG) {
                        trace("[GameScreen] New horde target: " + (_hordeTargetTower ? "tower " + _hordeTargetTower.towerId : "main castle"));
                    }
                }
            } else {
                // Tower survives - apply damage with pop animation
                tower.applyScale(newScale);
                applyTowerDamageVisual(tower);
            }
        }
        
        /**
         * Apply pop visual effect to tower during damage
         */
        private function applyTowerDamageVisual(tower:TowerAddition):void {
            if (!tower) return;
            
            var t:Number = Math.min(_hordeDamagePulseMs / _hordeDamageStepIntervalMs, 1.0);
            var pop:Number = 1 - t;
            pop = pop * pop; // ease-out
            
            var visualScale:Number = tower.currentScale * (1 + (_hordeDamagePopAmount * pop));
            tower.scaleX = visualScale;
            tower.scaleY = visualScale;
        }
        
        private function applyCastleDamageVisual():void {
            // Apply visual to current target (tower or castle)
            if (_hordeTargetTower && _hordeTargetTower.isLoaded) {
                applyTowerDamageVisual(_hordeTargetTower);
            } else if (_mainCastle) {
                var t:Number = Math.min(_hordeDamagePulseMs / _hordeDamageStepIntervalMs, 1.0);
                var pop:Number = 1 - t;
                pop = pop * pop; // ease-out
                
                var visualScale:Number = _castleScale * (1 + (_hordeDamagePopAmount * pop));
                applyCastleScale(visualScale);
            }
        }
        
        /**
         * Start horde damage - castle shrinks in steps with a popping effect
         */
        private function startHordeDamage():void {
            if (_hordeShrinkTimer) {
                _hordeShrinkTimer.stop();
                _hordeShrinkTimer.removeEventListener(TimerEvent.TIMER, onHordeShrinkTick);
            }
            
            // Reset step + pop animation
            _hordeDamageStepAccumMs = 0;
            _hordeDamagePulseMs = 0;
            
            // Apply an immediate "hit" so the popping effect starts right away
            applyHordeDamageStep();
            applyCastleDamageVisual();
            
            // If the castle was destroyed instantly, don't keep ticking damage
            if (_castleScale <= 0) {
                return;
            }
            
            _hordeShrinkTimer = new Timer(33); // ~30fps for smooth shrinking
            _hordeShrinkTimer.addEventListener(TimerEvent.TIMER, onHordeShrinkTick);
            _hordeShrinkTimer.start();
            
            // Start repeating attack sound
            var audioManager:AudioManager = getAudioManager();
            if (audioManager) {
                audioManager.startRepeatingSfx("enemyAttacking");
            }
            
            if (DEBUG) {
                trace("[GameScreen] Horde damage timer started - castle will shrink for " + _hordeAttackDuration + "ms");
            }
        }
        
        /**
         * Called each frame while horde is damaging castle
         */
        private function onHordeShrinkTick(e:TimerEvent):void {
            if (!_hordeAttackActive || !_mainCastle) {
                if (_hordeShrinkTimer) {
                    _hordeShrinkTimer.stop();
                }
                return;
            }
            
            var frameMs:Number = 33;
            _hordeDamageStepAccumMs += frameMs;
            _hordeDamagePulseMs += frameMs;
            
            // Apply damage in steps
            while (_hordeDamageStepAccumMs >= _hordeDamageStepIntervalMs) {
                _hordeDamageStepAccumMs -= _hordeDamageStepIntervalMs;
                applyHordeDamageStep();
                
                // Castle destroyed
                if (_castleScale <= 0) {
                    return;
                }
            }
            
            // Apply popping visual scale on top of the stepped scale
            applyCastleDamageVisual();
        }
        
        /**
         * End horde attack
         */
        private function endHordeAttack():void {
            if (_hordeDamageTimer) {
                _hordeDamageTimer.stop();
                _hordeDamageTimer = null;
            }
            
            _hordeForceRetreat = false;
            clearHordeDust();
            clearHordeShadow();
            
            if (_horde && parent && contains(_horde)) {
                removeChild(_horde);
            }
            
            _hordeAttackActive = false;
            
            // Stop repeating attack sound
            var audioManager:AudioManager = getAudioManager();
            if (audioManager) {
                audioManager.stopRepeatingSfx();
            }
            
            if (DEBUG) {
                trace("[GameScreen] Horde attack ended. Castle scale: " + _castleScale);
            }
        }
        

        
        /**
         * Update responsive layout values based on screen size
         */
        private function updateResponsiveValues():void {
            var minDim:Number = Math.min(_stageWidth, _stageHeight);
            var scale:Number = minDim / 600; // Base on 600px reference
            
            // Clamp scale between reasonable bounds
            scale = Math.max(0.5, Math.min(2.0, scale));
            
            _margin = Math.max(10, 20 * scale);
            _frameMargin = Math.max(20, 40 * scale);
            _buttonSize = Math.max(40, 50 * scale);
            _cornerRadius = Math.max(15, 30 * scale);
            
            // Orb HUD sizing
            _orbDesiredHeight = Math.max(18, Math.min(34, 26 * scale));
            _orbGap = Math.max(8, 12 * scale);
            _orbTopPadding = Math.max(10, 18 * scale);
        }
        
        /**
         * Create blue to purple gradient background
         */
        private function createGradientBackground():void {
            _gradientBackground = new Shape();
            drawGradientBackground();
            addChild(_gradientBackground);
        }
        
        private function drawGradientBackground():void {
            var g:* = _gradientBackground.graphics;
            g.clear();
            
            var matrix:* = new flash.geom.Matrix();
            matrix.createGradientBox(_stageWidth, _stageHeight, Math.PI / 2, 0, 0);
            
            g.beginGradientFill(
                "linear",
                [0x9B59B6, 0x4A90E2], // Purple on top, blue at bottom
                [1, 1],
                [0, 255],
                matrix
            );
            g.drawRect(0, 0, _stageWidth, _stageHeight);
            g.endFill();
        }
        
        /**
         * Create multi-layer clouds with parallax effect
         */
        private function createClouds():void {
            _cloudsContainer = new Sprite();
            _clouds = new Vector.<Object>();
            addChild(_cloudsContainer);
            
            // Load 4 types of clouds with different speeds for parallax effect
            var cloudConfigs:Array = [
                { file: "cloud1.png", count: 2, speed: 0.2, yRange: [80, 150], scale: 0.6 },   // Back layer - slowest, smallest
                { file: "cloud2.png", count: 2, speed: 0.4, yRange: [120, 180], scale: 0.8 },  // Mid-back layer
                { file: "cloud3.png", count: 2, speed: 0.7, yRange: [100, 160], scale: 1.0 },  // Mid-front layer
                { file: "cloud4.png", count: 2, speed: 1.0, yRange: [50, 120], scale: 0.7 }    // Front layer - fastest
            ];
            
            for (var i:int = 0; i < cloudConfigs.length; i++) {
                var config:Object = cloudConfigs[i];
                for (var j:int = 0; j < config.count; j++) {
                    loadCloud(config, j);
                }
            }
            
            // Start animation timer
            _cloudTimer = new Timer(33); // ~30fps
            _cloudTimer.addEventListener(TimerEvent.TIMER, onCloudTick);
            _cloudTimer.start();
        }
        
        private function loadCloud(config:Object, index:int):void {
            var loader:Loader = new Loader();
            var cloudData:Object = {
                loader: loader,
                speed: config.speed,
                yRange: config.yRange,
                scale: config.scale,
                index: index,
                loaded: false
            };
            
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bitmap:Bitmap = Bitmap(e.target.content);
                bitmap.smoothing = true;
                bitmap.scaleX = cloudData.scale;
                bitmap.scaleY = cloudData.scale;
                
                // Random starting position
                bitmap.x = Math.random() * (_stageWidth + 200) - 100;
                bitmap.y = cloudData.yRange[0] + Math.random() * (cloudData.yRange[1] - cloudData.yRange[0]);
                bitmap.alpha = 0.7 + Math.random() * 0.3;
                
                cloudData.bitmap = bitmap;
                cloudData.loaded = true;
                _clouds.push(cloudData);
                _cloudsContainer.addChild(bitmap);
            });
            
            loader.load(new URLRequest("assets/images/Game/" + config.file));
        }
        
        private function onCloudTick(e:TimerEvent):void {
            if (_isPaused) return;
            
            for (var i:int = 0; i < _clouds.length; i++) {
                var cloud:Object = _clouds[i];
                if (!cloud.loaded || !cloud.bitmap) continue;
                
                cloud.bitmap.x += cloud.speed;
                
                // Wrap around when off screen
                if (cloud.bitmap.x > _stageWidth + 50) {
                    cloud.bitmap.x = -cloud.bitmap.width - 50;
                    cloud.bitmap.y = cloud.yRange[0] + Math.random() * (cloud.yRange[1] - cloud.yRange[0]);
                }
            }
        }
        
        /**
         * Load background image
         */
        private function loadBackground():void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBackgroundLoaded);
            loader.load(new URLRequest("assets/images/Game/background.png"));
        }
        
        private function onBackgroundLoaded(e:Event):void {
            _backgroundBitmap = Bitmap(e.target.content);
            _backgroundBitmap.smoothing = true;
            
            // Scale to cover full screen
            _backgroundBitmap.width = _stageWidth;
            _backgroundBitmap.height = _stageHeight;
            
            // Position at (0,0)
            _backgroundBitmap.x = 0;
            _backgroundBitmap.y = 0;
            
            addChildAt(_backgroundBitmap, 0); // Add as first child (bottom layer)
            
            // Position clouds above background
            setChildIndex(_cloudsContainer, getChildIndex(_backgroundBitmap) + 1);
            
            // Shadows above background/clouds, below gameplay objects
            if (_shadowLayer) {
                setChildIndex(_shadowLayer, getChildIndex(_cloudsContainer) + 1);
            }
            
            // Position castle
            updateTowerPosition();
            
            // CRITICAL: Move castle above background
            if (_mainCastle) {
                setChildIndex(_mainCastle, numChildren - 1);
                if (DEBUG) {
                    trace("[GameScreen] Castle moved above background. Castle Z-index: " + getChildIndex(_mainCastle) + " of " + numChildren);
                }
            }
            
            // CRITICAL: Move buttons to top
            if (_upgradeButton) {
                setChildIndex(_upgradeButton, numChildren - 1);
            }
            if (_pauseButton) {
                setChildIndex(_pauseButton, numChildren - 1);
            }
            
            // Ensure upgrade FX renders behind the castle
            syncUpgradeFxLayerIndex();
            
            if (DEBUG) {
                trace("[GameScreen] Background loaded: " + _stageWidth + "x" + _stageHeight);
            }
        }
        

        
        /**
         * Create main castle using mainCastle.png
         */
        private function createTower():void {
            _mainCastle = new Sprite();
            addChild(_mainCastle);
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onMainCastleLoaded);
            loader.load(new URLRequest("assets/images/Game/mainCastle.png"));
        }
        
        private function onMainCastleLoaded(e:Event):void {
            _mainCastleBitmap = Bitmap(e.target.content);
            _mainCastleBitmap.smoothing = true;
            
            // Center the bitmap in sprite for scaling
            _mainCastleBitmap.x = -_mainCastleBitmap.width / 2;
            _mainCastleBitmap.y = -_mainCastleBitmap.height;
            
            _mainCastle.addChild(_mainCastleBitmap);
            _mainCastle.scaleX = _castleScale;
            _mainCastle.scaleY = _castleScale;
            
            // Play castle spawn audio
            var audioManager:AudioManager = getAudioManager();
            if (audioManager) {
                audioManager.playSfx("castleSpawn");
            }
            
            // Position will be updated when terrain loads
            updateTowerPosition();
            createCastleShadow();
            syncUpgradeFxLayerIndex();
            
            if (DEBUG) {
                trace("[GameScreen] Main castle loaded: " + _mainCastleBitmap.width + "x" + _mainCastleBitmap.height);
            }
            
            applySavedStateIfReady();
        }
        
        /**
         * Position castle in center of screen
         */
        private function updateTowerPosition():void {
            if (!_mainCastle || !_mainCastleBitmap) return;
            
            // Center horizontally
            _mainCastle.x = _stageWidth / 2;
            
            // Center vertically (lower position)
            var castleHeight:Number = _mainCastleBitmap.height * _castleScale;
            _mainCastle.y = (_stageHeight / 2) + 180;
            updateCastleShadow(_mainCastle.scaleX);
            
            if (DEBUG) {
                trace("[GameScreen] Castle positioned at (" + _mainCastle.x + ", " + _mainCastle.y + ")");
            }
        }
        
        private function updateTower():void {
            // No longer needed - castle is image-based now
        }
        
        /**
         * Create upgrade button (bottom left corner, using upgradeButton.png)
         */
        private function createUpgradeButton():void {
            _upgradeButton = new Sprite();
            addChild(_upgradeButton); // Add to stage immediately to ensure proper layering
            
            // Load image
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onUpgradeButtonLoaded);
            loader.load(new URLRequest("assets/images/Game/upgradeButton.png"));
        }
        
        private function onUpgradeButtonLoaded(e:Event):void {
            _upgradeButtonBitmap = Bitmap(e.target.content);
            _upgradeButtonBitmap.smoothing = true;
            
            // Scale to reasonable size (120px width for better visibility)
            var targetWidth:Number = 120;
            var scale:Number = targetWidth / _upgradeButtonBitmap.width;
            _upgradeButtonBitmap.scaleX = scale;
            _upgradeButtonBitmap.scaleY = scale;
            
            // Center bitmap for proper scaling from center
            _upgradeButtonBitmap.x = -_upgradeButtonBitmap.width / 2;
            _upgradeButtonBitmap.y = -_upgradeButtonBitmap.height / 2;
            
            _upgradeButton.addChild(_upgradeButtonBitmap);
            
            // Position button in bottom left (accounting for centered bitmap)
            _upgradeButton.x = _upgradeButtonBitmap.width / 2 + 40;
            _upgradeButton.y = _stageHeight - _upgradeButtonBitmap.height / 2 - 40;
            
            // CRITICAL: Ensure button is on the very top layer
            if (parent) {
                parent.setChildIndex(this, parent.numChildren - 1);
            }
            setChildIndex(_upgradeButton, numChildren - 1);
            
            // Make it interactive
            _upgradeButton.buttonMode = true;
            _upgradeButton.useHandCursor = true;
            _upgradeButton.mouseEnabled = true;
            _upgradeButton.addEventListener(MouseEvent.CLICK, onUpgradeClick);
            _upgradeButton.addEventListener(MouseEvent.ROLL_OVER, onUpgradeOver);
            _upgradeButton.addEventListener(MouseEvent.ROLL_OUT, onUpgradeOut);
            
            if (DEBUG) {
                trace("[GameScreen] Upgrade button loaded at (" + _upgradeButton.x + ", " + _upgradeButton.y + ")");
            }
        }
        

        
        private function positionUpgradeButton():void {
            if (!_upgradeButton || !_upgradeButtonBitmap) return;
            _upgradeButton.x = _upgradeButtonBitmap.width / 2 + 40;
            _upgradeButton.y = _stageHeight - _upgradeButtonBitmap.height / 2 - 40;
        }
        

        
        /**
         * Handle upgrade button click
         */
        private function onUpgradeClick(e:MouseEvent):void {
            if (DEBUG) {
                trace("[GameScreen] Upgrade button clicked");
            }
            
            // Player is active (upgrading) -> horde should not spawn.
            _isUpgradePopupOpen = true;
            pauseHordeCountdown();
            dispatchEvent(new Event(UPGRADE_CLICKED));
        }
        
        /**
         * Handle upgrade button hover
         */
        private function onUpgradeOver(e:MouseEvent):void {
            animateScale(_upgradeButton, HOVER_SCALE);
        }
        
        /**
         * Handle upgrade button out
         */
        private function onUpgradeOut(e:MouseEvent):void {
            animateScale(_upgradeButton, 1.0);
        }
        
        /**
         * Create pause button (top right corner)
         */
        private function createPauseButton():void {
            _pauseButton = new Sprite();
            addChild(_pauseButton);
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPauseButtonLoaded);
            loader.load(new URLRequest("assets/images/Game/pauseButton.png"));
        }
        
        private function onPauseButtonLoaded(e:Event):void {
            _pauseButtonBitmap = Bitmap(e.target.content);
            _pauseButtonBitmap.smoothing = true;
            
            // Scale to same size as upgrade button (120px)
            var targetWidth:Number = 120;
            var scale:Number = targetWidth / _pauseButtonBitmap.width;
            _pauseButtonBitmap.scaleX = scale;
            _pauseButtonBitmap.scaleY = scale;
            
            // Center the bitmap for proper scaling from center
            _pauseButtonBitmap.x = -_pauseButtonBitmap.width / 2;
            _pauseButtonBitmap.y = -_pauseButtonBitmap.height / 2;
            
            _pauseButton.addChild(_pauseButtonBitmap);
            
            // Position in top right (accounting for centered bitmap)
            _pauseButton.x = _stageWidth - _pauseButtonBitmap.width / 2 - 30;
            _pauseButton.y = _pauseButtonBitmap.height / 2 + 30;
            
            _pauseButton.buttonMode = true;
            _pauseButton.useHandCursor = true;
            _pauseButton.addEventListener(MouseEvent.CLICK, onPauseClick);
            _pauseButton.addEventListener(MouseEvent.ROLL_OVER, onPauseOver);
            _pauseButton.addEventListener(MouseEvent.ROLL_OUT, onPauseOut);
            
            // Ensure on top
            bringToFront(_pauseButton);
            
            if (DEBUG) {
                trace("[GameScreen] Pause button loaded at (" + _pauseButton.x + ", " + _pauseButton.y + ")");
            }
        }
        
        private function onPauseClick(e:MouseEvent):void {
            showPausePopup();
        }
        
        private function onPauseOver(e:MouseEvent):void {
            animateScale(_pauseButton, HOVER_SCALE);
        }
        
        private function onPauseOut(e:MouseEvent):void {
            animateScale(_pauseButton, 1.0);
        }
        
        /**
         * Smooth scale animation helper
         */
        private function animateScale(target:Sprite, targetScale:Number):void {
            // Simple immediate scale for now (could add tweening later)
            target.scaleX = targetScale;
            target.scaleY = targetScale;
        }
        
        /**
         * Create dark overlay for pause popup
         */
        private function createPauseOverlay():void {
            _pauseOverlay = new Shape();
            drawPauseOverlay();
            _pauseOverlay.visible = false;
            addChild(_pauseOverlay);
            
            // Create popup container
            _pausePopup = new Sprite();
            _pausePopup.visible = false;
            addChild(_pausePopup);
            
            // Load popup image
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPausePopupLoaded);
            loader.load(new URLRequest("assets/images/Game/pausePopup.png"));
        }
        
        private function drawPauseOverlay():void {
            var g:* = _pauseOverlay.graphics;
            g.clear();
            g.beginFill(0x000000, 0.7); // Dark overlay 70% opacity
            g.drawRect(0, 0, _stageWidth, _stageHeight);
            g.endFill();
        }
        
        private function onPausePopupLoaded(e:Event):void {
            _pausePopupBitmap = Bitmap(e.target.content);
            _pausePopupBitmap.smoothing = true;
            
            // Scale popup to fit nicely (max 60% of screen width)
            var maxWidth:Number = _stageWidth * 0.6;
            if (_pausePopupBitmap.width > maxWidth) {
                var scale:Number = maxWidth / _pausePopupBitmap.width;
                _pausePopupBitmap.scaleX = scale;
                _pausePopupBitmap.scaleY = scale;
            }
            
            _pausePopup.addChild(_pausePopupBitmap);
            
            // Center popup
            _pausePopup.x = (_stageWidth - _pausePopupBitmap.width) / 2;
            _pausePopup.y = (_stageHeight - _pausePopupBitmap.height) / 2;
            
            // Create popup buttons
            createPausePopupButtons();
            
            if (DEBUG) {
                trace("[GameScreen] Pause popup loaded - size: " + _pausePopupBitmap.width + "x" + _pausePopupBitmap.height);
            }
        }
        
        /**
         * Create buttons on pause popup: xButton, save, retry, mainMenu
         */
        private function createPausePopupButtons():void {
            // X Button (top right of popup) - 120px same as gear icon
            loadPausePopupButton("xButton.png", function(btn:Sprite, bmp:Bitmap):void {
                _pauseXButton = btn;
                btn.x = _pausePopupBitmap.width - bmp.width / 2 - 20;
                btn.y = bmp.height / 2 + 20;
                btn.addEventListener(MouseEvent.CLICK, onPauseXClick);
            }, 120);
            
            // Save Button (first - top) - 320px for better visibility
            loadPausePopupButton("saveButton.png", function(btn:Sprite, bmp:Bitmap):void {
                _saveButton = btn;
                btn.x = _pausePopupBitmap.width / 2;
                btn.y = _pausePopupBitmap.height * 0.35;
                btn.addEventListener(MouseEvent.CLICK, onSaveClick);
            }, 320);
            
            // Retry Button (second - middle) - 320px for better visibility
            loadPausePopupButton("retryButton.png", function(btn:Sprite, bmp:Bitmap):void {
                _retryButton = btn;
                btn.x = _pausePopupBitmap.width / 2;
                btn.y = _pausePopupBitmap.height * 0.52;
                btn.addEventListener(MouseEvent.CLICK, onRetryClick);
            }, 320);
            
            // Main Menu Button (third - bottom) - 320px for better visibility
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
                
                // Center bitmap for proper hover scaling
                bmp.x = -bmp.width / 2;
                bmp.y = -bmp.height / 2;
                
                btn.addChild(bmp);
                btn.buttonMode = true;
                btn.useHandCursor = true;
                
                // Add hover effect
                btn.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
                    animateScale(btn, HOVER_SCALE);
                });
                btn.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
                    animateScale(btn, 1.0);
                });
                
                setupCallback(btn, bmp);
                _pausePopup.addChild(btn);
            });
            
            loader.load(new URLRequest("assets/images/Game/" + filename));
        }
        
        private function onPauseXClick(e:MouseEvent):void {
            hidePausePopup();
        }
        
        private function onMainMenuClick(e:MouseEvent):void {
            hidePausePopup();
            dispatchEvent(new Event("goToMainMenu"));
            if (DEBUG) trace("[GameScreen] Main Menu clicked");
        }
        
        private function onRetryClick(e:MouseEvent):void {
            hidePausePopup();
            dispatchEvent(new Event("retryGame"));
            if (DEBUG) trace("[GameScreen] Retry clicked");
        }
        
        private function onSaveClick(e:MouseEvent):void {
            // Save game state
            saveGameState();
            if (DEBUG) trace("[GameScreen] Save clicked");
        }
        
        /**
         * Create save notification (hidden by default)
         */
        private function createSaveNotification():void {
            // Create sprite for notification image
            _saveNotificationBg = new Sprite();
            _saveNotificationBg.visible = false;
            addChild(_saveNotificationBg);
            
            // Create placeholder TextField (for compatibility)
            _saveNotification = new TextField();
            _saveNotification.visible = false;
            _saveNotification.mouseEnabled = false;
            addChild(_saveNotification);
            
            // Load notification image
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var notifBitmap:Bitmap = Bitmap(e.target.content);
                notifBitmap.smoothing = true;
                
                // Add bitmap to sprite
                _saveNotificationBg.addChild(notifBitmap);
                
                if (DEBUG) trace("[GameScreen] Save notification loaded");
            });
            loader.load(new URLRequest("assets/images/Game/savedNotif.png"));
            
            // Timer for auto-hide
            _saveNotificationTimer = new Timer(2000, 1); // 2 seconds, run once
            _saveNotificationTimer.addEventListener(TimerEvent.TIMER, onSaveNotificationTimeout);
        }
        
        private function onSaveNotificationTimeout(e:TimerEvent):void {
            hideSaveNotification();
        }
        
        /**
         * Show save notification
         */
        private function showSaveNotification():void {
            // Position notification at VERY top-left corner of screen (outside popup frame)
            if (_saveNotificationBg && _saveNotificationBg.numChildren > 0) {
                var notifBitmap:Bitmap = _saveNotificationBg.getChildAt(0) as Bitmap;
                if (notifBitmap) {
                    // Scale down to 30% for small notification
                    notifBitmap.scaleX = 0.3;
                    notifBitmap.scaleY = 0.3;
                    _saveNotificationBg.x = 20;
                    _saveNotificationBg.y = 20;
                }
            }
            
            _saveNotificationBg.visible = true;
            _saveNotification.visible = true;
            _saveNotificationBg.alpha = 1.0;
            _saveNotification.alpha = 1.0;
            
            // Bring to front
            bringToFront(_saveNotificationBg);
            bringToFront(_saveNotification);
            
            // Start timer to hide after 2 seconds
            _saveNotificationTimer.reset();
            _saveNotificationTimer.start();
        }
        
        /**
         * Hide save notification
         */
        private function hideSaveNotification():void {
            _saveNotificationBg.visible = false;
            _saveNotification.visible = false;
        }
        
        /**
         * Save current game state
         */
        private function saveGameState():void {
            var saveSystem:SaveSystem = SaveSystem.getInstance();
            saveSystem.data.castleState = _progressionManager.state.toObject();
            saveSystem.data.castleScale = _castleScale;
            saveSystem.data.currentDifficulty = _progressionManager.state.difficultyRank;
            saveSystem.data.currentMode = _progressionManager.state.mode;
            
            var saved:Boolean = saveSystem.saveState();
            if (saved) {
                if (DEBUG) trace("[GameScreen] Game state saved!");
                showSaveNotification();
            } else if (DEBUG) {
                trace("[GameScreen] ERROR: Failed to save game state");
            }
        }

        // ========== ORB HUD (WIN CHARGE) ==========
        
        private function createOrbHud():void {
            if (_orbHud) return;
            
            _orbHud = new Sprite();
            _orbHud.mouseEnabled = false;
            _orbHud.mouseChildren = false;
            addChild(_orbHud);
            
            _orbSprites = new Vector.<Sprite>();
            _orbBitmaps = new Vector.<Bitmap>();
            
            for (var i:int = 0; i < ORB_COUNT; i++) {
                var orb:Sprite = new Sprite();
                orb.mouseEnabled = false;
                orb.mouseChildren = false;
                
                var bmp:Bitmap = new Bitmap();
                bmp.smoothing = true;
                orb.addChild(bmp);
                
                _orbHud.addChild(orb);
                _orbSprites.push(orb);
                _orbBitmaps.push(bmp);
            }
            
            loadOrbAssets();
            layoutOrbHud();
            setOrbCharge(0, false);
        }
        
        private function loadOrbAssets():void {
            if (_orbEmptyData && _orbFilledData) {
                applyOrbVisuals();
                return;
            }
            
            var emptyLoader:Loader = new Loader();
            emptyLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = Bitmap(e.target.content);
                bmp.smoothing = true;
                _orbEmptyData = bmp.bitmapData;
                finalizeOrbHudIfReady();
            });
            emptyLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
                if (DEBUG) trace("[GameScreen] WARNING: Failed to load orb.png, using fallback.");
                _orbEmptyData = createFallbackOrbBitmap(false);
                finalizeOrbHudIfReady();
            });
            emptyLoader.load(new URLRequest("assets/images/Game/orb.png"));
            
            var filledLoader:Loader = new Loader();
            filledLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = Bitmap(e.target.content);
                bmp.smoothing = true;
                _orbFilledData = bmp.bitmapData;
                finalizeOrbHudIfReady();
            });
            filledLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
                if (DEBUG) trace("[GameScreen] WARNING: Failed to load orbFilled.png, using fallback.");
                _orbFilledData = createFallbackOrbBitmap(true);
                finalizeOrbHudIfReady();
            });
            filledLoader.load(new URLRequest("assets/images/Game/orbFilled.png"));
        }
        
        private function finalizeOrbHudIfReady():void {
            if (!_orbHud) return;
            if (!_orbEmptyData || !_orbFilledData) return;
            applyOrbVisuals();
        }
        
        private function applyOrbVisuals():void {
            if (!_orbBitmaps || _orbBitmaps.length != ORB_COUNT) return;
            
            for (var i:int = 0; i < ORB_COUNT; i++) {
                var bmp:Bitmap = _orbBitmaps[i];
                bmp.smoothing = true;
                bmp.bitmapData = (i < _orbCharge) ? _orbFilledData : _orbEmptyData;
                bmp.x = -bmp.bitmapData.width / 2;
                bmp.y = -bmp.bitmapData.height / 2;
            }
            
            layoutOrbHud();
        }
        
        private function layoutOrbHud():void {
            if (!_orbHud || !_orbSprites) return;
            
            // Stop pulses so resize/layout doesn't fight active animations.
            stopAllOrbPulses();
            
            var baseW:Number = _orbEmptyData ? _orbEmptyData.width : 64;
            var baseH:Number = _orbEmptyData ? _orbEmptyData.height : 64;
            var baseScale:Number = (baseH > 0) ? (_orbDesiredHeight / baseH) : 1.0;
            
            for each (var orb:Sprite in _orbSprites) {
                orb.scaleX = baseScale;
                orb.scaleY = baseScale;
            }
            
            var orbWidth:Number = baseW * baseScale;
            var step:Number = orbWidth + _orbGap;
            var startX:Number = -((ORB_COUNT - 1) * step) / 2;
            
            for (var i:int = 0; i < ORB_COUNT; i++) {
                _orbSprites[i].x = startX + (i * step);
                _orbSprites[i].y = 0;
            }
            
            _orbHud.x = _stageWidth / 2;
            _orbHud.y = _orbTopPadding;
            
            syncTopUiLayering();
        }
        
        private function setOrbCharge(charge:int, animateFill:Boolean):void {
            var clamped:int = Math.max(0, Math.min(ORB_COUNT, charge));
            var prev:int = _orbCharge;
            _orbCharge = clamped;
            
            if (!_orbEmptyData || !_orbFilledData || !_orbBitmaps) {
                return;
            }
            
            for (var i:int = 0; i < ORB_COUNT; i++) {
                var bmp:Bitmap = _orbBitmaps[i];
                bmp.bitmapData = (i < _orbCharge) ? _orbFilledData : _orbEmptyData;
                bmp.x = -bmp.bitmapData.width / 2;
                bmp.y = -bmp.bitmapData.height / 2;
            }
            
            if (animateFill && _orbCharge > prev) {
                for (var j:int = prev; j < _orbCharge; j++) {
                    pulseOrb(_orbSprites[j], ORB_FILL_PULSE_AMOUNT, ORB_FILL_PULSE_MS);
                }
            }
        }
        
        private function resetOrbChargeHud():void {
            stopOrbResetTimer();
            stopAllOrbPulses();
            setOrbCharge(0, false);
        }
        
        private function updateOrbChargeHudFromResult(result:ProgressionResult):void {
            if (!result) return;
            if (!_orbSprites || _orbSprites.length != ORB_COUNT) return;
            
            if (!result.wasCorrect) {
                resetOrbChargeHud();
                return;
            }
            
            // Any new win should cancel a pending "full -> reset" timer from the previous win.
            stopOrbResetTimer();
            
            // On the tower-spawn win, show 3/3, pulse all, then reset to empty.
            if (result.upgradeType == ProgressionResult.UPGRADE_NEW_TOWER) {
                stopAllOrbPulses();
                setOrbCharge(ORB_COUNT, false);
                
                for (var i:int = 0; i < ORB_COUNT; i++) {
                    pulseOrb(_orbSprites[i], ORB_FULL_PULSE_AMOUNT, ORB_FULL_PULSE_MS);
                }
                
                _orbResetTimer = new Timer(ORB_FULL_PULSE_MS, 1);
                _orbResetTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onOrbResetTimerComplete);
                _orbResetTimer.start();
                return;
            }
            
            var charge:int = 0;
            if (_progressionManager && _progressionManager.state) {
                charge = _progressionManager.state.winStreak % ORB_COUNT;
            }
            setOrbCharge(charge, true);
        }
        
        private function onOrbResetTimerComplete(e:TimerEvent):void {
            stopOrbResetTimer();
            setOrbCharge(0, false);
        }
        
        private function stopOrbResetTimer():void {
            if (_orbResetTimer) {
                _orbResetTimer.stop();
                _orbResetTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onOrbResetTimerComplete);
                _orbResetTimer = null;
            }
        }
        
        private function pulseOrb(orb:Sprite, amount:Number, durationMs:int, onComplete:Function = null):void {
            if (!orb) return;
            
            stopOrbPulse(orb);
            
            var timer:Timer = new Timer(16);
            var state:Object = {
                orb: orb,
                startMs: new Date().time,
                baseScale: orb.scaleX,
                amount: amount,
                durationMs: durationMs,
                onComplete: onComplete
            };
            
            _orbPulseBySprite[orb] = timer;
            _orbPulseByTimer[timer] = state;
            
            timer.addEventListener(TimerEvent.TIMER, onOrbPulseTick);
            timer.start();
        }
        
        private function onOrbPulseTick(e:TimerEvent):void {
            var timer:Timer = e.target as Timer;
            if (!timer) return;
            
            var state:Object = _orbPulseByTimer[timer];
            if (!state) return;
            
            var orb:Sprite = state.orb as Sprite;
            if (!orb) {
                stopOrbPulseTimer(timer);
                return;
            }
            
            var elapsed:Number = new Date().time - Number(state.startMs);
            var durationMs:Number = Math.max(1, Number(state.durationMs));
            var t:Number = Math.min(elapsed / durationMs, 1.0);
            
            var bump:Number = Math.sin(Math.PI * t); // 0 -> 1 -> 0
            var s:Number = Number(state.baseScale) * (1 + (Number(state.amount) * bump));
            orb.scaleX = s;
            orb.scaleY = s;
            
            if (t >= 1.0) {
                orb.scaleX = Number(state.baseScale);
                orb.scaleY = Number(state.baseScale);
                var cb:Function = state.onComplete as Function;
                stopOrbPulseTimer(timer);
                if (cb != null) cb();
            }
        }
        
        private function stopOrbPulse(orb:Sprite):void {
            if (!orb) return;
            var timer:Timer = _orbPulseBySprite[orb] as Timer;
            if (timer) {
                stopOrbPulseTimer(timer);
            }
        }
        
        private function stopOrbPulseTimer(timer:Timer):void {
            if (!timer) return;
            
            var state:Object = _orbPulseByTimer[timer];
            if (state && state.orb) {
                // Restore base scale immediately if we cancel mid-pulse.
                state.orb.scaleX = Number(state.baseScale);
                state.orb.scaleY = Number(state.baseScale);
                delete _orbPulseBySprite[state.orb];
            }
            delete _orbPulseByTimer[timer];
            
            timer.stop();
            timer.removeEventListener(TimerEvent.TIMER, onOrbPulseTick);
        }
        
        private function stopAllOrbPulses():void {
            if (!_orbPulseByTimer) return;
            var timers:Array = [];
            for (var key:* in _orbPulseByTimer) {
                timers.push(key);
            }
            for each (var t:Timer in timers) {
                stopOrbPulseTimer(t);
            }
        }
        
        private function createFallbackOrbBitmap(filled:Boolean):BitmapData {
            var size:int = 64;
            var s:Shape = new Shape();
            var g:* = s.graphics;
            g.clear();
            
            if (filled) {
                g.beginFill(0xFFD54A);
                g.drawCircle(size / 2, size / 2, (size / 2) - 4);
                g.endFill();
            } else {
                g.lineStyle(6, 0xFFD54A);
                g.drawCircle(size / 2, size / 2, (size / 2) - 6);
            }
            
            var bmd:BitmapData = new BitmapData(size, size, true, 0x00000000);
            bmd.draw(s);
            return bmd;
        }
        
        /**
         * Show pause popup with dark overlay
         */
        public function showPausePopup():void {
            _isPaused = true;
            
            // Stop horde timers
            pauseHordeCountdown();
            if (_hordeDamageTimer) _hordeDamageTimer.stop();
            
            // Show overlay and popup
            _pauseOverlay.visible = true;
            _pausePopup.visible = true;
            
            // Bring to front
            bringToFront(_pauseOverlay);
            bringToFront(_pausePopup);
            
            // Disable buttons while paused
            if (_upgradeButton) _upgradeButton.mouseEnabled = false;
            
            if (DEBUG) {
                trace("[GameScreen] Game PAUSED");
            }
        }
        
        /**
         * Hide pause popup and resume game
         */
        public function hidePausePopup():void {
            _isPaused = false;
            
            // Resume horde timers
            resumeHordeCountdown();
            if (!_isUpgradePopupOpen && _hordeDamageTimer && _hordeAttackActive && !_hordeDamageTimer.running) _hordeDamageTimer.start();
            
            // Hide overlay and popup
            _pauseOverlay.visible = false;
            _pausePopup.visible = false;
            
            // Re-enable buttons
            if (_upgradeButton) _upgradeButton.mouseEnabled = true;
            
            if (DEBUG) {
                trace("[GameScreen] Game RESUMED");
            }
        }
        
        /**
         * Check if game is paused
         */
        public function get isPaused():Boolean {
            return _isPaused;
        }
        
        /**
         * Helper to bring element to front
         */
        private function bringToFront(child:*):void {
            if (child && contains(child)) {
                setChildIndex(child, numChildren - 1);
            }
        }
        
        private function syncTopUiLayering():void {
            // Keep HUD and buttons above gameplay elements.
            if (_upgradeButton) bringToFront(_upgradeButton);
            if (_pauseButton) bringToFront(_pauseButton);
            if (_saveNotificationBg && _saveNotificationBg.visible) bringToFront(_saveNotificationBg);
            if (_saveNotification && _saveNotification.visible) bringToFront(_saveNotification);
            if (_orbHud) bringToFront(_orbHud);
            
            // Pause overlay/popup should always be above everything when visible.
            if (_pauseOverlay && _pauseOverlay.visible) bringToFront(_pauseOverlay);
            if (_pausePopup && _pausePopup.visible) bringToFront(_pausePopup);
        }

        
        /**
         * Show/hide upgrade button
         */
        public function setUpgradeButtonVisible(visible:Boolean):void {
            _upgradeButton.visible = visible;
        }
        
        /**
         * Enable/disable upgrade button
         */
        public function setUpgradeButtonEnabled(enabled:Boolean):void {
            if (_upgradeButton) {
                _upgradeButton.mouseEnabled = enabled;
                _upgradeButton.alpha = enabled ? 1.0 : 0.5;
            }
            
            // When upgrade popup is open, pause siege countdown so horde won't spawn.
            _isUpgradePopupOpen = !enabled;
            
            if (_isUpgradePopupOpen) {
                pauseHordeCountdown();
                return;
            }
            
            // Upgrade popup closed -> resume countdown (do not reset here).
            resumeHordeCountdown();
        }
        
        /**
         * Get castle center position for effects
         */
        public function getCastleCenter():Object {
            if (_mainCastle && _mainCastleBitmap) {
                return {
                    x: _mainCastle.x,
                    y: _mainCastle.y - (_mainCastleBitmap.height * _castleScale / 2)
                };
            }
            return {
                x: _stageWidth / 2,
                y: _stageHeight / 2
            };
        }
        
        /**
         * Get tower castle reference
         */
        public function getTowerCastle():TowerCastle {
            return _towerCastle;
        }
        
        /**
         * Process upgrade using ProgressionManager result
         */
        public function processUpgradeResult(result:ProgressionResult):void {
            if (!result.wasCorrect) {
                updateOrbChargeHudFromResult(result);
                var audioManager:AudioManager = getAudioManager();
                if (audioManager) {
                    audioManager.playSfx("castleShrink");
                }
                // Handle wrong answer - shrink or remove
                switch (result.upgradeType) {
                    case ProgressionResult.SHRINK_MAIN_CASTLE:
                        // Use integrity-based scale from CastleState
                        var integrityScale:Number = _progressionManager.state.getMainCastleIntegrityScale();
                        shrinkMainCastle(integrityScale);
                        
                        // Check for game over
                        if (_progressionManager.state.isMainCastleDestroyed) {
                            if (DEBUG) trace("[GameScreen] GAME OVER - Main castle destroyed!");
                            // TODO: Show game over UI
                        }
                        break;
                        
                    case ProgressionResult.SHRINK_TOWER:
                        // Find the tower and use its sizeStage to determine scale
                        shrinkTowerByStage(result.damagedTowerId, result.targetSizeStage);
                        break;
                        
                    case ProgressionResult.REMOVE_TOWER:
                        var removedId:String = result.removedTowerId;
                        if (!removedId || removedId == "") {
                            removedId = result.damagedTowerId;
                        }
                        removeTowerWithAnimation(removedId);
                        break;
                }
                
                if (DEBUG) {
                    trace("[GameScreen] Wrong answer processed: " + result.upgradeType + 
                          ", integrity=" + _progressionManager.state.mainCastleIntegrityStage);
                }
                return;
            }
            
            // Correct answer - handle upgrades
            updateOrbChargeHudFromResult(result);
            
            // If a new tower was spawned this win, add its visual first so it's available for any follow-up logic.
            var spawnedNewTowerThisWin:Boolean = (result.upgradeType == ProgressionResult.UPGRADE_NEW_TOWER && result.newTower != null);
            if (spawnedNewTowerThisWin) {
                addNewTower(result.newTower);
            }
            
            // Check if towers exist to determine target (post-result state)
            var hasTowers:Boolean = _progressionManager.state.hasTowers;
            
            if (hasTowers) {
                // TOWERS EXIST: newest tower must always give visible feedback; mainCastle stays still.
                // If a tower was spawned this win, the popup animation is already the feedback.
                if (!spawnedNewTowerThisWin) {
                    var targetTowerId:String = (result.healedTowerId && result.healedTowerId != "") ? result.healedTowerId : "";
                    if (targetTowerId == "") {
                        var newestStateTower:AdditionTower = _progressionManager.state.getNewestTower();
                        if (newestStateTower) targetTowerId = newestStateTower.id;
                    }
                    if (targetTowerId != "") {
                        repairTowerByStage(targetTowerId);
                    }
                }
                
                if (DEBUG) {
                    trace("[GameScreen] WIN: Towers exist - mainCastle UNCHANGED");
                }
            } else {
                // NO TOWERS: Scale up mainCastle
                if (result.mainCastleIntegrity > 0) {
                    // Use integrity scale
                    var repairScale:Number = _progressionManager.state.getMainCastleIntegrityScale();
                    if (repairScale > _castleScale) {
                        repairMainCastleIntegrity(repairScale);
                    }
                }
                
                // Also apply size growth
                var growthScale:Number = 0.7 + (_progressionManager.state.mainCastleSizeLevel * 0.1);
                var minIntegrityScale:Number = _progressionManager.state.getMainCastleIntegrityScale();
                var finalScale:Number = Math.max(growthScale, minIntegrityScale);
                upgradeMainCastle(finalScale);
                
                if (DEBUG) {
                    trace("[GameScreen] WIN: No towers - mainCastle scaled to " + finalScale.toFixed(3));
                }
            }
            
            // Play upgrade effects
            playUpgradeRiseFx();
            
            if (DEBUG) {
                var debugMsg:String = "[GameScreen] WIN processed:";
                debugMsg += " | hasTowers=" + hasTowers;
                debugMsg += " | type=" + result.upgradeType;
                if (result.healedTowerId) {
                    debugMsg += " | Healed: " + result.healedTowerId;
                }
                if (result.newTower) {
                    debugMsg += " | New tower: " + result.newTower.id;
                }
                if (result.mainCastleIntegrity > 0) {
                    debugMsg += " | MC-Integrity: " + result.mainCastleIntegrity;
                }
                if (result.mainCastleLevel > 0) {
                    debugMsg += " | MC-Level: " + result.mainCastleLevel;
                }
                trace(debugMsg);
            }
        }
        
        /**
         * Shrink main castle - ALWAYS scales DOWN based on integrity
         */
        private function shrinkMainCastle(targetScale:Number):void {
            var previousScale:Number = _mainCastle ? _mainCastle.scaleX : _castleScale;
            
            // CRITICAL: targetScale must be LESS than current scale (damage = shrink)
            if (targetScale >= previousScale) {
                if (DEBUG) {
                    trace("[GameScreen] WARNING: Damage called but targetScale >= current (" + targetScale + " >= " + previousScale + ")");
                }
                // Force shrink anyway - integrity damage always reduces
                targetScale = previousScale * 0.92; // 8% reduction minimum
            }
            
            _castleScale = Math.max(targetScale, 0.0); // Allow destruction (0.0)
            
            if (_mainCastle && _mainCastleBitmap) {
                // Ensure shrink wins over any in-progress "pop" upgrade animation.
                stopCastlePopAnimation();
                
                // Smooth shrink animation
                if (Math.abs(_castleScale - previousScale) < 0.001) {
                    applyCastleScale(_castleScale);
                } else {
                    startCastleShrinkAnimation(previousScale, _castleScale);
                }
                
                updateTowerPosition();
                repositionAllTowers();
                
                if (DEBUG) {
                    trace("[GameScreen] Main castle DAMAGED: " + previousScale.toFixed(3) + " → " + _castleScale.toFixed(3) + " (integrity-based)");
                }
            }
        }
        
        /**
         * Animate castle shrinking (smooth, no bounce)
         */
        private function startCastleShrinkAnimation(fromScale:Number, toScale:Number):void {
            var startTime:Number = new Date().getTime();
            var duration:Number = 400;
            var self:GameScreen = this;
            
            var shrinkTimer:Timer = new Timer(16);
            shrinkTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
                var elapsed:Number = new Date().getTime() - startTime;
                var progress:Number = Math.min(elapsed / duration, 1.0);
                
                // Smooth ease-out
                var easedProgress:Number = 1 - Math.pow(1 - progress, 2);
                var currentScale:Number = fromScale + (toScale - fromScale) * easedProgress;
                
                self.applyCastleScale(currentScale);
                
                if (progress >= 1.0) {
                    shrinkTimer.stop();
                    self.applyCastleScale(toScale);
                    self.updateTowerPosition();
                    self.repositionAllTowers();
                }
            });
            shrinkTimer.start();
        }
        
        /**
         * Repair/scale up a tower using its sizeStage (healed on win)
         */
        private function repairTowerByStage(towerId:String):void {
            // Find tower by ID from CastleState
            var stateTower:AdditionTower = _progressionManager.state.getTowerById(towerId);
            if (!stateTower) {
                if (DEBUG) trace("[GameScreen] ERROR: Tower " + towerId + " not found in state!");
                return;
            }
            
            // Get the visual scale from the model (after heal, sizeStage already increased)
            var targetScale:Number = stateTower.getScale();
            
            // Find visual tower component
            var visualTower:TowerAddition = findTowerById(stateTower.id);
            if (visualTower) {
                var previousScale:Number = visualTower.scaleX;
                
                // If no growth delta (already at max), still give a satisfying "win confirm" pulse.
                var epsilon:Number = 0.001;
                if (targetScale <= previousScale + epsilon) {
                    if (DEBUG) {
                        trace("[GameScreen] Tower " + towerId + " at max/unchanged (stage=" + stateTower.sizeStage + "), playing pulse");
                    }
                    visualTower.pulse(0.06, 260, function():void {
                        positionTower(visualTower);
                        repositionAllTowers();
                    });
                    return;
                }
                
                // Use grow animation (smooth scale up)
                var audioManager:AudioManager = getAudioManager();
                if (audioManager) {
                    audioManager.playSfx("castleUpgrade");
                }
                visualTower.scaleToTarget(targetScale, function():void {
                    positionTower(visualTower);
                    repositionAllTowers();
                });
                
                if (DEBUG) {
                    trace("[GameScreen] Tower " + towerId + " REPAIRED: stage=" + stateTower.sizeStage + 
                          ", scale: " + previousScale.toFixed(3) + " → " + targetScale.toFixed(3));
                }
            } else {
                if (DEBUG) trace("[GameScreen] ERROR: Visual tower not found! id=" + stateTower.id);
            }
        }
        
        /**
         * Repair mainCastle integrity (scale up based on integrity stage)
         */
        private function repairMainCastleIntegrity(targetScale:Number):void {
            var previousScale:Number = _mainCastle ? _mainCastle.scaleX : _castleScale;
            
            // Only scale up if target is actually higher
            if (targetScale <= previousScale) return;
            
            _castleScale = targetScale;
            
            if (_mainCastle && _mainCastleBitmap) {
                stopCastlePopAnimation();
                startCastlePopAnimation(previousScale, _castleScale);
                updateTowerPosition();
                repositionAllTowers();
                
                // Play castle upgrade sound
                var audioManager:AudioManager = getAudioManager();
                if (audioManager) {
                    audioManager.playSfx("castleUpgrade");
                }
                
                if (DEBUG) {
                    trace("[GameScreen] Main castle INTEGRITY REPAIRED: " + previousScale.toFixed(3) + " → " + _castleScale.toFixed(3));
                }
            }
        }
        
        /**
         * Shrink a tower using its sizeStage (NEW - uses AdditionTower model directly)
         */
        private function shrinkTowerByStage(towerId:String, sizeStage:int):void {
            // Find tower by ID from CastleState
            var stateTower:AdditionTower = _progressionManager.state.getTowerById(towerId);
            if (!stateTower) {
                if (DEBUG) trace("[GameScreen] ERROR: Tower " + towerId + " not found in state!");
                return;
            }
            
            // Get the visual scale from the model (AFTER damage already applied)
            var targetScale:Number = stateTower.getScale();
            
            // Find visual tower component
            var visualTower:TowerAddition = findTowerById(stateTower.id);
            if (visualTower) {
                var currentVisualScale:Number = visualTower.scaleX;
                
                // CRITICAL: Ensure target is LESS than current (damage = shrink)
                if (targetScale >= currentVisualScale) {
                    if (DEBUG) {
                        trace("[GameScreen] ERROR: Damage but targetScale >= current! " + 
                              "Tower=" + towerId + 
                              ", current=" + currentVisualScale.toFixed(3) + 
                              ", target=" + targetScale.toFixed(3) + 
                              ", stage=" + sizeStage);
                    }
                    // Force shrink by 15% to ensure visible damage
                    targetScale = currentVisualScale * 0.85;
                }
                
                // Stop any in-progress animations
                visualTower.shrink(targetScale, function():void {
                    positionTower(visualTower);
                    repositionAllTowers();
                });
                
                if (DEBUG) {
                    trace("[GameScreen] Tower " + towerId + " DAMAGED: stage=" + sizeStage + 
                          ", scale: " + currentVisualScale.toFixed(3) + " → " + targetScale.toFixed(3));
                }
            } else {
                if (DEBUG) trace("[GameScreen] ERROR: Visual tower not found! id=" + stateTower.id);
            }
        }
        
        /**
         * Shrink a tower (LEGACY - kept for backwards compatibility)
         */
        private function shrinkTower(batch:int, side:String, targetScale:Number):void {
            var tower:TowerAddition = findTower(batch, side);
            if (tower) {
                tower.shrink(targetScale, function():void {
                    positionTower(tower);
                    repositionAllTowers();
                });
                
                if (DEBUG) {
                    trace("[GameScreen] Tower batch=" + batch + " side=" + side + " shrunk to " + targetScale);
                }
            }
        }
        
        /**
         * Remove tower with gear animation
         */
        private function removeTowerWithAnimation(towerId:String):void {
            if (!towerId || towerId == "") {
                if (DEBUG) {
                    trace("[GameScreen] WARNING: removeTowerWithAnimation called without a towerId");
                }
                return;
            }
            
            var tower:TowerAddition = findTowerById(towerId);
            if (tower) {
                tower.playRemovalAnimation(function():void {
                    // Remove from display and array
                    if (_towerContainer && _towerContainer.contains(tower)) {
                        _towerContainer.removeChild(tower);
                    }
                    
                    var index:int = _towerAdditions.indexOf(tower);
                    if (index >= 0) {
                        _towerAdditions.splice(index, 1);
                    }
                    
                    tower.dispose();
                    repositionAllTowers();
                    
                    if (DEBUG) {
                        trace("[GameScreen] Tower " + towerId + " removed");
                    }
                });
                
                // Play castle destroyed sound
                var audioManager:AudioManager = getAudioManager();
                if (audioManager) {
                    audioManager.playSfx("castleDestroyed");
                }
            } else if (DEBUG) {
                trace("[GameScreen] WARNING: Tower " + towerId + " not found for removal");
            }
        }
        
        /**
         * Upgrade main castle - grows with size level (legacy support)
         * Note: This is separate from integrity system
         */
        private function upgradeMainCastle(targetScale:Number):void {
            var previousScale:Number = _mainCastle ? _mainCastle.scaleX : _castleScale;
            // Cap at 1.5x for visual growth, but integrity damage uses 1.0 base
            _castleScale = Math.min(targetScale, 1.5);
            
            if (_mainCastle && _mainCastleBitmap) {
                if (Math.abs(_castleScale - previousScale) < 0.001) {
                    applyCastleScale(_castleScale);
                } else {
                    startCastlePopAnimation(previousScale, _castleScale);
                    
                    // Play castle upgrade sound
                    var audioManager:AudioManager = getAudioManager();
                    if (audioManager) {
                        audioManager.playSfx("castleUpgrade");
                    }
                }
                
                updateTowerPosition();
                repositionAllTowers();
                
                if (DEBUG) {
                    trace("[GameScreen] Main castle UPGRADED to " + (_castleScale * 100).toFixed(1) + "%");
                }
            }
        }
        
        /**
         * Add a new tower
         */
        private function addNewTower(modelTower:AdditionTower):void {
            if (!modelTower) return;
            
            var batch:int = modelTower.createdAtIndex;
            var side:String = modelTower.side ? modelTower.side.toLowerCase() : "left";
            var initialScale:Number = modelTower.getScale();
            var maxScale:Number = (!isNaN(modelTower.maxScale) && modelTower.maxScale > 0) ?
                modelTower.maxScale : getMaxScaleForBatch(batch);
            
            // Create new tower
            var tower:TowerAddition = new TowerAddition(batch, side, initialScale, maxScale, modelTower.id, modelTower.imageUrl);
            tower.addEventListener(Event.COMPLETE, function(e:Event):void {
                positionTower(tower);
                updateTowerLayering();
                // Play popup animation after positioning
                tower.playPopupAnimation();
            });
            
            _towerAdditions.push(tower);
            
            // Add to display - towers go behind main castle
            if (!_towerContainer) {
                _towerContainer = new Sprite();
            }
            
            // Add tower container behind main castle if not already added
            if (!contains(_towerContainer)) {
                var castleIndex:int = _mainCastle ? getChildIndex(_mainCastle) : numChildren - 1;
                addChildAt(_towerContainer, castleIndex);
            }
            
            _towerContainer.addChild(tower);
            
            // Play castle spawn sound for new tower
            var audioManager:AudioManager = getAudioManager();
            if (audioManager) {
                audioManager.playSfx("castleSpawn");
            }
            
            if (DEBUG) {
                trace("[GameScreen] Added new tower: id=" + modelTower.id + ", batch=" + batch + ", side=" + side + ", scale=" + initialScale);
            }
        }

        private function rebuildTowersFromState(state:CastleState):void {
            clearAllTowers();
            
            if (!state || !state.towerCastle || state.towerCastle.length == 0) {
                return;
            }
            
            if (!_towerContainer) {
                _towerContainer = new Sprite();
            }
            
            if (!contains(_towerContainer)) {
                var castleIndex:int = _mainCastle ? getChildIndex(_mainCastle) : numChildren - 1;
                addChildAt(_towerContainer, castleIndex);
            }
            
            for each (var modelTower:AdditionTower in state.towerCastle) {
                addTowerFromState(modelTower);
            }
            
            updateTowerLayering();
            repositionAllTowers();
        }

        private function addTowerFromState(modelTower:AdditionTower):void {
            if (!modelTower) return;
            
            var batch:int = modelTower.createdAtIndex;
            var side:String = modelTower.side ? modelTower.side.toLowerCase() : "left";
            var targetScale:Number = modelTower.getScale();
            var maxScale:Number = (!isNaN(modelTower.maxScale) && modelTower.maxScale > 0) ?
                modelTower.maxScale : getMaxScaleForBatch(batch);
            
            var tower:TowerAddition = new TowerAddition(batch, side, targetScale, maxScale, modelTower.id, modelTower.imageUrl);
            tower.addEventListener(Event.COMPLETE, function(e:Event):void {
                tower.alpha = 1;
                tower.applyScale(targetScale);
                positionTower(tower);
                repositionAllTowers();
            });
            
            _towerAdditions.push(tower);
            _towerContainer.addChild(tower);
        }
        
        /**
         * Update tower layering - outer towers further back
         */
        private function updateTowerLayering():void {
            if (!_towerContainer) return;
            
            var depthById:Object = getTowerDepthMap();
            
            // Sort towers by depth (furthest outward first)
            var sorted:Vector.<TowerAddition> = _towerAdditions.slice();
            sorted.sort(function(a:TowerAddition, b:TowerAddition):int {
                var depthA:int = depthById.hasOwnProperty(a.towerId) ? depthById[a.towerId] : 0;
                var depthB:int = depthById.hasOwnProperty(b.towerId) ? depthById[b.towerId] : 0;
                if (depthA != depthB) {
                    return depthB - depthA;
                }
                return b.batch - a.batch;
            });
            
            // Reorder children in tower container
            for (var i:int = 0; i < sorted.length; i++) {
                if (_towerContainer.contains(sorted[i])) {
                    _towerContainer.setChildIndex(sorted[i], i);
                }
            }
            
            // Ensure main castle is always on top of tower container
            if (_mainCastle && contains(_mainCastle) && contains(_towerContainer)) {
                var towerIndex:int = getChildIndex(_towerContainer);
                var castleIndex:int = getChildIndex(_mainCastle);
                if (towerIndex > castleIndex) {
                    setChildIndex(_towerContainer, castleIndex);
                }
            }
            
            if (DEBUG) {
                trace("[GameScreen] Tower layering updated. Order (back to front):");
                for each (var t:TowerAddition in sorted) {
                    var label:String = (t.towerId && t.towerId.length > 0) ? t.towerId : ("batch " + t.batch);
                    trace("  - " + label + " " + t.side);
                }
            }
        }

        private function getTowerDepthMap():Object {
            var depth:Object = {};
            if (!_progressionManager || !_progressionManager.state) return depth;
            
            var state:CastleState = _progressionManager.state;
            var i:int;
            for (i = 0; i < state.leftTowers.length; i++) {
                depth[state.leftTowers[i]] = i + 1;
            }
            for (i = 0; i < state.rightTowers.length; i++) {
                depth[state.rightTowers[i]] = i + 1;
            }
            return depth;
        }
        
        /**
         * Upgrade existing tower
         */
        private function upgradeTower(batch:int, side:String, targetScale:Number):void {
            var tower:TowerAddition = findTower(batch, side);
            if (tower) {
                var previousScale:Number = tower.scaleX;
                tower.applyScale(targetScale);
                positionTower(tower);
                
                if (targetScale > previousScale + 0.001) {
                    var audioManager:AudioManager = getAudioManager();
                    if (audioManager) {
                        audioManager.playSfx("castleUpgrade");
                    }
                }
                
                if (DEBUG) {
                    trace("[GameScreen] Tower upgraded: batch=" + batch + ", side=" + side + ", scale=" + targetScale);
                }
            } else {
                if (DEBUG) {
                    trace("[GameScreen] WARNING: Tower not found for upgrade: batch=" + batch + ", side=" + side);
                }
            }
        }
        
        /**
         * Find tower by batch and side
         */
        private function findTower(batch:int, side:String):TowerAddition {
            for each (var tower:TowerAddition in _towerAdditions) {
                if (tower.batch == batch && tower.side == side) {
                    return tower;
                }
            }
            return null;
        }

        private function findTowerById(towerId:String):TowerAddition {
            if (!towerId || towerId == "") return null;
            for each (var tower:TowerAddition in _towerAdditions) {
                if (tower.towerId == towerId) {
                    return tower;
                }
            }
            return null;
        }
        
        /**
         * Find the newest tower (most recently created) - target for horde attacks.
         * The newest tower is always towerCastle[length-1] in ProgressionManager.
         * This finds the matching visual TowerAddition.
         */
        private function findNewestTower():TowerAddition {
            if (!_towerAdditions || _towerAdditions.length == 0) return null;
            
            if (_progressionManager && _progressionManager.state) {
                var stateTower:AdditionTower = _progressionManager.state.getNewestTower();
                if (stateTower) {
                    var visual:TowerAddition = findTowerById(stateTower.id);
                    if (visual) return visual;
                }
            }
            
            // Fallback: highest batch (legacy)
            var newest:TowerAddition = null;
            var highestBatch:int = 0;
            
            for each (var tower:TowerAddition in _towerAdditions) {
                if (tower.batch > highestBatch) {
                    highestBatch = tower.batch;
                    newest = tower;
                }
            }
            return newest;
        }
        
        /**
         * Find outermost tower on a side (legacy - for positioning)
         */
        private function findOutermostTowerOnSide(side:String):TowerAddition {
            var outermost:TowerAddition = null;
            var highestBatch:int = 0;
            
            for each (var tower:TowerAddition in _towerAdditions) {
                if (tower.side == side && tower.batch > highestBatch) {
                    highestBatch = tower.batch;
                    outermost = tower;
                }
            }
            return outermost;
        }
        
        /**
         * Get max scale for tower batch
         */
        private function getMaxScaleForBatch(batch:int):Number {
            return AdditionTower.getMaxScaleForCreatedIndex(batch);
        }
        
        /**
         * Position a tower at the edge of its anchor (node chain)
         */
        private function positionTower(tower:TowerAddition):void {
            if (!_mainCastle || !_mainCastleBitmap || !tower) return;
            
            var anchorX:Number = _mainCastle.x;
            var anchorY:Number = _mainCastle.y;
            var anchorHalfWidth:Number = (_mainCastleBitmap.width * _castleScale) / 2;
            var anchoredByChain:Boolean = false;
            
            if (_progressionManager && _progressionManager.state && tower.towerId && tower.towerId.length > 0) {
                var state:CastleState = _progressionManager.state;
                var sideLower:String = tower.side;
                var stateTower:AdditionTower = state.getTowerById(tower.towerId);
                if (stateTower) {
                    sideLower = (stateTower.side == CastleState.SIDE_RIGHT) ? "right" : "left";
                }
                
                var chain:Vector.<String> = (sideLower == "right") ? state.rightTowers : state.leftTowers;
                if (chain && chain.length > 0) {
                    var index:int = chain.indexOf(tower.towerId);
                    if (index >= 0) {
                        if (index > 0) {
                            var prevId:String = chain[index - 1];
                            var prevTower:TowerAddition = findTowerById(prevId);
                            if (prevTower) {
                                anchorX = prevTower.x;
                                anchorY = prevTower.y;
                                anchorHalfWidth = prevTower.getHalfWidth();
                            }
                        }
                        anchoredByChain = true;
                    }
                }
            }
            
            if (!anchoredByChain && tower.batch > 1) {
                // Legacy fallback: previous batch on same side
                var legacyPrev:TowerAddition = null;
                for each (var t:TowerAddition in _towerAdditions) {
                    if (t.side == tower.side && t.batch == tower.batch - 1) {
                        legacyPrev = t;
                        break;
                    }
                }
                
                if (legacyPrev) {
                    anchorX = legacyPrev.x;
                    anchorY = legacyPrev.y;
                    anchorHalfWidth = legacyPrev.getHalfWidth();
                }
            }
            
            // Position at edge with significant overlap (negative gap = overlap)
            tower.positionAtEdge(anchorX, anchorY, anchorHalfWidth, -40);
            
            if (DEBUG) {
                var label:String = (tower.towerId && tower.towerId.length > 0) ? tower.towerId : ("batch " + tower.batch);
                trace("[GameScreen] Positioned tower " + label + ", side=" + tower.side + " at x=" + tower.x);
            }
        }
        
        /**
         * Reposition all towers (called after main castle or tower scale changes)
         */
        private function repositionAllTowers():void {
            var ordered:Vector.<TowerAddition> = new Vector.<TowerAddition>();
            
            if (_progressionManager && _progressionManager.state) {
                var state:CastleState = _progressionManager.state;
                for each (var leftId:String in state.leftTowers) {
                    var leftTower:TowerAddition = findTowerById(leftId);
                    if (leftTower) ordered.push(leftTower);
                }
                for each (var rightId:String in state.rightTowers) {
                    var rightTower:TowerAddition = findTowerById(rightId);
                    if (rightTower) ordered.push(rightTower);
                }
            }
            
            if (ordered.length == 0) {
                ordered = _towerAdditions.slice();
                ordered.sort(function(a:TowerAddition, b:TowerAddition):int {
                    return a.batch - b.batch;
                });
            }
            
            for each (var tower:TowerAddition in ordered) {
                if (tower.isLoaded) {
                    positionTower(tower);
                }
            }
            
            // Update layering after repositioning
            updateTowerLayering();
        }
        
        /**
         * Process upgrade based on streak (LEGACY - for backwards compatibility)
         */
        public function processUpgrade(streak:int):void {
            // Scale castle bigger with each upgrade (from 0.7 to 1.0)
            var previousScale:Number = _mainCastle ? _mainCastle.scaleX : _castleScale;
            
            _castleScale = 0.7 + (streak * 0.03); // 3% increase per streak
            _castleScale = Math.min(_castleScale, 1.0); // Max 100% scale
            
            if (_mainCastle && _mainCastleBitmap) {
                // Pop animation when the castle grows (more satisfying than instant scaling)
                if (Math.abs(_castleScale - previousScale) < 0.001) {
                    applyCastleScale(_castleScale);
                } else {
                    startCastlePopAnimation(previousScale, _castleScale);
                }
                
                // Tiny lamp + gear icons rising behind the castle
                playUpgradeRiseFx();
                
                // Reposition after scaling
                updateTowerPosition();
                repositionAllTowers();
                
                if (DEBUG) {
                    trace("[GameScreen] Castle scaled to " + (_castleScale * 100) + "% for streak " + streak);
                }
            }
        }
        
        /**
         * Process wrong answer
         */
        public function processWrong():void {
            // Image-based castle doesn't change on wrong answer
        }
        
        /**
         * Remove a side tower (called when wrong 3x streak)
         * Returns true if a tower was removed
         */
        public function removeSideTower():Boolean {
            // Remove the most recently added tower
            if (_towerAdditions.length > 0) {
                var tower:TowerAddition = _towerAdditions.pop();
                if (tower.parent) {
                    tower.parent.removeChild(tower);
                }
                tower.dispose();
                return true;
            }
            return false;
        }
        
        /**
         * Check if there are side towers to remove
         */
        public function hasSideTowers():Boolean {
            return _towerAdditions.length > 0;
        }
        
        /**
         * Clear all towers
         */
        public function clearAllTowers():void {
            for each (var tower:TowerAddition in _towerAdditions) {
                if (tower.parent) {
                    tower.parent.removeChild(tower);
                }
                tower.dispose();
            }
            _towerAdditions = new Vector.<TowerAddition>();
        }
        
        /**
         * Reset castle
         */
        public function resetCastle():void {
            _castleScale = 1.0; // Full integrity (stage 5)
            stopCastlePopAnimation();
            clearUpgradeFx();
            clearAllTowers();
            
            // Reset progression
            _progressionManager.reset();
            resetOrbChargeHud();
            
            // End any active horde attack
            endHordeAttack();
            
            // Restart horde timer
            if (_hordeTimer) _hordeTimer.stop();
            startRandomHordeTimer();
            
            if (_mainCastle) {
                applyCastleScale(_castleScale);
                updateTowerPosition();
            }
        }
        
        /**
         * Get current streak
         */
        public function getCurrentStreak():int {
            if (_towerCastle) {
                return _towerCastle.getCurrentStreak();
            }
            return 0;
        }
        
        // Legacy methods for compatibility
        public function enlargeRandomBlock():Boolean {
            return false;
        }
        
        public function shrinkRandomBlock():Boolean {
            processWrong();
            return true;
        }
        
        public function addNewBlock():Object {
            return null;
        }
        
        public function removeRandomBlock():Boolean {
            return false;
        }
        
        public function getBlockCount():int {
            if (_towerCastle) {
                return _towerCastle.getTowerCount();
            }
            return 0;
        }
        
        /**
         * Handle resize - updates all components
         */
        public function onResize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            // Update responsive values
            updateResponsiveValues();
            
            // Resize background to fit screen
            if (_backgroundBitmap) {
                _backgroundBitmap.width = _stageWidth;
                _backgroundBitmap.height = _stageHeight;
            }
            
            updateTower();
            updateTowerPosition();
            updateHordeShadow();
            
            // Reposition upgrade button (centered origin)
            if (_upgradeButton && _upgradeButtonBitmap) {
                _upgradeButton.x = _upgradeButtonBitmap.width / 2 + 40;
                _upgradeButton.y = _stageHeight - _upgradeButtonBitmap.height / 2 - 40;
                bringToFront(_upgradeButton);
            }
            
            // Reposition pause button (centered origin)
            if (_pauseButton && _pauseButtonBitmap) {
                _pauseButton.x = _stageWidth - _pauseButtonBitmap.width / 2 - 30;
                _pauseButton.y = _pauseButtonBitmap.height / 2 + 30;
                bringToFront(_pauseButton);
            }
            
            // Resize pause overlay
            if (_pauseOverlay) {
                drawPauseOverlay();
            }
            
            // Recenter pause popup
            if (_pausePopup && _pausePopupBitmap) {
                _pausePopup.x = (_stageWidth - _pausePopupBitmap.width) / 2;
                _pausePopup.y = (_stageHeight - _pausePopupBitmap.height) / 2;
            }

            // Reposition orb HUD (top-center)
            layoutOrbHud();

            // If pause UI is visible, keep it on top after resizing/layout changes.
            if (_pauseOverlay && _pauseOverlay.visible) bringToFront(_pauseOverlay);
            if (_pausePopup && _pausePopup.visible) bringToFront(_pausePopup);
            
            if (DEBUG) {
                trace("[GameScreen] Resized to: " + stageWidth + "x" + stageHeight);
            }
        }
        
        /**
         * Get AudioManager instance (defensive)
         */
        private function getAudioManager():AudioManager {
            try {
                var audioManager:AudioManager = ServiceLocator.get("AudioManager") as AudioManager;
                if (!audioManager) {
                    if (DEBUG) trace("[GameScreen] WARNING: AudioManager not found in ServiceLocator");
                }
                return audioManager;
            } catch (error:Error) {
                if (DEBUG) trace("[GameScreen] ERROR getting AudioManager: " + error.message);
                return null;
            }
            // Should never reach here, but compiler wants explicit return
            return null;
        }
        
        // Getters
        public function get stageWidth():Number { return _stageWidth; }
        public function get stageHeight():Number { return _stageHeight; }
    }
}
