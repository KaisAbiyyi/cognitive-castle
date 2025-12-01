package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Graphics;
    import flash.display.GradientType;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;
    import flash.filters.GlowFilter;
    
    /**
     * SettingsMenu - Full screen settings page with volume sliders.
     * Displays Music Volume and SFX Volume sliders with back button.
     */
    public class SettingsMenu extends Sprite {
        
        // Events
        public static const SETTINGS_CHANGED:String = "settingsChanged";
        public static const BACK_CLICKED:String = "backClicked";
        public static const CLOSE_CLICKED:String = "backClicked"; // Alias for compatibility
        
        // Settings values
        private var _musicVolume:Number = 0.8;
        private var _sfxVolume:Number = 0.8;
        
        // Dimensions
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Visual elements
        private var _background:Shape;
        private var _titleText:TextField;
        private var _backButton:Sprite;
        private var _settingsContainer:Sprite;
        
        // Slider components
        private var _musicSlider:Sprite;
        private var _sfxSlider:Sprite;
        private var _musicValueLabel:TextField;
        private var _sfxValueLabel:TextField;
        
        // Slider dimensions
        private var _sliderWidth:Number = 300;
        private var _sliderHeight:Number = 8;
        
        // Dragging state
        private var _isDragging:Boolean = false;
        private var _currentSlider:Sprite;
        private var _currentType:String;
        
        /**
         * Constructor
         */
        public function SettingsMenu() {
            visible = false;
        }
        
        /**
         * Initialize page
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            createBackground();
            createTitle();
            createBackButton();
            createSettings();
        }
        
        /**
         * Create gradient background
         */
        private function createBackground():void {
            _background = new Shape();
            drawBackground();
            addChild(_background);
        }
        
        private function drawBackground():void {
            var g:Graphics = _background.graphics;
            g.clear();
            
            // Gradient from dark blue to purple (same as main menu)
            var matrix:Matrix = new Matrix();
            matrix.createGradientBox(_stageWidth, _stageHeight, Math.PI / 2);
            
            g.beginGradientFill(
                GradientType.LINEAR,
                [0x1A1A2E, 0x16213E, 0x0F3460],
                [1, 1, 1],
                [0, 128, 255],
                matrix
            );
            g.drawRect(0, 0, _stageWidth, _stageHeight);
            g.endFill();
        }
        
        /**
         * Create title
         */
        private function createTitle():void {
            _titleText = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = Math.max(28, Math.min(_stageWidth * 0.04, 48));
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            _titleText.defaultTextFormat = format;
            _titleText.text = "SETTINGS";
            _titleText.width = _stageWidth;
            _titleText.height = 60;
            _titleText.selectable = false;
            _titleText.y = _stageHeight * 0.1;
            
            _titleText.filters = [
                new GlowFilter(0x4A90E2, 0.6, 10, 10, 1.5),
                new DropShadowFilter(3, 45, 0x000000, 0.5, 8, 8)
            ];
            
            addChild(_titleText);
        }
        
        /**
         * Create back button
         */
        private function createBackButton():void {
            _backButton = new Sprite();
            
            var btnWidth:Number = Math.max(140, Math.min(_stageWidth * 0.18, 200));
            var btnHeight:Number = Math.max(45, Math.min(_stageHeight * 0.07, 55));
            var cornerRadius:Number = btnHeight / 2; // Pill shape
            
            // Background container
            var bgContainer:Sprite = new Sprite();
            bgContainer.name = "bgContainer";
            var g:Graphics = bgContainer.graphics;
            
            // Draw pill-shaped button
            g.beginFill(0x2C3E50);
            g.drawRoundRect(-btnWidth / 2, -btnHeight / 2, btnWidth, btnHeight, cornerRadius, cornerRadius);
            g.endFill();
            
            // Arrow icon (chevron left)
            var arrowSize:Number = btnHeight * 0.3;
            var arrowX:Number = -btnWidth / 2 + btnHeight * 0.5;
            g.lineStyle(3, 0xFFFFFF, 1, false, "normal", "round", "round");
            g.moveTo(arrowX + arrowSize * 0.4, -arrowSize * 0.5);
            g.lineTo(arrowX - arrowSize * 0.1, 0);
            g.lineTo(arrowX + arrowSize * 0.4, arrowSize * 0.5);
            
            bgContainer.filters = [new DropShadowFilter(3, 45, 0x000000, 0.4, 8, 8)];
            _backButton.addChild(bgContainer);
            
            // Label
            var labelTF:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = Math.max(14, Math.min(btnHeight * 0.38, 18));
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            labelTF.defaultTextFormat = format;
            labelTF.text = "Back";
            labelTF.width = btnWidth - btnHeight;
            labelTF.height = btnHeight;
            labelTF.x = -btnWidth / 2 + btnHeight * 0.7;
            labelTF.y = (- Number(format.size) - 4) / 2;
            labelTF.selectable = false;
            labelTF.mouseEnabled = false;
            
            _backButton.addChild(labelTF);
            
            _backButton.x = _stageWidth * 0.12;
            _backButton.y = _stageHeight * 0.92;
            _backButton.buttonMode = true;
            _backButton.useHandCursor = true;
            _backButton.filters = [new DropShadowFilter(3, 45, 0x000000, 0.4, 6, 6)];
            
            _backButton.addEventListener(MouseEvent.CLICK, onBackClick);
            _backButton.addEventListener(MouseEvent.ROLL_OVER, onBackOver);
            _backButton.addEventListener(MouseEvent.ROLL_OUT, onBackOut);
            
            addChild(_backButton);
        }
        
        private function onBackClick(e:MouseEvent):void {
            dispatchEvent(new Event(BACK_CLICKED));
        }
        
        private function onBackOver(e:MouseEvent):void {
            _backButton.scaleX = 1.05;
            _backButton.scaleY = 1.05;
            var bgContainer:Sprite = _backButton.getChildByName("bgContainer") as Sprite;
            if (bgContainer) {
                bgContainer.filters = [
                    new DropShadowFilter(5, 45, 0x000000, 0.5, 12, 12),
                    new GlowFilter(0x4A90E2, 0.6, 20, 20)
                ];
            }
        }
        
        private function onBackOut(e:MouseEvent):void {
            _backButton.scaleX = 1.0;
            _backButton.scaleY = 1.0;
            var bgContainer:Sprite = _backButton.getChildByName("bgContainer") as Sprite;
            if (bgContainer) {
                bgContainer.filters = [new DropShadowFilter(3, 45, 0x000000, 0.4, 8, 8)];
            }
        }
        
        /**
         * Create settings controls
         */
        private function createSettings():void {
            _settingsContainer = new Sprite();
            
            // Responsive slider width
            _sliderWidth = Math.max(200, Math.min(_stageWidth * 0.4, 400));
            
            // Center the settings container
            _settingsContainer.x = _stageWidth / 2;
            _settingsContainer.y = _stageHeight * 0.4;
            
            var yPos:Number = 0;
            var labelSliderGap:Number = 35;
            var rowSpacing:Number = 100;
            
            // Music Volume
            createLabel("Music Volume", 0, yPos);
            _musicSlider = createSlider("music", _musicVolume, 0, yPos + labelSliderGap);
            _musicValueLabel = createValueLabel(Math.round(_musicVolume * 100) + "%", _sliderWidth / 2 + 20, yPos + labelSliderGap - 5);
            _settingsContainer.addChild(_musicSlider);
            _settingsContainer.addChild(_musicValueLabel);
            yPos += rowSpacing;
            
            // SFX Volume
            createLabel("Sound Effects", 0, yPos);
            _sfxSlider = createSlider("sfx", _sfxVolume, 0, yPos + labelSliderGap);
            _sfxValueLabel = createValueLabel(Math.round(_sfxVolume * 100) + "%", _sliderWidth / 2 + 20, yPos + labelSliderGap - 5);
            _settingsContainer.addChild(_sfxSlider);
            _settingsContainer.addChild(_sfxValueLabel);
            
            addChild(_settingsContainer);
        }
        
        /**
         * Create setting label
         */
        private function createLabel(text:String, x:Number, y:Number):void {
            var tf:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = Math.max(16, Math.min(_stageWidth * 0.02, 22));
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            tf.defaultTextFormat = format;
            tf.text = text;
            tf.width = _sliderWidth;
            tf.height = 30;
            tf.selectable = false;
            tf.x = x - _sliderWidth / 2;
            tf.y = y;
            
            _settingsContainer.addChild(tf);
        }
        
        /**
         * Create value label for slider
         */
        private function createValueLabel(text:String, x:Number, y:Number):TextField {
            var tf:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = Math.max(14, Math.min(_stageWidth * 0.018, 18));
            format.color = 0xCCCCCC;
            format.bold = false;
            
            tf.defaultTextFormat = format;
            tf.text = text;
            tf.width = 50;
            tf.height = 25;
            tf.selectable = false;
            tf.x = x;
            tf.y = y;
            
            return tf;
        }
        
        /**
         * Create slider control
         */
        private function createSlider(sliderType:String, value:Number, x:Number, y:Number):Sprite {
            var slider:Sprite = new Sprite();
            slider.name = sliderType;
            slider.x = x - _sliderWidth / 2;
            slider.y = y;
            
            var handleRadius:Number = 12;
            var trackY:Number = handleRadius - _sliderHeight / 2;
            
            // Track background
            var track:Shape = new Shape();
            track.graphics.beginFill(0x2A2A45);
            track.graphics.drawRoundRect(0, trackY, _sliderWidth, _sliderHeight, 4, 4);
            track.graphics.endFill();
            slider.addChild(track);
            
            // Fill (progress)
            var fill:Shape = new Shape();
            fill.name = "fill";
            fill.graphics.beginFill(0x4A90E2);
            fill.graphics.drawRoundRect(0, trackY, _sliderWidth * value, _sliderHeight, 4, 4);
            fill.graphics.endFill();
            slider.addChild(fill);
            
            // Handle (draggable) - draw centered at origin
            var handle:Sprite = new Sprite();
            handle.name = "handle";
            handle.graphics.beginFill(0xFFFFFF);
            handle.graphics.lineStyle(2, 0x4A90E2);
            handle.graphics.drawCircle(0, handleRadius, handleRadius);
            handle.graphics.endFill();
            handle.x = _sliderWidth * value;
            handle.buttonMode = true;
            handle.useHandCursor = true;
            slider.addChild(handle);
            
            // Add hover effect on handle
            handle.addEventListener(MouseEvent.ROLL_OVER, onHandleOver);
            handle.addEventListener(MouseEvent.ROLL_OUT, onHandleOut);
            handle.addEventListener(MouseEvent.MOUSE_DOWN, onHandleDown);
            
            // Also allow clicking on track
            slider.addEventListener(MouseEvent.CLICK, onSliderClick);
            
            return slider;
        }
        
        private function onHandleOver(e:MouseEvent):void {
            var handle:Sprite = e.currentTarget as Sprite;
            handle.scaleX = 1.2;
            handle.scaleY = 1.2;
            handle.filters = [new GlowFilter(0x4A90E2, 0.8, 12, 12)];
        }
        
        private function onHandleOut(e:MouseEvent):void {
            if (!_isDragging) {
                var handle:Sprite = e.currentTarget as Sprite;
                handle.scaleX = 1.0;
                handle.scaleY = 1.0;
                handle.filters = [];
            }
        }
        
        private function onHandleDown(e:MouseEvent):void {
            _isDragging = true;
            var handle:Sprite = e.currentTarget as Sprite;
            _currentSlider = handle.parent as Sprite;
            _currentType = _currentSlider.name;
            
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onHandleMove);
            stage.addEventListener(MouseEvent.MOUSE_UP, onHandleUp);
        }
        
        private function onHandleMove(e:MouseEvent):void {
            if (_isDragging && _currentSlider) {
                updateSliderFromMouse(_currentSlider, e.stageX);
            }
        }
        
        private function onHandleUp(e:MouseEvent):void {
            _isDragging = false;
            
            if (_currentSlider) {
                var handle:Sprite = _currentSlider.getChildByName("handle") as Sprite;
                if (handle) {
                    handle.scaleX = 1.0;
                    handle.scaleY = 1.0;
                    handle.filters = [];
                }
            }
            
            _currentSlider = null;
            _currentType = null;
            
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onHandleMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onHandleUp);
            
            // Dispatch settings changed
            dispatchEvent(new Event(SETTINGS_CHANGED));
        }
        
        private function onSliderClick(e:MouseEvent):void {
            var slider:Sprite = e.currentTarget as Sprite;
            updateSliderFromMouse(slider, e.stageX);
            dispatchEvent(new Event(SETTINGS_CHANGED));
        }
        
        private function updateSliderFromMouse(slider:Sprite, mouseX:Number):void {
            // Convert to slider's local coordinates
            var localX:Number = slider.globalToLocal(new Point(mouseX, 0)).x;
            var value:Number = Math.max(0, Math.min(1, localX / _sliderWidth));
            
            // Update slider visual
            updateSliderVisual(slider, value);
            
            // Update internal value
            if (slider.name == "music") {
                _musicVolume = value;
                _musicValueLabel.text = Math.round(value * 100) + "%";
            } else if (slider.name == "sfx") {
                _sfxVolume = value;
                _sfxValueLabel.text = Math.round(value * 100) + "%";
            }
        }
        
        private function updateSliderVisual(slider:Sprite, value:Number):void {
            var handleRadius:Number = 12;
            var trackY:Number = handleRadius - _sliderHeight / 2;
            
            // Update fill
            var fill:Shape = slider.getChildByName("fill") as Shape;
            if (fill) {
                fill.graphics.clear();
                fill.graphics.beginFill(0x4A90E2);
                fill.graphics.drawRoundRect(0, trackY, _sliderWidth * value, _sliderHeight, 4, 4);
                fill.graphics.endFill();
            }
            
            // Update handle position
            var handle:Sprite = slider.getChildByName("handle") as Sprite;
            if (handle) {
                handle.x = _sliderWidth * value;
            }
        }
        
        // ============ PUBLIC METHODS ============
        
        /**
         * Show settings page with fade animation
         */
        public function show():void {
            visible = true;
            alpha = 0;
            addEventListener(Event.ENTER_FRAME, fadeIn);
        }
        
        private function fadeIn(e:Event):void {
            alpha += 0.1;
            if (alpha >= 1) {
                alpha = 1;
                removeEventListener(Event.ENTER_FRAME, fadeIn);
            }
        }
        
        /**
         * Hide settings page with fade animation
         */
        public function hide():void {
            addEventListener(Event.ENTER_FRAME, fadeOut);
        }
        
        private function fadeOut(e:Event):void {
            alpha -= 0.1;
            if (alpha <= 0) {
                alpha = 0;
                visible = false;
                removeEventListener(Event.ENTER_FRAME, fadeOut);
            }
        }
        
        /**
         * Resize handler
         */
        public function resize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            // Redraw background
            drawBackground();
            
            // Update title
            if (_titleText) {
                var titleFormat:TextFormat = _titleText.getTextFormat();
                titleFormat.size = Math.max(28, Math.min(_stageWidth * 0.04, 48));
                _titleText.setTextFormat(titleFormat);
                _titleText.width = _stageWidth;
                _titleText.y = _stageHeight * 0.1;
            }
            
            // Update back button position
            if (_backButton) {
                _backButton.x = _stageWidth * 0.1;
                _backButton.y = _stageHeight * 0.9;
            }
            
            // Rebuild settings
            if (_settingsContainer) {
                removeChild(_settingsContainer);
                createSettings();
            }
        }
        
        /**
         * Get music volume (0-1)
         */
        public function get musicVolume():Number {
            return _musicVolume;
        }
        
        /**
         * Set music volume (0-1)
         */
        public function set musicVolume(value:Number):void {
            _musicVolume = Math.max(0, Math.min(1, value));
            if (_musicSlider) {
                updateSliderVisual(_musicSlider, _musicVolume);
                _musicValueLabel.text = Math.round(_musicVolume * 100) + "%";
            }
        }
        
        /**
         * Get SFX volume (0-1)
         */
        public function get sfxVolume():Number {
            return _sfxVolume;
        }
        
        /**
         * Set SFX volume (0-1)
         */
        public function set sfxVolume(value:Number):void {
            _sfxVolume = Math.max(0, Math.min(1, value));
            if (_sfxSlider) {
                updateSliderVisual(_sfxSlider, _sfxVolume);
                _sfxValueLabel.text = Math.round(_sfxVolume * 100) + "%";
            }
        }
        
        /**
         * Cleanup
         */
        public function dispose():void {
            if (_backButton) {
                _backButton.removeEventListener(MouseEvent.CLICK, onBackClick);
                _backButton.removeEventListener(MouseEvent.ROLL_OVER, onBackOver);
                _backButton.removeEventListener(MouseEvent.ROLL_OUT, onBackOut);
            }
            
            if (stage) {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onHandleMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onHandleUp);
            }
        }
    }
}
