package ui {
    
    import flash.display.MovieClip;
    import flash.display.SimpleButton;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    /**
     * MainMenu - Mengontrol logika menu utama.
     * Desain visual (tombol, background, judul) diatur di dalam Library Animate.
     */
    public class MainMenu extends MovieClip {
        
        // ============ EVENTS ============
        // Event ini akan didengarkan oleh Main.as untuk navigasi
        public static const PLAY_CLICKED:String = "playClicked";
        public static const SETTINGS_CLICKED:String = "settingsClicked";
        public static const ABOUT_US_CLICKED:String = "aboutUsClicked";
        
        // ============ VISUAL ELEMENTS (DARI ANIMATE) ============
        // PENTING: Nama variabel ini HARUS SAMA PERSIS dengan "Instance Name" di panel Properties Animate
        
        public var btnPlay:SimpleButton;      // Instance Name di Animate: btnPlay
        public var settingBtn:SimpleButton;   // Instance Name di Animate: settingBtn
        public var aboutBtn:SimpleButton;     // Instance Name di Animate: aboutBtn
        
        /**
         * Constructor
         */
        public function MainMenu() {
            super();
            // Kita tunggu sampai objek benar-benar muncul di stage sebelum memasang interaksi
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        private function onAddedToStage(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            setupButtons();
        }
        
        /**
         * initialize dipanggil oleh Main.as saat pertama kali dibuat
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            resize(stageWidth, stageHeight);
        }
        
        /**
         * Memasang listener klik pada tombol-tombol
         */
        private function setupButtons():void {
            // Setup Tombol Play
            if (btnPlay) {
                btnPlay.addEventListener(MouseEvent.CLICK, onPlayClick);
            } else {
                trace("[MainMenu] Warning: btnPlay tidak ditemukan di Symbol Animate!");
            }
            
            // Setup Tombol Setting
            if (settingBtn) {
                settingBtn.addEventListener(MouseEvent.CLICK, onSettingsClick);
            } else {
                trace("[MainMenu] Warning: settingBtn tidak ditemukan di Symbol Animate!");
            }
            
            // Setup Tombol About
            if (aboutBtn) {
                aboutBtn.addEventListener(MouseEvent.CLICK, onAboutClick);
            } else {
                trace("[MainMenu] Warning: aboutBtn tidak ditemukan di Symbol Animate!");
            }
        }
        
        // ============ EVENT HANDLERS ============
        
        private function onPlayClick(e:MouseEvent):void {
            trace("Play Clicked");
            dispatchEvent(new Event(PLAY_CLICKED));
        }
        
        private function onSettingsClick(e:MouseEvent):void {
            trace("Settings Clicked");
            dispatchEvent(new Event(SETTINGS_CLICKED));
        }
        
        private function onAboutClick(e:MouseEvent):void {
            trace("About Us Clicked");
            dispatchEvent(new Event(ABOUT_US_CLICKED));
        }
        
        // ============ PUBLIC METHODS ============
        
        public function show():void {
            this.visible = true;
            // Jika Anda punya animasi intro di timeline Animate, bisa tambahkan:
            // this.gotoAndPlay("intro"); 
        }
        
        public function hide():void {
            this.visible = false;
        }
        
        /**
         * Mengatur posisi menu agar responsif
         */
        public function resize(newWidth:Number, newHeight:Number):void {
            // Karena desain dibuat di Animate, biasanya kita letakkan titik tengah menu di tengah layar.
            // Pastikan titik registrasi (tanda +) Symbol MainMenu ada di tengah-tengah desain Anda.
            
            this.x = newWidth / 2;
            this.y = newHeight / 2;
        }
        
        /**
         * Membersihkan listener saat menu dihancurkan (opsional, tapi good practice)
         */
        public function dispose():void {
            if (btnPlay) btnPlay.removeEventListener(MouseEvent.CLICK, onPlayClick);
            if (settingBtn) settingBtn.removeEventListener(MouseEvent.CLICK, onSettingsClick);
            if (aboutBtn) aboutBtn.removeEventListener(MouseEvent.CLICK, onAboutClick);
        }
    }
}