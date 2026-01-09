package ui {
    import flash.display.*;
    import flash.events.*;
    import flash.net.URLRequest;
    import services.AudioManager;
    import services.SaveSystem;
    import ui.components.VolumeDisplay;
    import ui.CustomCheckbox;
    import utils.TweenManager;

    public class SettingsMenu extends MovieClip {
        public static const CLOSE_CLICKED:String = "closeClicked";
        public static const SETTINGS_CHANGED:String = "settingsChanged";

        // Constants
        private const PATH_PLUS:String = "assets/Gambar/Plus.png";
        private const PATH_MIN:String = "assets/Gambar/Min.png";
        private const PATH_BAR_FILL:String = "assets/Gambar/Rectangle 21.png";
        private const PATH_BAR_EMPTY:String = "assets/Gambar/Rectangle 24.png";
        
        // Layout Config
        private const BASE_Y:Number = -55;     // Posisi Y dasar
        private const TARGET_H:Number = 72;    // Tinggi standar (sesuai tinggi Bar)
        private const MARGIN:Number = 15;      // Jarak tombol ke bar

        private var _volumeDisplay:VolumeDisplay;
        private var _checkbox:CustomCheckbox;
        public var plusBtn:Sprite;
        public var minBtn:Sprite;
        public var xBtn:SimpleButton; 

        private var _currentLevel:int = 10;

        public function SettingsMenu() {
            visible = false;
            if (stage) init(); else addEventListener(Event.ADDED_TO_STAGE, init);
        }

        private function init(e:Event = null):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            TweenManager.init();
            
            // Load saved volume level first (do NOT call AudioManager.init() as it resets volume)
            loadSavedVolumeLevel();
            
            // Apply saved volume to AudioManager
            AudioManager.getInstance().setMasterLevel(_currentLevel);
            
            buildUI();
        }
        
        private function loadSavedVolumeLevel():void {
            var saveSystem:SaveSystem = SaveSystem.getInstance();
            if (saveSystem.data && saveSystem.data.settings) {
                var savedMasterVolume:Number = saveSystem.data.settings.masterVolume;
                if (!isNaN(savedMasterVolume) && savedMasterVolume >= 0 && savedMasterVolume <= 1) {
                    _currentLevel = Math.round(savedMasterVolume * 10);
                }
            }
        }

        private function buildUI():void {
            // 1. Setup Tombol (Posisi X sementara, nanti diatur refreshLayout)
            plusBtn = createBtn(PATH_PLUS, 335, BASE_Y, 1);
            minBtn = createBtn(PATH_MIN, -430, BASE_Y, -1);

            // 2. Setup Volume Display
            _volumeDisplay = new VolumeDisplay();
            addChild(_volumeDisplay);
            
            // Initialize volume display with saved level
            _volumeDisplay.update(_currentLevel);

            // Load Assets Bar
            loadBitmap(PATH_BAR_EMPTY, function(b:BitmapData):void { _volumeDisplay.setEmptyAsset(b); });
            loadBitmap(PATH_BAR_FILL, function(b:BitmapData):void { _volumeDisplay.setFillAsset(b); });

            // 3. Checkbox
            _checkbox = new CustomCheckbox(false);
            _checkbox.x = -450; _checkbox.y = 85;
            addChild(_checkbox);
            _checkbox.addEventListener(Event.CHANGE, function(e:Event):void {
                stage.displayState = _checkbox.isChecked ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
                AudioManager.getInstance().playSfx("ButtonIn");
            });

            if(xBtn) xBtn.addEventListener(MouseEvent.CLICK, function(e:Event):void { visible=false; dispatchEvent(new Event(CLOSE_CLICKED)); });
            
            // Panggil layout awal
            refreshLayout();
        }

        // --- CORE LAYOUT FIX ---
        private function refreshLayout():void {
            if (!minBtn || !plusBtn || !_volumeDisplay) return;

            // 1. Fix Button "Bantet": Scale proporsional sesuai tinggi Bar (72px)
            scaleToHeight(minBtn, TARGET_H);
            scaleToHeight(plusBtn, TARGET_H);

            // 2. Fix Vertical Align: Center semua elemen ke titik tengah BASE_Y
            // Titik tengah = BASE_Y + (Setengah Tinggi Target)
            var centerY:Number = BASE_Y + (TARGET_H / 2);
            
            alignCenterY(minBtn, centerY);
            alignCenterY(plusBtn, centerY);
            alignCenterY(_volumeDisplay, centerY);

            // 3. Horizontal Stretch (Bar membentang dari Min ke Plus)
            var startX:Number = minBtn.x + minBtn.width + MARGIN;
            var endX:Number = plusBtn.x - MARGIN;
            
            _volumeDisplay.fitToWidth(startX, endX);
        }

        private function scaleToHeight(container:Sprite, targetH:Number):void {
            if(container.numChildren > 0) {
                var bmp:Bitmap = container.getChildAt(0) as Bitmap;
                if(bmp) {
                    // Hitung rasio asli agar tidak gepeng
                    var ratio:Number = bmp.bitmapData.width / bmp.bitmapData.height;
                    bmp.height = targetH;
                    bmp.width = targetH * ratio; // Lebar menyesuaikan rasio
                    bmp.smoothing = true;
                }
            }
        }

        private function alignCenterY(obj:DisplayObject, centerY:Number):void {
            // Geser objek supaya titik tengahnya ada di centerY
            obj.y = centerY - (obj.height / 2);
        }
        // -----------------------

        private function createBtn(path:String, tx:Number, ty:Number, delta:int):Sprite {
            var btn:Sprite = new Sprite();
            btn.x = tx; btn.y = ty; btn.buttonMode = true;
            addChild(btn);

            loadBitmap(path, function(bd:BitmapData):void {
                var bmp:Bitmap = new Bitmap(bd);
                bmp.smoothing = true;
                btn.addChild(bmp);
                refreshLayout(); // Update layout saat gambar selesai load
            });

            btn.addEventListener(MouseEvent.CLICK, function(e:Event):void { updateVolume(delta); });
            return btn;
        }

        private function updateVolume(delta:int):void {
            var newLevel:int = _currentLevel + delta;
            if (newLevel >= 0 && newLevel <= 10) {
                _currentLevel = newLevel;
                AudioManager.getInstance().setMasterLevel(_currentLevel);
                if(delta != 0) AudioManager.getInstance().playSfx(delta > 0 ? "ButtonIn" : "ButtonOut");
                _volumeDisplay.update(_currentLevel);
                
                // Save volume setting to SaveSystem
                saveVolumeLevel();
                
                dispatchEvent(new Event(SETTINGS_CHANGED));
            }
        }
        
        private function saveVolumeLevel():void {
            var saveSystem:SaveSystem = SaveSystem.getInstance();
            if (saveSystem.data && saveSystem.data.settings) {
                saveSystem.data.settings.masterVolume = _currentLevel / 10;
                saveSystem.data.settings.sfxVolume = _currentLevel / 10;
                saveSystem.saveState();
            }
        }

        private function loadBitmap(path:String, onComplete:Function):void {
            var l:Loader = new Loader();
            l.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = e.target.content as Bitmap;
                if(bmp) onComplete(bmp.bitmapData);
            });
            try { l.load(new URLRequest(path)); } catch(e:Error){}
        }

        // --- Compatibility ---
        public function initialize(w:Number, h:Number):void { x = w/2; y = h/2; }
        public function setPlusButtonPosition(px:Number, py:Number):void { if(plusBtn){ plusBtn.x=px; plusBtn.y=py; refreshLayout(); } }
        public function setMinButtonPosition(px:Number, py:Number):void { if(minBtn){ minBtn.x=px; minBtn.y=py; refreshLayout(); } }
        public function show():void { visible = true; }
        public function hide():void { visible = false; }
        public function resize(w:Number, h:Number):void { initialize(w, h); }
    }
}
