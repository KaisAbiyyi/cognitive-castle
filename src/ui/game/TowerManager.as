package ui.game {
    
    import flash.display.Sprite;
    import flash.events.Event;
    import castle.AdditionTower;
    import castle.CastleState;
    import castle.TowerAddition;
    import game.ProgressionManager;
    import services.AudioManager;
    import core.ServiceLocator;
    
    /**
     * TowerManager - Manages tower additions (add, remove, position, layer).
     */
    public class TowerManager extends Sprite {
        private static const DEBUG:Boolean = true;
        private var _towerAdditions:Vector.<TowerAddition>;
        private var _towerContainer:Sprite;
        private var _progressionManager:ProgressionManager;
        private var _getCastleInfo:Function;
        
        public function TowerManager() { _towerAdditions = new Vector.<TowerAddition>(); _progressionManager = ProgressionManager.getInstance(); }
        public function initialize(getCastleInfo:Function):void { _getCastleInfo = getCastleInfo; }
        
        public function addNewTower(modelTower:AdditionTower, onComplete:Function = null):void {
            if (!modelTower) return;
            var batch:int = modelTower.createdAtIndex;
            var side:String = modelTower.side ? modelTower.side.toLowerCase() : "left";
            var initialScale:Number = modelTower.getScale();
            var maxScale:Number = (!isNaN(modelTower.maxScale) && modelTower.maxScale > 0) ? modelTower.maxScale : AdditionTower.getMaxScaleForCreatedIndex(batch);
            
            var tower:TowerAddition = new TowerAddition(batch, side, initialScale, maxScale, modelTower.id, modelTower.imageUrl);
            tower.addEventListener(Event.COMPLETE, function(e:Event):void { positionTower(tower); updateLayering(); tower.playPopupAnimation(); if (onComplete != null) onComplete(tower); });
            _towerAdditions.push(tower); ensureContainer(); _towerContainer.addChild(tower);
            playAudio("castleSpawn");
            if (DEBUG) trace("[TowerManager] Added tower: " + modelTower.id + ", batch=" + batch);
        }
        
        public function rebuildFromState(state:CastleState):void {
            clearAll();
            if (!state || !state.towerCastle || state.towerCastle.length == 0) return;
            ensureContainer();
            for each (var modelTower:AdditionTower in state.towerCastle) addTowerFromState(modelTower);
            updateLayering(); repositionAll();
        }
        
        private function addTowerFromState(modelTower:AdditionTower):void {
            if (!modelTower) return;
            var batch:int = modelTower.createdAtIndex;
            var side:String = modelTower.side ? modelTower.side.toLowerCase() : "left";
            var targetScale:Number = modelTower.getScale();
            var maxScale:Number = (!isNaN(modelTower.maxScale) && modelTower.maxScale > 0) ? modelTower.maxScale : AdditionTower.getMaxScaleForCreatedIndex(batch);
            var tower:TowerAddition = new TowerAddition(batch, side, targetScale, maxScale, modelTower.id, modelTower.imageUrl);
            tower.addEventListener(Event.COMPLETE, function(e:Event):void { tower.alpha = 1; tower.applyScale(targetScale); positionTower(tower); repositionAll(); });
            _towerAdditions.push(tower); _towerContainer.addChild(tower);
        }
        
        private function ensureContainer():void { if (!_towerContainer) _towerContainer = new Sprite(); if (!contains(_towerContainer)) addChild(_towerContainer); }
        
        public function repairTower(towerId:String):void {
            var stateTower:AdditionTower = _progressionManager.state.getTowerById(towerId);
            if (!stateTower) return;
            var targetScale:Number = stateTower.getScale();
            var visualTower:TowerAddition = findById(stateTower.id);
            if (!visualTower) return;
            var previousScale:Number = visualTower.scaleX;
            if (targetScale <= previousScale + 0.001) { visualTower.pulse(0.06, 260, function():void { positionTower(visualTower); repositionAll(); }); return; }
            playAudio("castleUpgrade");
            visualTower.scaleToTarget(targetScale, function():void { positionTower(visualTower); repositionAll(); });
            if (DEBUG) trace("[TowerManager] Tower " + towerId + " repaired to " + targetScale.toFixed(3));
        }
        
        public function shrinkTower(towerId:String, sizeStage:int):void {
            var stateTower:AdditionTower = _progressionManager.state.getTowerById(towerId);
            if (!stateTower) return;
            var targetScale:Number = stateTower.getScale();
            var visualTower:TowerAddition = findById(stateTower.id);
            if (!visualTower) return;
            var currentVisualScale:Number = visualTower.scaleX;
            if (targetScale >= currentVisualScale) targetScale = currentVisualScale * 0.85;
            visualTower.shrink(targetScale, function():void { positionTower(visualTower); repositionAll(); });
            if (DEBUG) trace("[TowerManager] Tower " + towerId + " shrunk to " + targetScale.toFixed(3));
        }
        
        public function removeTower(towerId:String, onComplete:Function = null):void {
            if (!towerId || towerId == "") return;
            var tower:TowerAddition = findById(towerId);
            if (!tower) return;
            tower.playRemovalAnimation(function():void {
                if (_towerContainer && _towerContainer.contains(tower)) _towerContainer.removeChild(tower);
                var index:int = _towerAdditions.indexOf(tower);
                if (index >= 0) _towerAdditions.splice(index, 1);
                tower.dispose(); repositionAll();
                if (onComplete != null) onComplete();
                if (DEBUG) trace("[TowerManager] Tower " + towerId + " removed");
            });
            playAudio("castleDestroyed");
        }
        
        public function findById(towerId:String):TowerAddition {
            if (!towerId || towerId == "") return null;
            for each (var tower:TowerAddition in _towerAdditions) if (tower.towerId == towerId) return tower;
            return null;
        }
        
        public function findNewest():TowerAddition {
            if (!_towerAdditions || _towerAdditions.length == 0) return null;
            if (_progressionManager && _progressionManager.state) {
                var stateTower:AdditionTower = _progressionManager.state.getNewestTower();
                if (stateTower) { var visual:TowerAddition = findById(stateTower.id); if (visual) return visual; }
            }
            var newest:TowerAddition = null, highestBatch:int = 0;
            for each (var tower:TowerAddition in _towerAdditions) if (tower.batch > highestBatch) { highestBatch = tower.batch; newest = tower; }
            return newest;
        }
        
        private function positionTower(tower:TowerAddition):void {
            var castleInfo:Object = null;
            if (_getCastleInfo != null) castleInfo = _getCastleInfo();
            if (!castleInfo || !tower) return;
            var anchorX:Number = castleInfo.x, anchorY:Number = castleInfo.y, anchorHalfWidth:Number = castleInfo.halfWidth;
            if (_progressionManager && _progressionManager.state && tower.towerId && tower.towerId.length > 0) {
                var state:CastleState = _progressionManager.state;
                var sideLower:String = tower.side;
                var stateTower:AdditionTower = state.getTowerById(tower.towerId);
                if (stateTower) sideLower = (stateTower.side == CastleState.SIDE_RIGHT) ? "right" : "left";
                var chain:Vector.<String> = (sideLower == "right") ? state.rightTowers : state.leftTowers;
                if (chain && chain.length > 0) {
                    var index:int = chain.indexOf(tower.towerId);
                    if (index > 0) {
                        var prevTower:TowerAddition = findById(chain[index - 1]);
                        if (prevTower) { anchorX = prevTower.x; anchorY = prevTower.y; anchorHalfWidth = prevTower.getHalfWidth(); }
                    }
                }
            }
            tower.positionAtEdge(anchorX, anchorY, anchorHalfWidth, -40);
        }
        
        public function repositionAll():void {
            var ordered:Vector.<TowerAddition> = new Vector.<TowerAddition>();
            if (_progressionManager && _progressionManager.state) {
                var state:CastleState = _progressionManager.state;
                for each (var leftId:String in state.leftTowers) { var lt:TowerAddition = findById(leftId); if (lt) ordered.push(lt); }
                for each (var rightId:String in state.rightTowers) { var rt:TowerAddition = findById(rightId); if (rt) ordered.push(rt); }
            }
            if (ordered.length == 0) { ordered = _towerAdditions.slice(); ordered.sort(function(a:TowerAddition, b:TowerAddition):int { return a.batch - b.batch; }); }
            for each (var tower:TowerAddition in ordered) if (tower.isLoaded) positionTower(tower);
            updateLayering();
        }
        
        private function updateLayering():void {
            if (!_towerContainer) return;
            var depthById:Object = getTowerDepthMap();
            var sorted:Vector.<TowerAddition> = _towerAdditions.slice();
            sorted.sort(function(a:TowerAddition, b:TowerAddition):int {
                var depthA:int = depthById.hasOwnProperty(a.towerId) ? depthById[a.towerId] : 0;
                var depthB:int = depthById.hasOwnProperty(b.towerId) ? depthById[b.towerId] : 0;
                return (depthA != depthB) ? depthB - depthA : b.batch - a.batch;
            });
            for (var i:int = 0; i < sorted.length; i++) if (_towerContainer.contains(sorted[i])) _towerContainer.setChildIndex(sorted[i], i);
        }
        
        private function getTowerDepthMap():Object {
            var depth:Object = {};
            if (!_progressionManager || !_progressionManager.state) return depth;
            var state:CastleState = _progressionManager.state;
            for (var i:int = 0; i < state.leftTowers.length; i++) depth[state.leftTowers[i]] = i + 1;
            for (var j:int = 0; j < state.rightTowers.length; j++) depth[state.rightTowers[j]] = j + 1;
            return depth;
        }
        
        public function clearAll():void {
            for each (var tower:TowerAddition in _towerAdditions) { if (tower.parent) tower.parent.removeChild(tower); tower.dispose(); }
            _towerAdditions = new Vector.<TowerAddition>();
        }
        
        private function playAudio(sfx:String):void { try { var am:AudioManager = ServiceLocator.get("AudioManager") as AudioManager; if (am) am.playSfx(sfx); } catch (e:Error) {} }
        
        public function get towerContainer():Sprite { return _towerContainer; }
        public function get towerCount():int { return _towerAdditions.length; }
        public function get hasTowers():Boolean { return _towerAdditions.length > 0; }
        public function get towers():Vector.<TowerAddition> { return _towerAdditions; }
        public function dispose():void { clearAll(); }
    }
}
