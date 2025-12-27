package ui {
    import flash.display.*;
    import flash.text.*;
    import flash.events.*;

    public class SettingsPanel extends MovieClip {
        public static const SETTINGS_CHANGED:String = "settingsChanged";
        public static const CLOSE_CLICKED:String = "closeClicked";
        
        public var xBtn:SimpleButton;
        private var _panel:Sprite;
        private var _draggedSlider:Sprite;
        
        // Data Settings
        public var musicVolume:Number = 0.8;
        public var sfxVolume:Number = 0.8;
        public var hapticEnabled:Boolean = true;
        public var colorBlindMode:Boolean = false;
        public var showTimer:Boolean = true;

        public function SettingsPanel() { visible = false; }

        public function initialize(w:Number, h:Number):void {
            createOverlay(w, h);
            createPanel(w, h);
            createControls();
        }

        private function createOverlay(w:Number, h:Number):void {
            var ov:Shape = new Shape();
            ov.graphics.beginFill(0, 0.7); ov.graphics.drawRect(0, 0, w, h);
            addChild(ov);
            ov.addEventListener(MouseEvent.CLICK, function(e:Event):void { dispatchEvent(new Event(CLOSE_CLICKED)); });
        }

        private function createPanel(w:Number, h:Number):void {
            _panel = new Sprite();
            _panel.graphics.beginFill(0x1A1A2E, 0.98); _panel.graphics.lineStyle(3, 0x4A90E2);
            _panel.graphics.drawRoundRect(0, 0, 450, 450, 20);
            _panel.x = (w - 450)/2; _panel.y = (h - 450)/2;
            addChild(_panel);

            // Title
            var tf:TextField = createText("SETTINGS", 24, true);
            tf.width = 450; tf.y = 15; tf.autoSize = TextFieldAutoSize.CENTER;
            _panel.addChild(tf);

            // Close Button
            var btn:Sprite = new Sprite();
            btn.graphics.beginFill(0xE53E3E); btn.graphics.drawCircle(15,15,15);
            btn.graphics.lineStyle(3, 0xFFFFFF); btn.graphics.moveTo(10,10); btn.graphics.lineTo(20,20); btn.graphics.moveTo(20,10); btn.graphics.lineTo(10,20);
            btn.x = 450 - 45; btn.y = 15; btn.buttonMode = true;
            btn.addEventListener(MouseEvent.CLICK, function(e:Event):void { dispatchEvent(new Event(CLOSE_CLICKED)); });
            _panel.addChild(btn);
        }

        private function createControls():void {
            var container:Sprite = new Sprite(); container.x = 30; container.y = 80;
            _panel.addChild(container);

            var y:int = 0;
            addControl(container, "Music Volume", createSlider(musicVolume, "music"), y); y+=60;
            addControl(container, "Sound Effects", createSlider(sfxVolume, "sfx"), y); y+=60;
            addControl(container, "Haptic Feedback", createToggle(hapticEnabled, "haptic"), y); y+=60;
            addControl(container, "Color Blind Mode", createToggle(colorBlindMode, "color"), y); y+=60;
            addControl(container, "Show Timer", createToggle(showTimer, "timer"), y);
        }

        private function addControl(p:Sprite, label:String, ctrl:Sprite, y:int):void {
            var tf:TextField = createText(label, 16); tf.x = 0; tf.y = y; p.addChild(tf);
            ctrl.x = 150; ctrl.y = y + 5; p.addChild(ctrl);
        }

        private function createSlider(val:Number, name:String):Sprite {
            var s:Sprite = new Sprite(); s.name = name;
            // Track
            s.graphics.beginFill(0x333355); s.graphics.drawRoundRect(0,0,180,8,4);
            // Fill & Handle (digambar ulang saat update)
            var fill:Shape = new Shape(); fill.name="fill"; s.addChild(fill);
            var handle:Sprite = new Sprite(); handle.name="handle"; handle.graphics.beginFill(0xFF); handle.graphics.lineStyle(2,0x4A90E2); handle.graphics.drawCircle(0,4,10); s.addChild(handle);
            
            s.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
                _draggedSlider = s;
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onSliderDrag);
                stage.addEventListener(MouseEvent.MOUSE_UP, onSliderUp);
                updateSlider(s, s.mouseX);
            });
            updateSliderUI(s, val);
            return s;
        }

        private function onSliderDrag(e:MouseEvent):void { if(_draggedSlider) updateSlider(_draggedSlider, _draggedSlider.mouseX); }
        private function onSliderUp(e:MouseEvent):void { stage.removeEventListener(MouseEvent.MOUSE_MOVE, onSliderDrag); stage.removeEventListener(MouseEvent.MOUSE_UP, onSliderUp); _draggedSlider=null; dispatchEvent(new Event(SETTINGS_CHANGED)); }

        private function updateSlider(s:Sprite, x:Number):void {
            var pct:Number = Math.max(0, Math.min(1, x / 180));
            if(s.name == "music") musicVolume = pct; else sfxVolume = pct;
            updateSliderUI(s, pct);
        }
        
        private function updateSliderUI(s:Sprite, pct:Number):void {
            var fill:Shape = s.getChildByName("fill") as Shape;
            fill.graphics.clear(); fill.graphics.beginFill(0x4A90E2); fill.graphics.drawRoundRect(0,0,180*pct,8,4);
            s.getChildByName("handle").x = 180*pct;
        }

        private function createToggle(val:Boolean, name:String):Sprite {
            var t:Sprite = new Sprite(); t.name = name;
            var draw:Function = function(v:Boolean):void {
                t.graphics.clear(); t.graphics.beginFill(v?0x4CAF50:0x555555); t.graphics.drawRoundRect(0,0,60,28,28);
                t.graphics.beginFill(0xFF); t.graphics.drawCircle(v?46:14, 14, 10);
            };
            draw(val);
            t.buttonMode = true;
            t.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
                var newVal:Boolean = (t.name == "haptic" ? (hapticEnabled = !hapticEnabled) : 
                                      (t.name == "color" ? (colorBlindMode = !colorBlindMode) : (showTimer = !showTimer)));
                draw(newVal);
                dispatchEvent(new Event(SETTINGS_CHANGED));
            });
            return t;
        }

        private function createText(str:String, size:int, bold:Boolean=false):TextField {
            var tf:TextField = new TextField();
            var fmt:TextFormat = new TextFormat("Arial", size, 0xFFFFFF, bold);
            tf.defaultTextFormat = fmt; tf.text = str; tf.selectable = false;
            return tf;
        }

        public function show():void { visible = true; alpha = 0; addEventListener(Event.ENTER_FRAME, fade); }
        public function hide():void { addEventListener(Event.ENTER_FRAME, fade); }
        private function fade(e:Event):void {
            alpha += (visible && alpha < 1) ? 0.15 : -0.15;
            if (alpha >= 1 || alpha <= 0) { removeEventListener(Event.ENTER_FRAME, fade); if(alpha<=0) visible=false; }
        }
        public function resize(w:Number, h:Number):void { _panel.x = (w-_panel.width)/2; _panel.y = (h-_panel.height)/2; }
        public function dispose():void { }
    }
}