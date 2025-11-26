package ui {
    
    import flash.display.Stage;
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    
    /**
     * AutoLayout - Centralized layout manager that automatically updates
     * all registered components when the stage resizes.
     * 
     * Usage:
     * 1. AutoLayout.getInstance().initialize(stage);
     * 2. AutoLayout.getInstance().register(component, layoutCallback);
     * 3. Component receives callback with new dimensions on resize
     */
    public class AutoLayout extends EventDispatcher {
        
        // Singleton
        private static var _instance:AutoLayout;
        
        // Events
        public static const LAYOUT_UPDATE:String = "layoutUpdate";
        
        // Stage reference
        private var _stage:Stage;
        
        // Current dimensions
        private var _width:Number = 800;
        private var _height:Number = 600;
        
        // Registered components
        private var _components:Vector.<Object>;
        
        // Layout modes
        public static const MODE_FILL:String = "fill";           // Fill entire area
        public static const MODE_FIT:String = "fit";             // Fit maintaining aspect ratio
        public static const MODE_CENTER:String = "center";       // Center without scaling
        public static const MODE_STRETCH:String = "stretch";     // Stretch to fill (may distort)
        
        // Anchor points
        public static const ANCHOR_TOP_LEFT:String = "topLeft";
        public static const ANCHOR_TOP_CENTER:String = "topCenter";
        public static const ANCHOR_TOP_RIGHT:String = "topRight";
        public static const ANCHOR_CENTER_LEFT:String = "centerLeft";
        public static const ANCHOR_CENTER:String = "center";
        public static const ANCHOR_CENTER_RIGHT:String = "centerRight";
        public static const ANCHOR_BOTTOM_LEFT:String = "bottomLeft";
        public static const ANCHOR_BOTTOM_CENTER:String = "bottomCenter";
        public static const ANCHOR_BOTTOM_RIGHT:String = "bottomRight";
        
        /**
         * Constructor (private for singleton)
         */
        public function AutoLayout() {
            if (_instance != null) {
                throw new Error("AutoLayout is a singleton. Use getInstance()");
            }
            _components = new Vector.<Object>();
        }
        
        /**
         * Get singleton instance
         */
        public static function getInstance():AutoLayout {
            if (_instance == null) {
                _instance = new AutoLayout();
            }
            return _instance;
        }
        
        /**
         * Initialize with stage reference
         */
        public function initialize(stage:Stage):void {
            _stage = stage;
            _width = stage.stageWidth;
            _height = stage.stageHeight;
            
            _stage.addEventListener(Event.RESIZE, onStageResize);
            
            trace("[AutoLayout] Initialized: " + _width + "x" + _height);
        }
        
        /**
         * Register a component for auto layout updates
         * @param component The DisplayObject to layout
         * @param callback Function(width:Number, height:Number):void
         * @param config Optional layout configuration
         */
        public function register(component:DisplayObject, callback:Function, config:Object = null):void {
            // Check if already registered
            for each (var item:Object in _components) {
                if (item.component == component) {
                    item.callback = callback;
                    item.config = config || {};
                    return;
                }
            }
            
            // Add new registration
            _components.push({
                component: component,
                callback: callback,
                config: config || {}
            });
            
            // Immediately call with current dimensions
            callback(_width, _height);
            
            trace("[AutoLayout] Registered component: " + component);
        }
        
        /**
         * Unregister a component
         */
        public function unregister(component:DisplayObject):void {
            for (var i:int = _components.length - 1; i >= 0; i--) {
                if (_components[i].component == component) {
                    _components.splice(i, 1);
                    trace("[AutoLayout] Unregistered component: " + component);
                    return;
                }
            }
        }
        
        /**
         * Handle stage resize
         */
        private function onStageResize(e:Event):void {
            _width = _stage.stageWidth;
            _height = _stage.stageHeight;
            
            trace("[AutoLayout] Stage resized: " + _width + "x" + _height);
            
            updateAllComponents();
            
            dispatchEvent(new Event(LAYOUT_UPDATE));
        }
        
        /**
         * Update all registered components
         */
        public function updateAllComponents():void {
            for each (var item:Object in _components) {
                if (item.component && item.callback != null) {
                    try {
                        item.callback(_width, _height);
                    } catch (e:Error) {
                        trace("[AutoLayout] Error updating component: " + e.message);
                    }
                }
            }
        }
        
        /**
         * Force layout update
         */
        public function forceUpdate():void {
            if (_stage) {
                _width = _stage.stageWidth;
                _height = _stage.stageHeight;
            }
            updateAllComponents();
        }
        
        // ============ LAYOUT HELPERS ============
        
        /**
         * Calculate position based on anchor point
         */
        public function getAnchorPosition(
            anchor:String, 
            objectWidth:Number, 
            objectHeight:Number,
            margin:Number = 0
        ):Object {
            var pos:Object = { x: 0, y: 0 };
            
            switch (anchor) {
                case ANCHOR_TOP_LEFT:
                    pos.x = margin;
                    pos.y = margin;
                    break;
                case ANCHOR_TOP_CENTER:
                    pos.x = (_width - objectWidth) / 2;
                    pos.y = margin;
                    break;
                case ANCHOR_TOP_RIGHT:
                    pos.x = _width - objectWidth - margin;
                    pos.y = margin;
                    break;
                case ANCHOR_CENTER_LEFT:
                    pos.x = margin;
                    pos.y = (_height - objectHeight) / 2;
                    break;
                case ANCHOR_CENTER:
                    pos.x = (_width - objectWidth) / 2;
                    pos.y = (_height - objectHeight) / 2;
                    break;
                case ANCHOR_CENTER_RIGHT:
                    pos.x = _width - objectWidth - margin;
                    pos.y = (_height - objectHeight) / 2;
                    break;
                case ANCHOR_BOTTOM_LEFT:
                    pos.x = margin;
                    pos.y = _height - objectHeight - margin;
                    break;
                case ANCHOR_BOTTOM_CENTER:
                    pos.x = (_width - objectWidth) / 2;
                    pos.y = _height - objectHeight - margin;
                    break;
                case ANCHOR_BOTTOM_RIGHT:
                    pos.x = _width - objectWidth - margin;
                    pos.y = _height - objectHeight - margin;
                    break;
            }
            
            return pos;
        }
        
        /**
         * Calculate percentage of width
         */
        public function percentWidth(percent:Number):Number {
            return _width * percent / 100;
        }
        
        /**
         * Calculate percentage of height
         */
        public function percentHeight(percent:Number):Number {
            return _height * percent / 100;
        }
        
        /**
         * Calculate responsive value based on min stage dimension
         */
        public function responsive(baseValue:Number, minDimension:Number = 600):Number {
            var scale:Number = Math.min(_width, _height) / minDimension;
            return baseValue * Math.max(0.5, Math.min(2, scale));
        }
        
        /**
         * Get safe area with margins
         */
        public function getSafeArea(margin:Number = 20):Object {
            return {
                x: margin,
                y: margin,
                width: _width - margin * 2,
                height: _height - margin * 2,
                right: _width - margin,
                bottom: _height - margin,
                centerX: _width / 2,
                centerY: _height / 2
            };
        }
        
        /**
         * Calculate grid layout positions
         */
        public function getGridLayout(
            columns:int, 
            rows:int, 
            cellWidth:Number, 
            cellHeight:Number, 
            gapX:Number = 10, 
            gapY:Number = 10
        ):Array {
            var positions:Array = [];
            var totalWidth:Number = columns * cellWidth + (columns - 1) * gapX;
            var totalHeight:Number = rows * cellHeight + (rows - 1) * gapY;
            var startX:Number = (_width - totalWidth) / 2;
            var startY:Number = (_height - totalHeight) / 2;
            
            for (var row:int = 0; row < rows; row++) {
                for (var col:int = 0; col < columns; col++) {
                    positions.push({
                        x: startX + col * (cellWidth + gapX),
                        y: startY + row * (cellHeight + gapY),
                        width: cellWidth,
                        height: cellHeight,
                        row: row,
                        col: col,
                        index: row * columns + col
                    });
                }
            }
            
            return positions;
        }
        
        // ============ GETTERS ============
        
        public function get width():Number { return _width; }
        public function get height():Number { return _height; }
        public function get stage():Stage { return _stage; }
        public function get aspectRatio():Number { return _width / _height; }
        public function get isLandscape():Boolean { return _width >= _height; }
        public function get isPortrait():Boolean { return _width < _height; }
        public function get minDimension():Number { return Math.min(_width, _height); }
        public function get maxDimension():Number { return Math.max(_width, _height); }
    }
}
