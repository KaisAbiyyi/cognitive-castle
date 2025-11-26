package castle {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.geom.Point;
    import flash.events.Event;
    
    /**
     * BlockCastle - Simple block-based castle visualization with animations.
     * Castle is built from square blocks only.
     * 
     * Flow:
     * - Correct 1-2x: Enlarge random existing block (with animation)
     * - Correct 3x (streak): Add new block (with grow animation)
     * - Wrong 1-2x: Shrink random existing block (with animation)
     * - Wrong 3x: Remove random block (with shrink animation)
     */
    public class BlockCastle extends Sprite {
        
        // Debug
        private static const DEBUG:Boolean = true;
        
        // Block settings
        private static const MIN_BLOCK_SIZE:Number = 20;
        private static const MAX_BLOCK_SIZE:Number = 80;
        private static const DEFAULT_BLOCK_SIZE:Number = 40;
        private static const SIZE_CHANGE_AMOUNT:Number = 15;
        
        // Animation settings
        private static const ANIMATION_SPEED:Number = 0.15; // Easing speed (0-1)
        private static const PULSE_AMOUNT:Number = 1.2; // Pulse scale multiplier
        
        // Colors for blocks
        private static const BLOCK_COLORS:Array = [
            0x4A90E2, // Blue
            0x48BB78, // Green
            0xED8936, // Orange
            0x9F7AEA, // Purple
            0xF56565, // Red
            0x38B2AC, // Teal
            0xECC94B, // Yellow
            0x667EEA  // Indigo
        ];
        
        // Container for blocks
        private var _blocksContainer:Sprite;
        
        // Block data: Array of {shape: Shape, x: Number, y: Number, size: Number, targetSize: Number, color: uint, animating: Boolean}
        private var _blocks:Array;
        
        // Animation queue for blocks pending removal
        private var _removeQueue:Array;
        
        // View dimensions
        private var _viewWidth:Number;
        private var _viewHeight:Number;
        
        // Grid settings for positioning
        private var _gridCols:int = 6;
        private var _gridRows:int = 4;
        private var _cellWidth:Number;
        private var _cellHeight:Number;
        
        // Animation state
        private var _isAnimating:Boolean = false;
        
        /**
         * Constructor
         */
        public function BlockCastle(viewWidth:Number = 600, viewHeight:Number = 400) {
            _viewWidth = viewWidth;
            _viewHeight = viewHeight;
            _cellWidth = viewWidth / _gridCols;
            _cellHeight = viewHeight / _gridRows;
            
            _blocks = [];
            _removeQueue = [];
            
            _blocksContainer = new Sprite();
            addChild(_blocksContainer);
            
            // Start with one initial block in center
            addInitialBlock();
            
            // Start animation loop
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            
            if (DEBUG) {
                trace("[BlockCastle] Initialized with size " + viewWidth + "x" + viewHeight);
            }
        }
        
        /**
         * Animation loop - handles smooth size transitions
         */
        private function onEnterFrame(e:Event):void {
            var hasAnimation:Boolean = false;
            
            // Animate existing blocks
            for each (var block:Object in _blocks) {
                if (block.animating) {
                    // Ease current size toward target size
                    var diff:Number = block.targetSize - block.currentSize;
                    
                    if (Math.abs(diff) < 0.5) {
                        // Animation complete
                        block.currentSize = block.targetSize;
                        block.animating = false;
                        drawBlock(block.shape, block.currentSize, block.color);
                    } else {
                        // Continue animating
                        block.currentSize += diff * ANIMATION_SPEED;
                        drawBlock(block.shape, block.currentSize, block.color);
                        hasAnimation = true;
                    }
                }
            }
            
            // Animate blocks being removed (shrink to 0)
            for (var i:int = _removeQueue.length - 1; i >= 0; i--) {
                var removeBlock:Object = _removeQueue[i];
                removeBlock.currentSize *= 0.8; // Shrink quickly
                
                if (removeBlock.currentSize < 2) {
                    // Remove completely
                    if (removeBlock.shape.parent) {
                        removeBlock.shape.parent.removeChild(removeBlock.shape);
                    }
                    _removeQueue.splice(i, 1);
                } else {
                    drawBlock(removeBlock.shape, removeBlock.currentSize, removeBlock.color);
                    hasAnimation = true;
                }
            }
            
            _isAnimating = hasAnimation;
        }
        
        /**
         * Add initial center block
         */
        private function addInitialBlock():void {
            var centerX:Number = _viewWidth / 2;
            var centerY:Number = _viewHeight / 2;
            addBlockAt(centerX, centerY, DEFAULT_BLOCK_SIZE, true);
        }
        
        /**
         * Add a new block at position with optional grow animation
         */
        private function addBlockAt(x:Number, y:Number, size:Number, animate:Boolean = false):Object {
            var shape:Shape = new Shape();
            var color:uint = BLOCK_COLORS[Math.floor(Math.random() * BLOCK_COLORS.length)];
            
            // Start small if animating
            var startSize:Number = animate ? 5 : size;
            drawBlock(shape, startSize, color);
            
            shape.x = x;
            shape.y = y;
            
            _blocksContainer.addChild(shape);
            
            var blockData:Object = {
                shape: shape,
                x: x,
                y: y,
                size: size,
                currentSize: startSize,
                targetSize: size,
                color: color,
                animating: animate
            };
            
            _blocks.push(blockData);
            
            if (DEBUG) {
                trace("[BlockCastle] Added block at (" + x + ", " + y + ") size: " + size + (animate ? " with animation" : ""));
            }
            
            return blockData;
        }
        
        /**
         * Draw a square block
         */
        private function drawBlock(shape:Shape, size:Number, color:uint):void {
            var g:* = shape.graphics;
            g.clear();
            
            // Draw square block centered
            g.beginFill(color);
            g.lineStyle(2, darkenColor(color, 0.3));
            g.drawRect(-size / 2, -size / 2, size, size);
            g.endFill();
            
            // Add highlight
            g.beginFill(0xFFFFFF, 0.2);
            g.drawRect(-size / 2, -size / 2, size, size / 4);
            g.endFill();
        }
        
        /**
         * Darken a color
         */
        private function darkenColor(color:uint, amount:Number):uint {
            var r:int = ((color >> 16) & 0xFF) * (1 - amount);
            var g:int = ((color >> 8) & 0xFF) * (1 - amount);
            var b:int = (color & 0xFF) * (1 - amount);
            return (r << 16) | (g << 8) | b;
        }
        
        /**
         * Enlarge a random existing block with animation
         */
        public function enlargeRandomBlock():Boolean {
            if (_blocks.length == 0) return false;
            
            var index:int = Math.floor(Math.random() * _blocks.length);
            var block:Object = _blocks[index];
            
            if (block.size < MAX_BLOCK_SIZE) {
                block.size += SIZE_CHANGE_AMOUNT;
                if (block.size > MAX_BLOCK_SIZE) block.size = MAX_BLOCK_SIZE;
                
                // Set target for animation with pulse effect
                block.targetSize = block.size * PULSE_AMOUNT;
                block.animating = true;
                
                // After pulse, return to actual size
                pulseBlock(block);
                
                if (DEBUG) {
                    trace("[BlockCastle] Enlarging block " + index + " to size " + block.size + " with animation");
                }
                return true;
            }
            return false;
        }
        
        /**
         * Pulse effect - temporarily grow then return to normal
         */
        private function pulseBlock(block:Object):void {
            // Set a delayed reset to actual size
            var actualSize:Number = block.size;
            block.targetSize = actualSize * PULSE_AMOUNT;
            block.animating = true;
            
            // Use a simple frame counter approach
            var frameCount:int = 0;
            var maxFrames:int = 10;
            
            var onPulse:Function = function(e:Event):void {
                frameCount++;
                if (frameCount >= maxFrames) {
                    block.targetSize = actualSize;
                    removeEventListener(Event.ENTER_FRAME, onPulse);
                }
            };
            addEventListener(Event.ENTER_FRAME, onPulse);
        }
        
        /**
         * Shrink a random existing block with animation
         */
        public function shrinkRandomBlock():Boolean {
            if (_blocks.length == 0) return false;
            
            var index:int = Math.floor(Math.random() * _blocks.length);
            var block:Object = _blocks[index];
            
            if (block.size > MIN_BLOCK_SIZE) {
                block.size -= SIZE_CHANGE_AMOUNT;
                if (block.size < MIN_BLOCK_SIZE) block.size = MIN_BLOCK_SIZE;
                
                // Set target for animation
                block.targetSize = block.size;
                block.animating = true;
                
                if (DEBUG) {
                    trace("[BlockCastle] Shrinking block " + index + " to size " + block.size + " with animation");
                }
                return true;
            }
            return false;
        }
        
        /**
         * Add a new block at random position with grow animation
         */
        public function addNewBlock():Object {
            // Find a position near existing blocks
            var newX:Number;
            var newY:Number;
            
            if (_blocks.length > 0) {
                // Pick a random existing block and place new one nearby
                var refBlock:Object = _blocks[Math.floor(Math.random() * _blocks.length)];
                var offsetX:Number = (Math.random() - 0.5) * 150;
                var offsetY:Number = (Math.random() - 0.5) * 100;
                
                newX = refBlock.x + offsetX;
                newY = refBlock.y + offsetY;
                
                // Clamp to view bounds
                var margin:Number = DEFAULT_BLOCK_SIZE;
                newX = Math.max(margin, Math.min(_viewWidth - margin, newX));
                newY = Math.max(margin, Math.min(_viewHeight - margin, newY));
            } else {
                newX = _viewWidth / 2;
                newY = _viewHeight / 2;
            }
            
            // Add with grow animation
            return addBlockAt(newX, newY, DEFAULT_BLOCK_SIZE, true);
        }
        
        /**
         * Remove a random block with shrink animation
         */
        public function removeRandomBlock():Boolean {
            if (_blocks.length <= 1) {
                // Keep at least one block
                if (DEBUG) {
                    trace("[BlockCastle] Cannot remove - only 1 block left");
                }
                return false;
            }
            
            var index:int = Math.floor(Math.random() * _blocks.length);
            var block:Object = _blocks[index];
            
            // Move to remove queue for animation
            _removeQueue.push(block);
            
            // Remove from main array
            _blocks.splice(index, 1);
            
            if (DEBUG) {
                trace("[BlockCastle] Removing block " + index + " with animation. Remaining: " + _blocks.length);
            }
            
            return true;
        }
        
        /**
         * Get block count
         */
        public function get blockCount():int {
            return _blocks.length;
        }
        
        /**
         * Get total castle size (sum of all block sizes)
         */
        public function get totalSize():Number {
            var total:Number = 0;
            for each (var block:Object in _blocks) {
                total += block.size;
            }
            return total;
        }
        
        /**
         * Reset castle to initial state
         */
        public function reset():void {
            // Remove all blocks
            while (_blocksContainer.numChildren > 0) {
                _blocksContainer.removeChildAt(0);
            }
            _blocks = [];
            _removeQueue = [];
            
            // Add initial block
            addInitialBlock();
            
            if (DEBUG) {
                trace("[BlockCastle] Reset to initial state");
            }
        }
        
        /**
         * Check if any animation is playing
         */
        public function get isAnimating():Boolean {
            return _isAnimating || _removeQueue.length > 0;
        }
        
        /**
         * Get center position of castle
         */
        public function getCenter():Point {
            if (_blocks.length == 0) {
                return new Point(_viewWidth / 2, _viewHeight / 2);
            }
            
            var sumX:Number = 0;
            var sumY:Number = 0;
            for each (var block:Object in _blocks) {
                sumX += block.x;
                sumY += block.y;
            }
            
            return new Point(sumX / _blocks.length, sumY / _blocks.length);
        }
        
        /**
         * Resize the castle view - repositions blocks proportionally
         */
        public function resize(newWidth:Number, newHeight:Number):void {
            if (newWidth <= 0 || newHeight <= 0) return;
            
            // Calculate scale factors
            var scaleX:Number = newWidth / _viewWidth;
            var scaleY:Number = newHeight / _viewHeight;
            
            // Update dimensions
            _viewWidth = newWidth;
            _viewHeight = newHeight;
            _cellWidth = newWidth / _gridCols;
            _cellHeight = newHeight / _gridRows;
            
            // Reposition all blocks proportionally
            for each (var block:Object in _blocks) {
                block.x *= scaleX;
                block.y *= scaleY;
                
                // Clamp to new bounds
                var margin:Number = block.size / 2;
                block.x = Math.max(margin, Math.min(newWidth - margin, block.x));
                block.y = Math.max(margin, Math.min(newHeight - margin, block.y));
                
                // Update shape position
                block.shape.x = block.x;
                block.shape.y = block.y;
            }
            
            // Also reposition blocks in remove queue
            for each (var removeBlock:Object in _removeQueue) {
                removeBlock.x *= scaleX;
                removeBlock.y *= scaleY;
                removeBlock.shape.x = removeBlock.x;
                removeBlock.shape.y = removeBlock.y;
            }
            
            if (DEBUG) {
                trace("[BlockCastle] Resized to " + newWidth + "x" + newHeight);
            }
        }
        
        /**
         * Get view dimensions
         */
        public function get viewWidth():Number { return _viewWidth; }
        public function get viewHeight():Number { return _viewHeight; }
    }
}
