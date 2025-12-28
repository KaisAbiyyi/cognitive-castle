package ui {
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;

    public class CustomCheckbox extends Sprite {
        private static const BOX_SIZE:Number = 28;
        private static const BOX_ASSET_PATH:String = "assets/Gambar/KotakCeklis.png";
        private static const MARK_ASSET_PATH:String = "assets/Gambar/Ceklis.png";
        
        private var _box:DisplayObject;
        private var _mark:DisplayObject;
        private var _isChecked:Boolean = false;

        public function CustomCheckbox(defaultState:Boolean = false) {
            super();

            loadAssets();
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
            updateMarkVisibility();
        }

        private function loadAssets():void {
            loadBitmap(BOX_ASSET_PATH, function(bmp:Bitmap):void {
                _box = bmp;
                addChildAt(_box, 0);
                layoutMark();
            }, function():void {
                _box = createFallbackBox();
                addChildAt(_box, 0);
                layoutMark();
            });

            loadBitmap(MARK_ASSET_PATH, function(bmp:Bitmap):void {
                _mark = bmp;
                addChild(_mark);
                layoutMark();
                updateMarkVisibility();
            }, function():void {
                _mark = createFallbackMark();
                addChild(_mark);
                layoutMark();
                updateMarkVisibility();
            });
        }

        private function loadBitmap(path:String, onComplete:Function, onError:Function):void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = e.target.content as Bitmap;
                if (!bmp) {
                    onError();
                    return;
                }
                bmp.smoothing = true;
                onComplete(bmp);
            });
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
                onError();
            });
            try {
                loader.load(new URLRequest(path));
            } catch (err:Error) {
                onError();
            }
        }

        private function createFallbackBox():Shape {
            var bg:Shape = new Shape();
            var g:* = bg.graphics;
            g.lineStyle(2, 0xFFFFFF, 0.9);
            g.beginFill(0x000000, 0.25);
            g.drawRect(0, 0, BOX_SIZE, BOX_SIZE);
            g.endFill();
            return bg;
        }

        private function createFallbackMark():Shape {
            var mark:Shape = new Shape();
            var m:* = mark.graphics;
            m.lineStyle(3, 0xFFFFFF, 0.95);
            m.moveTo(6, 15);
            m.lineTo(12, 21);
            m.lineTo(22, 8);
            return mark;
        }

        private function layoutMark():void {
            if (!_box || !_mark) return;
            _mark.x = (_box.width - _mark.width) / 2;
            _mark.y = (_box.height - _mark.height) / 2;
        }

        private function updateMarkVisibility():void {
            if (_mark) _mark.visible = _isChecked;
        }
    }
}
