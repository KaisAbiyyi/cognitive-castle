package ui {
    
    import flash.display.MovieClip;
    import flash.display.SimpleButton;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    public class SettingsMenu extends MovieClip {
        
        // Events
        public static const CLOSE_CLICKED:String = "closeClicked";
        public static const SETTINGS_CHANGED:String = "settingsChanged";
        
        // ============ VISUAL ELEMENTS DARI ANIMATE ============
        // Pastikan Instance Name di Animate: "btnClose"
        public var btnClose:SimpleButton;
        
        // Tambahkan elemen lain jika ada di desain Animate, contoh:
        // public var btnMusic:MovieClip;
        // public var btnSound:MovieClip;
        
        public function SettingsMenu() {
            super();
            visible = false; // Default sembunyi
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        private function onAddedToStage(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            setupButtons();
        }
        
        /**
         * Initialize dipanggil dari Main.as
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            resize(stageWidth, stageHeight);
        }
        
        private function setupButtons():void {
            if (btnClose) {
                btnClose.addEventListener(MouseEvent.CLICK, onCloseClick);
            } else {
                trace("[SettingsMenu] Warning: btnClose not found in Animate symbol!");
            }
            
            // Setup tombol lain di sini...
        }
        
        private function onCloseClick(e:MouseEvent):void {
            dispatchEvent(new Event(CLOSE_CLICKED));
        }
        
        // ============ PUBLIC METHODS ============
        
        public function show():void {
            this.visible = true;
            // Reset posisi atau update tampilan toggle di sini jika perlu
        }
        
        public function hide():void {
            this.visible = false;
        }
        
        public function resize(newWidth:Number, newHeight:Number):void {
            // Posisikan di 0,0 jika desain full screen
            this.x = 0;
            this.y = 0;
            
            // Atau tengahkan jika desain popup kecil
            /*
            this.x = (newWidth - this.width) / 2;
            this.y = (newHeight - this.height) / 2;
            */
        }
        
        public function dispose():void {
            if (btnClose) {
                btnClose.removeEventListener(MouseEvent.CLICK, onCloseClick);
            }
        }
    }
}