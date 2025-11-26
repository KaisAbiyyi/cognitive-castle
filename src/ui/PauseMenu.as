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
     * PauseMenu - Pause menu overlay.
     * Features: Resume, Settings, Main Menu, and game info display.
     * 
     * T1-079: Pause Menu
     */
    public class PauseMenu extends Sprite {
        
        // Events
        public static const RESUME_CLICKED:String = "resumeClicked";
        public static const SETTINGS_CLICKED:String = "settingsClicked";
        public static const MAIN_MENU_CLICKED:String = "mainMenuClicked";
        public static const QUIT_CLICKED:String = "quitClicked";
        
        // Dimensions
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        
        // Visual elements
        private var _overlay:Shape;
        private var _panel:Sprite;
        private var _titleText:TextField;
        private var _statsContainer:Sprite;
        private var _buttonsContainer:Sprite;
        private var _buttons:Vector.<Sprite>;
        
        // Game stats display
        private var _scoreText:TextField;
        private var _levelText:TextField;
        private var _streakText:TextField;
        
        /**
         * Constructor
         */
        public function PauseMenu() {
            _buttons = new Vector.<Sprite>();
            visible = false;
        }
        
        /**
         * Initialize menu
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            createOverlay();
            createPanel();
            createTitle();
            createStats();
            createButtons();
        }
        
        /**
         * Create dark overlay
         */
        private function createOverlay():void {
            _overlay = new Shape();
            drawOverlay();
            addChild(_overlay);
        }
        
        private function drawOverlay():void {
            var g:Graphics = _overlay.graphics;
            g.clear();
            g.beginFill(0x000000, 0.7);
            g.drawRect(0, 0, _stageWidth, _stageHeight);
            g.endFill();
        }
        
        /**
         * Create panel background
         */
        private function createPanel():void {
            _panel = new Sprite();
            
            var panelWidth:Number = Math.min(_stageWidth * 0.5, 350);
            var panelHeight:Number = Math.min(_stageHeight * 0.6, 400);
            
            var g:Graphics = _panel.graphics;
            
            // Shadow
            g.beginFill(0x000000, 0.3);
            g.drawRoundRect(5, 5, panelWidth, panelHeight, 20, 20);
            g.endFill();
            
            // Main panel
            g.beginFill(0x1A1A2E, 0.95);
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
            _titleText.text = "PAUSED";
            _titleText.width = _panel.width;
            _titleText.height = 40;
            _titleText.selectable = false;
            _titleText.x = 0;
            _titleText.y = 15;
            
            _panel.addChild(_titleText);
        }
        
        /**
         * Create stats display
         */
        private function createStats():void {
            _statsContainer = new Sprite();
            _statsContainer.x = 20;
            _statsContainer.y = 80;
            
            // Score
            _scoreText = createStatText("Score: 0", 0);
            _statsContainer.addChild(_scoreText);
            
            // Level
            _levelText = createStatText("Level: 1", 30);
            _statsContainer.addChild(_levelText);
            
            // Streak
            _streakText = createStatText("Streak: 0", 60);
            _statsContainer.addChild(_streakText);
            
            _panel.addChild(_statsContainer);
        }
        
        private function createStatText(text:String, yPos:Number):TextField {
            var tf:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 16;
            format.color = 0xCCCCCC;
            
            tf.defaultTextFormat = format;
            tf.text = text;
            tf.width = _panel.width - 40;
            tf.height = 25;
            tf.selectable = false;
            tf.y = yPos;
            
            return tf;
        }
        
        /**
         * Create buttons
         */
        private function createButtons():void {
            _buttonsContainer = new Sprite();
            _buttonsContainer.x = 0;
            _buttonsContainer.y = 180;
            
            var buttonData:Array = [
                { label: "RESUME", event: RESUME_CLICKED, primary: true },
                { label: "SETTINGS", event: SETTINGS_CLICKED, primary: false },
                { label: "MAIN MENU", event: MAIN_MENU_CLICKED, primary: false }
            ];
            
            var buttonWidth:Number = _panel.width - 60;
            var buttonHeight:Number = 45;
            var spacing:Number = 12;
            
            for (var i:int = 0; i < buttonData.length; i++) {
                var btn:Sprite = createButton(
                    buttonData[i].label,
                    buttonData[i].event,
                    buttonWidth,
                    buttonHeight,
                    buttonData[i].primary
                );
                btn.x = 30;
                btn.y = i * (buttonHeight + spacing);
                _buttonsContainer.addChild(btn);
                _buttons.push(btn);
            }
            
            _panel.addChild(_buttonsContainer);
        }
        
        /**
         * Create a button
         */
        private function createButton(label:String, eventName:String, width:Number, height:Number, primary:Boolean):Sprite {
            var btn:Sprite = new Sprite();
            btn.name = eventName;
            
            var bgColor:uint = primary ? 0x4CAF50 : 0x3498DB;
            var borderColor:uint = primary ? 0x388E3C : 0x2980B9;
            
            // Background
            var bg:Shape = new Shape();
            var g:Graphics = bg.graphics;
            
            g.lineStyle(2, borderColor);
            g.beginFill(bgColor);
            g.drawRoundRect(0, 0, width, height, 8, 8);
            g.endFill();
            
            btn.addChild(bg);
            
            // Label
            var labelTF:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 16;
            format.color = 0xFFFFFF;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            labelTF.defaultTextFormat = format;
            labelTF.text = label;
            labelTF.width = width;
            labelTF.height = height;
            labelTF.y = (height - 20) / 2;
            labelTF.selectable = false;
            labelTF.mouseEnabled = false;
            
            btn.addChild(labelTF);
            
            // Interactions
            btn.buttonMode = true;
            btn.useHandCursor = true;
            btn.addEventListener(MouseEvent.ROLL_OVER, onButtonOver);
            btn.addEventListener(MouseEvent.ROLL_OUT, onButtonOut);
            btn.addEventListener(MouseEvent.CLICK, onButtonClick);
            
            return btn;
        }
        
        // ============ INTERACTIONS ============
        
        private function onButtonOver(e:MouseEvent):void {
            var btn:Sprite = e.currentTarget as Sprite;
            btn.scaleX = 1.02;
            btn.scaleY = 1.02;
            btn.alpha = 0.9;
        }
        
        private function onButtonOut(e:MouseEvent):void {
            var btn:Sprite = e.currentTarget as Sprite;
            btn.scaleX = 1.0;
            btn.scaleY = 1.0;
            btn.alpha = 1.0;
        }
        
        private function onButtonClick(e:MouseEvent):void {
            var btn:Sprite = e.currentTarget as Sprite;
            dispatchEvent(new Event(btn.name));
        }
        
        // ============ PUBLIC METHODS ============
        
        /**
         * Show pause menu with current game stats
         */
        public function show(score:int = 0, level:int = 1, streak:int = 0):void {
            updateStats(score, level, streak);
            visible = true;
            alpha = 0;
            
            // Fade in
            addEventListener(Event.ENTER_FRAME, function fadeIn(e:Event):void {
                alpha += 0.15;
                if (alpha >= 1) {
                    alpha = 1;
                    removeEventListener(Event.ENTER_FRAME, fadeIn);
                }
            });
        }
        
        /**
         * Hide pause menu
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
         * Update displayed stats
         */
        public function updateStats(score:int, level:int, streak:int):void {
            if (_scoreText) _scoreText.text = "Score: " + score;
            if (_levelText) _levelText.text = "Level: " + level;
            if (_streakText) _streakText.text = "Streak: " + streak;
        }
        
        /**
         * Resize handler
         */
        public function resize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            
            // Redraw overlay
            drawOverlay();
            
            // Reposition panel
            if (_panel) {
                var panelWidth:Number = Math.min(_stageWidth * 0.5, 350);
                var panelHeight:Number = Math.min(_stageHeight * 0.6, 400);
                _panel.x = (_stageWidth - panelWidth) / 2;
                _panel.y = (_stageHeight - panelHeight) / 2;
            }
        }
        
        /**
         * Cleanup
         */
        public function dispose():void {
            for each (var btn:Sprite in _buttons) {
                btn.removeEventListener(MouseEvent.ROLL_OVER, onButtonOver);
                btn.removeEventListener(MouseEvent.ROLL_OUT, onButtonOut);
                btn.removeEventListener(MouseEvent.CLICK, onButtonClick);
            }
        }
    }
}
