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
     * AboutUsPanel - Full screen About Us page.
     * Placeholder for future content with back button.
     */
    public class AboutUsPanel extends Sprite {
        
        // Events
        public static const BACK_CLICKED:String = "backClicked";
        public static const CLOSE_CLICKED:String = "backClicked"; // Alias for compatibility
        
        // Dimensions
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Visual elements
        private var _background:Shape;
        private var _titleText:TextField;
        private var _backButton:Sprite;
        private var _contentContainer:Sprite;
        private var _contentText:TextField;
        
        /**
         * Constructor
         */
        public function AboutUsPanel() {
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
            createContent();
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
            _titleText.text = "ABOUT US";
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
         * Create content area
         */
        private function createContent():void {
            _contentContainer = new Sprite();
            _contentContainer.x = _stageWidth / 2;
            _contentContainer.y = _stageHeight * 0.45;
            
            // Main content text
            _contentText = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = Math.max(16, Math.min(_stageWidth * 0.022, 24));
            format.color = 0xAAAAAA;
            format.align = TextFormatAlign.CENTER;
            format.leading = 8;
            
            _contentText.defaultTextFormat = format;
            _contentText.text = "Cognitive Castle\n\nA memory training game that helps you\nbuild your cognitive skills.\n\n\nDeveloped by Soramula\n\nVersion 1.0.0";
            _contentText.width = Math.min(_stageWidth * 0.7, 500);
            _contentText.height = 300;
            _contentText.x = -_contentText.width / 2;
            _contentText.y = 0;
            _contentText.selectable = false;
            _contentText.wordWrap = true;
            _contentText.multiline = true;
            
            _contentContainer.addChild(_contentText);
            addChild(_contentContainer);
        }
        
        // ============ PUBLIC METHODS ============
        
        /**
         * Show page with fade animation
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
         * Hide page with fade animation
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
            
            // Update content position
            if (_contentContainer) {
                _contentContainer.x = _stageWidth / 2;
                _contentContainer.y = _stageHeight * 0.45;
                
                if (_contentText) {
                    var contentFormat:TextFormat = _contentText.getTextFormat();
                    contentFormat.size = Math.max(16, Math.min(_stageWidth * 0.022, 24));
                    _contentText.setTextFormat(contentFormat);
                    _contentText.width = Math.min(_stageWidth * 0.7, 500);
                    _contentText.x = -_contentText.width / 2;
                }
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
        }
    }
}
