package ui.game {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.geom.Rectangle;
    
    /**
     * HordeDust - Handles dust particle effects for horde movement.
     */
    public class HordeDust extends Sprite {
        
        private var _particles:Vector.<Object>;
        private var _spawnRemainder:Number = 0;
        
        public function HordeDust() {
            _particles = new Vector.<Object>();
            mouseEnabled = false;
        }
        
        public function clear():void {
            _spawnRemainder = 0;
            if (_particles) _particles.length = 0;
            while (numChildren > 0) removeChildAt(0);
        }
        
        public function tick(frameMs:Number, hordeBounds:Rectangle, fromRight:Boolean, shouldSpawn:Boolean):void {
            if (shouldSpawn && hordeBounds && hordeBounds.width > 0) {
                var puffsPerSecond:Number = 18;
                _spawnRemainder += (puffsPerSecond * frameMs) / 1000;
                var spawnCount:int = int(_spawnRemainder);
                _spawnRemainder -= spawnCount;
                for (var s:int = 0; s < spawnCount; s++) spawn(hordeBounds, fromRight);
            }
            
            for (var i:int = _particles.length - 1; i >= 0; i--) {
                var dust:Object = _particles[i];
                dust.age += frameMs;
                var t:Number = dust.age / dust.life;
                if (t >= 1) {
                    if (dust.sprite && dust.sprite.parent) dust.sprite.parent.removeChild(dust.sprite);
                    _particles.splice(i, 1);
                    continue;
                }
                var sprite:Sprite = dust.sprite as Sprite;
                if (!sprite) { _particles.splice(i, 1); continue; }
                sprite.x += dust.vx * frameMs;
                sprite.y += dust.vy * frameMs;
                sprite.alpha = dust.baseAlpha * (1 - t);
                var scale:Number = dust.startScale + (dust.endScale - dust.startScale) * t;
                sprite.scaleX = scale; sprite.scaleY = scale;
            }
        }
        
        private function spawn(hordeBounds:Rectangle, fromRight:Boolean):void {
            var bias:Number = fromRight ? 0.78 : 0.22;
            var spawnX:Number = hordeBounds.left + (hordeBounds.width * bias) + (Math.random() - 0.5) * hordeBounds.width * 0.25;
            var spawnY:Number = hordeBounds.bottom - 6 + (Math.random() - 0.5) * 6;
            
            var puff:Shape = new Shape();
            var g:* = puff.graphics;
            g.beginFill(0xFFFFFF, 1);
            var r:Number = 6 + Math.random() * 6;
            g.drawCircle(0, 0, r);
            g.drawCircle(r * 0.6, -r * 0.25, r * 0.7);
            g.drawCircle(-r * 0.65, -r * 0.15, r * 0.6);
            g.endFill();
            
            var sprite:Sprite = new Sprite();
            sprite.mouseEnabled = false;
            sprite.addChild(puff);
            sprite.x = spawnX;
            sprite.y = spawnY;
            
            var startScale:Number = 0.16 + Math.random() * 0.18;
            sprite.scaleX = startScale; sprite.scaleY = startScale;
            sprite.alpha = 0.25 + Math.random() * 0.25;
            addChild(sprite);
            
            var drift:Number = fromRight ? 1 : -1;
            _particles.push({
                sprite: sprite,
                vx: (((12 + Math.random() * 28) / 1000) * drift) + (((Math.random() - 0.5) * 12) / 1000),
                vy: -((10 + Math.random() * 25) / 1000),
                age: 0, life: 420 + Math.random() * 320,
                startScale: startScale, endScale: startScale * (1.7 + Math.random() * 0.5),
                baseAlpha: sprite.alpha
            });
        }
    }
}
