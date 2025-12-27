package castle {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.events.Event;
    import flash.filters.GlowFilter;
    import flash.filters.ColorMatrixFilter;
    
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
     * 
     * Animations:
     * - Correct answer: Green glow pulse effect
     * - Wrong answer: Red flash with shake effect
     * - New tower: Bounce/pop-in animation
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
        
        // Result animation settings
        private static const PULSE_SCALE:Number = 1.15; // Scale for correct answer pulse
        private static const SHAKE_INTENSITY:Number = 8; // Pixels to shake
        private static const SHAKE_DURATION:int = 20; // Frames
        private static const GLOW_DURATION:int = 30; // Frames
        private static const BOUNCE_SCALE_MAX:Number = 1.3; // Max scale for bounce
        private static const BOUNCE_DURATION:int = 25; // Frames
        
        // Colors
        private static const MAIN_TOWER_COLOR:uint = 0x4A5568; // Gray-blue
        private static const SIDE_TOWER_COLOR:uint = 0x718096; // Lighter gray
        private static const ROOF_COLOR:uint = 0xC53030; // Red roof
        private static const OUTLINE_COLOR:uint = 0x2D3748; // Dark outline
        private static const CORRECT_GLOW_COLOR:uint = 0x48BB78; // Green glow
        private static const WRONG_FLASH_COLOR:uint = 0xF56565; // Red flash
        
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
        
        // Result animation state
        private var _resultAnimationType:String = null; // "correct", "wrong", "newTower", "removeTower", "growWidth", "growHeight"
        private var _resultAnimationFrame:int = 0;
        private var _shakeOffset:Number = 0;
        private var _pulseScale:Number = 1.0;
        private var _glowIntensity:Number = 0;
        private var _bounceScale:Number = 1.0;
        private var _newTowerRef:Object = null; // Reference to newly created tower for drop animation
        private var _removeTowerRef:Object = null; // Reference to tower being removed
        private var _originalContainerX:Number = 0;
        
        // Growth animation state
        private var _growAnimationTower:Object = null; // Tower being animated for growth
        private var _growAnimationType:String = null; // "width" or "height"
        
        // Drop animation settings
        private static const DROP_DURATION:int = 35; // Frames for drop animation
        private static const DROP_START_Y:Number = -200; // Start position above screen
        private static const REMOVE_DURATION:int = 25; // Frames for remove animation
        private static const GROW_ANIMATION_DURATION:int = 20; // Frames for growth animation
        
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
            
            // Store original container position
            _originalContainerX = 0;
            
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
                side: side,
                // Animation properties for drop
                offsetY: DROP_START_Y, // Start above the screen
                targetOffsetY: 0 // Target is the normal position
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
            
            // Get offset for animation (default 0 if not set)
            var offsetY:Number = tower.offsetY ? tower.offsetY : 0;
            
            // Draw tower body (centered on x, bottom at y)
            var halfW:Number = tower.width / 2;
            var drawX:Number = tower.x - halfW;
            var drawY:Number = tower.y - tower.height + offsetY;
            
            // Outline
            shape.graphics.lineStyle(2, OUTLINE_COLOR);
            shape.graphics.beginFill(tower.color);
            shape.graphics.drawRect(drawX, drawY, tower.width, tower.height);
            shape.graphics.endFill();
            
            // Add window details
            drawTowerWindows(shape, tower, offsetY);
        }
        
        /**
         * Draw windows on tower
         */
        private function drawTowerWindows(shape:Shape, tower:Object, offsetY:Number = 0):void {
            var windowSize:Number = Math.min(tower.width * 0.2, 15);
            var windowGap:Number = windowSize * 1.5;
            var startY:Number = tower.y - tower.height + windowGap + offsetY;
            
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
            
            // Scale entire castle slightly bigger with each upgrade
            var newScale:Number = 1.0 + (streak * 0.03); // Increase 3% per streak
            newScale = Math.min(newScale, 1.5); // Max 150% scale
            this.scaleX = newScale;
            this.scaleY = newScale;
            
            // Start correct answer animation
            startCorrectAnimation();
            
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
         * Enlarge main tower (alternates between width and height growth)
         */
        private function enlargeMainTower():void {
            // Check which dimension has more room to grow
            var widthRoom:Number = MAIN_TOWER_MAX_WIDTH - _mainTower.targetWidth;
            var heightRoom:Number = MAIN_TOWER_MAX_HEIGHT - _mainTower.targetHeight;
            
            // Alternate based on streak - odd = height, even = width
            var growHeight:Boolean = (_currentStreak % 2 == 1) || widthRoom <= 0;
            var growWidth:Boolean = (_currentStreak % 2 == 0) || heightRoom <= 0;
            
            // If one dimension is maxed, grow the other
            if (widthRoom <= 0) growHeight = true;
            if (heightRoom <= 0) growWidth = true;
            
            if (growHeight && heightRoom > 0) {
                var newHeight:Number = Math.min(_mainTower.targetHeight + GROW_AMOUNT_HEIGHT, MAIN_TOWER_MAX_HEIGHT);
                _mainTower.targetHeight = newHeight;
                startHeightGrowAnimation(_mainTower);
                
                if (DEBUG) {
                    trace("[TowerCastle] Enlarging main tower HEIGHT to " + newHeight);
                }
            } else if (growWidth && widthRoom > 0) {
                var newWidth:Number = Math.min(_mainTower.targetWidth + GROW_AMOUNT_WIDTH, MAIN_TOWER_MAX_WIDTH);
                _mainTower.targetWidth = newWidth;
                startWidthGrowAnimation(_mainTower);
                
                if (DEBUG) {
                    trace("[TowerCastle] Enlarging main tower WIDTH to " + newWidth);
                }
            } else {
                // Both maxed - just play correct animation
                startCorrectAnimation();
                if (DEBUG) {
                    trace("[TowerCastle] Main tower at max size");
                }
            }
        }
        
        /**
         * Add first side tower (random side)
         */
        private function addFirstSideTower():void {
            // Random side
            _firstSideTowerSide = (Math.random() > 0.5) ? "left" : "right";
            
            var newTower:Object;
            if (_firstSideTowerSide == "left") {
                _leftTower = createSideTower("left");
                newTower = _leftTower;
            } else {
                _rightTower = createSideTower("right");
                newTower = _rightTower;
            }
            
            // Start bounce animation for new tower
            startNewTowerAnimation(newTower);
            
            if (DEBUG) {
                trace("[TowerCastle] Added first side tower on " + _firstSideTowerSide);
            }
        }
        
        /**
         * Add second side tower (opposite side from first)
         */
        private function addSecondSideTower():void {
            var newTower:Object;
            if (_firstSideTowerSide == "left") {
                _rightTower = createSideTower("right");
                newTower = _rightTower;
            } else {
                _leftTower = createSideTower("left");
                newTower = _leftTower;
            }
            
            // Start bounce animation for new tower
            startNewTowerAnimation(newTower);
            
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
         * Enlarge a side tower with max ratio constraints (alternates width/height)
         */
        private function enlargeSideTower(tower:Object):void {
            // Max size based on main tower
            var maxWidth:Number = _mainTower.targetWidth * SIDE_TOWER_MAX_WIDTH_RATIO;
            var maxHeight:Number = _mainTower.targetHeight * SIDE_TOWER_MAX_HEIGHT_RATIO;
            
            var widthRoom:Number = maxWidth - tower.targetWidth;
            var heightRoom:Number = maxHeight - tower.targetHeight;
            
            // Alternate based on streak
            var growHeight:Boolean = (_currentStreak % 2 == 1) || widthRoom <= 0;
            
            if (growHeight && heightRoom > 0) {
                var newHeight:Number = Math.min(tower.targetHeight + GROW_AMOUNT_HEIGHT * 0.7, maxHeight);
                tower.targetHeight = newHeight;
                startHeightGrowAnimation(tower);
                
                if (DEBUG) {
                    trace("[TowerCastle] Enlarging side tower HEIGHT to " + newHeight);
                }
            } else if (widthRoom > 0) {
                var newWidth:Number = Math.min(tower.targetWidth + GROW_AMOUNT_WIDTH * 0.7, maxWidth);
                tower.targetWidth = newWidth;
                startWidthGrowAnimation(tower);
                
                if (DEBUG) {
                    trace("[TowerCastle] Enlarging side tower WIDTH to " + newWidth);
                }
            } else {
                // Both maxed
                startCorrectAnimation();
                if (DEBUG) {
                    trace("[TowerCastle] Side tower at max size");
                }
            }
        }
        
        // =====================================================
        // RESULT ANIMATION METHODS
        // =====================================================
        
        /**
         * Start correct answer animation (just glow, no zoom)
         */
        private function startCorrectAnimation():void {
            _resultAnimationType = "correct";
            _resultAnimationFrame = 0;
            _glowIntensity = 0;
            
            if (DEBUG) {
                trace("[TowerCastle] Starting correct answer animation (glow only)");
            }
        }
        
        /**
         * Start width growth animation (horizontal stretch effect)
         */
        private function startWidthGrowAnimation(tower:Object):void {
            _growAnimationTower = tower;
            _growAnimationType = "width";
            _resultAnimationType = "growWidth";
            _resultAnimationFrame = 0;
            
            if (DEBUG) {
                trace("[TowerCastle] Starting width growth animation");
            }
        }
        
        /**
         * Start height growth animation (vertical stretch effect)
         */
        private function startHeightGrowAnimation(tower:Object):void {
            _growAnimationTower = tower;
            _growAnimationType = "height";
            _resultAnimationType = "growHeight";
            _resultAnimationFrame = 0;
            
            if (DEBUG) {
                trace("[TowerCastle] Starting height growth animation");
            }
        }
        
        /**
         * Start wrong answer animation (red flash + shake)
         */
        private function startWrongAnimation():void {
            _resultAnimationType = "wrong";
            _resultAnimationFrame = 0;
            _shakeOffset = 0;
            _glowIntensity = 0;
            
            if (DEBUG) {
                trace("[TowerCastle] Starting wrong answer animation");
            }
        }
        
        /**
         * Start new tower drop animation (from above)
         */
        private function startNewTowerAnimation(tower:Object):void {
            _newTowerRef = tower;
            _resultAnimationType = "newTower";
            _resultAnimationFrame = 0;
            
            // Set initial position above screen
            tower.offsetY = DROP_START_Y;
            tower.targetOffsetY = 0;
            
            if (DEBUG) {
                trace("[TowerCastle] Starting new tower drop animation from above");
            }
        }
        
        /**
         * Update result animations
         */
        private function updateResultAnimation():Boolean {
            if (_resultAnimationType == null) return false;
            
            _resultAnimationFrame++;
            
            switch (_resultAnimationType) {
                case "correct":
                    return updateCorrectAnimation();
                case "wrong":
                    return updateWrongAnimation();
                case "newTower":
                    return updateNewTowerAnimation();
                case "removeTower":
                    return updateRemoveTowerAnimation();
                case "growWidth":
                    return updateWidthGrowAnimation();
                case "growHeight":
                    return updateHeightGrowAnimation();
            }
            
            return false;
        }
        
        /**
         * Update correct answer animation (glow only, no zoom)
         */
        private function updateCorrectAnimation():Boolean {
            var progress:Number = _resultAnimationFrame / GLOW_DURATION;
            
            if (progress >= 1.0) {
                // Animation complete - reset
                _towersContainer.filters = [];
                _resultAnimationType = null;
                return false;
            }
            
            // Glow effect only (fade in then out) - NO ZOOM
            if (progress < 0.3) {
                _glowIntensity = progress / 0.3;
            } else {
                _glowIntensity = 1.0 - ((progress - 0.3) / 0.7);
            }
            
            // Apply glow filter only (no scale changes)
            var glowStrength:Number = _glowIntensity * 3;
            var glowFilter:GlowFilter = new GlowFilter(CORRECT_GLOW_COLOR, 0.8, 20, 20, glowStrength, 1, false, false);
            _towersContainer.filters = [glowFilter];
            
            return true;
        }
        
        /**
         * Update width growth animation (horizontal flash effect from sides)
         */
        private function updateWidthGrowAnimation():Boolean {
            if (_resultAnimationFrame >= GROW_ANIMATION_DURATION || _growAnimationTower == null) {
                // Animation complete
                _towersContainer.filters = [];
                _growAnimationTower = null;
                _resultAnimationType = null;
                return false;
            }
            
            var progress:Number = _resultAnimationFrame / GROW_ANIMATION_DURATION;
            
            // Horizontal pulse glow effect (blue/cyan color for width)
            var glowColor:uint = 0x3182CE; // Blue for width
            if (progress < 0.4) {
                _glowIntensity = progress / 0.4;
            } else {
                _glowIntensity = 1.0 - ((progress - 0.4) / 0.6);
            }
            
            // Apply horizontal-biased glow (wider blur X)
            var glowStrength:Number = _glowIntensity * 4;
            var glowFilter:GlowFilter = new GlowFilter(glowColor, 0.9, 35, 15, glowStrength, 1, false, false);
            _towersContainer.filters = [glowFilter];
            
            return true;
        }
        
        /**
         * Update height growth animation (vertical flash effect from top)
         */
        private function updateHeightGrowAnimation():Boolean {
            if (_resultAnimationFrame >= GROW_ANIMATION_DURATION || _growAnimationTower == null) {
                // Animation complete
                _towersContainer.filters = [];
                _growAnimationTower = null;
                _resultAnimationType = null;
                return false;
            }
            
            var progress:Number = _resultAnimationFrame / GROW_ANIMATION_DURATION;
            
            // Vertical pulse glow effect (gold/yellow color for height)
            var glowColor:uint = 0xD69E2E; // Gold for height
            if (progress < 0.4) {
                _glowIntensity = progress / 0.4;
            } else {
                _glowIntensity = 1.0 - ((progress - 0.4) / 0.6);
            }
            
            // Apply vertical-biased glow (taller blur Y)
            var glowStrength:Number = _glowIntensity * 4;
            var glowFilter:GlowFilter = new GlowFilter(glowColor, 0.9, 15, 35, glowStrength, 1, false, false);
            _towersContainer.filters = [glowFilter];
            
            return true;
        }
        
        /**
         * Update wrong answer animation
         */
        private function updateWrongAnimation():Boolean {
            if (_resultAnimationFrame >= SHAKE_DURATION) {
                // Animation complete - reset
                _towersContainer.x = _originalContainerX;
                _towersContainer.filters = [];
                _resultAnimationType = null;
                return false;
            }
            
            var progress:Number = _resultAnimationFrame / SHAKE_DURATION;
            
            // Shake effect (decreasing intensity)
            var shakeAmount:Number = SHAKE_INTENSITY * (1 - progress);
            _shakeOffset = Math.sin(_resultAnimationFrame * 1.5) * shakeAmount;
            _towersContainer.x = _originalContainerX + _shakeOffset;
            
            // Red flash glow (fade out)
            _glowIntensity = 1.0 - progress;
            var glowStrength:Number = _glowIntensity * 4;
            var glowFilter:GlowFilter = new GlowFilter(WRONG_FLASH_COLOR, 0.9, 25, 25, glowStrength, 1, false, false);
            _towersContainer.filters = [glowFilter];
            
            return true;
        }
        
        /**
         * Update new tower drop animation (from above)
         */
        private function updateNewTowerAnimation():Boolean {
            if (_resultAnimationFrame >= DROP_DURATION || _newTowerRef == null) {
                // Animation complete - reset
                if (_newTowerRef) {
                    _newTowerRef.offsetY = 0;
                    drawTower(_newTowerRef);
                }
                _newTowerRef = null;
                _resultAnimationType = null;
                return false;
            }
            
            var progress:Number = _resultAnimationFrame / DROP_DURATION;
            
            // Easing function for drop (ease out bounce)
            var easedProgress:Number;
            if (progress < 0.7) {
                // Main drop with ease-out
                easedProgress = 1 - Math.pow(1 - (progress / 0.7), 3);
            } else if (progress < 0.85) {
                // Small bounce up
                var bounceProgress:Number = (progress - 0.7) / 0.15;
                easedProgress = 1 + 0.1 * Math.sin(bounceProgress * Math.PI);
            } else {
                // Settle down
                var settleProgress:Number = (progress - 0.85) / 0.15;
                easedProgress = 1.1 - 0.1 * settleProgress;
            }
            
            // Calculate current Y offset
            if (_newTowerRef) {
                _newTowerRef.offsetY = DROP_START_Y * (1 - Math.min(easedProgress, 1));
                drawTower(_newTowerRef);
            }
            
            return true;
        }
        
        /**
         * Start remove tower animation (fly up and disappear)
         */
        private function startRemoveTowerAnimation(tower:Object):void {
            _removeTowerRef = tower;
            _resultAnimationType = "removeTower";
            _resultAnimationFrame = 0;
            
            if (DEBUG) {
                trace("[TowerCastle] Starting tower removal animation");
            }
        }
        
        /**
         * Update remove tower animation (fly up)
         */
        private function updateRemoveTowerAnimation():Boolean {
            if (_resultAnimationFrame >= REMOVE_DURATION || _removeTowerRef == null) {
                // Animation complete - actually remove the tower
                if (_removeTowerRef) {
                    actuallyRemoveTower(_removeTowerRef);
                }
                _removeTowerRef = null;
                _resultAnimationType = null;
                return false;
            }
            
            var progress:Number = _resultAnimationFrame / REMOVE_DURATION;
            
            // Fly up with acceleration
            var flyOffset:Number = -DROP_START_Y * Math.pow(progress, 2);
            
            // Also fade out
            if (_removeTowerRef && _removeTowerRef.shape) {
                _removeTowerRef.offsetY = flyOffset;
                _removeTowerRef.shape.alpha = 1 - progress;
                drawTower(_removeTowerRef);
            }
            
            return true;
        }
        
        /**
         * Actually remove a tower from the display
         */
        private function actuallyRemoveTower(tower:Object):void {
            if (!tower) return;
            
            // Remove from container
            if (tower.shape && tower.shape.parent) {
                _towersContainer.removeChild(tower.shape);
            }
            
            // Clear reference
            if (tower == _leftTower) {
                _leftTower = null;
            } else if (tower == _rightTower) {
                _rightTower = null;
            }
            
            // Also remove roof if exists
            for (var i:int = _roofShapes.length - 1; i >= 0; i--) {
                if (_roofShapes[i].tower == tower) {
                    if (_roofShapes[i].shape && _roofShapes[i].shape.parent) {
                        _towersContainer.removeChild(_roofShapes[i].shape);
                    }
                    _roofShapes.splice(i, 1);
                }
            }
            
            if (DEBUG) {
                trace("[TowerCastle] Tower removed from display");
            }
        }
        
        /**
         * Play correct animation (public method for external calls)
         */
        public function playCorrectAnimation():void {
            startCorrectAnimation();
        }
        
        /**
         * Play wrong animation (public method for external calls)
         */
        public function playWrongAnimation():void {
            startWrongAnimation();
        }
        
        /**
         * Remove a side tower with animation (called when wrong 3x)
         * Returns true if a tower was removed
         */
        public function removeSideTower():Boolean {
            // Remove in reverse order: second side tower first, then first side tower
            var towerToRemove:Object = null;
            
            // Determine which tower to remove based on order they were added
            if (_firstSideTowerSide == "left") {
                // First was left, so right is second
                if (_rightTower) {
                    towerToRemove = _rightTower;
                } else if (_leftTower) {
                    towerToRemove = _leftTower;
                }
            } else {
                // First was right, so left is second
                if (_leftTower) {
                    towerToRemove = _leftTower;
                } else if (_rightTower) {
                    towerToRemove = _rightTower;
                }
            }
            
            if (towerToRemove) {
                startRemoveTowerAnimation(towerToRemove);
                
                // Decrease streak
                if (_currentStreak > 0) {
                    _currentStreak = Math.max(0, _currentStreak - 3);
                }
                
                if (DEBUG) {
                    trace("[TowerCastle] Removing side tower due to 3 wrong answers");
                }
                return true;
            }
            
            if (DEBUG) {
                trace("[TowerCastle] No side tower to remove");
            }
            return false;
        }
        
        /**
         * Check if there are side towers to remove
         */
        public function hasSideTowers():Boolean {
            return (_leftTower != null || _rightTower != null);
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
            
            // Update result animations first
            hasAnimation = updateResultAnimation() || hasAnimation;
            
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
            // Start wrong answer animation
            startWrongAnimation();
            
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
