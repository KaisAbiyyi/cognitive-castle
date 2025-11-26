package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Graphics;
    import flash.display.GradientType;
    import flash.geom.Matrix;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;
    import flash.filters.GlowFilter;
    
    /**
     * MainMenu - Main menu screen with Play, Settings, Statistics, Credits.
     * Features animated title, menu buttons, and background castle silhouette.
     * 
     * T1-078: Main Menu
     */
    public class MainMenu extends Sprite {
        
        // Events
        public static const PLAY_CLICKED:String = "playClicked";
        public static const CONTINUE_CLICKED:String = "continueClicked";
        public static const SETTINGS_CLICKED:String = "settingsClicked";
        public static const STATISTICS_CLICKED:String = "statisticsClicked";
        public static const CREDITS_CLICKED:String = "creditsClicked";
        
        // Dimensions
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Visual elements
        private var _background:Shape;
        private var _castleSilhouette:Sprite;
        private var _titleContainer:Sprite;
        private var _titleText:TextField;
        private var _subtitleText:TextField;
        private var _buttonsContainer:Sprite;
        private var _buttons:Vector.<Sprite>;
        private var _versionText:TextField;
        
        // State
        private var _hasSaveData:Boolean = false;
        
        // Animation
        private var _animPhase:Number = 0;
        
        /**
         * Constructor
         */
        public function MainMenu() {
            _buttons = new Vector.<Sprite>();
        }
        
        /**
         * Initialize menu
         */
        public function initialize(stageWidth:Number, stageHeight:Number, hasSaveData:Boolean = false):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            _hasSaveData = hasSaveData;
            
            createBackground();
            createCastleSilhouette();
            createTitle();
            createMenuButtons();
            createVersion();
            
            // Start animation
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
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
            
            // Gradient from dark blue to purple
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
            
            // Add stars
            drawStars(g);
        }
        
        private function drawStars(g:Graphics):void {
            // Random stars
            for (var i:int = 0; i < 50; i++) {
                var starX:Number = Math.random() * _stageWidth;
                var starY:Number = Math.random() * _stageHeight * 0.6;
                var starSize:Number = Math.random() * 2 + 1;
                var starAlpha:Number = Math.random() * 0.5 + 0.3;
                
                g.beginFill(0xFFFFFF, starAlpha);
                g.drawCircle(starX, starY, starSize);
                g.endFill();
            }
        }
        
        /**
         * Create castle silhouette in background
         */
        private function createCastleSilhouette():void {
            _castleSilhouette = new Sprite();
            var g:Graphics = _castleSilhouette.graphics;
            
            var baseY:Number = _stageHeight * 0.85;
            var centerX:Number = _stageWidth / 2;
            
            // Castle silhouette color
            g.beginFill(0x0A0A15, 0.8);
            
            // Main keep
            g.drawRect(centerX - 60, baseY - 150, 120, 150);
            
            // Top of keep
            g.moveTo(centerX - 60, baseY - 150);
            g.lineTo(centerX - 70, baseY - 150);
            g.lineTo(centerX - 70, baseY - 160);
            g.lineTo(centerX - 55, baseY - 160);
            g.lineTo(centerX - 55, baseY - 150);
            
            // More battlements
            for (var i:int = 0; i < 5; i++) {
                var bx:Number = centerX - 50 + i * 25;
                g.drawRect(bx, baseY - 170, 15, 20);
            }
            
            // Left tower
            g.drawRect(centerX - 150, baseY - 200, 50, 200);
            g.moveTo(centerX - 150, baseY - 200);
            g.lineTo(centerX - 125, baseY - 240);
            g.lineTo(centerX - 100, baseY - 200);
            
            // Right tower
            g.drawRect(centerX + 100, baseY - 200, 50, 200);
            g.moveTo(centerX + 100, baseY - 200);
            g.lineTo(centerX + 125, baseY - 240);
            g.lineTo(centerX + 150, baseY - 200);
            
            // Walls
            g.drawRect(centerX - 150, baseY - 80, 300, 80);
            
            // Small towers on walls
            g.drawRect(centerX - 180, baseY - 120, 30, 120);
            g.drawRect(centerX + 150, baseY - 120, 30, 120);
            
            // Ground
            g.drawRect(0, baseY, _stageWidth, _stageHeight - baseY);
            
            g.endFill();
            
            addChild(_castleSilhouette);
        }
        
        /**
         * Create title
         */
        private function createTitle():void {
            _titleContainer = new Sprite();
            
            // Main title
            _titleText = new TextField();
            var titleFormat:TextFormat = new TextFormat();
            titleFormat.font = "Arial";
            titleFormat.size = Math.min(_stageWidth * 0.08, 64);
            titleFormat.color = 0xFFFFFF;
            titleFormat.bold = true;
            titleFormat.align = TextFormatAlign.CENTER;
            titleFormat.letterSpacing = 4;
            
            _titleText.defaultTextFormat = titleFormat;
            _titleText.text = "COGNITIVE CASTLE";
            _titleText.width = _stageWidth;
            _titleText.height = 80;
            _titleText.selectable = false;
            _titleText.x = 0;
            _titleText.y = 0;
            
            // Title glow
            _titleText.filters = [
                new GlowFilter(0x4A90E2, 0.8, 15, 15, 2),
                new DropShadowFilter(4, 45, 0x000000, 0.5, 10, 10)
            ];
            
            _titleContainer.addChild(_titleText);
            
            // Subtitle
            _subtitleText = new TextField();
            var subFormat:TextFormat = new TextFormat();
            subFormat.font = "Arial";
            subFormat.size = Math.min(_stageWidth * 0.025, 18);
            subFormat.color = 0xAAAAAA;
            subFormat.align = TextFormatAlign.CENTER;
            subFormat.italic = true;
            
            _subtitleText.defaultTextFormat = subFormat;
            _subtitleText.text = "Train Your Memory, Build Your Kingdom";
            _subtitleText.width = _stageWidth;
            _subtitleText.height = 30;
            _subtitleText.selectable = false;
            _subtitleText.x = 0;
            _subtitleText.y = 70;
            
            _titleContainer.addChild(_subtitleText);
            
            _titleContainer.x = 0;
            _titleContainer.y = _stageHeight * 0.12;
            
            addChild(_titleContainer);
        }
        
        /**
         * Create menu buttons
         */
        private function createMenuButtons():void {
            _buttonsContainer = new Sprite();
            
            var buttonData:Array = [];
            
            if (_hasSaveData) {
                buttonData.push({ label: "CONTINUE", event: CONTINUE_CLICKED, primary: true });
                buttonData.push({ label: "NEW GAME", event: PLAY_CLICKED, primary: false });
            } else {
                buttonData.push({ label: "PLAY", event: PLAY_CLICKED, primary: true });
            }
            
            buttonData.push({ label: "SETTINGS", event: SETTINGS_CLICKED, primary: false });
            buttonData.push({ label: "STATISTICS", event: STATISTICS_CLICKED, primary: false });
            buttonData.push({ label: "CREDITS", event: CREDITS_CLICKED, primary: false });
            
            var buttonWidth:Number = Math.min(_stageWidth * 0.4, 250);
            var buttonHeight:Number = Math.min(_stageHeight * 0.08, 50);
            var spacing:Number = 15;
            var startY:Number = 0;
            
            for (var i:int = 0; i < buttonData.length; i++) {
                var btn:Sprite = createButton(
                    buttonData[i].label,
                    buttonData[i].event,
                    buttonWidth,
                    buttonHeight,
                    buttonData[i].primary
                );
                btn.x = (_stageWidth - buttonWidth) / 2;
                btn.y = startY + i * (buttonHeight + spacing);
                _buttonsContainer.addChild(btn);
                _buttons.push(btn);
            }
            
            // Center buttons vertically
            var totalHeight:Number = buttonData.length * buttonHeight + (buttonData.length - 1) * spacing;
            _buttonsContainer.x = 0;
            _buttonsContainer.y = (_stageHeight - totalHeight) / 2 + 30;
            
            addChild(_buttonsContainer);
        }
        
        /**
         * Create a menu button
         */
        private function createButton(label:String, eventName:String, width:Number, height:Number, primary:Boolean):Sprite {
            var btn:Sprite = new Sprite();
            btn.name = eventName;
            
            var bgColor:uint = primary ? 0x4A90E2 : 0x2C3E50;
            var borderColor:uint = primary ? 0x357ABD : 0x1A252F;
            
            // Background
            var bg:Shape = new Shape();
            var g:Graphics = bg.graphics;
            
            g.lineStyle(2, borderColor);
            g.beginFill(bgColor);
            g.drawRoundRect(0, 0, width, height, 10, 10);
            g.endFill();
            
            btn.addChild(bg);
            
            // Label
            var labelTF:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            var fontSize:int = primary ? 20 : 16;
            format.size = fontSize;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            labelTF.defaultTextFormat = format;
            labelTF.text = label;
            labelTF.width = width;
            labelTF.height = height;
            labelTF.y = (height - fontSize - 8) / 2;
            labelTF.selectable = false;
            labelTF.mouseEnabled = false;
            
            btn.addChild(labelTF);
            
            // Shadow
            btn.filters = [new DropShadowFilter(3, 45, 0x000000, 0.4, 6, 6)];
            
            // Interactions
            btn.buttonMode = true;
            btn.useHandCursor = true;
            btn.addEventListener(MouseEvent.ROLL_OVER, onButtonOver);
            btn.addEventListener(MouseEvent.ROLL_OUT, onButtonOut);
            btn.addEventListener(MouseEvent.CLICK, onButtonClick);
            
            return btn;
        }
        
        /**
         * Create version text
         */
        private function createVersion():void {
            _versionText = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 12;
            format.color = 0x666666;
            format.align = TextFormatAlign.CENTER;
            
            _versionText.defaultTextFormat = format;
            _versionText.text = "v1.0.0";
            _versionText.width = _stageWidth;
            _versionText.height = 20;
            _versionText.selectable = false;
            _versionText.y = _stageHeight - 30;
            
            addChild(_versionText);
        }
        
        // ============ INTERACTIONS ============
        
        private function onButtonOver(e:MouseEvent):void {
            var btn:Sprite = e.currentTarget as Sprite;
            btn.scaleX = 1.05;
            btn.scaleY = 1.05;
            btn.filters = [
                new DropShadowFilter(5, 45, 0x000000, 0.5, 10, 10),
                new GlowFilter(0x4A90E2, 0.4, 20, 20)
            ];
        }
        
        private function onButtonOut(e:MouseEvent):void {
            var btn:Sprite = e.currentTarget as Sprite;
            btn.scaleX = 1.0;
            btn.scaleY = 1.0;
            btn.filters = [new DropShadowFilter(3, 45, 0x000000, 0.4, 6, 6)];
        }
        
        private function onButtonClick(e:MouseEvent):void {
            var btn:Sprite = e.currentTarget as Sprite;
            dispatchEvent(new Event(btn.name));
        }
        
        // ============ ANIMATION ============
        
        private function onEnterFrame(e:Event):void {
            _animPhase += 0.02;
            
            // Gentle title float animation
            if (_titleContainer) {
                _titleContainer.y = _stageHeight * 0.12 + Math.sin(_animPhase) * 5;
            }
        }
        
        // ============ PUBLIC METHODS ============
        
        /**
         * Update for save data presence
         */
        public function setHasSaveData(hasSave:Boolean):void {
            if (_hasSaveData != hasSave) {
                _hasSaveData = hasSave;
                
                // Rebuild buttons
                if (_buttonsContainer) {
                    removeChild(_buttonsContainer);
                    _buttons.length = 0;
                }
                createMenuButtons();
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
            
            // Reposition elements
            if (_castleSilhouette) {
                removeChild(_castleSilhouette);
                createCastleSilhouette();
            }
            
            if (_titleContainer) {
                _titleContainer.x = 0;
                _titleContainer.y = _stageHeight * 0.12;
                _titleText.width = _stageWidth;
                _subtitleText.width = _stageWidth;
            }
            
            // Reposition buttons
            if (_buttonsContainer) {
                var buttonHeight:Number = Math.min(_stageHeight * 0.08, 50);
                var spacing:Number = 15;
                var totalHeight:Number = _buttons.length * buttonHeight + (_buttons.length - 1) * spacing;
                _buttonsContainer.y = (_stageHeight - totalHeight) / 2 + 30;
            }
            
            if (_versionText) {
                _versionText.width = _stageWidth;
                _versionText.y = _stageHeight - 30;
            }
        }
        
        /**
         * Show menu with animation
         */
        public function show():void {
            visible = true;
            alpha = 0;
            
            // Fade in animation (simple)
            addEventListener(Event.ENTER_FRAME, function fadeIn(e:Event):void {
                alpha += 0.1;
                if (alpha >= 1) {
                    alpha = 1;
                    removeEventListener(Event.ENTER_FRAME, fadeIn);
                }
            });
        }
        
        /**
         * Hide menu with animation
         */
        public function hide():void {
            addEventListener(Event.ENTER_FRAME, function fadeOut(e:Event):void {
                alpha -= 0.1;
                if (alpha <= 0) {
                    alpha = 0;
                    visible = false;
                    removeEventListener(Event.ENTER_FRAME, fadeOut);
                }
            });
        }
        
        /**
         * Cleanup
         */
        public function dispose():void {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            
            for each (var btn:Sprite in _buttons) {
                btn.removeEventListener(MouseEvent.ROLL_OVER, onButtonOver);
                btn.removeEventListener(MouseEvent.ROLL_OUT, onButtonOut);
                btn.removeEventListener(MouseEvent.CLICK, onButtonClick);
            }
        }
    }
}
