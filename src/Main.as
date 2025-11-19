package {
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.system.Capabilities;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;

    public class Main extends Sprite {
        public function Main() {
            // 1. Setup Layar agar tidak gepeng (Responsive)
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;

            // 2. Cek Platform
            var platform:String = Capabilities.version;
            
            // 3. Tampilkan Teks
            var tf:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.size = 30; // Ukuran font besar
            
            tf.defaultTextFormat = format;
            tf.text = "Cognitive Castle\n" + 
                      "System: " + platform + "\n" + 
                      "Resolution: " + stage.stageWidth + "x" + stage.stageHeight;
            
            tf.width = stage.stageWidth; // Lebar ngikutin layar
            tf.height = 500;
            tf.textColor = 0x000000; // Warna Hitam
            addChild(tf);
            
            // Logika visualisasi kastil akan dimulai dari sini nanti
            // initCastle(); 
        }
    }
}