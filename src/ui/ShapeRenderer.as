package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Graphics;
    import flash.filters.GlowFilter;
    import config.VisualConfig;
    
    /**
     * ShapeRenderer - Renders 6 core shapes with proper vector graphics.
     * Used by StimulusView, InputButton, and other UI components.
     * 
     * T1-062: Visual vocabulary - 6 shapes
     */
    public class ShapeRenderer extends Sprite {
        
        // Shape being rendered
        private var _shape:String;
        private var _color:uint;
        private var _size:Number;
        
        // Visual elements
        private var _shapeGraphic:Shape;
        private var _glowFilter:GlowFilter;
        
        /**
         * Constructor
         */
        public function ShapeRenderer(shape:String = "circle", color:uint = 0x0072B2, size:Number = 60) {
            _shape = shape;
            _color = color;
            _size = size;
            
            createShape();
        }
        
        /**
         * Create the shape graphic
         */
        private function createShape():void {
            if (_shapeGraphic) {
                if (contains(_shapeGraphic)) {
                    removeChild(_shapeGraphic);
                }
            }
            
            _shapeGraphic = new Shape();
            var g:Graphics = _shapeGraphic.graphics;
            
            // Draw with stroke for better visibility
            g.lineStyle(2, darkenColor(_color, 0.3), 1);
            g.beginFill(_color);
            
            var halfSize:Number = _size / 2;
            
            switch (_shape) {
                case VisualConfig.SHAPE_CIRCLE:
                    drawCircle(g, halfSize);
                    break;
                case VisualConfig.SHAPE_SQUARE:
                    drawSquare(g, halfSize);
                    break;
                case VisualConfig.SHAPE_TRIANGLE:
                    drawTriangle(g, halfSize);
                    break;
                case VisualConfig.SHAPE_STAR:
                    drawStar(g, halfSize, 5);
                    break;
                case VisualConfig.SHAPE_HEXAGON:
                    drawPolygon(g, halfSize, 6);
                    break;
                case VisualConfig.SHAPE_DIAMOND:
                    drawDiamond(g, halfSize);
                    break;
                default:
                    drawCircle(g, halfSize);
            }
            
            g.endFill();
            
            addChild(_shapeGraphic);
        }
        
        // ============ SHAPE DRAWING METHODS ============
        
        private function drawCircle(g:Graphics, radius:Number):void {
            g.drawCircle(0, 0, radius);
        }
        
        private function drawSquare(g:Graphics, halfSize:Number):void {
            g.drawRect(-halfSize, -halfSize, halfSize * 2, halfSize * 2);
        }
        
        private function drawTriangle(g:Graphics, halfSize:Number):void {
            // Equilateral triangle centered
            var height:Number = halfSize * 2 * Math.sin(Math.PI / 3);
            var offsetY:Number = height / 3; // Center vertically
            
            g.moveTo(0, -height + offsetY);
            g.lineTo(-halfSize, offsetY);
            g.lineTo(halfSize, offsetY);
            g.lineTo(0, -height + offsetY);
        }
        
        private function drawStar(g:Graphics, radius:Number, points:int):void {
            var innerRadius:Number = radius * 0.4;
            var angle:Number = -Math.PI / 2; // Start from top
            var step:Number = Math.PI / points;
            
            g.moveTo(
                Math.cos(angle) * radius,
                Math.sin(angle) * radius
            );
            
            for (var i:int = 1; i <= points * 2; i++) {
                angle += step;
                var r:Number = (i % 2 == 0) ? radius : innerRadius;
                g.lineTo(
                    Math.cos(angle) * r,
                    Math.sin(angle) * r
                );
            }
        }
        
        private function drawPolygon(g:Graphics, radius:Number, sides:int):void {
            var angle:Number = -Math.PI / 2; // Start from top
            var step:Number = (Math.PI * 2) / sides;
            
            g.moveTo(
                Math.cos(angle) * radius,
                Math.sin(angle) * radius
            );
            
            for (var i:int = 1; i <= sides; i++) {
                angle += step;
                g.lineTo(
                    Math.cos(angle) * radius,
                    Math.sin(angle) * radius
                );
            }
        }
        
        private function drawDiamond(g:Graphics, halfSize:Number):void {
            // Taller diamond (rotated square stretched)
            var vStretch:Number = 1.3;
            
            g.moveTo(0, -halfSize * vStretch);
            g.lineTo(halfSize, 0);
            g.lineTo(0, halfSize * vStretch);
            g.lineTo(-halfSize, 0);
            g.lineTo(0, -halfSize * vStretch);
        }
        
        // ============ VISUAL EFFECTS ============
        
        /**
         * Apply glow effect
         */
        public function setGlow(color:uint, blur:Number = 15, strength:Number = 2):void {
            _glowFilter = new GlowFilter(color, 1, blur, blur, strength);
            this.filters = [_glowFilter];
        }
        
        /**
         * Remove glow effect
         */
        public function removeGlow():void {
            this.filters = [];
            _glowFilter = null;
        }
        
        /**
         * Apply correct feedback glow
         */
        public function showCorrect():void {
            setGlow(VisualConfig.GLOW_CORRECT, 20, 3);
        }
        
        /**
         * Apply wrong feedback glow
         */
        public function showWrong():void {
            setGlow(VisualConfig.GLOW_WRONG, 20, 3);
        }
        
        /**
         * Apply highlight glow
         */
        public function showHighlight():void {
            setGlow(VisualConfig.GLOW_HIGHLIGHT, 15, 2);
        }
        
        // ============ UPDATE METHODS ============
        
        /**
         * Update the shape
         */
        public function setShape(shape:String):void {
            if (_shape != shape) {
                _shape = shape;
                createShape();
            }
        }
        
        /**
         * Update the color
         */
        public function setColor(color:uint):void {
            if (_color != color) {
                _color = color;
                createShape();
            }
        }
        
        /**
         * Update the size
         */
        public function setSize(size:Number):void {
            if (_size != size) {
                _size = size;
                createShape();
            }
        }
        
        /**
         * Update all properties at once
         */
        public function update(shape:String, color:uint, size:Number):void {
            _shape = shape;
            _color = color;
            _size = size;
            createShape();
        }
        
        // ============ UTILITY ============
        
        /**
         * Darken a color by a factor
         */
        private function darkenColor(color:uint, factor:Number):uint {
            var r:int = ((color >> 16) & 0xFF) * (1 - factor);
            var g:int = ((color >> 8) & 0xFF) * (1 - factor);
            var b:int = (color & 0xFF) * (1 - factor);
            
            return (r << 16) | (g << 8) | b;
        }
        
        /**
         * Lighten a color by a factor
         */
        private function lightenColor(color:uint, factor:Number):uint {
            var r:int = Math.min(255, ((color >> 16) & 0xFF) + (255 - ((color >> 16) & 0xFF)) * factor);
            var g:int = Math.min(255, ((color >> 8) & 0xFF) + (255 - ((color >> 8) & 0xFF)) * factor);
            var b:int = Math.min(255, (color & 0xFF) + (255 - (color & 0xFF)) * factor);
            
            return (r << 16) | (g << 8) | b;
        }
        
        // ============ GETTERS ============
        
        public function get shapeType():String { return _shape; }
        public function get color():uint { return _color; }
        public function get size():Number { return _size; }
    }
}
