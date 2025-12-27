package ui {
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class CustomCheckbox extends Sprite {
        [Embed(source="../../assets/Gambar/KotakCeklis.png")] private var KotakImageClass:Class;
        [Embed(source="../../assets/Gambar/Ceklis.png")] private var CeklisImageClass:Class;

        private var _mark:Bitmap;
        private var _isChecked:Boolean = false;

        public function CustomCheckbox(defaultState:Boolean = false) {
            super();
            var bg:Bitmap = new KotakImageClass() as Bitmap;
            addChild(bg);

            _mark = new CeklisImageClass() as Bitmap;
            _mark.x = (bg.width - _mark.width) / 2;
            _mark.y = (bg.height - _mark.height) / 2;
            addChild(_mark);

            this.isChecked = defaultState;
            this.buttonMode = true; 
            this.mouseChildren = false;
            this.addEventListener(MouseEvent.CLICK, onToggleClick);
        }

        private function onToggleClick(e:MouseEvent):void {
            this.isChecked = !_isChecked;
            dispatchEvent(new Event(Event.CHANGE));
        }

        public function get isChecked():Boolean { return _isChecked; }
        
        public function set isChecked(value:Boolean):void {
            _isChecked = value;
            if (_mark) _mark.visible = _isChecked;
        }
    }
}