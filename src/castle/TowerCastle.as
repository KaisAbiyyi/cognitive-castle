package castle {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.events.Event;
    
    /**
     * TowerCastle - Tower-based castle visualization with upgrade system.
     * 
     * Upgrade Flow (based on correct streak 1-11):
     * Streak 1-2: Enlarge main tower (portrait, more height than width)
     * Streak 3: Add side tower (random left/right)
     * Streak 4-5: Enlarge first side tower (max ratio 2:1 height, 3:2 width vs main)
     * Streak 6: Add second side tower (opposite side)
     * Streak 7-8: Enlarge second side tower
     * Streak 9: Add roof triangles to all towers
     * Streak 10-11: Increase roof triangle heights
     * 
     * Each tower has max size to prevent exploit (intentional wrong answers to grow tower)
     */
    public class TowerCastle extends Sprite {
        
        // Debug
        private static const DEBUG:Boolean = true;
        
        // Tower settings
        private static const MAIN_TOWER_INITIAL_WIDTH:Number = 60;
        private static const MAIN_TOWER_INITIAL_HEIGHT:Number = 100;
        private static const MAIN_TOWER_MAX_WIDTH:Number = 120;
        private static const MAIN_TOWER_MAX_HEIGHT:Number = 250;
        
        private static const SIDE_TOWER_INITIAL_WIDTH:Number = 40;
        private static const SIDE_TOWER_INITIAL_HEIGHT:Number = 60;
        // Side tower max: 2:1 height ratio, 3:2 width ratio compared to main
        private static const SIDE_TOWER_MAX_HEIGHT_RATIO:Number = 0.5; // 50% of main tower height
        private static const SIDE_TOWER_MAX_WIDTH_RATIO:Number = 0.67; // 67% of main tower width
        
        private static const ROOF_INITIAL_HEIGHT:Number = 20;
        private static const ROOF_MAX_HEIGHT:Number = 60;
        
        private static const TOWER_GAP:Number = 10; // Gap between towers
        private static const GROW_AMOUNT_WIDTH:Number = 15;
        private static const GROW_AMOUNT_HEIGHT:Number = 25; // More height growth
        private static const ROOF_GROW_AMOUNT:Number = 15;
        
        // Animation settings
        private static const ANIMATION_SPEED:Number = 0.12;
        
        // Colors
        private static const MAIN_TOWER_COLOR:uint = 0x4A5568; // Gray-blue
        private static const SIDE_TOWER_COLOR:uint = 0x718096; // Lighter gray
        private static const ROOF_COLOR:uint = 0xC53030; // Red roof
        private static const OUTLINE_COLOR:uint = 0x2D3748; // Dark outline
        
        // Container
        private var _towersContainer:Sprite;
        
        // Tower data
        private var _mainTower:Object; // {shape, width, height, targetWidth, targetHeight, x, y}
        private var _leftTower:Object; // null until streak 3 or 6
        private var _rightTower:Object; // null until streak 3 or 6
        private var _firstSideTowerSide:String; // "left" or "right" - tracks which side first tower was added
        
        // Roof data
        private var _hasRoofs:Boolean = false;
        private var _roofHeight:Number = 0;
        private var _targetRoofHeight:Number = 0;
        private var _roofShapes:Array; // Array of Shape for roofs
        
        // View dimensions
        private var _viewWidth:Number;
        private var _viewHeight:Number;
        
        // Current upgrade streak (1-11)
        private var _currentStreak:int = 0;
        
        // Animation state
        private var _isAnimating:Boolean = false;
        
        /**
         * Constructor
         */
        public function TowerCastle(viewWidth:Number = 600, viewHeight:Number = 400) {
            _viewWidth = viewWidth;
            _viewHeight = viewHeight;
            
            _roofShapes = [];
            
            _towersContainer = new Sprite();
            addChild(_towersContainer);
            
            // Create initial main tower
            createMainTower();
            
            // Start animation loop
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            
            if (DEBUG) {
                trace("[TowerCastle] Initialized with size " + viewWidth + "x" + viewHeight);
            }
        }
        
        /**
         * Create the initial main tower (portrait rectangle)
         */
        private function createMainTower():void {
            var shape:Shape = new Shape();
            
            // Center position, bottom aligned
            var towerX:Number = _viewWidth / 2;
            var towerY:Number = _viewHeight - 50; // Bottom margin
            
            _mainTower = {
                shape: shape,
                width: MAIN_TOWER_INITIAL_WIDTH,
                height: MAIN_TOWER_INITIAL_HEIGHT,
                targetWidth: MAIN_TOWER_INITIAL_WIDTH,
                targetHeight: MAIN_TOWER_INITIAL_HEIGHT,
                x: towerX,
                y: towerY,
                color: MAIN_TOWER_COLOR
            };
            
            _towersContainer.addChild(shape);
            drawTower(_mainTower);
            
            if (DEBUG) {
                trace("[TowerCastle] Main tower created at (" + towerX + ", " + towerY + ")");
            }
        }
        
        /**
         * Create a side tower
         */
        private function createSideTower(side:String):Object {
            var shape:Shape = new Shape();
            
            var tower:Object = {
                shape: shape,
                width: SIDE_TOWER_INITIAL_WIDTH,
                height: SIDE_TOWER_INITIAL_HEIGHT,
                targetWidth: SIDE_TOWER_INITIAL_WIDTH,
                targetHeight: SIDE_TOWER_INITIAL_HEIGHT,
                x: 0, // Will be calculated
                y: _mainTower.y,
                color: SIDE_TOWER_COLOR,
                side: side
            };
            
            // Position based on side
            updateSideTowerPosition(tower);
            
            _towersContainer.addChild(shape);
            drawTower(tower);
            
            if (DEBUG) {
                trace("[TowerCastle] Side tower created on " + side + " side");
            }
            
            return tower;
        }
        
        /**
         * Update side tower X position based on main tower and side
         */
        private function updateSideTowerPosition(tower:Object):void {
            if (!tower) return;
            
            var side:String = tower.side;
            if (side == "left") {
                // Left side: main tower left edge - gap - half of side tower width
                tower.x = _mainTower.x - (_mainTower.width / 2) - TOWER_GAP - (tower.width / 2);
            } else {
                // Right side: main tower right edge + gap + half of side tower width
                tower.x = _mainTower.x + (_mainTower.width / 2) + TOWER_GAP + (tower.width / 2);
            }
        }
        
        /**
         * Draw a tower shape
         */
        private function drawTower(tower:Object):void {
            var shape:Shape = tower.shape;
            shape.graphics.clear();
            
            // Draw tower body (centered on x, bottom at y)
            var halfW:Number = tower.width / 2;
            var drawX:Number = tower.x - halfW;
            var drawY:Number = tower.y - tower.height;
            
            // Outline
            shape.graphics.lineStyle(2, OUTLINE_COLOR);
            shape.graphics.beginFill(tower.color);
            shape.graphics.drawRect(drawX, drawY, tower.width, tower.height);
            shape.graphics.endFill();
            
            // Add window details
            drawTowerWindows(shape, tower);
        }
        
        /**
         * Draw windows on tower
         */
        private function drawTowerWindows(shape:Shape, tower:Object):void {
            var windowSize:Number = Math.min(tower.width * 0.2, 15);
            var windowGap:Number = windowSize * 1.5;
            var startY:Number = tower.y - tower.height + windowGap;
            
            shape.graphics.beginFill(0x1A202C); // Dark window color
            
            // Draw windows in rows
            var cols:int = Math.max(1, Math.floor((tower.width - windowGap) / (windowSize + windowGap)));
            var rows:int = Math.max(1, Math.floor((tower.height - windowGap * 2) / (windowSize + windowGap)));
            
            var totalWindowWidth:Number = cols * windowSize + (cols - 1) * (windowGap / 2);
            var startX:Number = tower.x - totalWindowWidth / 2;
            
            for (var row:int = 0; row < rows; row++) {
                for (var col:int = 0; col < cols; col++) {
                    var wx:Number = startX + col * (windowSize + windowGap / 2);
                    var wy:Number = startY + row * (windowSize + windowGap);
                    shape.graphics.drawRect(wx, wy, windowSize, windowSize);
                }
            }
            
            shape.graphics.endFill();
        }
        
        /**
         * Draw roof (triangle) on a tower
         */
        private function drawRoof(tower:Object, roofShape:Shape, height:Number):void {
            roofShape.graphics.clear();
            
            if (height <= 0) return;
            
            var halfW:Number = tower.width / 2 + 5; // Slightly wider than tower
            var baseY:Number = tower.y - tower.height;
            var peakY:Number = baseY - height;
            
            roofShape.graphics.lineStyle(2, OUTLINE_COLOR);
            roofShape.graphics.beginFill(ROOF_COLOR);
            roofShape.graphics.moveTo(tower.x - halfW, baseY);
            roofShape.graphics.lineTo(tower.x, peakY);
            roofShape.graphics.lineTo(tower.x + halfW, baseY);
            roofShape.graphics.lineTo(tower.x - halfW, baseY);
            roofShape.graphics.endFill();
        }
        
        /**
         * Process upgrade based on correct streak (1-11)
         */
        public function processUpgrade(streak:int):void {
            _currentStreak = streak;
            
            if (DEBUG) {
                trace("[TowerCastle] Processing upgrade for streak " + streak);
            }
            
            switch (streak) {
                case 1:
                case 2:
                    // Enlarge main tower
                    enlargeMainTower();
                    break;
                    
                case 3:
                    // Add first side tower (random side)
                    addFirstSideTower();
                    break;
                    
                case 4:
                case 5:
                    // Enlarge first side tower
                    enlargeFirstSideTower();
                    break;
                    
                case 6:
                    // Add second side tower (opposite side)
                    addSecondSideTower();
                    break;
                    
                case 7:
                case 8:
                    // Enlarge second side tower
                    enlargeSecondSideTower();
                    break;
                    
                case 9:
                    // Add roofs to all towers
                    addRoofs();
                    break;
                    
                case 10:
                case 11:
                    // Increase roof heights
                    enlargeRoofs();
                    break;
                    
                default:
                    // Streak > 11: alternate between tower and roof upgrades
                    if (streak % 2 == 0) {
                        enlargeMainTower();
                    } else {
                        if (_hasRoofs) {
                            enlargeRoofs();
                        } else {
                            enlargeMainTower();
                        }
                    }
            }
        }
        
        /**
         * Enlarge main tower (more height than width)
         */
        private function enlargeMainTower():void {
            var newWidth:Number = Math.min(_mainTower.targetWidth + GROW_AMOUNT_WIDTH, MAIN_TOWER_MAX_WIDTH);
            var newHeight:Number = Math.min(_mainTower.targetHeight + GROW_AMOUNT_HEIGHT, MAIN_TOWER_MAX_HEIGHT);
            
            _mainTower.targetWidth = newWidth;
            _mainTower.targetHeight = newHeight;
            
            if (DEBUG) {
                trace("[TowerCastle] Enlarging main tower to " + newWidth + "x" + newHeight);
            }
        }
        
        /**
         * Add first side tower (random side)
         */
        private function addFirstSideTower():void {
            // Random side
            _firstSideTowerSide = (Math.random() > 0.5) ? "left" : "right";
            
            if (_firstSideTowerSide == "left") {
                _leftTower = createSideTower("left");
            } else {
                _rightTower = createSideTower("right");
            }
            
            if (DEBUG) {
                trace("[TowerCastle] Added first side tower on " + _firstSideTowerSide);
            }
        }
        
        /**
         * Add second side tower (opposite side from first)
         */
        private function addSecondSideTower():void {
            if (_firstSideTowerSide == "left") {
                _rightTower = createSideTower("right");
            } else {
                _leftTower = createSideTower("left");
            }
            
            if (DEBUG) {
                trace("[TowerCastle] Added second side tower on opposite side");
            }
        }
        
        /**
         * Enlarge first side tower
         */
        private function enlargeFirstSideTower():void {
            var tower:Object = (_firstSideTowerSide == "left") ? _leftTower : _rightTower;
            if (!tower) return;
            
            enlargeSideTower(tower);
        }
        
        /**
         * Enlarge second side tower
         */
        private function enlargeSecondSideTower():void {
            var tower:Object = (_firstSideTowerSide == "left") ? _rightTower : _leftTower;
            if (!tower) return;
            
            enlargeSideTower(tower);
        }
        
        /**
         * Enlarge a side tower with max ratio constraints
         */
        private function enlargeSideTower(tower:Object):void {
            // Max size based on main tower
            var maxWidth:Number = _mainTower.targetWidth * SIDE_TOWER_MAX_WIDTH_RATIO;
            var maxHeight:Number = _mainTower.targetHeight * SIDE_TOWER_MAX_HEIGHT_RATIO;
            
            var newWidth:Number = Math.min(tower.targetWidth + GROW_AMOUNT_WIDTH * 0.7, maxWidth);
            var newHeight:Number = Math.min(tower.targetHeight + GROW_AMOUNT_HEIGHT * 0.7, maxHeight);
            
            tower.targetWidth = newWidth;
            tower.targetHeight = newHeight;
            
            if (DEBUG) {
                trace("[TowerCastle] Enlarging side tower to " + newWidth + "x" + newHeight);
            }
        }
        
        /**
         * Add roofs to all towers
         */
        private function addRoofs():void {
            _hasRoofs = true;
            _targetRoofHeight = ROOF_INITIAL_HEIGHT;
            
            // Create roof shapes
            createRoofShape(_mainTower);
            if (_leftTower) createRoofShape(_leftTower);
            if (_rightTower) createRoofShape(_rightTower);
            
            if (DEBUG) {
                trace("[TowerCastle] Roofs added to all towers");
            }
        }
        
        /**
         * Create roof shape for a tower
         */
        private function createRoofShape(tower:Object):void {
            var roofShape:Shape = new Shape();
            _towersContainer.addChild(roofShape);
            _roofShapes.push({shape: roofShape, tower: tower});
        }
        
        /**
         * Enlarge all roofs
         */
        private function enlargeRoofs():void {
            _targetRoofHeight = Math.min(_targetRoofHeight + ROOF_GROW_AMOUNT, ROOF_MAX_HEIGHT);
            
            if (DEBUG) {
                trace("[TowerCastle] Enlarging roofs to height " + _targetRoofHeight);
            }
        }
        
        /**
         * Animation loop
         */
        private function onEnterFrame(e:Event):void {
            var hasAnimation:Boolean = false;
            
            // Animate main tower
            if (_mainTower) {
                hasAnimation = animateTower(_mainTower) || hasAnimation;
            }
            
            // Animate side towers
            if (_leftTower) {
                hasAnimation = animateTower(_leftTower) || hasAnimation;
                updateSideTowerPosition(_leftTower);
            }
            if (_rightTower) {
                hasAnimation = animateTower(_rightTower) || hasAnimation;
                updateSideTowerPosition(_rightTower);
            }
            
            // Animate roofs
            if (_hasRoofs) {
                hasAnimation = animateRoofs() || hasAnimation;
            }
            
            _isAnimating = hasAnimation;
        }
        
        /**
         * Animate tower size changes
         */
        private function animateTower(tower:Object):Boolean {
            var widthDiff:Number = tower.targetWidth - tower.width;
            var heightDiff:Number = tower.targetHeight - tower.height;
            
            if (Math.abs(widthDiff) < 0.5 && Math.abs(heightDiff) < 0.5) {
                tower.width = tower.targetWidth;
                tower.height = tower.targetHeight;
                drawTower(tower);
                return false;
            }
            
            tower.width += widthDiff * ANIMATION_SPEED;
            tower.height += heightDiff * ANIMATION_SPEED;
            drawTower(tower);
            
            return true;
        }
        
        /**
         * Animate roof height changes
         */
        private function animateRoofs():Boolean {
            var diff:Number = _targetRoofHeight - _roofHeight;
            
            if (Math.abs(diff) < 0.5) {
                _roofHeight = _targetRoofHeight;
                updateAllRoofs();
                return false;
            }
            
            _roofHeight += diff * ANIMATION_SPEED;
            updateAllRoofs();
            
            return true;
        }
        
        /**
         * Update all roof drawings
         */
        private function updateAllRoofs():void {
            for each (var roofData:Object in _roofShapes) {
                drawRoof(roofData.tower, roofData.shape, _roofHeight);
            }
        }
        
        /**
         * Get castle center point for effects
         */
        public function getCenter():Object {
            return {
                x: _viewWidth / 2,
                y: _viewHeight / 2
            };
        }
        
        /**
         * Get current streak
         */
        public function getCurrentStreak():int {
            return _currentStreak;
        }
        
        /**
         * Check if castle has all features (streak >= 11)
         */
        public function isFullyUpgraded():Boolean {
            return _currentStreak >= 11;
        }
        
        /**
         * Reset castle to initial state
         */
        public function reset():void {
            _currentStreak = 0;
            
            // Reset main tower
            _mainTower.targetWidth = MAIN_TOWER_INITIAL_WIDTH;
            _mainTower.targetHeight = MAIN_TOWER_INITIAL_HEIGHT;
            
            // Remove side towers
            if (_leftTower) {
                _towersContainer.removeChild(_leftTower.shape);
                _leftTower = null;
            }
            if (_rightTower) {
                _towersContainer.removeChild(_rightTower.shape);
                _rightTower = null;
            }
            
            // Remove roofs
            for each (var roofData:Object in _roofShapes) {
                _towersContainer.removeChild(roofData.shape);
            }
            _roofShapes = [];
            _hasRoofs = false;
            _roofHeight = 0;
            _targetRoofHeight = 0;
            
            _firstSideTowerSide = null;
            
            if (DEBUG) {
                trace("[TowerCastle] Castle reset to initial state");
            }
        }
        
        /**
         * Handle wrong answer - shrink elements
         */
        public function processWrong():void {
            // Shrink in reverse order of upgrades
            if (_hasRoofs && _roofHeight > ROOF_INITIAL_HEIGHT) {
                _targetRoofHeight = Math.max(_targetRoofHeight - ROOF_GROW_AMOUNT, ROOF_INITIAL_HEIGHT);
                if (DEBUG) trace("[TowerCastle] Shrinking roofs");
            } else if (_rightTower && _rightTower.targetHeight > SIDE_TOWER_INITIAL_HEIGHT) {
                shrinkSideTower(_rightTower);
            } else if (_leftTower && _leftTower.targetHeight > SIDE_TOWER_INITIAL_HEIGHT) {
                shrinkSideTower(_leftTower);
            } else if (_mainTower.targetHeight > MAIN_TOWER_INITIAL_HEIGHT) {
                _mainTower.targetWidth = Math.max(_mainTower.targetWidth - GROW_AMOUNT_WIDTH, MAIN_TOWER_INITIAL_WIDTH);
                _mainTower.targetHeight = Math.max(_mainTower.targetHeight - GROW_AMOUNT_HEIGHT, MAIN_TOWER_INITIAL_HEIGHT);
                if (DEBUG) trace("[TowerCastle] Shrinking main tower");
            }
        }
        
        /**
         * Shrink a side tower
         */
        private function shrinkSideTower(tower:Object):void {
            tower.targetWidth = Math.max(tower.targetWidth - GROW_AMOUNT_WIDTH * 0.7, SIDE_TOWER_INITIAL_WIDTH);
            tower.targetHeight = Math.max(tower.targetHeight - GROW_AMOUNT_HEIGHT * 0.7, SIDE_TOWER_INITIAL_HEIGHT);
            if (DEBUG) trace("[TowerCastle] Shrinking side tower");
        }
        
        /**
         * Get tower count
         */
        public function getTowerCount():int {
            var count:int = 1; // Main tower always exists
            if (_leftTower) count++;
            if (_rightTower) count++;
            return count;
        }
        
        /**
         * Resize view
         */
        public function resize(newWidth:Number, newHeight:Number):void {
            _viewWidth = newWidth;
            _viewHeight = newHeight;
            
            // Update main tower position
            _mainTower.x = _viewWidth / 2;
            _mainTower.y = _viewHeight - 50;
            
            // Update side towers
            if (_leftTower) {
                _leftTower.y = _mainTower.y;
                updateSideTowerPosition(_leftTower);
            }
            if (_rightTower) {
                _rightTower.y = _mainTower.y;
                updateSideTowerPosition(_rightTower);
            }
        }
    }
}
