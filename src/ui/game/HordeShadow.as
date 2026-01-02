package ui.game {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Bitmap;
    import flash.display.BlendMode;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.geom.ColorTransform;
    
    /**
     * HordeShadow - Handles shadow rendering for horde visuals.
     */
    public class HordeShadow {
        
        private static const SHADOW_COLOR:uint = 0x000000;
        private static const HORDE_SHADOW_ALPHA:Number = 0.20;
        private static const HORDE_SHADOW_FLATTEN:Number = 0.15;
        private static const HORDE_SHADOW_STRETCH:Number = 1.05;
        private static const HORDE_SHADOW_SKEW_DEG:Number = 26;
        private static const HORDE_SHADOW_OFFSET_X:Number = 0;
        private static const HORDE_SHADOW_OFFSET_Y:Number = -3;
        private static const HORDE_CONTACT_ALPHA:Number = 0.26;
        private static const HORDE_CONTACT_WIDTH_RATIO:Number = 0.90;
        private static const CONTACT_OFFSET_Y:Number = 0;
        
        private var _shadowSprite:Sprite;
        private var _shadowBitmap:Bitmap;
        private var _contactShadow:Shape;
        private var _shadowLayer:Sprite;
        
        public function HordeShadow() {}
        
        public function create(hordeBitmap:Bitmap, shadowLayer:Sprite):void {
            if (!hordeBitmap || !shadowLayer) return;
            _shadowLayer = shadowLayer;
            clear();
            ensureContactShadow();
            
            _shadowSprite = new Sprite();
            _shadowSprite.mouseEnabled = false;
            _shadowSprite.cacheAsBitmap = true;
            _shadowSprite.blendMode = BlendMode.MULTIPLY;
            
            _shadowBitmap = new Bitmap(hordeBitmap.bitmapData);
            _shadowBitmap.smoothing = true;
            _shadowBitmap.x = -_shadowBitmap.width / 2;
            _shadowBitmap.y = -_shadowBitmap.height;
            tintToSingleColor(_shadowBitmap, SHADOW_COLOR);
            _shadowSprite.addChild(_shadowBitmap);
            _shadowSprite.alpha = HORDE_SHADOW_ALPHA;
            
            shadowLayer.addChild(_shadowSprite);
        }
        
        public function update(bounds:Rectangle, hordeScaleX:Number, hordeScaleY:Number):void {
            if (!_shadowSprite || !_shadowBitmap) return;
            
            var baseX:Number = bounds.x + (bounds.width / 2);
            var baseY:Number = bounds.bottom;
            
            var sx:Number = hordeScaleX * HORDE_SHADOW_STRETCH;
            var sy:Number = hordeScaleY * HORDE_SHADOW_FLATTEN;
            var skewRad:Number = HORDE_SHADOW_SKEW_DEG * (Math.PI / 180);
            
            var m:Matrix = new Matrix();
            m.a = sx;
            m.c = -sy * Math.tan(skewRad);
            m.d = -sy;
            m.tx = baseX + HORDE_SHADOW_OFFSET_X;
            m.ty = baseY + HORDE_SHADOW_OFFSET_Y;
            
            _shadowSprite.transform.matrix = m;
            updateContact(bounds);
        }
        
        private function updateContact(bounds:Rectangle):void {
            if (!_contactShadow) return;
            _contactShadow.visible = true;
            
            var w:Number = bounds.width * HORDE_CONTACT_WIDTH_RATIO;
            var h:Number = Math.max(6, bounds.height * 0.10);
            var x:Number = bounds.x + (bounds.width / 2);
            var y:Number = bounds.bottom + CONTACT_OFFSET_Y;
            
            var g:* = _contactShadow.graphics;
            g.clear();
            g.beginFill(SHADOW_COLOR, 1);
            g.drawEllipse(-w / 2, -h / 2, w, h);
            g.endFill();
            
            _contactShadow.x = x;
            _contactShadow.y = y;
        }
        
        private function ensureContactShadow():void {
            if (_contactShadow || !_shadowLayer) return;
            _contactShadow = new Shape();
            _contactShadow.blendMode = BlendMode.MULTIPLY;
            _contactShadow.alpha = HORDE_CONTACT_ALPHA;
            _contactShadow.visible = false;
            _shadowLayer.addChild(_contactShadow);
        }
        
        public function clear():void {
            if (_shadowSprite && _shadowSprite.parent) _shadowSprite.parent.removeChild(_shadowSprite);
            _shadowSprite = null;
            _shadowBitmap = null;
            if (_contactShadow) { _contactShadow.visible = false; _contactShadow.graphics.clear(); }
        }
        
        private function tintToSingleColor(target:*, color:uint):void {
            var r:int = (color >> 16) & 0xFF;
            var g:int = (color >> 8) & 0xFF;
            var b:int = color & 0xFF;
            target.transform.colorTransform = new ColorTransform(0, 0, 0, 1, r, g, b, 0);
        }
    }
}
