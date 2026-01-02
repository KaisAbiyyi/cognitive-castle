package ui.game {
    
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.geom.Rectangle;
    import castle.AdditionTower;
    import castle.CastleState;
    import castle.TowerAddition;
    import game.ProgressionManager;
    import services.AudioManager;
    import core.ServiceLocator;
    
    /**
     * HordeManager - Handles horde attacks, movement, and damage. Delegates dust/shadow to sub-components.
     */
    public class HordeManager extends Sprite {
        
        private static const DEBUG:Boolean = true;
        private static const HORDE_MIN_DELAY_MS:Number = 120000;
        private static const HORDE_MAX_DELAY_MS:Number = 180000;
        
        private var _horde:Sprite;
        private var _hordeBitmap:Bitmap;
        private var _hordeDust:HordeDust;
        private var _hordeShadow:HordeShadow;
        private var _hordeTimer:Timer;
        private var _hordeShrinkTimer:Timer;
        private var _hordeDueAtMs:Number = 0;
        private var _hordeRemainingMs:Number = 0;
        private var _hordeAttackActive:Boolean = false;
        private var _hordeForceRetreat:Boolean = false;
        private var _hordeFromRight:Boolean = false;
        private var _hordeTargetTower:TowerAddition = null;
        
        private var _hordeDamagePerSecond:Number = 0.04;
        private var _hordeAttackDuration:Number = 2500;
        private var _hordeCastleOverlapPx:Number = 30;
        private var _hordeDamageStepIntervalMs:Number = 180;
        private var _hordeDamageStepAccumMs:Number = 0;
        
        private var _onDamageStep:Function;
        private var _getCastleInfo:Function;
        private var _findNewestTower:Function;
        private var _getShadowLayer:Function;
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        private var _progressionManager:ProgressionManager;
        
        public function HordeManager() {
            _hordeDust = new HordeDust();
            _hordeShadow = new HordeShadow();
            _progressionManager = ProgressionManager.getInstance();
        }
        
        public function initialize(stageW:Number, stageH:Number, callbacks:Object):void {
            _stageWidth = stageW;
            _stageHeight = stageH;
            _onDamageStep = callbacks.onDamageStep;
            _getCastleInfo = callbacks.getCastleInfo;
            _findNewestTower = callbacks.findNewestTower;
            _getShadowLayer = callbacks.getShadowLayer;
        }
        
        public function startRandomHordeTimer():void {
            _hordeRemainingMs = HORDE_MIN_DELAY_MS + Math.random() * (HORDE_MAX_DELAY_MS - HORDE_MIN_DELAY_MS);
            startHordeCountdown(_hordeRemainingMs);
        }
        
        public function forceHordeAttack():void {
            if (_hordeAttackActive) return;
            disposeHordeTimer();
            triggerHordeAttack();
            startRandomHordeTimer();
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
            if (_hordeTimer) { _hordeTimer.stop(); _hordeTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onHordeAttackTrigger); _hordeTimer = null; }
        }
        
        public function pauseCountdown():void {
            if (_hordeTimer && _hordeTimer.running) { var now:Number = new Date().time; _hordeRemainingMs = Math.max(1, _hordeDueAtMs - now); }
            _hordeDueAtMs = 0; disposeHordeTimer();
        }
        
        public function resumeCountdown():void {
            if (_hordeTimer && _hordeTimer.running) return;
            if (_hordeRemainingMs <= 0) _hordeRemainingMs = HORDE_MIN_DELAY_MS + Math.random() * (HORDE_MAX_DELAY_MS - HORDE_MIN_DELAY_MS);
            startHordeCountdown(_hordeRemainingMs);
        }
        
        public function resetTimer():void { startRandomHordeTimer(); }
        
        private function onHordeAttackTrigger(e:TimerEvent):void {
            _hordeRemainingMs = 0; _hordeDueAtMs = 0;
            var castleInfo:Object = null;
            if (_getCastleInfo != null) castleInfo = _getCastleInfo();
            if (castleInfo && castleInfo.scale > 0.1) triggerHordeAttack();
            startRandomHordeTimer();
        }
        
        private function triggerHordeAttack():void {
            if (_hordeAttackActive) return;
            _hordeAttackActive = true;
            _horde = new Sprite();
            addChild(_horde);
            if (!contains(_hordeDust)) addChild(_hordeDust);
            _hordeDust.clear();
            _hordeShadow.clear();
            
            var fromRight:Boolean = determineHordeDirection();
            _hordeFromRight = fromRight;
            if (_findNewestTower != null) _hordeTargetTower = _findNewestTower(); else _hordeTargetTower = null;
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                _hordeBitmap = Bitmap(e.target.content);
                _hordeBitmap.smoothing = true;
                var scale:Number = 100 / _hordeBitmap.height;
                _hordeBitmap.scaleX = scale; _hordeBitmap.scaleY = scale;
                _horde.addChild(_hordeBitmap);
                _hordeBitmap.x = -_hordeBitmap.width / 2;
                _hordeBitmap.y = -_hordeBitmap.height / 2;
                
                var halfWidth:Number = _hordeBitmap.width / 2;
                var pad:Number = 100;
                _horde.x = fromRight ? _stageWidth + halfWidth + pad : -halfWidth - pad;
                _horde.scaleX = fromRight ? 1 : -1;
                
                    var castleInfo:Object = null;
                    if (_getCastleInfo != null) castleInfo = _getCastleInfo();
                var desiredTop:Number = (castleInfo ? castleInfo.y : _stageHeight / 2) - 80;
                _horde.y = desiredTop + _hordeBitmap.height / 2;
                
                var shadowLayer:Sprite = null;
                if (_getShadowLayer != null) shadowLayer = _getShadowLayer();
                if (shadowLayer) _hordeShadow.create(_hordeBitmap, shadowLayer);
                startHordeMovement(fromRight);
                if (DEBUG) trace("[HordeManager] Horde attack from " + (fromRight ? "right" : "left"));
            });
            loader.load(new URLRequest("assets/images/Game/horde.png"));
        }
        
        private function determineHordeDirection():Boolean {
            if (_progressionManager && _progressionManager.state) {
                var stateTower:AdditionTower = _progressionManager.state.getNewestTower();
                if (stateTower) return stateTower.side == CastleState.SIDE_RIGHT;
            }
            return Math.random() > 0.5;
        }
        
        private function startHordeMovement(fromRight:Boolean):void {
            var duration:Number = 3000;
            var startTime:Number = new Date().getTime();
            var startX:Number = _horde.x;
            var castleInfo:Object = null;
            if (_getCastleInfo != null) castleInfo = _getCastleInfo();
            var targetX:Number = castleInfo ? castleInfo.x : _stageWidth / 2;
            var phase:String = "approach";
            var damageStartTime:Number = 0, retreatStartTime:Number = 0;
            var audioManager:AudioManager = getAudioManager();
            var frameMs:Number = 33;
            
            var moveTimer:Timer = new Timer(frameMs);
            moveTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
                if (!_hordeAttackActive || !_horde) { moveTimer.stop(); return; }
                
                var hordeBounds:Rectangle = _horde.getBounds(parent);
                _hordeDust.tick(frameMs, hordeBounds, fromRight, phase == "approach");
                
                if (_hordeForceRetreat && phase != "retreating") {
                    _hordeForceRetreat = false; phase = "retreating";
                    retreatStartTime = new Date().getTime();
                    if (_horde) _horde.scaleX *= -1;
                    if (_hordeShrinkTimer) _hordeShrinkTimer.stop();
                    if (audioManager) audioManager.stopRepeatingSfx();
                }
                
                if (phase == "approach") {
                    var elapsed:Number = new Date().getTime() - startTime;
                    var progress:Number = Math.min(elapsed / duration, 1.0);
                    _horde.x = startX + (targetX - startX) * progress;
                    if (checkHordeCastleCollision(fromRight)) { phase = "damaging"; damageStartTime = new Date().getTime(); startHordeDamage(); }
                } else if (phase == "damaging") {
                    if (new Date().getTime() - damageStartTime >= _hordeAttackDuration) {
                        phase = "retreating"; retreatStartTime = new Date().getTime();
                        if (_horde) _horde.scaleX *= -1;
                        if (_hordeShrinkTimer) _hordeShrinkTimer.stop();
                        if (audioManager) audioManager.stopRepeatingSfx();
                    }
                } else if (phase == "retreating") {
                    var retreatProgress:Number = Math.min((new Date().getTime() - retreatStartTime) / 2000, 1.0);
                    var halfW:Number = _hordeBitmap ? _hordeBitmap.width / 2 : 0;
                    var retreatTargetX:Number = fromRight ? _stageWidth + halfW + 100 : -halfW - 100;
                    _horde.x = _horde.x + (retreatTargetX - _horde.x) * retreatProgress;
                    if (retreatProgress >= 1.0) { endHordeAttack(); moveTimer.stop(); }
                }
                
                if (_hordeBitmap && _horde) {
                    var bounds:Rectangle = _hordeBitmap.getBounds(parent);
                    _hordeShadow.update(bounds, _hordeBitmap.scaleX * _horde.scaleX, _hordeBitmap.scaleY * _horde.scaleY);
                }
            });
            moveTimer.start();
        }
        
        private function checkHordeCastleCollision(fromRight:Boolean):Boolean {
            if (!_horde) return false;
            var hordeBounds:Rectangle = _horde.getBounds(this.parent);
            var targetBounds:Rectangle;
            if (_hordeTargetTower && _hordeTargetTower.isLoaded) targetBounds = _hordeTargetTower.getBounds(this.parent);
            else {
                var castleInfo:Object = null;
                if (_getCastleInfo != null) castleInfo = _getCastleInfo();
                if (castleInfo && castleInfo.sprite) targetBounds = castleInfo.sprite.getBounds(this.parent);
                else return false;
            }
            
            if (!(hordeBounds.bottom >= targetBounds.top && hordeBounds.top <= targetBounds.bottom)) return false;
            
            var isColliding:Boolean;
            if (fromRight) { var desiredLeft:Number = targetBounds.right - _hordeCastleOverlapPx; isColliding = hordeBounds.left <= desiredLeft; if (isColliding) _horde.x += desiredLeft - hordeBounds.left; }
            else { var desiredRight:Number = targetBounds.left + _hordeCastleOverlapPx; isColliding = hordeBounds.right >= desiredRight; if (isColliding) _horde.x += desiredRight - hordeBounds.right; }
            return isColliding;
        }
        
        private function startHordeDamage():void {
            if (_hordeShrinkTimer) { _hordeShrinkTimer.stop(); _hordeShrinkTimer.removeEventListener(TimerEvent.TIMER, onHordeShrinkTick); }
            _hordeDamageStepAccumMs = 0;
            applyHordeDamageStep();
            _hordeShrinkTimer = new Timer(33);
            _hordeShrinkTimer.addEventListener(TimerEvent.TIMER, onHordeShrinkTick);
            _hordeShrinkTimer.start();
            var am:AudioManager = getAudioManager();
            if (am) am.startRepeatingSfx("enemyAttacking");
        }
        
        private function onHordeShrinkTick(e:TimerEvent):void {
            if (!_hordeAttackActive) { if (_hordeShrinkTimer) _hordeShrinkTimer.stop(); return; }
            _hordeDamageStepAccumMs += 33;
            while (_hordeDamageStepAccumMs >= _hordeDamageStepIntervalMs) { _hordeDamageStepAccumMs -= _hordeDamageStepIntervalMs; applyHordeDamageStep(); }
        }
        
        private function applyHordeDamageStep():void {
            var stepDamage:Number = _hordeDamagePerSecond * (_hordeDamageStepIntervalMs / 1000);
            if (_onDamageStep != null) {
                var result:Object = _onDamageStep(stepDamage, _hordeTargetTower);
                if (result && result.destroyed) {
                    if (result.type == "castle") { _hordeForceRetreat = true; if (_hordeShrinkTimer) _hordeShrinkTimer.stop(); }
                    else if (result.type == "tower") { if (_findNewestTower != null) _hordeTargetTower = _findNewestTower(); else _hordeTargetTower = null; }
                }
            }
        }
        
        public function forceRetreat():void { _hordeForceRetreat = true; }
        
        public function endHordeAttack():void {
            _hordeDust.clear();
            _hordeShadow.clear();
            if (_horde && _horde.parent) _horde.parent.removeChild(_horde);
            _hordeAttackActive = false; _hordeForceRetreat = false;
            var am:AudioManager = getAudioManager();
            if (am) am.stopRepeatingSfx();
            if (DEBUG) trace("[HordeManager] Horde attack ended");
        }
        
        private function getAudioManager():AudioManager { try { return ServiceLocator.get("AudioManager") as AudioManager; } catch (e:Error) {} return null; }
        
        public function get isActive():Boolean { return _hordeAttackActive; }
        public function get targetTower():TowerAddition { return _hordeTargetTower; }
        public function set targetTower(t:TowerAddition):void { _hordeTargetTower = t; }
        
        public function dispose():void { disposeHordeTimer(); if (_hordeShrinkTimer) { _hordeShrinkTimer.stop(); _hordeShrinkTimer = null; } endHordeAttack(); }
    }
}
