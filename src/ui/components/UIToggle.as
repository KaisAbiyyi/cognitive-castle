package ui.components {
    import flash.display.*;
    import flash.events.*;

    public class UIToggle extends Sprite {
        public var onChange:Function;
        private var _isOn:Boolean;

        public function UIToggle(isOn:Boolean) {
            _isOn = isOn;
            buttonMode = true;
            addEventListener(MouseEvent.CLICK, function(e:Event):void {
                _isOn = !_isOn;
                draw();
                if(onChange != null) onChange(_isOn);
            });
            draw();
        }

        private function draw():void {
            graphics.clear();
            graphics.beginFill(_isOn ? 0x4CAF50 : 0x555);
            graphics.drawRoundRect(0, 0, 50, 24, 24);
            graphics.beginFill(0xFFFFFF);
            graphics.drawCircle(_isOn ? 38 : 12, 12, 10);
        }
    }
}