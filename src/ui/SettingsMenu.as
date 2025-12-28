package ui {
    import flash.display.*;
    import flash.events.*;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.net.URLRequest;
    import ui.CustomCheckbox;
    import utils.TweenManager;
    import services.AudioManager;

    public class SettingsMenu extends MovieClip {
        public static const CLOSE_CLICKED:String = "closeClicked";
        public static const SETTINGS_CHANGED:String = "settingsChanged";
        
        public var xBtn:InteractiveObject;
        public var plusBtn:InteractiveObject;
        public var minBtn:InteractiveObject;
        
        private var volumeContainer:Sprite;
        private var fillBars:Vector.<DisplayObject> = new Vector.<DisplayObject>();
        private var currentLevel:int = 10;
        private var kotakCeklis:CustomCheckbox;

        private static const PLUS_ASSET_PATH:String = "assets/Gambar/Plus.png";
        private static const MIN_ASSET_PATH:String = "assets/Gambar/Min.png";
        private static const VOLUME_BAR_FILLED_PATH:String = "assets/Gambar/Rectangle 21.png";
        private static const VOLUME_BAR_EMPTY_PATH:String = "assets/Gambar/Rectangle 24.png";
        private static const VOLUME_BAR_COUNT:int = 10;
        private static const VOLUME_BAR_MARGIN:Number = 18;
        private static const VOLUME_BAR_SPACING_RATIO:Number = 0.45;
        private static const VOLUME_BAR_MIN_WIDTH:Number = 24;
        private static const VOLUME_BAR_MAX_WIDTH:Number = 60;
        private static const VOLUME_BAR_MIN_SPACING:Number = 8;
        private static const VOLUME_BAR_MAX_SPACING:Number = 28;
        private static const VOLUME_BAR_MIN_HEIGHT:Number = 56;
        private static const VOLUME_BAR_MAX_HEIGHT:Number = 96;
        private static const VOLUME_BAR_DEFAULT_HEIGHT:Number = 72;
        private static const VOLUME_BUTTON_FALLBACK_WIDTH:Number = 88;
        private static const VOLUME_BUTTON_FALLBACK_HEIGHT:Number = 87;

        private var _volumeFillBitmapData:BitmapData;
        private var _volumeEmptyBitmapData:BitmapData;
        
        // Konfigurasi Posisi
        public var plusButtonX:Number = NaN, plusButtonY:Number = NaN;
        public var minButtonX:Number = NaN, minButtonY:Number = NaN;

        public function SettingsMenu() {
            visible = false;
            if (stage) init(); else addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void { init(); });
        }

        private function init():void {
            stop();
            TweenManager.init();
            addEventListener(Event.ENTER_FRAME, function(e:Event):void { TweenManager.update(); });
            
            AudioManager.getInstance().init();
            AudioManager.getInstance().setMasterLevel(currentLevel);

            setupVolumeUI();
            setupCheckbox();
            setupButtons();
        }

        private function setupCheckbox():void {
            kotakCeklis = new CustomCheckbox(false);
            kotakCeklis.x = -450; kotakCeklis.y = 85;
            addChild(kotakCeklis);
            kotakCeklis.addEventListener(Event.CHANGE, function(e:Event):void {
                AudioManager.getInstance().playSfx(kotakCeklis.isChecked ? "ButtonIn" : "ButtonOut");
                stage.displayState = kotakCeklis.isChecked ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
                dispatchEvent(new Event(SETTINGS_CHANGED));
            });
        }

        private function setupVolumeUI():void {
            volumeContainer = new Sprite();
            volumeContainer.x = -305;
            volumeContainer.y = -55;
            addChild(volumeContainer);

            rebuildVolumeBars();
            loadVolumeBarAssets();
        }

        private function loadVolumeBarAssets():void {
            var loadedCount:int = 0;
            var failed:Boolean = false;

            var onAssetDone:Function = function():void {
                loadedCount++;
                if (loadedCount < 2) return;
                if (!failed && _volumeFillBitmapData && _volumeEmptyBitmapData) {
                    rebuildVolumeBars();
                }
            };

            var onAssetError:Function = function():void {
                failed = true;
                onAssetDone();
            };

            loadBitmapData(VOLUME_BAR_EMPTY_PATH, function(bmd:BitmapData):void {
                _volumeEmptyBitmapData = bmd;
                onAssetDone();
            }, onAssetError);

            loadBitmapData(VOLUME_BAR_FILLED_PATH, function(bmd:BitmapData):void {
                _volumeFillBitmapData = bmd;
                onAssetDone();
            }, onAssetError);
        }

        private function loadBitmapData(path:String, onComplete:Function, onError:Function):void {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = e.target.content as Bitmap;
                if (!bmp || !bmp.bitmapData) {
                    onError();
                    return;
                }
                onComplete(bmp.bitmapData);
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

        private function buildVolumeBarsWithBitmaps():void {
            clearVolumeBars();

            var layout:Object = getVolumeBarLayout();
            var barWidth:Number = layout.barWidth;
            var barHeight:Number = layout.barHeight;
            var spacing:Number = layout.spacing;
            volumeContainer.x = layout.x;
            volumeContainer.y = layout.y;
            
            for (var i:int = 0; i < VOLUME_BAR_COUNT; i++) {
                var slot:Sprite = new Sprite();
                slot.x = i * (barWidth + spacing);

                var emptyBmp:Bitmap = new Bitmap(_volumeEmptyBitmapData);
                emptyBmp.smoothing = true;
                sizeBitmap(emptyBmp, barWidth, barHeight);
                slot.addChild(emptyBmp);

                var fillBmp:Bitmap = new Bitmap(_volumeFillBitmapData);
                fillBmp.smoothing = true;
                sizeBitmap(fillBmp, barWidth, barHeight);
                slot.addChild(fillBmp);

                volumeContainer.addChild(slot);
                fillBars.push(fillBmp);
            }
            updateVolumeDisplay();
        }

        private function buildVolumeBarsFallback():void {
            clearVolumeBars();

            var layout:Object = getVolumeBarLayout();
            var barWidth:Number = layout.barWidth;
            var barHeight:Number = layout.barHeight;
            var spacing:Number = layout.spacing;
            volumeContainer.x = layout.x;
            volumeContainer.y = layout.y;

            for (var i:int = 0; i < VOLUME_BAR_COUNT; i++) {
                var bg:Shape = new Shape();
                var bgG:* = bg.graphics;
                bgG.beginFill(0x2F2F2F, 0.5);
                bgG.drawRect(0, 0, barWidth, barHeight);
                bgG.endFill();

                var fill:Shape = new Shape();
                var fillG:* = fill.graphics;
                fillG.beginFill(0xF2D25B, 0.95);
                fillG.drawRect(0, 0, barWidth, barHeight);
                fillG.endFill();

                bg.x = fill.x = i * (barWidth + spacing);

                volumeContainer.addChild(bg);
                volumeContainer.addChild(fill);
                fillBars.push(fill);
            }
            updateVolumeDisplay();
        }

        private function rebuildVolumeBars():void {
            if (!volumeContainer) return;
            if (_volumeFillBitmapData && _volumeEmptyBitmapData) {
                buildVolumeBarsWithBitmaps();
            } else {
                buildVolumeBarsFallback();
            }
        }

        private function clearVolumeBars():void {
            while (volumeContainer.numChildren > 0) volumeContainer.removeChildAt(0);
            fillBars = new Vector.<DisplayObject>();
        }

        private function sizeBitmap(bmp:Bitmap, targetW:Number, targetH:Number):void {
            bmp.width = targetW;
            bmp.height = targetH;
        }

        private function setupButtons():void {
            if (xBtn) xBtn.addEventListener(MouseEvent.CLICK, function(e:Event):void { visible = false; dispatchEvent(new Event(CLOSE_CLICKED)); });

            if (plusBtn is DisplayObject) DisplayObject(plusBtn).visible = false;
            if (minBtn is DisplayObject) DisplayObject(minBtn).visible = false;

            plusBtn = createVolumeButton(true);
            minBtn = createVolumeButton(false);
            addChild(DisplayObject(plusBtn));
            addChild(DisplayObject(minBtn));
            
            // Terapkan posisi manual jika ada
            if(!isNaN(plusButtonX)) plusBtn.x = plusButtonX;
            if(!isNaN(minButtonX)) minBtn.x = minButtonX;
            if(!isNaN(plusButtonY)) plusBtn.y = plusButtonY;
            if(!isNaN(minButtonY)) minBtn.y = minButtonY;

            refreshVolumeLayout();
        }

        private function createVolumeButton(isPlus:Boolean):Sprite {
            var btn:Sprite = new Sprite();
            btn.buttonMode = true;
            btn.mouseChildren = false;
            applyVolumeButtonPosition(btn, isPlus);

            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                var bmp:Bitmap = e.target.content as Bitmap;
                if (!bmp) {
                    drawFallbackVolumeButton(btn, isPlus);
                    return;
                }
                bmp.smoothing = true;
                btn.addChild(bmp);
                refreshVolumeLayout();
            });
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
                drawFallbackVolumeButton(btn, isPlus);
            });

            try {
                loader.load(new URLRequest(isPlus ? PLUS_ASSET_PATH : MIN_ASSET_PATH));
            } catch (err:Error) {
                drawFallbackVolumeButton(btn, isPlus);
            }

            btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { changeVolume(isPlus ? 1 : -1, btn); });
            return btn;
        }

        private function applyVolumeButtonPosition(btn:DisplayObject, isPlus:Boolean):void {
            btn.x = volumeContainer.x + (isPlus ? 340 : 388);
            btn.y = volumeContainer.y;
        }

        private function drawFallbackVolumeButton(btn:Sprite, isPlus:Boolean):void {
            btn.graphics.clear();
            while (btn.numChildren > 0) btn.removeChildAt(0);

            var g:* = btn.graphics;
            g.beginFill(0x1B1B1B, 0.8);
            g.lineStyle(2, 0xFFFFFF, 0.8);
            g.drawRoundRect(0, 0, 36, 28, 6, 6);
            g.endFill();

            var tf:TextField = new TextField();
            tf.defaultTextFormat = new TextFormat("Arial", 16, 0xFFFFFF, true);
            tf.text = isPlus ? "+" : "-";
            tf.width = 36;
            tf.height = 28;
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.y = 2;
            btn.addChild(tf);
        }

        private function changeVolume(delta:int, target:DisplayObject):void {
            var newLevel:int = currentLevel + delta;
            if (newLevel >= 0 && newLevel <= 10) {
                currentLevel = newLevel;
                updateVolumeDisplay();
                AudioManager.getInstance().setMasterLevel(currentLevel);
                AudioManager.getInstance().playSfx(delta > 0 ? "ButtonIn" : "ButtonOut");
                
                // Efek pencet
                var ox:Number = target.scaleX, oy:Number = target.scaleY;
                TweenManager.to(target, 0.06, {scaleX: ox*0.8, scaleY: oy*0.8, onComplete:function():void{ TweenManager.to(target, 0.1, {scaleX:ox, scaleY:oy}); }});
                dispatchEvent(new Event(SETTINGS_CHANGED));
            }
        }

        private function updateVolumeDisplay():void {
            if (fillBars.length == 0) return;
            var total:int = Math.min(fillBars.length, VOLUME_BAR_COUNT);
            for (var i:int = 0; i < total; i++) fillBars[i].visible = (i < currentLevel);
        }

        // --- Public Methods ---
        public function initialize(w:Number, h:Number):void { resize(w, h); } // Redirect ke resize agar konsisten
        
        // PERBAIKAN: Menambahkan fungsi resize agar bisa dipanggil Main.as
        public function resize(w:Number, h:Number):void { 
            x = w/2; 
            y = h/2; 
        }

        public function show():void { visible = true; try{ gotoAndPlay("open"); } catch(e:Error){ gotoAndPlay(1); } }
        public function hide():void { try{ gotoAndPlay("close"); } catch(e:Error){ visible=false; } }
        public function onCloseComplete():void { visible = false; dispatchEvent(new Event(CLOSE_CLICKED)); } // Dipanggil timeline Animate
        public function setPlusButtonPosition(x:Number, y:Number):void { plusButtonX = x; plusButtonY = y; if(plusBtn){plusBtn.x=x; plusBtn.y=y;} refreshVolumeLayout(); }
        public function setMinButtonPosition(x:Number, y:Number):void { minButtonX = x; minButtonY = y; if(minBtn){minBtn.x=x; minBtn.y=y;} refreshVolumeLayout(); }
        public function dispose():void { /* Cleanup jika perlu */ }

        private function refreshVolumeLayout():void {
            if (!volumeContainer) return;
            rebuildVolumeBars();
        }

        private function getVolumeBarLayout():Object {
            var minDisplay:DisplayObject = minBtn as DisplayObject;
            var plusDisplay:DisplayObject = plusBtn as DisplayObject;
            var hasButtons:Boolean = (minDisplay != null && plusDisplay != null);
            var barHeight:Number = VOLUME_BAR_DEFAULT_HEIGHT;
            var startX:Number = volumeContainer.x;
            var startY:Number = volumeContainer.y;
            var availableWidth:Number = 0;

            if (hasButtons) {
                var buttonHeight:Number = Math.max(getButtonHeight(minDisplay), getButtonHeight(plusDisplay));
                barHeight = clamp(buttonHeight * 0.8, VOLUME_BAR_MIN_HEIGHT, VOLUME_BAR_MAX_HEIGHT);

                var leftEdge:Number = minDisplay.x + getButtonWidth(minDisplay) + VOLUME_BAR_MARGIN;
                var rightEdge:Number = plusDisplay.x - VOLUME_BAR_MARGIN;
                availableWidth = rightEdge - leftEdge;

                if (availableWidth > 0) {
                    startX = leftEdge;
                    startY = minDisplay.y + (buttonHeight - barHeight) / 2;
                }
            }

            if (availableWidth <= 0) {
                availableWidth = (VOLUME_BAR_COUNT * 32) + ((VOLUME_BAR_COUNT - 1) * 14);
            }

            var barWidth:Number = availableWidth / (VOLUME_BAR_COUNT + VOLUME_BAR_SPACING_RATIO * (VOLUME_BAR_COUNT - 1));
            barWidth = clamp(barWidth, VOLUME_BAR_MIN_WIDTH, VOLUME_BAR_MAX_WIDTH);

            var spacing:Number = (availableWidth - (barWidth * VOLUME_BAR_COUNT)) / (VOLUME_BAR_COUNT - 1);
            spacing = clamp(spacing, VOLUME_BAR_MIN_SPACING, VOLUME_BAR_MAX_SPACING);

            var totalWidth:Number = (VOLUME_BAR_COUNT * barWidth) + ((VOLUME_BAR_COUNT - 1) * spacing);
            if (hasButtons && availableWidth > totalWidth) {
                startX += (availableWidth - totalWidth) / 2;
            }

            return { x: startX, y: startY, barWidth: barWidth, barHeight: barHeight, spacing: spacing };
        }

        private function getButtonWidth(btn:DisplayObject):Number {
            if (!btn) return VOLUME_BUTTON_FALLBACK_WIDTH;
            return (btn.width > 0) ? btn.width : VOLUME_BUTTON_FALLBACK_WIDTH;
        }

        private function getButtonHeight(btn:DisplayObject):Number {
            if (!btn) return VOLUME_BUTTON_FALLBACK_HEIGHT;
            return (btn.height > 0) ? btn.height : VOLUME_BUTTON_FALLBACK_HEIGHT;
        }

        private function clamp(value:Number, min:Number, max:Number):Number {
            return Math.max(min, Math.min(max, value));
        }
    }
}
