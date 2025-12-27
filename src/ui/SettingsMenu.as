package ui {
    import flash.display.*;
    import flash.events.*;
    import ui.CustomCheckbox;
    import utils.TweenManager;
    import services.AudioManager;

    public class SettingsMenu extends MovieClip {
        public static const CLOSE_CLICKED:String = "closeClicked";
        public static const SETTINGS_CHANGED:String = "settingsChanged";
        
        public var xBtn:InteractiveObject;
        public var plusBtn:InteractiveObject;
        public var minBtn:InteractiveObject;
        
        [Embed(source="../../assets/Gambar/Rectangle 24.png")] private var RectBgClass:Class;
        [Embed(source="../../assets/Gambar/Rectangle 21.png")] private var RectFillClass:Class;
        [Embed(source="../../assets/Gambar/Plus.png")] private var PlusImg:Class;
        [Embed(source="../../assets/Gambar/Min.png")] private var MinImg:Class;

        private var volumeContainer:Sprite;
        private var fillBars:Vector.<Bitmap> = new Vector.<Bitmap>();
        private var currentLevel:int = 10;
        private var kotakCeklis:CustomCheckbox;
        
        // Konfigurasi Posisi
        public var plusButtonX:Number = NaN, plusButtonY:Number = NaN;
        public var minButtonX:Number = NaN, minButtonY:Number = NaN;

        public function SettingsMenu() {
            visible = false;
            if (stage) init(); else addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void { init(); });
        }

        private function init():void {
            stop();
            TweenManager.init();
            addEventListener(Event.ENTER_FRAME, function(e:Event):void { TweenManager.update(); });
            
            AudioManager.getInstance().init();
            AudioManager.getInstance().setMasterLevel(currentLevel);

            setupVolumeUI();
            setupCheckbox();
            setupButtons();
        }

        private function setupCheckbox():void {
            kotakCeklis = new CustomCheckbox(false);
            kotakCeklis.x = -450; kotakCeklis.y = 85;
            addChild(kotakCeklis);
            kotakCeklis.addEventListener(Event.CHANGE, function(e:Event):void {
                stage.displayState = kotakCeklis.isChecked ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
                dispatchEvent(new Event(SETTINGS_CHANGED));
            });
        }

        private function setupVolumeUI():void {
            volumeContainer = new Sprite();
            volumeContainer.x = -305; volumeContainer.y = -55;
            addChild(volumeContainer);

            for (var i:int = 0; i < 10; i++) {
                var bg:Bitmap = new RectBgClass();
                var fill:Bitmap = new RectFillClass();
                bg.scaleX = bg.scaleY = fill.scaleX = fill.scaleY = 0.96;
                bg.x = fill.x = i * (bg.width + 20);
                
                volumeContainer.addChild(bg);
                volumeContainer.addChild(fill);
                fillBars.push(fill);
            }
            updateVolumeDisplay();
        }

        private function setupButtons():void {
            if (xBtn) xBtn.addEventListener(MouseEvent.CLICK, function(e:Event):void { visible = false; dispatchEvent(new Event(CLOSE_CLICKED)); });
            
            // Helper untuk tombol plus/min
            // PERBAIKAN: Menambahkan tipe :Function
            var setupVolBtn:Function = function(btn:InteractiveObject, isPlus:Boolean, fallbackClass:Class):void {
                if (!btn) {
                    btn = new Sprite();
                    var bmp:Bitmap = new fallbackClass(); bmp.smoothing = true;
                    (btn as Sprite).addChild(bmp);
                    addChild(btn);
                    // Default pos logic sederhana
                    btn.x = volumeContainer.x + (isPlus ? 340 : 388); 
                    btn.y = volumeContainer.y; 
                }
                btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { changeVolume(isPlus ? 1 : -1, btn); });
                if (isPlus) plusBtn = btn; else minBtn = btn;
            };

            setupVolBtn(plusBtn, true, PlusImg);
            setupVolBtn(minBtn, false, MinImg);
            
            // Terapkan posisi manual jika ada
            if(!isNaN(plusButtonX)) plusBtn.x = plusButtonX;
            if(!isNaN(minButtonX)) minBtn.x = minButtonX;
            if(!isNaN(plusButtonY)) plusBtn.y = plusButtonY;
            if(!isNaN(minButtonY)) minBtn.y = minButtonY;
        }

        private function changeVolume(delta:int, target:InteractiveObject):void {
            var newLevel:int = currentLevel + delta;
            if (newLevel >= 0 && newLevel <= 10) {
                currentLevel = newLevel;
                updateVolumeDisplay();
                AudioManager.getInstance().setMasterLevel(currentLevel);
                AudioManager.getInstance().play(delta > 0 ? "ButtonIn" : "ButtonOut");
                
                // Efek pencet
                var ox:Number = target.scaleX, oy:Number = target.scaleY;
                TweenManager.to(target, 0.06, {scaleX: ox*0.8, scaleY: oy*0.8, onComplete:function():void{ TweenManager.to(target, 0.1, {scaleX:ox, scaleY:oy}); }});
                dispatchEvent(new Event(SETTINGS_CHANGED));
            }
        }

        private function updateVolumeDisplay():void {
            for (var i:int = 0; i < 10; i++) fillBars[i].visible = (i < currentLevel);
        }

        // --- Public Methods ---
        public function initialize(w:Number, h:Number):void { resize(w, h); } // Redirect ke resize agar konsisten
        
        // PERBAIKAN: Menambahkan fungsi resize agar bisa dipanggil Main.as
        public function resize(w:Number, h:Number):void { 
            x = w/2; 
            y = h/2; 
        }

        public function show():void { visible = true; try{ gotoAndPlay("open"); } catch(e:Error){ gotoAndPlay(1); } }
        public function hide():void { try{ gotoAndPlay("close"); } catch(e:Error){ visible=false; } }
        public function onCloseComplete():void { visible = false; dispatchEvent(new Event(CLOSE_CLICKED)); } // Dipanggil timeline Animate
        public function setPlusButtonPosition(x:Number, y:Number):void { plusButtonX = x; plusButtonY = y; if(plusBtn){plusBtn.x=x; plusBtn.y=y;} }
        public function setMinButtonPosition(x:Number, y:Number):void { minButtonX = x; minButtonY = y; if(minBtn){minBtn.x=x; minBtn.y=y;} }
        public function dispose():void { /* Cleanup jika perlu */ }
    }
}