package ui {
    import flash.display.MovieClip;
    import flash.display.SimpleButton;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class MainMenu extends MovieClip {
        public static const PLAY_CLICKED:String = "playClicked";
        public static const SETTINGS_CLICKED:String = "settingsClicked";
        public static const ABOUT_US_CLICKED:String = "aboutUsClicked";
        public static const LESSONS_CLICKED:String = "lessonsClicked";

        public var btnPlay:SimpleButton;
        public var settingBtn:SimpleButton;
        public var aboutBtn:SimpleButton;
        public var lessonsBtn:SimpleButton;

        public function MainMenu() {
            super();
            addEventListener(Event.ADDED_TO_STAGE, onAdded);
        }
        
        private function onAdded(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAdded);
            setupBtn(btnPlay, PLAY_CLICKED);
            setupBtn(settingBtn, SETTINGS_CLICKED);
            setupBtn(aboutBtn, ABOUT_US_CLICKED);
            setupBtn(lessonsBtn, LESSONS_CLICKED);
        }
        
        private function setupBtn(btn:SimpleButton, eventType:String):void {
            if (btn) btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { dispatchEvent(new Event(eventType)); });
        }
        
        public function initialize(w:Number, h:Number):void { resize(w, h); }
        public function show():void { visible = true; }
        public function hide():void { visible = false; }
        public function resize(w:Number, h:Number):void { x = w / 2; y = h / 2; }
    }
}