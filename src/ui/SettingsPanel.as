package ui {
    import flash.display.*;
    import flash.text.*;
    import flash.events.*;
    import ui.components.UISlider; // Pastikan file ini dibuat
    import ui.components.UIToggle; // Pastikan file ini dibuat

    public class SettingsPanel extends MovieClip {
        public static const SETTINGS_CHANGED:String = "settingsChanged";
        public static const CLOSE_CLICKED:String = "closeClicked";
        
        public var musicVolume:Number = 0.8;
        public var sfxVolume:Number = 0.8;
        public var hapticEnabled:Boolean = true;
        public var colorBlindMode:Boolean = false;
        public var showTimer:Boolean = true;

        private var _panel:Sprite = new Sprite();

        public function SettingsPanel() { 
            addChild(_panel);
            visible = false; 
        }

        public function initialize(w:Number, h:Number):void {
            createBackground(w, h);
            createForm();
        }

        private function createBackground(w:Number, h:Number):void {
            graphics.clear();
            graphics.beginFill(0, 0.7); graphics.drawRect(0, 0, w, h);
            
            _panel.graphics.clear();
            _panel.graphics.beginFill(0x1A1A2E); _panel.graphics.lineStyle(2, 0x4A90E2);
            _panel.graphics.drawRoundRect(0, 0, 450, 450, 20);
            _panel.x = (w-450)/2; _panel.y = (h-450)/2;
            
            // Close logic
            if(!hasEventListener(MouseEvent.CLICK)) 
                addEventListener(MouseEvent.CLICK, function(e:Event):void { 
                    if(e.target == this) { visible=false; dispatchEvent(new Event(CLOSE_CLICKED)); }
                });
        }

        private function createForm():void {
            while(_panel.numChildren>0) _panel.removeChildAt(0); // Clear old
            
            var box:Sprite = new Sprite(); 
            box.x = 40; box.y = 60;
            _panel.addChild(box);

            var yPos:int = 0;
            var add = function(lbl:String, item:DisplayObject):void {
                var tf:TextField = new TextField(); tf.text=lbl; tf.textColor=0xFFFFFF; tf.y=yPos;
                box.addChild(tf);
                item.x = 160; item.y = yPos+5;
                box.addChild(item);
                yPos += 50;
            };

            // Controls
            var mSlider:UISlider = new UISlider(150, musicVolume);
            mSlider.onChange = function(v):void { musicVolume=v; dispatchEvent(new Event(SETTINGS_CHANGED)); };
            add("Music", mSlider);

            var sSlider:UISlider = new UISlider(150, sfxVolume);
            sSlider.onChange = function(v):void { sfxVolume=v; dispatchEvent(new Event(SETTINGS_CHANGED)); };
            add("SFX", sSlider);

            var hToggle:UIToggle = new UIToggle(hapticEnabled);
            hToggle.onChange = function(v):void { hapticEnabled=v; dispatchEvent(new Event(SETTINGS_CHANGED)); };
            add("Haptics", hToggle);
        }

        public function show():void { visible = true; }
        public function hide():void { visible = false; }
        public function resize(w:Number, h:Number):void { initialize(w, h); }
    }
}