package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import castle.TowerCastle;
    
    /**
     * GameScreen - Main game screen with FULL WINDOW castle view and upgrade button.
     * Auto-resizing layout that adapts to any window size.
     * 
     * Layout:
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
        private var _windowFrame:Shape;
        private var _background:Shape;
        private var _towerCastle:TowerCastle;
        private var _upgradeButton:Sprite;
        private var _alertPopup:Sprite;
        private var _alertText:TextField;
        
        // State
        private var _isAlertVisible:Boolean = false;
        
        /**
         * Constructor
         */
        public function GameScreen() {
            // Nothing needed in constructor
        }
        
        /**
         * Initialize the screen
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            // Calculate responsive values
            updateResponsiveValues();
            
            createBackground();
            createWindowFrame();
            createBlockCastle();
            createUpgradeButton();
            createAlertPopup();
            
            if (DEBUG) {
                trace("[GameScreen] Initialized with size: " + stageWidth + "x" + stageHeight);
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
        }
        
        /**
         * Create background
         */
        private function createBackground():void {
            _background = new Shape();
            drawBackground();
            addChild(_background);
        }
        
        private function drawBackground():void {
            var g:* = _background.graphics;
            g.clear();
            g.beginFill(0xF5F5F5);
            g.drawRect(0, 0, _stageWidth, _stageHeight);
            g.endFill();
        }
        
        /**
         * Create window frame (black rounded border)
         */
        private function createWindowFrame():void {
            _windowFrame = new Shape();
            drawWindowFrame();
            addChild(_windowFrame);
        }
        
        private function drawWindowFrame():void {
            var g:* = _windowFrame.graphics;
            g.clear();
            
            var frameWidth:Number = _stageWidth - _margin * 2;
            var frameHeight:Number = _stageHeight - _margin * 2;
            var strokeWidth:Number = Math.max(4, 8 * Math.min(_stageWidth, _stageHeight) / 600);
            
            g.lineStyle(strokeWidth, 0x000000, 1);
            g.beginFill(0xFFFFFF);
            g.drawRoundRect(_margin, _margin, frameWidth, frameHeight, _cornerRadius, _cornerRadius);
            g.endFill();
        }
        
        /**
         * Create block castle - FULL WINDOW size
         */
        private function createBlockCastle():void {
            var castleWidth:Number = _stageWidth - _frameMargin * 2;
            var castleHeight:Number = _stageHeight - _frameMargin * 2 - _buttonSize - 20;
            
            _towerCastle = new TowerCastle(castleWidth, castleHeight);
            _towerCastle.x = _frameMargin;
            _towerCastle.y = _frameMargin;
            
            addChild(_towerCastle);
            
            if (DEBUG) {
                trace("[GameScreen] TowerCastle created: " + castleWidth + "x" + castleHeight);
            }
        }
        
        private function updateBlockCastle():void {
            if (!_towerCastle) return;
            
            var castleWidth:Number = _stageWidth - _frameMargin * 2;
            var castleHeight:Number = _stageHeight - _frameMargin * 2 - _buttonSize - 20;
            
            _towerCastle.resize(castleWidth, castleHeight);
            _towerCastle.x = _frameMargin;
            _towerCastle.y = _frameMargin;
        }
        
        /**
         * Create upgrade button (bottom left corner, circular with + icon)
         */
        private function createUpgradeButton():void {
            _upgradeButton = new Sprite();
            drawUpgradeButton();
            positionUpgradeButton();
            
            _upgradeButton.buttonMode = true;
            _upgradeButton.useHandCursor = true;
            _upgradeButton.addEventListener(MouseEvent.CLICK, onUpgradeClick);
            _upgradeButton.addEventListener(MouseEvent.ROLL_OVER, onUpgradeOver);
            _upgradeButton.addEventListener(MouseEvent.ROLL_OUT, onUpgradeOut);
            
            addChild(_upgradeButton);
        }
        
        private function drawUpgradeButton():void {
            var g:* = _upgradeButton.graphics;
            g.clear();
            
            var strokeWidth:Number = Math.max(2, 3 * _buttonSize / 50);
            
            // Background circle
            g.lineStyle(strokeWidth, 0x333333);
            g.beginFill(0xFFFFFF);
            g.drawCircle(_buttonSize / 2, _buttonSize / 2, _buttonSize / 2);
            g.endFill();
            
            // Draw plus icon
            var iconSize:Number = _buttonSize * 0.4;
            var centerX:Number = _buttonSize / 2;
            var centerY:Number = _buttonSize / 2;
            
            g.lineStyle(strokeWidth, 0x333333);
            // Horizontal line
            g.moveTo(centerX - iconSize / 2, centerY);
            g.lineTo(centerX + iconSize / 2, centerY);
            // Vertical line
            g.moveTo(centerX, centerY - iconSize / 2);
            g.lineTo(centerX, centerY + iconSize / 2);
            // Circle around
            g.lineStyle(strokeWidth * 0.7, 0x333333);
            g.drawCircle(centerX, centerY, iconSize / 2 + _buttonSize * 0.1);
        }
        
        private function positionUpgradeButton():void {
            _upgradeButton.x = _frameMargin;
            _upgradeButton.y = _stageHeight - _buttonSize - _frameMargin;
        }
        
        /**
         * Create alert popup for upgrades
         */
        private function createAlertPopup():void {
            _alertPopup = new Sprite();
            
            var popupWidth:Number = Math.max(120, 150 * Math.min(_stageWidth, _stageHeight) / 600);
            var popupHeight:Number = Math.max(30, 40 * Math.min(_stageWidth, _stageHeight) / 600);
            
            var g:* = _alertPopup.graphics;
            g.beginFill(0xE8E8E8);
            g.lineStyle(1, 0xCCCCCC);
            g.drawRoundRect(0, 0, popupWidth, popupHeight, 8, 8);
            g.endFill();
            
            // Create text
            _alertText = new TextField();
            var fontSize:Number = Math.max(10, 14 * Math.min(_stageWidth, _stageHeight) / 600);
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = fontSize;
            format.color = 0x666666;
            format.align = TextFormatAlign.CENTER;
            
            _alertText.defaultTextFormat = format;
            _alertText.width = popupWidth;
            _alertText.height = popupHeight;
            _alertText.y = (popupHeight - fontSize) / 2 - 2;
            _alertText.selectable = false;
            _alertText.text = "alert upgrade";
            
            _alertPopup.addChild(_alertText);
            
            // Position center
            positionAlertPopup();
            
            _alertPopup.visible = false;
            addChild(_alertPopup);
        }
        
        private function positionAlertPopup():void {
            if (!_alertPopup) return;
            _alertPopup.x = (_stageWidth - _alertPopup.width) / 2;
            _alertPopup.y = (_stageHeight - _alertPopup.height) / 2;
        }
        
        /**
         * Handle upgrade button click
         */
        private function onUpgradeClick(e:MouseEvent):void {
            if (DEBUG) {
                trace("[GameScreen] Upgrade button clicked");
            }
            dispatchEvent(new Event(UPGRADE_CLICKED));
        }
        
        /**
         * Handle upgrade button hover
         */
        private function onUpgradeOver(e:MouseEvent):void {
            _upgradeButton.scaleX = 1.1;
            _upgradeButton.scaleY = 1.1;
        }
        
        /**
         * Handle upgrade button out
         */
        private function onUpgradeOut(e:MouseEvent):void {
            _upgradeButton.scaleX = 1.0;
            _upgradeButton.scaleY = 1.0;
        }
        
        /**
         * Show upgrade alert
         */
        public function showUpgradeAlert(message:String = "Upgrade Available!"):void {
            _alertText.text = message;
            positionAlertPopup();
            _alertPopup.visible = true;
            _isAlertVisible = true;
        }
        
        /**
         * Hide upgrade alert
         */
        public function hideUpgradeAlert():void {
            _alertPopup.visible = false;
            _isAlertVisible = false;
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
            _upgradeButton.mouseEnabled = enabled;
            _upgradeButton.alpha = enabled ? 1.0 : 0.5;
        }
        
        /**
         * Get castle center position for effects
         */
        public function getCastleCenter():Object {
            if (_towerCastle) {
                var center:* = _towerCastle.getCenter();
                return {
                    x: _towerCastle.x + center.x,
                    y: _towerCastle.y + center.y
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
         * Process upgrade based on streak (1-11 system)
         */
        public function processUpgrade(streak:int):void {
            if (_towerCastle) {
                _towerCastle.processUpgrade(streak);
            }
        }
        
        /**
         * Process wrong answer
         */
        public function processWrong():void {
            if (_towerCastle) {
                _towerCastle.processWrong();
            }
        }
        
        /**
         * Remove a side tower (called when wrong 3x streak)
         * Returns true if a tower was removed
         */
        public function removeSideTower():Boolean {
            if (_towerCastle) {
                return _towerCastle.removeSideTower();
            }
            return false;
        }
        
        /**
         * Check if there are side towers to remove
         */
        public function hasSideTowers():Boolean {
            if (_towerCastle) {
                return _towerCastle.hasSideTowers();
            }
            return false;
        }
        
        /**
         * Reset castle
         */
        public function resetCastle():void {
            if (_towerCastle) {
                _towerCastle.reset();
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
            
            // Redraw all components
            drawBackground();
            drawWindowFrame();
            updateBlockCastle();
            
            // Redraw and reposition button
            drawUpgradeButton();
            positionUpgradeButton();
            
            // Reposition alert
            positionAlertPopup();
            
            if (DEBUG) {
                trace("[GameScreen] Resized to: " + stageWidth + "x" + stageHeight);
            }
        }
        
        // Getters
        public function get stageWidth():Number { return _stageWidth; }
        public function get stageHeight():Number { return _stageHeight; }
    }
}
