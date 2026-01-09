package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.DisplayObject;
    import flash.geom.Rectangle;
    
    /**
     * ScreenContainer - Maintains 16:9 aspect ratio with black borders
     * Ensures all game content stays within bounds
     */
    public class ScreenContainer extends Sprite {
        
        // Target aspect ratio: 16:9
        private static const ASPECT_RATIO:Number = 16 / 9;
        private static const BORDER_SIZE:int = 4; // Black border thickness
        
        private var _gameArea:Sprite;
        private var _topBorder:Shape;
        private var _bottomBorder:Shape;
        private var _leftBorder:Shape;
        private var _rightBorder:Shape;
        private var _letterboxTop:Shape;
        private var _letterboxBottom:Shape;
        private var _letterboxLeft:Shape;
        private var _letterboxRight:Shape;
        
        private var _stageWidth:Number = 800;
        private var _stageHeight:Number = 600;
        private var _gameWidth:Number = 800;
        private var _gameHeight:Number = 450;
        private var _offsetX:Number = 0;
        private var _offsetY:Number = 0;
        
        public function ScreenContainer() {
            super();
            createGameArea();
            createBorders();
            createLetterbox();
        }
        
        private function createGameArea():void {
            _gameArea = new Sprite();
            addChild(_gameArea);
        }
        
        private function createBorders():void {
            _topBorder = new Shape();
            _bottomBorder = new Shape();
            _leftBorder = new Shape();
            _rightBorder = new Shape();
            
            addChild(_topBorder);
            addChild(_bottomBorder);
            addChild(_leftBorder);
            addChild(_rightBorder);
        }
        
        private function createLetterbox():void {
            _letterboxTop = new Shape();
            _letterboxBottom = new Shape();
            _letterboxLeft = new Shape();
            _letterboxRight = new Shape();
            
            addChild(_letterboxTop);
            addChild(_letterboxBottom);
            addChild(_letterboxLeft);
            addChild(_letterboxRight);
        }
        
        /**
         * Initialize with stage dimensions
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            calculateGameArea();
            updateLayout();
        }
        
        private function calculateGameArea():void {
            var currentRatio:Number = _stageWidth / _stageHeight;
            
            if (currentRatio > ASPECT_RATIO) {
                // Stage is wider than 16:9 - add pillarboxing (side bars)
                _gameHeight = _stageHeight - (BORDER_SIZE * 2);
                _gameWidth = _gameHeight * ASPECT_RATIO;
                _offsetX = (_stageWidth - _gameWidth) / 2;
                _offsetY = BORDER_SIZE;
            } else if (currentRatio < ASPECT_RATIO) {
                // Stage is taller than 16:9 - add letterboxing (top/bottom bars)
                _gameWidth = _stageWidth - (BORDER_SIZE * 2);
                _gameHeight = _gameWidth / ASPECT_RATIO;
                _offsetX = BORDER_SIZE;
                _offsetY = (_stageHeight - _gameHeight) / 2;
            } else {
                // Perfect 16:9
                _gameWidth = _stageWidth - (BORDER_SIZE * 2);
                _gameHeight = _stageHeight - (BORDER_SIZE * 2);
                _offsetX = BORDER_SIZE;
                _offsetY = BORDER_SIZE;
            }
        }
        
        private function updateLayout():void {
            // Position game area
            _gameArea.x = _offsetX;
            _gameArea.y = _offsetY;
            
            // Apply mask to clip content within game area
            var maskShape:Shape = new Shape();
            maskShape.graphics.beginFill(0xFF0000);
            maskShape.graphics.drawRect(0, 0, _gameWidth, _gameHeight);
            maskShape.graphics.endFill();
            maskShape.x = _offsetX;
            maskShape.y = _offsetY;
            addChild(maskShape);
            _gameArea.mask = maskShape;
            
            // Draw inner borders (around game area)
            drawBorder(_topBorder, _offsetX - BORDER_SIZE, _offsetY - BORDER_SIZE, _gameWidth + (BORDER_SIZE * 2), BORDER_SIZE);
            drawBorder(_bottomBorder, _offsetX - BORDER_SIZE, _offsetY + _gameHeight, _gameWidth + (BORDER_SIZE * 2), BORDER_SIZE);
            drawBorder(_leftBorder, _offsetX - BORDER_SIZE, _offsetY, BORDER_SIZE, _gameHeight);
            drawBorder(_rightBorder, _offsetX + _gameWidth, _offsetY, BORDER_SIZE, _gameHeight);
            
            // Draw letterbox/pillarbox areas (fill remaining space with black)
            var lb:Shape;
            
            // Top letterbox
            if (_offsetY > BORDER_SIZE) {
                drawLetterbox(_letterboxTop, 0, 0, _stageWidth, _offsetY - BORDER_SIZE);
            } else {
                clearShape(_letterboxTop);
            }
            
            // Bottom letterbox
            if (_offsetY > BORDER_SIZE) {
                drawLetterbox(_letterboxBottom, 0, _offsetY + _gameHeight + BORDER_SIZE, _stageWidth, _stageHeight - (_offsetY + _gameHeight + BORDER_SIZE));
            } else {
                clearShape(_letterboxBottom);
            }
            
            // Left pillarbox
            if (_offsetX > BORDER_SIZE) {
                drawLetterbox(_letterboxLeft, 0, 0, _offsetX - BORDER_SIZE, _stageHeight);
            } else {
                clearShape(_letterboxLeft);
            }
            
            // Right pillarbox
            if (_offsetX > BORDER_SIZE) {
                drawLetterbox(_letterboxRight, _offsetX + _gameWidth + BORDER_SIZE, 0, _stageWidth - (_offsetX + _gameWidth + BORDER_SIZE), _stageHeight);
            } else {
                clearShape(_letterboxRight);
            }
        }
        
        private function drawBorder(shape:Shape, x:Number, y:Number, w:Number, h:Number):void {
            shape.graphics.clear();
            shape.graphics.beginFill(0x000000, 1);
            shape.graphics.drawRect(x, y, w, h);
            shape.graphics.endFill();
        }
        
        private function drawLetterbox(shape:Shape, x:Number, y:Number, w:Number, h:Number):void {
            shape.graphics.clear();
            if (w > 0 && h > 0) {
                shape.graphics.beginFill(0x000000, 1);
                shape.graphics.drawRect(x, y, w, h);
                shape.graphics.endFill();
            }
        }
        
        private function clearShape(shape:Shape):void {
            shape.graphics.clear();
        }
        
        /**
         * Add a child to the game area (clipped)
         */
        public function addToGameArea(child:DisplayObject):DisplayObject {
            return _gameArea.addChild(child);
        }
        
        /**
         * Remove a child from game area
         */
        public function removeFromGameArea(child:DisplayObject):DisplayObject {
            if (_gameArea.contains(child)) {
                return _gameArea.removeChild(child);
            }
            return null;
        }
        
        /**
         * Check if game area contains child
         */
        public function gameAreaContains(child:DisplayObject):Boolean {
            return _gameArea.contains(child);
        }
        
        /**
         * Get game area sprite for direct access
         */
        public function get gameArea():Sprite {
            return _gameArea;
        }
        
        /**
         * Get the calculated game dimensions
         */
        public function get gameWidth():Number {
            return _gameWidth;
        }
        
        public function get gameHeight():Number {
            return _gameHeight;
        }
        
        public function get gameOffsetX():Number {
            return _offsetX;
        }
        
        public function get gameOffsetY():Number {
            return _offsetY;
        }
        
        /**
         * Handle resize
         */
        public function onResize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            // Remove old mask
            if (_gameArea.mask) {
                if (contains(_gameArea.mask as Shape)) {
                    removeChild(_gameArea.mask as Shape);
                }
                _gameArea.mask = null;
            }
            
            calculateGameArea();
            updateLayout();
        }
        
        /**
         * Bring borders to front (call after adding children)
         */
        public function bringBordersToFront():void {
            if (contains(_topBorder)) setChildIndex(_topBorder, numChildren - 1);
            if (contains(_bottomBorder)) setChildIndex(_bottomBorder, numChildren - 1);
            if (contains(_leftBorder)) setChildIndex(_leftBorder, numChildren - 1);
            if (contains(_rightBorder)) setChildIndex(_rightBorder, numChildren - 1);
            if (contains(_letterboxTop)) setChildIndex(_letterboxTop, numChildren - 1);
            if (contains(_letterboxBottom)) setChildIndex(_letterboxBottom, numChildren - 1);
            if (contains(_letterboxLeft)) setChildIndex(_letterboxLeft, numChildren - 1);
            if (contains(_letterboxRight)) setChildIndex(_letterboxRight, numChildren - 1);
        }
    }
}
