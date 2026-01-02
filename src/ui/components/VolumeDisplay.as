package ui.components {
    import flash.display.*;

    public class VolumeDisplay extends Sprite {
        private var _slots:Vector.<Sprite> = new Vector.<Sprite>();
        private var _bmdEmpty:BitmapData;
        private var _bmdFill:BitmapData;
        
        // Config Layout
        private var _barWidth:Number = 24;
        private const BAR_HEIGHT:Number = 72; // Tinggi Bar Tetap
        private const GAP:Number = 8;
        private const COUNT:int = 10;
        
        private var _currentLevel:int = 10;

        public function VolumeDisplay() {
            for (var i:int = 0; i < COUNT; i++) {
                var s:Sprite = new Sprite();
                addChild(s);
                _slots.push(s);
            }
        }

        public function fitToWidth(startX:Number, endX:Number):void {
            var availableW:Number = endX - startX;
            var totalGap:Number = (COUNT - 1) * GAP;
            
            // Hitung lebar per bar
            _barWidth = (availableW - totalGap) / COUNT;
            if (_barWidth < 2) _barWidth = 2; // Safety min width

            this.x = startX;
            
            // Reposisi slot
            for (var i:int = 0; i < COUNT; i++) {
                _slots[i].x = i * (_barWidth + GAP);
            }
            redraw();
        }

        public function setEmptyAsset(b:BitmapData):void { _bmdEmpty = b; redraw(); }
        public function setFillAsset(b:BitmapData):void { _bmdFill = b; redraw(); }

        public function update(level:int):void {
            _currentLevel = level;
            redraw();
        }

        private function redraw():void {
            for (var i:int = 0; i < COUNT; i++) {
                var s:Sprite = _slots[i];
                var isActive:Boolean = (i < _currentLevel);
                
                while(s.numChildren > 0) s.removeChildAt(0);
                
                if (_bmdEmpty && _bmdFill) {
                    var bmp:Bitmap = new Bitmap(isActive ? _bmdFill : _bmdEmpty);
                    bmp.smoothing = true;
                    // Lebar dinamis (stretch), Tinggi tetap (agar align center rapi)
                    bmp.width = _barWidth; 
                    bmp.height = BAR_HEIGHT;
                    s.addChild(bmp);
                } else {
                    // Fallback visual
                    s.graphics.clear();
                    s.graphics.beginFill(isActive ? 0xF2D25B : 0x2F2F2F, isActive ? 1 : 0.5);
                    s.graphics.drawRect(0, 0, _barWidth, BAR_HEIGHT);
                }
            }
        }
    }
}