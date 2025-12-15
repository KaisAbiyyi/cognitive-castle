package ui {
    
    import flash.display.MovieClip;
    import flash.display.SimpleButton;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    /**
     * AboutUsPanel - Logika untuk halaman About Us.
     * Desain visual (Background, Teks, dll) diambil langsung dari Library Animate.
     */
    public class AboutUsPanel extends MovieClip {
        
        // ============ EVENTS ============
        public static const CLOSE_CLICKED:String = "closeClicked";
        
        // ============ VISUAL ELEMENTS (DARI ANIMATE) ============
        // PENTING: Beri nama tombol "back/close" di Animate menjadi: btnClose
        // Agar seragam dengan halaman Settings.
        public var btnClose:SimpleButton; 
        
        /**
         * Constructor
         */
        public function AboutUsPanel() {
            super();
            visible = false; // Default sembunyi saat game mulai
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        private function onAddedToStage(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            setupButtons();
        }
        
        /**
         * initialize dipanggil oleh Main.as
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            resize(stageWidth, stageHeight);
        }
        
        /**
         * Menghubungkan tombol visual dengan kode
         */
        private function setupButtons():void {
            if (btnClose) {
                btnClose.addEventListener(MouseEvent.CLICK, onCloseClick);
            } else {
                trace("[AboutUsPanel] Warning: btnClose tidak ditemukan di Symbol Animate!");
                trace("Pastikan Instance Name tombol back/close di Animate adalah 'btnClose'");
            }
        }
        
        // ============ HANDLERS ============
        
        private function onCloseClick(e:MouseEvent):void {
            // Mengirim sinyal ke Main.as untuk menutup halaman ini
            dispatchEvent(new Event(CLOSE_CLICKED));
        }
        
        // ============ PUBLIC METHODS ============
        
        public function show():void {
            this.visible = true;
            // Jika ada animasi intro di timeline Animate, uncomment baris bawah:
            // this.gotoAndPlay("intro");
        }
        
        public function hide():void {
            this.visible = false;
        }
        
        /**
         * Mengatur posisi agar selalu di tengah layar
         */
        public function resize(newWidth:Number, newHeight:Number):void {
            // Asumsi titik registrasi (+) symbol ada di pojok kiri atas (0,0)
            this.x = 0;
            this.y = 0;
            
            // Jika Anda ingin menengahkan panel kecil (pop-up):
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