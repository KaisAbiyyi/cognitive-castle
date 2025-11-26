package ui {
    
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.system.Capabilities;
    
    /**
     * LayoutManager - Multi-resolution support and responsive layout system.
     * Handles different screen sizes, safe zones, and responsive grid calculations.
     * 
     * T1-059, T1-060, T1-061
     */
    public class LayoutManager extends EventDispatcher {
        
        // Singleton
        private static var _instance:LayoutManager;
        
        // Events
        public static const LAYOUT_CHANGED:String = "layoutChanged";
        
        // Design reference (base design size)
        public static const DESIGN_WIDTH:Number = 800;
        public static const DESIGN_HEIGHT:Number = 600;
        
        // Device types
        public static const DEVICE_PHONE:String = "phone";
        public static const DEVICE_TABLET:String = "tablet";
        public static const DEVICE_DESKTOP:String = "desktop";
        
        // Orientation
        public static const ORIENTATION_PORTRAIT:String = "portrait";
        public static const ORIENTATION_LANDSCAPE:String = "landscape";
        
        // Current dimensions
        private var _stageWidth:Number = DESIGN_WIDTH;
        private var _stageHeight:Number = DESIGN_HEIGHT;
        private var _scale:Number = 1.0;
        private var _scaleX:Number = 1.0;
        private var _scaleY:Number = 1.0;
        
        // Safe zones (for notch, status bar, navigation bar)
        private var _safeTop:Number = 0;
        private var _safeBottom:Number = 0;
        private var _safeLeft:Number = 0;
        private var _safeRight:Number = 0;
        
        // Device info
        private var _deviceType:String = DEVICE_DESKTOP;
        private var _orientation:String = ORIENTATION_LANDSCAPE;
        private var _dpi:Number = 96;
        private var _isTouch:Boolean = false;
        
        // Grid system
        private var _columns:int = 12;
        private var _gutterWidth:Number = 16;
        private var _marginWidth:Number = 24;
        
        // Stage reference
        private var _stage:Stage;
        
        /**
         * Constructor (private for singleton)
         */
        public function LayoutManager() {
            if (_instance != null) {
                throw new Error("LayoutManager is a singleton. Use getInstance()");
            }
            detectDeviceCapabilities();
        }
        
        /**
         * Get singleton instance
         */
        public static function getInstance():LayoutManager {
            if (_instance == null) {
                _instance = new LayoutManager();
            }
            return _instance;
        }
        
        /**
         * Initialize with stage reference
         */
        public function initialize(stage:Stage):void {
            _stage = stage;
            _stageWidth = stage.stageWidth;
            _stageHeight = stage.stageHeight;
            
            // Listen for resize
            _stage.addEventListener(Event.RESIZE, onStageResize);
            
            // Calculate initial values
            calculateLayout();
            
            trace("[LayoutManager] Initialized: " + _stageWidth + "x" + _stageHeight + 
                  " Device: " + _deviceType + " DPI: " + _dpi);
        }
        
        /**
         * Detect device capabilities
         */
        private function detectDeviceCapabilities():void {
            // Get DPI
            _dpi = Capabilities.screenDPI;
            
            // Detect touch
            _isTouch = Capabilities.touchscreenType != "none";
            
            // Get screen dimensions
            var screenWidth:Number = Capabilities.screenResolutionX;
            var screenHeight:Number = Capabilities.screenResolutionY;
            var diagonal:Number = Math.sqrt(screenWidth * screenWidth + screenHeight * screenHeight) / _dpi;
            
            // Determine device type based on screen diagonal
            if (diagonal < 7) {
                _deviceType = DEVICE_PHONE;
                _safeTop = 44;    // Status bar + notch
                _safeBottom = 34; // Home indicator
            } else if (diagonal < 12) {
                _deviceType = DEVICE_TABLET;
                _safeTop = 24;
                _safeBottom = 20;
            } else {
                _deviceType = DEVICE_DESKTOP;
                _safeTop = 0;
                _safeBottom = 0;
            }
            
            trace("[LayoutManager] Detected: " + _deviceType + 
                  " Touch: " + _isTouch + " DPI: " + _dpi);
        }
        
        /**
         * Calculate layout values
         */
        private function calculateLayout():void {
            // Determine orientation
            _orientation = (_stageWidth >= _stageHeight) ? 
                           ORIENTATION_LANDSCAPE : ORIENTATION_PORTRAIT;
            
            // Calculate scale factors
            _scaleX = _stageWidth / DESIGN_WIDTH;
            _scaleY = _stageHeight / DESIGN_HEIGHT;
            
            // Use uniform scale (maintain aspect ratio)
            _scale = Math.min(_scaleX, _scaleY);
            
            // Adjust grid based on device
            switch (_deviceType) {
                case DEVICE_PHONE:
                    _columns = 4;
                    _gutterWidth = 8 * _scale;
                    _marginWidth = 16 * _scale;
                    break;
                case DEVICE_TABLET:
                    _columns = 8;
                    _gutterWidth = 12 * _scale;
                    _marginWidth = 20 * _scale;
                    break;
                case DEVICE_DESKTOP:
                default:
                    _columns = 12;
                    _gutterWidth = 16 * _scale;
                    _marginWidth = 24 * _scale;
                    break;
            }
        }
        
        /**
         * Handle stage resize
         */
        private function onStageResize(e:Event):void {
            _stageWidth = _stage.stageWidth;
            _stageHeight = _stage.stageHeight;
            
            calculateLayout();
            
            dispatchEvent(new Event(LAYOUT_CHANGED));
            
            trace("[LayoutManager] Resized: " + _stageWidth + "x" + _stageHeight);
        }
        
        // ============ COORDINATE CONVERSION ============
        
        /**
         * Convert design coordinate to actual screen coordinate
         */
        public function toScreenX(designX:Number):Number {
            return designX * _scale + (_stageWidth - DESIGN_WIDTH * _scale) / 2;
        }
        
        public function toScreenY(designY:Number):Number {
            return designY * _scale + (_stageHeight - DESIGN_HEIGHT * _scale) / 2;
        }
        
        /**
         * Convert screen coordinate to design coordinate
         */
        public function toDesignX(screenX:Number):Number {
            return (screenX - (_stageWidth - DESIGN_WIDTH * _scale) / 2) / _scale;
        }
        
        public function toDesignY(screenY:Number):Number {
            return (screenY - (_stageHeight - DESIGN_HEIGHT * _scale) / 2) / _scale;
        }
        
        /**
         * Scale a design value to screen size
         */
        public function scaleValue(designValue:Number):Number {
            return designValue * _scale;
        }
        
        // ============ SAFE ZONES ============
        
        /**
         * Get safe area bounds (excluding notch, status bar, etc.)
         */
        public function getSafeArea():Object {
            return {
                x: _safeLeft,
                y: _safeTop,
                width: _stageWidth - _safeLeft - _safeRight,
                height: _stageHeight - _safeTop - _safeBottom,
                right: _stageWidth - _safeRight,
                bottom: _stageHeight - _safeBottom
            };
        }
        
        /**
         * Set custom safe zone margins
         */
        public function setSafeZones(top:Number, bottom:Number, left:Number, right:Number):void {
            _safeTop = top;
            _safeBottom = bottom;
            _safeLeft = left;
            _safeRight = right;
        }
        
        // ============ GRID SYSTEM ============
        
        /**
         * Get column width for responsive grid
         * @param numColumns Number of columns element should span
         */
        public function getColumnWidth(numColumns:int = 1):Number {
            var safeArea:Object = getSafeArea();
            var totalGutters:Number = (_columns - 1) * _gutterWidth;
            var availableWidth:Number = safeArea.width - 2 * _marginWidth - totalGutters;
            var singleColumn:Number = availableWidth / _columns;
            
            return singleColumn * numColumns + _gutterWidth * (numColumns - 1);
        }
        
        /**
         * Get X position for a column
         * @param columnIndex 0-based column index
         */
        public function getColumnX(columnIndex:int):Number {
            var safeArea:Object = getSafeArea();
            var singleColumn:Number = getColumnWidth(1);
            
            return safeArea.x + _marginWidth + columnIndex * (singleColumn + _gutterWidth);
        }
        
        /**
         * Get row height for responsive grid
         * @param numRows Number of rows element should span
         * @param totalRows Total rows in the grid
         */
        public function getRowHeight(numRows:int = 1, totalRows:int = 12):Number {
            var safeArea:Object = getSafeArea();
            var totalGutters:Number = (totalRows - 1) * _gutterWidth;
            var availableHeight:Number = safeArea.height - 2 * _marginWidth - totalGutters;
            var singleRow:Number = availableHeight / totalRows;
            
            return singleRow * numRows + _gutterWidth * (numRows - 1);
        }
        
        // ============ RESPONSIVE SIZING ============
        
        /**
         * Get responsive font size
         */
        public function getFontSize(baseSize:Number):Number {
            var scaled:Number = baseSize * _scale;
            
            // Ensure minimum readable size
            var minSize:Number = (_deviceType == DEVICE_PHONE) ? 12 : 10;
            return Math.max(scaled, minSize);
        }
        
        /**
         * Get responsive button size
         */
        public function getButtonSize():Number {
            switch (_deviceType) {
                case DEVICE_PHONE:
                    return 44 * _scale; // Apple HIG minimum
                case DEVICE_TABLET:
                    return 48 * _scale;
                case DEVICE_DESKTOP:
                default:
                    return 40 * _scale;
            }
        }
        
        /**
         * Get responsive padding
         */
        public function getPadding(base:Number = 16):Number {
            return base * _scale;
        }
        
        /**
         * Get stimulus size for display
         */
        public function getStimulusSize():Number {
            var baseSize:Number = 80;
            switch (_deviceType) {
                case DEVICE_PHONE:
                    return baseSize * _scale * 1.2; // Larger on phone
                case DEVICE_TABLET:
                    return baseSize * _scale * 1.1;
                case DEVICE_DESKTOP:
                default:
                    return baseSize * _scale;
            }
        }
        
        /**
         * Get input grid configuration
         */
        public function getInputGridConfig():Object {
            switch (_deviceType) {
                case DEVICE_PHONE:
                    return { rows: 2, cols: 3, cellSize: 60 * _scale, gap: 8 * _scale };
                case DEVICE_TABLET:
                    return { rows: 2, cols: 3, cellSize: 80 * _scale, gap: 12 * _scale };
                case DEVICE_DESKTOP:
                default:
                    return { rows: 2, cols: 3, cellSize: 70 * _scale, gap: 10 * _scale };
            }
        }
        
        // ============ CENTER POSITIONING ============
        
        /**
         * Get center X of screen
         */
        public function getCenterX():Number {
            return _stageWidth / 2;
        }
        
        /**
         * Get center Y of screen
         */
        public function getCenterY():Number {
            return _stageHeight / 2;
        }
        
        /**
         * Get center X of safe area
         */
        public function getSafeCenterX():Number {
            var safeArea:Object = getSafeArea();
            return safeArea.x + safeArea.width / 2;
        }
        
        /**
         * Get center Y of safe area
         */
        public function getSafeCenterY():Number {
            var safeArea:Object = getSafeArea();
            return safeArea.y + safeArea.height / 2;
        }
        
        // ============ GETTERS ============
        
        public function get stageWidth():Number { return _stageWidth; }
        public function get stageHeight():Number { return _stageHeight; }
        public function get scale():Number { return _scale; }
        public function get scaleX():Number { return _scaleX; }
        public function get scaleY():Number { return _scaleY; }
        public function get deviceType():String { return _deviceType; }
        public function get orientation():String { return _orientation; }
        public function get isTouch():Boolean { return _isTouch; }
        public function get dpi():Number { return _dpi; }
        public function get columns():int { return _columns; }
        public function get gutterWidth():Number { return _gutterWidth; }
        public function get marginWidth():Number { return _marginWidth; }
        public function get safeTop():Number { return _safeTop; }
        public function get safeBottom():Number { return _safeBottom; }
        public function get safeLeft():Number { return _safeLeft; }
        public function get safeRight():Number { return _safeRight; }
    }
}
