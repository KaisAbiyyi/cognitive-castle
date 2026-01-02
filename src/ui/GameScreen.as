package ui {
    
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;
    import castle.AdditionTower;
    import castle.CastleState;
    import castle.TowerAddition;
    import castle.TowerCastle;
    import game.ProgressionManager;
    import game.ProgressionResult;
    import services.AudioManager;
    import services.SaveSystem;
    import core.ServiceLocator;
    import ui.game.HordeManager;
    import ui.game.CastleVisuals;
    import ui.game.CloudSystem;
    import ui.game.PauseSystem;
    import ui.game.OrbHUD;
    import ui.game.UpgradeFX;
    import ui.game.TowerManager;
    import ui.game.GameButtons;
    
    /**
     * GameScreen - Main game screen coordinator. Delegates to specialized components.
     */
    public class GameScreen extends Sprite {
        
        private static const DEBUG:Boolean = true;
        private static const ORB_COUNT:int = 3;
        
        public static const UPGRADE_CLICKED:String = "upgradeClicked";
        public static const TRIAL_COMPLETE:String = "trialComplete";
        
        private var _stageWidth:Number, _stageHeight:Number;
        private var _backgroundBitmap:Bitmap;
        private var _cloudSystem:CloudSystem;
        private var _shadowLayer:Sprite;
        private var _castleVisuals:CastleVisuals;
        private var _towerManager:TowerManager;
        private var _hordeManager:HordeManager;
        private var _pauseSystem:PauseSystem;
        private var _orbHUD:OrbHUD;
        private var _upgradeFX:UpgradeFX;
        private var _gameButtons:GameButtons;
        private var _isUpgradePopupOpen:Boolean = false;
        private var _progressionManager:ProgressionManager;
        private var _pendingSavedState:CastleState;
        private var _pendingSavedCastleScale:Number = NaN;
        private var _towerCastle:TowerCastle;
        
        public function GameScreen() { _progressionManager = ProgressionManager.getInstance(); }
        
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth; _stageHeight = stageHeight;
            createShadowLayer();
            loadBackground();
            createComponents();
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage, false, 0, true);
            if (stage) onAddedToStage(null);
            var am:AudioManager = getAudioManager();
            if (am) am.playBgm("bgmGame");
            if (DEBUG) trace("[GameScreen] Initialized: " + stageWidth + "x" + stageHeight);
        }

        private function onAddedToStage(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            if (stage) stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyboardDown, false, 0, true);
        }

        private function onRemovedFromStage(e:Event):void {
            if (stage) stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleKeyboardDown);
        }
        
        private function createShadowLayer():void { _shadowLayer = new Sprite(); _shadowLayer.mouseEnabled = false; addChild(_shadowLayer); }
        
        private function loadBackground():void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _backgroundBitmap = Bitmap(e.target.content); _backgroundBitmap.smoothing = true;
                _backgroundBitmap.width = _stageWidth; _backgroundBitmap.height = _stageHeight;
                addChildAt(_backgroundBitmap, 0);
                if (_cloudSystem) setChildIndex(_cloudSystem, 1); if (_shadowLayer) setChildIndex(_shadowLayer, 2); syncLayering();
            });
            loader.load(new URLRequest("assets/images/Game/background.png"));
        }
        
        private function createComponents():void {
            _cloudSystem = new CloudSystem(); _cloudSystem.initialize(_stageWidth); addChild(_cloudSystem);
            _castleVisuals = new CastleVisuals(); _castleVisuals.initialize(_stageWidth, _stageHeight, _shadowLayer);
            _castleVisuals.loadCastle(function():void { syncLayering(); applySavedStateIfReady(); var am:AudioManager = getAudioManager(); if (am) am.playSfx("castleSpawn"); });
            addChild(_castleVisuals);
            _towerManager = new TowerManager(); _towerManager.initialize(getCastleInfo); addChild(_towerManager);
            _upgradeFX = new UpgradeFX(); addChild(_upgradeFX);
            _hordeManager = new HordeManager();
            _hordeManager.initialize(_stageWidth, _stageHeight, { onDamageStep: onHordeDamage, getCastleInfo: getCastleInfo,
                findNewestTower: function():TowerAddition { return _towerManager ? _towerManager.findNewest() : null; },
                getShadowLayer: function():Sprite { return _shadowLayer; } });
            _hordeManager.startRandomHordeTimer(); addChild(_hordeManager);
            _gameButtons = new GameButtons(); _gameButtons.initialize(_stageWidth, _stageHeight);
            _gameButtons.addEventListener(GameButtons.UPGRADE_CLICKED, onUpgradeClick);
            _gameButtons.addEventListener(GameButtons.PAUSE_CLICKED, function(e:Event):void { _pauseSystem.show(); });
            addChild(_gameButtons);
            _pauseSystem = new PauseSystem(); _pauseSystem.initialize(_stageWidth, _stageHeight, { onPauseChanged: onPauseChanged, onSave: saveGameState });
            _pauseSystem.addEventListener(PauseSystem.MAIN_MENU_CLICKED, function(e:Event):void { dispatchEvent(new Event("goToMainMenu")); });
            _pauseSystem.addEventListener(PauseSystem.RETRY_CLICKED, function(e:Event):void { dispatchEvent(new Event("retryGame")); });
            addChild(_pauseSystem);
            _orbHUD = new OrbHUD(); _orbHUD.initialize(_stageWidth); addChild(_orbHUD);
        }
        
        private function handleKeyboardDown(e:KeyboardEvent):void { if (e.ctrlKey && e.shiftKey && e.keyCode == Keyboard.H) { if (DEBUG) trace("[GameScreen] CHEAT: Force Horde!"); if (_hordeManager) _hordeManager.forceHordeAttack(); } }
        private function onUpgradeClick(e:Event):void { _isUpgradePopupOpen = true; if (_hordeManager) _hordeManager.pauseCountdown(); dispatchEvent(new Event(UPGRADE_CLICKED)); }
        
        private function onPauseChanged(isPaused:Boolean):void {
            if (_cloudSystem) _cloudSystem.paused = isPaused; if (_upgradeFX) _upgradeFX.paused = isPaused;
            if (isPaused) { if (_hordeManager) _hordeManager.pauseCountdown(); _gameButtons.setUpgradeEnabled(false); }
            else { if (!_isUpgradePopupOpen && _hordeManager) _hordeManager.resumeCountdown(); _gameButtons.setUpgradeEnabled(true); }
            syncLayering();
        }
        
        private function onHordeDamage(damage:Number, targetTower:TowerAddition):Object {
            if (targetTower && targetTower.isLoaded) {
                var newScale:Number = targetTower.currentScale - damage;
                var threshold:Number = targetTower.destroyThreshold;
                if (newScale <= threshold) { _towerManager.removeTower(targetTower.towerId); return { destroyed: true, type: "tower" }; }
                targetTower.applyScale(newScale); return { destroyed: false };
            }
            var scale:Number = Math.max(0, _castleVisuals.castleScale - damage);
            _castleVisuals.castleScale = scale; _castleVisuals.applyScale(scale);
            if (scale <= 0.45) {
                _castleVisuals.castleScale = 0; _castleVisuals.applyScale(0);
                var am:AudioManager = getAudioManager(); if (am) { am.playSfx("castleDestroyed"); am.stopRepeatingSfx(); }
                return { destroyed: true, type: "castle" };
            }
            return { destroyed: false };
        }
        
        private function getCastleInfo():Object {
            if (!_castleVisuals || !_castleVisuals.isLoaded) return null;
            var bmp:Bitmap = _castleVisuals.mainCastleBitmap;
            return { x: _castleVisuals.castleX, y: _castleVisuals.castleY, scale: _castleVisuals.castleScale, halfWidth: bmp ? (bmp.width * _castleVisuals.castleScale) / 2 : 0, sprite: _castleVisuals.mainCastle };
        }
        
        private function syncLayering():void { var layers:Array = [_castleVisuals, _towerManager, _upgradeFX, _hordeManager, _gameButtons, _orbHUD, _pauseSystem]; for each (var c:* in layers) if (c && contains(c)) setChildIndex(c, numChildren - 1); }
        public function applySavedState(savedState:CastleState, castleScale:Number = NaN):void { _pendingSavedState = savedState; _pendingSavedCastleScale = castleScale; applySavedStateIfReady(); }
        
        private function applySavedStateIfReady():void {
            if (!_pendingSavedState || !_castleVisuals || !_castleVisuals.isLoaded) return;
            var state:CastleState = _pendingSavedState;
            var targetScale:Number = isNaN(_pendingSavedCastleScale) ? Math.max(0.7 + (state.mainCastleSizeLevel * 0.1), state.getMainCastleIntegrityScale()) : _pendingSavedCastleScale;
            _castleVisuals.castleScale = Math.max(0, targetScale); _castleVisuals.applyScale(_castleVisuals.castleScale); _castleVisuals.updatePosition();
            _towerManager.rebuildFromState(state); _orbHUD.reset();
            _orbHUD.setCharge(state.winStreak % ORB_COUNT, false);
            _pendingSavedState = null; _pendingSavedCastleScale = NaN;
        }
        
        public function processUpgradeResult(result:ProgressionResult):void {
            var am:AudioManager = getAudioManager();
            if (!result.wasCorrect) {
                updateOrbFromResult(result);
                if (am) am.playSfx("castleShrink");
                if (result.upgradeType == ProgressionResult.SHRINK_MAIN_CASTLE) {
                    var integ:Number = _progressionManager.state.getMainCastleIntegrityScale();
                    var prev:Number = _castleVisuals.castleScale;
                    if (integ >= prev) integ = prev * 0.92;
                    _castleVisuals.castleScale = Math.max(integ, 0);
                    _castleVisuals.animateShrinkScale(prev, _castleVisuals.castleScale, function():void { _castleVisuals.updatePosition(); _towerManager.repositionAll(); });
                } else if (result.upgradeType == ProgressionResult.SHRINK_TOWER) {
                    _towerManager.shrinkTower(result.damagedTowerId, result.targetSizeStage);
                } else if (result.upgradeType == ProgressionResult.REMOVE_TOWER) {
                    _towerManager.removeTower(result.removedTowerId || result.damagedTowerId);
                }
                return;
            }
            updateOrbFromResult(result);
            if (result.upgradeType == ProgressionResult.UPGRADE_NEW_TOWER && result.newTower) _towerManager.addNewTower(result.newTower);
            var hasTowers:Boolean = _progressionManager.state.hasTowers;
            if (hasTowers && result.upgradeType != ProgressionResult.UPGRADE_NEW_TOWER) {
                var tid:String = result.healedTowerId || "";
                if (tid == "") { var n:AdditionTower = _progressionManager.state.getNewestTower(); if (n) tid = n.id; }
                if (tid != "") _towerManager.repairTower(tid);
            } else if (!hasTowers) {
                var rs:Number = _progressionManager.state.getMainCastleIntegrityScale();
                if (rs > _castleVisuals.castleScale) { _castleVisuals.castleScale = rs; _castleVisuals.animatePopScale(_castleVisuals.castleScale - 0.08, rs); if (am) am.playSfx("castleUpgrade"); }
                var gs:Number = Math.min(0.7 + (_progressionManager.state.mainCastleSizeLevel * 0.1), 1.5);
                var fs:Number = Math.max(gs, _progressionManager.state.getMainCastleIntegrityScale());
                if (fs > _castleVisuals.castleScale) { _castleVisuals.castleScale = fs; _castleVisuals.animatePopScale(fs - 0.03, fs); if (am) am.playSfx("castleUpgrade"); }
                _castleVisuals.updatePosition(); _towerManager.repositionAll();
            }
            playUpgradeFX();
        }
        
        private function updateOrbFromResult(result:ProgressionResult):void {
            if (!result.wasCorrect) { _orbHUD.reset(); return; }
            if (result.upgradeType == ProgressionResult.UPGRADE_NEW_TOWER) { _orbHUD.showFullAndReset(); return; }
            _orbHUD.setCharge(_progressionManager.state.winStreak % ORB_COUNT, true);
        }
        
        private function playUpgradeFX():void { if (!_upgradeFX || !_castleVisuals) return; var h:Number = _castleVisuals.mainCastleBitmap ? (_castleVisuals.mainCastleBitmap.height * _castleVisuals.castleScale) : 300; _upgradeFX.playRiseEffect(_castleVisuals.castleX, _castleVisuals.castleY - (h * 0.55)); }
        
        private function saveGameState():void {
            var ss:SaveSystem = SaveSystem.getInstance();
            ss.data.castleState = _progressionManager.state.toObject(); ss.data.castleScale = _castleVisuals.castleScale;
            ss.data.currentDifficulty = _progressionManager.state.difficultyRank; ss.data.currentMode = _progressionManager.state.mode;
            if (ss.saveState()) _pauseSystem.showSaveNotification();
        }
        
        public function setUpgradeButtonVisible(v:Boolean):void { _gameButtons.setUpgradeVisible(v); }
        public function setUpgradeButtonEnabled(e:Boolean):void { _gameButtons.setUpgradeEnabled(e); _isUpgradePopupOpen = !e; if (_isUpgradePopupOpen) { if (_hordeManager) _hordeManager.pauseCountdown(); } else { if (_hordeManager) _hordeManager.resumeCountdown(); } }
        public function resetHordeTimer():void { if (_hordeManager) _hordeManager.resetTimer(); }
        public function showPausePopup():void { if (_pauseSystem) _pauseSystem.show(); }
        public function hidePausePopup():void { if (_pauseSystem) _pauseSystem.hide(); }
        public function get isPaused():Boolean { return _pauseSystem ? _pauseSystem.isPaused : false; }
        public function getCastleCenter():Object { if (_castleVisuals && _castleVisuals.isLoaded) { var h:Number = _castleVisuals.mainCastleBitmap.height * _castleVisuals.castleScale; return { x: _castleVisuals.castleX, y: _castleVisuals.castleY - h / 2 }; } return { x: _stageWidth / 2, y: _stageHeight / 2 }; }
        public function getTowerCastle():TowerCastle { return _towerCastle; }
        
        public function resetCastle():void { _castleVisuals.castleScale = 1.0; _castleVisuals.stopCastlePopAnimation(); _castleVisuals.applyScale(1.0); _upgradeFX.clear(); _towerManager.clearAll(); _progressionManager.reset(); _orbHUD.reset(); _hordeManager.endHordeAttack(); _hordeManager.resetTimer(); }
        
        public function processUpgrade(streak:int):void { var prev:Number = _castleVisuals.castleScale; _castleVisuals.castleScale = Math.min(0.7 + (streak * 0.03), 1.0); if (Math.abs(_castleVisuals.castleScale - prev) >= 0.001) _castleVisuals.animatePopScale(prev, _castleVisuals.castleScale); playUpgradeFX(); _castleVisuals.updatePosition(); _towerManager.repositionAll(); }
        
        public function processWrong():void {}
        public function removeSideTower():Boolean { if (_towerManager.towerCount > 0) { _towerManager.clearAll(); return true; } return false; }
        public function hasSideTowers():Boolean { return _towerManager.hasTowers; }
        public function clearAllTowers():void { _towerManager.clearAll(); }
        public function getCurrentStreak():int { return _towerCastle ? _towerCastle.getCurrentStreak() : 0; }
        public function enlargeRandomBlock():Boolean { return false; }
        public function shrinkRandomBlock():Boolean { return true; }
        public function addNewBlock():Object { return null; }
        public function removeRandomBlock():Boolean { return false; }
        public function getBlockCount():int { return _towerCastle ? _towerCastle.getTowerCount() : 0; }
        
        public function onResize(stageWidth:Number, stageHeight:Number):void { _stageWidth = stageWidth; _stageHeight = stageHeight; if (_backgroundBitmap) { _backgroundBitmap.width = _stageWidth; _backgroundBitmap.height = _stageHeight; } if (_castleVisuals) _castleVisuals.onResize(_stageWidth, _stageHeight); if (_towerManager) _towerManager.repositionAll(); if (_pauseSystem) _pauseSystem.onResize(_stageWidth, _stageHeight); if (_orbHUD) _orbHUD.onResize(_stageWidth); if (_gameButtons) _gameButtons.onResize(_stageWidth, _stageHeight); syncLayering(); }
        private function getAudioManager():AudioManager { try { return ServiceLocator.get("AudioManager") as AudioManager; } catch (e:Error) {} return null; }
        public function get stageWidth():Number { return _stageWidth; }
        public function get stageHeight():Number { return _stageHeight; }
    }
}
