package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Graphics;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;
    
    /**
     * SettingsPanel - Settings overlay with volume, haptic, and accessibility options.
     * 
     * T1-080: Settings Panel
     */
    public class SettingsPanel extends Sprite {
        
        // Events
        public static const SETTINGS_CHANGED:String = "settingsChanged";
        public static const CLOSE_CLICKED:String = "closeClicked";
        
        // Settings values
        private var _musicVolume:Number = 0.8;
        private var _sfxVolume:Number = 0.8;
        private var _hapticEnabled:Boolean = true;
        private var _colorBlindMode:Boolean = false;
        private var _showTimer:Boolean = true;
        
        // Dimensions
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Visual elements
        private var _overlay:Shape;
        private var _panel:Sprite;
        private var _titleText:TextField;
        private var _closeButton:Sprite;
        private var _settingsContainer:Sprite;
        
        // Controls
        private var _musicSlider:Sprite;
        private var _sfxSlider:Sprite;
        private var _hapticToggle:Sprite;
        private var _colorBlindToggle:Sprite;
        private var _timerToggle:Sprite;
        
        /**
         * Constructor
         */
        public function SettingsPanel() {
            visible = false;
        }
        
        /**
         * Initialize panel
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            createOverlay();
            createPanel();
            createTitle();
            createCloseButton();
            createSettings();
        }
        
        /**
         * Create dark overlay
         */
        private function createOverlay():void {
            _overlay = new Shape();
            drawOverlay();
            addChild(_overlay);
            
            // Close on overlay click
            _overlay.addEventListener(MouseEvent.CLICK, onOverlayClick);
        }
        
        private function drawOverlay():void {
            var g:Graphics = _overlay.graphics;
            g.clear();
            g.beginFill(0x000000, 0.7);
            g.drawRect(0, 0, _stageWidth, _stageHeight);
            g.endFill();
        }
        
        private function onOverlayClick(e:MouseEvent):void {
            // Only close if clicking directly on overlay
            if (e.target == _overlay) {
                dispatchEvent(new Event(CLOSE_CLICKED));
            }
        }
        
        /**
         * Create panel background
         */
        private function createPanel():void {
            _panel = new Sprite();
            
            var panelWidth:Number = Math.min(_stageWidth * 0.6, 450);
            var panelHeight:Number = Math.min(_stageHeight * 0.7, 450);
            
            var g:Graphics = _panel.graphics;
            
            // Shadow
            g.beginFill(0x000000, 0.3);
            g.drawRoundRect(5, 5, panelWidth, panelHeight, 20, 20);
            g.endFill();
            
            // Main panel
            g.beginFill(0x1A1A2E, 0.98);
            g.lineStyle(3, 0x4A90E2, 1);
            g.drawRoundRect(0, 0, panelWidth, panelHeight, 20, 20);
            g.endFill();
            
            // Header
            g.beginFill(0x4A90E2, 1);
            g.drawRoundRect(0, 0, panelWidth, 60, 20, 20);
            g.drawRect(0, 40, panelWidth, 20);
            g.endFill();
            
            _panel.x = (_stageWidth - panelWidth) / 2;
            _panel.y = (_stageHeight - panelHeight) / 2;
            
            addChild(_panel);
        }
        
        /**
         * Create title
         */
        private function createTitle():void {
            _titleText = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 24;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            _titleText.defaultTextFormat = format;
            _titleText.text = "SETTINGS";
            _titleText.width = _panel.width;
            _titleText.height = 40;
            _titleText.selectable = false;
            _titleText.x = 0;
            _titleText.y = 15;
            
            _panel.addChild(_titleText);
        }
        
        /**
         * Create close button
         */
        private function createCloseButton():void {
            _closeButton = new Sprite();
            
            var size:Number = 30;
            var g:Graphics = _closeButton.graphics;
            
            g.beginFill(0xE53E3E);
            g.drawCircle(size / 2, size / 2, size / 2);
            g.endFill();
            
            // X icon
            g.lineStyle(3, 0xFFFFFF);
            g.moveTo(10, 10);
            g.lineTo(20, 20);
            g.moveTo(20, 10);
            g.lineTo(10, 20);
            
            _closeButton.x = _panel.width - size - 15;
            _closeButton.y = 15;
            _closeButton.buttonMode = true;
            _closeButton.useHandCursor = true;
            _closeButton.addEventListener(MouseEvent.CLICK, onCloseClick);
            
            _panel.addChild(_closeButton);
        }
        
        private function onCloseClick(e:MouseEvent):void {
            dispatchEvent(new Event(CLOSE_CLICKED));
        }
        
        /**
         * Create settings controls
         */
        private function createSettings():void {
            _settingsContainer = new Sprite();
            _settingsContainer.x = 30;
            _settingsContainer.y = 80;
            
            var yPos:Number = 0;
            var spacing:Number = 60;
            
            // Music volume
            createLabel("Music Volume", 0, yPos);
            _musicSlider = createSlider(_musicVolume, 150, yPos + 25);
            _settingsContainer.addChild(_musicSlider);
            yPos += spacing;
            
            // SFX volume
            createLabel("Sound Effects", 0, yPos);
            _sfxSlider = createSlider(_sfxVolume, 150, yPos + 25);
            _settingsContainer.addChild(_sfxSlider);
            yPos += spacing;
            
            // Haptic toggle
            createLabel("Haptic Feedback", 0, yPos);
            _hapticToggle = createToggle(_hapticEnabled, 150, yPos);
            _settingsContainer.addChild(_hapticToggle);
            yPos += spacing;
            
            // Color blind mode
            createLabel("Color Blind Mode", 0, yPos);
            _colorBlindToggle = createToggle(_colorBlindMode, 150, yPos);
            _settingsContainer.addChild(_colorBlindToggle);
            yPos += spacing;
            
            // Show timer
            createLabel("Show Timer", 0, yPos);
            _timerToggle = createToggle(_showTimer, 150, yPos);
            _settingsContainer.addChild(_timerToggle);
            
            _panel.addChild(_settingsContainer);
        }
        
        /**
         * Create setting label
         */
        private function createLabel(text:String, x:Number, y:Number):void {
            var tf:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 16;
            format.color = 0xFFFFFF;
            
            tf.defaultTextFormat = format;
            tf.text = text;
            tf.width = 200;
            tf.height = 25;
            tf.selectable = false;
            tf.x = x;
            tf.y = y;
            
            _settingsContainer.addChild(tf);
        }
        
        /**
         * Create slider control
         */
        private function createSlider(value:Number, x:Number, y:Number):Sprite {
            var slider:Sprite = new Sprite();
            slider.x = x;
            slider.y = y;
            
            var width:Number = 180;
            var height:Number = 8;
            
            // Track
            var track:Shape = new Shape();
            track.graphics.beginFill(0x333355);
            track.graphics.drawRoundRect(0, 0, width, height, 4, 4);
            track.graphics.endFill();
            slider.addChild(track);
            
            // Fill
            var fill:Shape = new Shape();
            fill.name = "fill";
            fill.graphics.beginFill(0x4A90E2);
            fill.graphics.drawRoundRect(0, 0, width * value, height, 4, 4);
            fill.graphics.endFill();
            slider.addChild(fill);
            
            // Handle
            var handle:Sprite = new Sprite();
            handle.name = "handle";
            handle.graphics.beginFill(0xFFFFFF);
            handle.graphics.lineStyle(2, 0x4A90E2);
            handle.graphics.drawCircle(0, height / 2, 10);
            handle.graphics.endFill();
            handle.x = width * value;
            handle.buttonMode = true;
            slider.addChild(handle);
            
            // Value label
            var valueTF:TextField = new TextField();
            valueTF.name = "valueLabel";
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 12;
            format.color = 0xAAAAAA;
            valueTF.defaultTextFormat = format;
            valueTF.text = Math.round(value * 100) + "%";
            valueTF.width = 40;
            valueTF.height = 20;
            valueTF.x = width + 10;
            valueTF.y = -6;
            valueTF.selectable = false;
            slider.addChild(valueTF);
            
            // Store width for calculations
            slider.name = String(width);
            
            // Interaction
            slider.addEventListener(MouseEvent.MOUSE_DOWN, onSliderDown);
            
            return slider;
        }
        
        private function onSliderDown(e:MouseEvent):void {
            var slider:Sprite = e.currentTarget as Sprite;
            var width:Number = Number(slider.name);
            
            stage.addEventListener(MouseEvent.MOUSE_MOVE, function onMove(me:MouseEvent):void {
                updateSliderValue(slider, width);
            });
            
            stage.addEventListener(MouseEvent.MOUSE_UP, function onUp(me:MouseEvent):void {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onUp);
                dispatchEvent(new Event(SETTINGS_CHANGED));
            });
            
            updateSliderValue(slider, width);
        }
        
        private function updateSliderValue(slider:Sprite, width:Number):void {
            var localX:Number = slider.mouseX;
            var value:Number = Math.max(0, Math.min(1, localX / width));
            
            // Update fill
            var fill:Shape = slider.getChildByName("fill") as Shape;
            if (fill) {
                fill.graphics.clear();
                fill.graphics.beginFill(0x4A90E2);
                fill.graphics.drawRoundRect(0, 0, width * value, 8, 4, 4);
                fill.graphics.endFill();
            }
            
            // Update handle
            var handle:Sprite = slider.getChildByName("handle") as Sprite;
            if (handle) {
                handle.x = width * value;
            }
            
            // Update label
            var valueTF:TextField = slider.getChildByName("valueLabel") as TextField;
            if (valueTF) {
                valueTF.text = Math.round(value * 100) + "%";
            }
            
            // Store value
            if (slider == _musicSlider) {
                _musicVolume = value;
            } else if (slider == _sfxSlider) {
                _sfxVolume = value;
            }
        }
        
        /**
         * Create toggle control
         */
        private function createToggle(value:Boolean, x:Number, y:Number):Sprite {
            var toggle:Sprite = new Sprite();
            toggle.x = x;
            toggle.y = y;
            
            var width:Number = 60;
            var height:Number = 28;
            
            // Track
            var track:Shape = new Shape();
            track.name = "track";
            drawToggleTrack(track, width, height, value);
            toggle.addChild(track);
            
            // Handle
            var handle:Shape = new Shape();
            handle.name = "handle";
            handle.graphics.beginFill(0xFFFFFF);
            handle.graphics.drawCircle(0, 0, 10);
            handle.graphics.endFill();
            handle.x = value ? width - 14 : 14;
            handle.y = height / 2;
            toggle.addChild(handle);
            
            // Store state
            toggle.name = value ? "on" : "off";
            
            // Interaction
            toggle.buttonMode = true;
            toggle.useHandCursor = true;
            toggle.addEventListener(MouseEvent.CLICK, onToggleClick);
            
            return toggle;
        }
        
        private function drawToggleTrack(track:Shape, width:Number, height:Number, isOn:Boolean):void {
            track.graphics.clear();
            track.graphics.beginFill(isOn ? 0x4CAF50 : 0x555555);
            track.graphics.drawRoundRect(0, 0, width, height, height, height);
            track.graphics.endFill();
        }
        
        private function onToggleClick(e:MouseEvent):void {
            var toggle:Sprite = e.currentTarget as Sprite;
            var isOn:Boolean = toggle.name == "on";
            var newValue:Boolean = !isOn;
            
            // Update visual
            var track:Shape = toggle.getChildByName("track") as Shape;
            if (track) {
                drawToggleTrack(track, 60, 28, newValue);
            }
            
            var handle:Shape = toggle.getChildByName("handle") as Shape;
            if (handle) {
                handle.x = newValue ? 46 : 14;
            }
            
            toggle.name = newValue ? "on" : "off";
            
            // Update value
            if (toggle == _hapticToggle) {
                _hapticEnabled = newValue;
            } else if (toggle == _colorBlindToggle) {
                _colorBlindMode = newValue;
            } else if (toggle == _timerToggle) {
                _showTimer = newValue;
            }
            
            dispatchEvent(new Event(SETTINGS_CHANGED));
        }
        
        // ============ PUBLIC METHODS ============
        
        /**
         * Show settings panel
         */
        public function show():void {
            visible = true;
            alpha = 0;
            
            addEventListener(Event.ENTER_FRAME, function fadeIn(e:Event):void {
                alpha += 0.15;
                if (alpha >= 1) {
                    alpha = 1;
                    removeEventListener(Event.ENTER_FRAME, fadeIn);
                }
            });
        }
        
        /**
         * Hide settings panel
         */
        public function hide():void {
            addEventListener(Event.ENTER_FRAME, function fadeOut(e:Event):void {
                alpha -= 0.15;
                if (alpha <= 0) {
                    alpha = 0;
                    visible = false;
                    removeEventListener(Event.ENTER_FRAME, fadeOut);
                }
            });
        }
        
        /**
         * Get current settings
         */
        public function getSettings():Object {
            return {
                musicVolume: _musicVolume,
                sfxVolume: _sfxVolume,
                hapticEnabled: _hapticEnabled,
                colorBlindMode: _colorBlindMode,
                showTimer: _showTimer
            };
        }
        
        /**
         * Set settings values
         */
        public function setSettings(settings:Object):void {
            if (settings.hasOwnProperty("musicVolume")) {
                _musicVolume = settings.musicVolume;
            }
            if (settings.hasOwnProperty("sfxVolume")) {
                _sfxVolume = settings.sfxVolume;
            }
            if (settings.hasOwnProperty("hapticEnabled")) {
                _hapticEnabled = settings.hapticEnabled;
            }
            if (settings.hasOwnProperty("colorBlindMode")) {
                _colorBlindMode = settings.colorBlindMode;
            }
            if (settings.hasOwnProperty("showTimer")) {
                _showTimer = settings.showTimer;
            }
            
            // Update UI to reflect values
            // (Would need to update sliders and toggles)
        }
        
        /**
         * Resize handler
         */
        public function resize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            drawOverlay();
            
            if (_panel) {
                var panelWidth:Number = Math.min(_stageWidth * 0.6, 450);
                var panelHeight:Number = Math.min(_stageHeight * 0.7, 450);
                _panel.x = (_stageWidth - panelWidth) / 2;
                _panel.y = (_stageHeight - panelHeight) / 2;
            }
        }
        
        /**
         * Cleanup
         */
        public function dispose():void {
            if (_closeButton) {
                _closeButton.removeEventListener(MouseEvent.CLICK, onCloseClick);
            }
        }
        
        // ============ GETTERS ============
        
        public function get musicVolume():Number { return _musicVolume; }
        public function get sfxVolume():Number { return _sfxVolume; }
        public function get hapticEnabled():Boolean { return _hapticEnabled; }
        public function get colorBlindMode():Boolean { return _colorBlindMode; }
        public function get showTimer():Boolean { return _showTimer; }
    }
}
