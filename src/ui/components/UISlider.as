package ui.components {
    import flash.display.*;
    import flash.events.*;

    public class UISlider extends Sprite {
        public var onChange:Function;
        private var _val:Number;
        private var _w:Number;
        private var _fill:Shape = new Shape();
        private var _knob:Shape = new Shape();

        public function UISlider(w:Number, val:Number) {
            _w = w; _val = val;
            
            graphics.beginFill(0x333); graphics.drawRoundRect(0,0,w,6,6); // Track
            addChild(_fill);
            
            _knob.graphics.beginFill(0xFFFFFF); _knob.graphics.drawCircle(0,3,8);
            addChild(_knob);
            
            addEventListener(MouseEvent.MOUSE_DOWN, function(e:Event):void {
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onDrag);
                stage.addEventListener(MouseEvent.MOUSE_UP, onUp);
            });
            draw();
        }

        private function onDrag(e:MouseEvent):void {
            _val = Math.max(0, Math.min(1, mouseX/_w));
            draw();
            if(onChange != null) onChange(_val);
        }
        
        private function onUp(e:MouseEvent):void {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDrag);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onUp);
        }

        private function draw():void {
            _fill.graphics.clear(); _fill.graphics.beginFill(0x4A90E2);
            _fill.graphics.drawRoundRect(0,0,_val*_w,6,6);
            _knob.x = _val * _w;
        }
    }
}