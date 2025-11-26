package castle {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.geom.Point;
    
    /**
     * CastleView - Visual representation of the castle.
     * Renders castle parts based on CastleState and handles animations.
     */
    public class CastleView extends Sprite {
        
        // Debug flag
        private static const DEBUG:Boolean = true;
        
        // Grid settings
        private var _cellSize:int;
        private var _gridWidth:int;
        private var _gridHeight:int;
        private var _offsetX:Number;
        private var _offsetY:Number;
        
        // Layers
        private var _backgroundLayer:Sprite;
        private var _partsLayer:Sprite;
        private var _effectsLayer:Sprite;
        
        // Part sprites map (partId -> Sprite)
        private var _partSprites:Object;
        
        // Color palettes by tier
        private static const TIER_COLORS:Array = [
            { base: 0x8B7355, highlight: 0xA0896B, shadow: 0x6B5545 }, // Tier 1 - Wood
            { base: 0x808080, highlight: 0xA0A0A0, shadow: 0x606060 }, // Tier 2 - Stone
            { base: 0x4A4A4A, highlight: 0x6A6A6A, shadow: 0x2A2A2A }, // Tier 3 - Dark Stone
            { base: 0xB8860B, highlight: 0xDAA520, shadow: 0x8B6914 }, // Tier 4 - Gold
            { base: 0xE6E6FA, highlight: 0xFFFFFF, shadow: 0xB0B0DA }  // Tier 5 - Crystal
        ];
        
        /**
         * Constructor
         * @param width View width
         * @param height View height
         */
        public function CastleView(viewWidth:Number = 420, viewHeight:Number = 300) {
            _gridWidth = CastleConfig.GRID_WIDTH;
            _gridHeight = CastleConfig.GRID_HEIGHT;
            _cellSize = CastleConfig.CELL_SIZE;
            
            // Center the grid
            _offsetX = (viewWidth - (_gridWidth * _cellSize)) / 2;
            _offsetY = (viewHeight - (_gridHeight * _cellSize)) / 2;
            
            _partSprites = {};
            
            createLayers();
            drawBackground();
        }
        
        /**
         * Create rendering layers
         */
        private function createLayers():void {
            _backgroundLayer = new Sprite();
            _partsLayer = new Sprite();
            _effectsLayer = new Sprite();
            
            addChild(_backgroundLayer);
            addChild(_partsLayer);
            addChild(_effectsLayer);
        }
        
        /**
         * Draw grid background
         */
        private function drawBackground():void {
            var g:* = _backgroundLayer.graphics;
            
            // Draw ground/grass
            g.beginFill(0x228B22, 0.3);
            g.drawRect(_offsetX, _offsetY, _gridWidth * _cellSize, _gridHeight * _cellSize);
            g.endFill();
            
            // Draw grid lines (debug)
            if (DEBUG) {
                g.lineStyle(1, 0xFFFFFF, 0.1);
                for (var i:int = 0; i <= _gridWidth; i++) {
                    g.moveTo(_offsetX + i * _cellSize, _offsetY);
                    g.lineTo(_offsetX + i * _cellSize, _offsetY + _gridHeight * _cellSize);
                }
                for (var j:int = 0; j <= _gridHeight; j++) {
                    g.moveTo(_offsetX, _offsetY + j * _cellSize);
                    g.lineTo(_offsetX + _gridWidth * _cellSize, _offsetY + j * _cellSize);
                }
            }
        }
        
        /**
         * Render castle state
         * @param state Castle state to render
         */
        public function render(state:CastleState):void {
            // Clear existing parts
            clearParts();
            
            // Sort parts by z-index
            var sortedParts:Vector.<CastlePart> = state.parts.slice();
            sortedParts.sort(compareZIndex);
            
            // Render each part
            for each (var part:CastlePart in sortedParts) {
                if (part.isAlive) {
                    renderPart(part);
                }
            }
            
            if (DEBUG) {
                trace("Rendered " + sortedParts.length + " castle parts");
            }
        }
        
        /**
         * Compare function for z-index sorting
         */
        private function compareZIndex(a:CastlePart, b:CastlePart):int {
            return a.zIndex - b.zIndex;
        }
        
        /**
         * Clear all part sprites
         */
        private function clearParts():void {
            while (_partsLayer.numChildren > 0) {
                _partsLayer.removeChildAt(0);
            }
            _partSprites = {};
        }
        
        /**
         * Render a single part
         */
        private function renderPart(part:CastlePart):void {
            var sprite:Sprite = new Sprite();
            var pos:Point = gridToScreen(part.gridX, part.gridY);
            
            sprite.x = pos.x;
            sprite.y = pos.y;
            
            // Draw based on type
            switch (part.type) {
                case CastlePart.TYPE_FOUNDATION:
                    drawFoundation(sprite, part);
                    break;
                case CastlePart.TYPE_WALL:
                    drawWall(sprite, part);
                    break;
                case CastlePart.TYPE_TOWER:
                    drawTower(sprite, part);
                    break;
                case CastlePart.TYPE_KEEP:
                    drawKeep(sprite, part);
                    break;
                case CastlePart.TYPE_DECORATION:
                    drawDecoration(sprite, part);
                    break;
                case CastlePart.TYPE_SPECIAL:
                    drawSpecial(sprite, part);
                    break;
            }
            
            // Apply damage visual
            if (part.state == CastlePart.STATE_DAMAGED) {
                applyDamageVisual(sprite, part.health);
            }
            
            _partsLayer.addChild(sprite);
            _partSprites[part.id] = sprite;
        }
        
        /**
         * Convert grid position to screen position
         */
        private function gridToScreen(gridX:int, gridY:int):Point {
            return new Point(
                _offsetX + gridX * _cellSize + _cellSize / 2,
                _offsetY + gridY * _cellSize + _cellSize / 2
            );
        }
        
        /**
         * Get colors for tier
         */
        private function getTierColors(tier:int):Object {
            var idx:int = Math.min(tier - 1, TIER_COLORS.length - 1);
            return TIER_COLORS[Math.max(0, idx)];
        }
        
        // ========== DRAWING FUNCTIONS ==========
        
        private function drawFoundation(sprite:Sprite, part:CastlePart):void {
            var g:* = sprite.graphics;
            var colors:Object = getTierColors(part.tier);
            var size:Number = _cellSize * 0.9;
            
            // Draw stone foundation block
            g.beginFill(colors.shadow);
            g.drawRect(-size/2, -size/4, size, size/2);
            g.endFill();
            
            g.beginFill(colors.base);
            g.drawRect(-size/2, -size/3, size, size/3);
            g.endFill();
            
            // Highlight
            g.beginFill(colors.highlight, 0.3);
            g.drawRect(-size/2, -size/3, size, size/6);
            g.endFill();
        }
        
        private function drawWall(sprite:Sprite, part:CastlePart):void {
            var g:* = sprite.graphics;
            var colors:Object = getTierColors(part.tier);
            var width:Number = _cellSize * 0.8;
            var height:Number = _cellSize * 1.2;
            
            // Wall body
            g.beginFill(colors.base);
            g.drawRect(-width/2, -height + _cellSize/4, width, height);
            g.endFill();
            
            // Battlements on top
            var merlonWidth:Number = width / 5;
            g.beginFill(colors.shadow);
            for (var i:int = 0; i < 3; i++) {
                var mx:Number = -width/2 + merlonWidth * (i * 2);
                g.drawRect(mx, -height + _cellSize/4 - merlonWidth, merlonWidth, merlonWidth);
            }
            g.endFill();
            
            // Stone pattern
            g.lineStyle(1, colors.shadow, 0.5);
            for (var row:int = 0; row < 4; row++) {
                var y:Number = -height + _cellSize/4 + row * (height/4);
                g.moveTo(-width/2, y);
                g.lineTo(width/2, y);
            }
        }
        
        private function drawTower(sprite:Sprite, part:CastlePart):void {
            var g:* = sprite.graphics;
            var colors:Object = getTierColors(part.tier);
            var width:Number = _cellSize * 0.7;
            var height:Number = _cellSize * 1.8;
            
            // Tower body (cylindrical representation)
            g.beginFill(colors.base);
            g.drawRect(-width/2, -height + _cellSize/3, width, height);
            g.endFill();
            
            // Conical roof
            g.beginFill(0x8B0000); // Dark red roof
            g.moveTo(0, -height + _cellSize/3 - width/2);
            g.lineTo(-width/2 - 5, -height + _cellSize/3);
            g.lineTo(width/2 + 5, -height + _cellSize/3);
            g.lineTo(0, -height + _cellSize/3 - width/2);
            g.endFill();
            
            // Windows
            g.beginFill(0x000033, 0.8);
            g.drawRect(-width/6, -height/2, width/3, height/6);
            g.endFill();
            
            // Flag on top
            g.beginFill(0xFF0000);
            g.moveTo(0, -height + _cellSize/3 - width/2);
            g.lineTo(0, -height + _cellSize/3 - width/2 - 15);
            g.endFill();
            g.beginFill(0xFFD700);
            g.drawRect(2, -height + _cellSize/3 - width/2 - 15, 12, 8);
            g.endFill();
        }
        
        private function drawKeep(sprite:Sprite, part:CastlePart):void {
            var g:* = sprite.graphics;
            var colors:Object = getTierColors(part.tier);
            var width:Number = _cellSize * 1.2;
            var height:Number = _cellSize * 2;
            
            // Main building
            g.beginFill(colors.base);
            g.drawRect(-width/2, -height + _cellSize/2, width, height);
            g.endFill();
            
            // Roof
            g.beginFill(0x4A4A4A);
            g.moveTo(-width/2 - 5, -height + _cellSize/2);
            g.lineTo(0, -height + _cellSize/2 - height/4);
            g.lineTo(width/2 + 5, -height + _cellSize/2);
            g.endFill();
            
            // Large door
            g.beginFill(0x4A2511);
            g.drawRect(-width/4, -_cellSize/3, width/2, _cellSize/2);
            g.endFill();
            
            // Windows
            g.beginFill(0xFFD700, 0.7);
            g.drawRect(-width/3, -height/2, width/6, height/8);
            g.drawRect(width/6, -height/2, width/6, height/8);
            g.endFill();
            
            // Crown decoration
            g.beginFill(0xFFD700);
            for (var i:int = 0; i < 3; i++) {
                var cx:Number = -width/4 + i * (width/4);
                g.drawRect(cx, -height + _cellSize/2 - height/4 - 5, 8, 10);
            }
            g.endFill();
        }
        
        private function drawDecoration(sprite:Sprite, part:CastlePart):void {
            var g:* = sprite.graphics;
            
            switch (part.variant) {
                case "flag":
                    // Flagpole
                    g.beginFill(0x4A4A4A);
                    g.drawRect(-2, -_cellSize, 4, _cellSize);
                    g.endFill();
                    // Flag
                    g.beginFill(0xFF0000);
                    g.moveTo(2, -_cellSize);
                    g.lineTo(25, -_cellSize + 8);
                    g.lineTo(2, -_cellSize + 16);
                    g.endFill();
                    break;
                    
                case "garden":
                    // Bushes/trees
                    g.beginFill(0x228B22);
                    g.drawCircle(-10, 0, 12);
                    g.drawCircle(10, -5, 15);
                    g.drawCircle(0, 5, 10);
                    g.endFill();
                    // Flowers
                    g.beginFill(0xFF69B4);
                    g.drawCircle(-8, -3, 3);
                    g.drawCircle(12, -8, 4);
                    g.endFill();
                    break;
                    
                case "banner_left":
                case "banner_right":
                    // Banner pole
                    g.beginFill(0x8B4513);
                    g.drawRect(-2, -_cellSize * 0.8, 4, _cellSize * 0.8);
                    g.endFill();
                    // Banner cloth
                    g.beginFill(0x0000FF);
                    g.drawRect(-15, -_cellSize * 0.75, 30, 40);
                    g.endFill();
                    // Emblem
                    g.beginFill(0xFFD700);
                    g.drawCircle(0, -_cellSize * 0.5, 8);
                    g.endFill();
                    break;
                    
                case "turret":
                    // Small tower turret
                    g.beginFill(0x808080);
                    g.drawRect(-12, -_cellSize * 0.6, 24, _cellSize * 0.6);
                    g.endFill();
                    g.beginFill(0x8B0000);
                    g.moveTo(0, -_cellSize * 0.8);
                    g.lineTo(-15, -_cellSize * 0.6);
                    g.lineTo(15, -_cellSize * 0.6);
                    g.endFill();
                    break;
                    
                case "window":
                    // Decorative window
                    g.beginFill(0x4A4A4A);
                    g.drawRect(-8, -20, 16, 25);
                    g.endFill();
                    g.beginFill(0x87CEEB, 0.8);
                    g.drawRect(-6, -18, 12, 20);
                    g.endFill();
                    break;
                    
                default:
                    // Generic decoration
                    g.beginFill(0xFFD700);
                    g.drawCircle(0, 0, 8);
                    g.endFill();
            }
        }
        
        private function drawSpecial(sprite:Sprite, part:CastlePart):void {
            var g:* = sprite.graphics;
            
            switch (part.variant) {
                case "moat":
                    // Water moat
                    g.beginFill(0x4169E1, 0.7);
                    g.drawRect(-_cellSize/2, -_cellSize/4, _cellSize, _cellSize/2);
                    g.endFill();
                    // Waves
                    g.lineStyle(2, 0xADD8E6, 0.5);
                    for (var i:int = 0; i < 3; i++) {
                        g.moveTo(-_cellSize/2 + i * 15, 0);
                        g.curveTo(-_cellSize/2 + i * 15 + 7, -5, -_cellSize/2 + i * 15 + 15, 0);
                    }
                    break;
                    
                case "drawbridge":
                    // Bridge planks
                    g.beginFill(0x8B4513);
                    g.drawRect(-_cellSize/3, -5, _cellSize * 0.7, 10);
                    g.endFill();
                    // Chains
                    g.lineStyle(2, 0x808080);
                    g.moveTo(-_cellSize/3, -5);
                    g.lineTo(-_cellSize/3 - 10, -20);
                    g.moveTo(_cellSize/3, -5);
                    g.lineTo(_cellSize/3 + 10, -20);
                    break;
                    
                case "spire":
                    // Tall spire
                    g.beginFill(0xE6E6FA);
                    g.moveTo(0, -_cellSize * 2);
                    g.lineTo(-15, -_cellSize * 0.5);
                    g.lineTo(15, -_cellSize * 0.5);
                    g.endFill();
                    // Glow effect
                    g.beginFill(0xFFFFFF, 0.3);
                    g.drawCircle(0, -_cellSize, 20);
                    g.endFill();
                    break;
                    
                default:
                    // Generic special
                    g.beginFill(0x9932CC);
                    g.drawCircle(0, 0, 15);
                    g.endFill();
            }
        }
        
        /**
         * Apply damage visual overlay
         */
        private function applyDamageVisual(sprite:Sprite, health:int):void {
            var g:* = sprite.graphics;
            var damageLevel:Number = 1 - (health / 100);
            
            // Cracks
            g.lineStyle(2, 0x000000, damageLevel * 0.8);
            for (var i:int = 0; i < Math.ceil(damageLevel * 5); i++) {
                var cx:Number = (Math.random() - 0.5) * _cellSize * 0.8;
                var cy:Number = (Math.random() - 0.5) * _cellSize * 0.8;
                g.moveTo(cx, cy);
                g.lineTo(cx + (Math.random() - 0.5) * 20, cy + (Math.random() - 0.5) * 20);
            }
            
            // Darkening overlay
            var overlay:Shape = new Shape();
            overlay.graphics.beginFill(0x000000, damageLevel * 0.3);
            overlay.graphics.drawRect(-_cellSize/2, -_cellSize, _cellSize, _cellSize * 1.5);
            overlay.graphics.endFill();
            sprite.addChild(overlay);
        }
        
        /**
         * Get screen position for a part
         */
        public function getPartPosition(partId:String):Point {
            var sprite:Sprite = _partSprites[partId] as Sprite;
            if (sprite) {
                return new Point(sprite.x, sprite.y);
            }
            return new Point(width / 2, height / 2);
        }
        
        /**
         * Get center of the castle view
         */
        public function getCenter():Point {
            return new Point(
                _offsetX + (_gridWidth * _cellSize) / 2,
                _offsetY + (_gridHeight * _cellSize) / 2
            );
        }
    }
}
