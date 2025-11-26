package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.events.Event;
    import flash.geom.Point;
    
    /**
     * ParticleSystem - Simple particle rendering for visual effects.
     * Supports confetti, sparkles, and dust particles.
     * 
     * T1-084
     */
    public class ParticleSystem extends Sprite {
        
        // Particle types
        public static const TYPE_CONFETTI:String = "confetti";
        public static const TYPE_SPARKLE:String = "sparkle";
        public static const TYPE_DUST:String = "dust";
        
        // Active particles
        private var _particles:Array;
        private var _maxParticles:int = 100;
        private var _active:Boolean = false;
        
        // Emitter position
        private var _emitterX:Number = 0;
        private var _emitterY:Number = 0;
        
        // Bounds
        private var _boundsWidth:Number;
        private var _boundsHeight:Number;
        
        /**
         * Constructor
         */
        public function ParticleSystem(boundsWidth:Number = 800, boundsHeight:Number = 600) {
            _boundsWidth = boundsWidth;
            _boundsHeight = boundsHeight;
            _particles = [];
        }
        
        /**
         * Emit confetti burst (for correct answer)
         */
        public function emitConfetti(x:Number, y:Number, count:int = 30):void {
            _emitterX = x;
            _emitterY = y;
            
            var colors:Array = [0xFF6B6B, 0x4ECDC4, 0xFFE66D, 0x95E1D3, 0xF38181, 0xAA96DA];
            
            for (var i:int = 0; i < count; i++) {
                if (_particles.length >= _maxParticles) break;
                
                var particle:Object = {
                    shape: createConfettiShape(colors[i % colors.length]),
                    x: x,
                    y: y,
                    vx: (Math.random() - 0.5) * 15,
                    vy: -Math.random() * 15 - 5,
                    rotation: Math.random() * 360,
                    rotationSpeed: (Math.random() - 0.5) * 20,
                    gravity: 0.3,
                    friction: 0.98,
                    life: 1.0,
                    decay: 0.015 + Math.random() * 0.01,
                    type: TYPE_CONFETTI
                };
                
                addChild(particle.shape);
                _particles.push(particle);
            }
            
            startAnimation();
        }
        
        /**
         * Emit sparkles (for streak)
         */
        public function emitSparkles(x:Number, y:Number, count:int = 15):void {
            _emitterX = x;
            _emitterY = y;
            
            for (var i:int = 0; i < count; i++) {
                if (_particles.length >= _maxParticles) break;
                
                var angle:Number = (i / count) * Math.PI * 2;
                var speed:Number = 3 + Math.random() * 5;
                
                var particle:Object = {
                    shape: createSparkleShape(),
                    x: x,
                    y: y,
                    vx: Math.cos(angle) * speed,
                    vy: Math.sin(angle) * speed,
                    rotation: 0,
                    rotationSpeed: 0,
                    gravity: 0,
                    friction: 0.95,
                    life: 1.0,
                    decay: 0.03 + Math.random() * 0.02,
                    type: TYPE_SPARKLE,
                    twinkle: Math.random() * Math.PI * 2
                };
                
                addChild(particle.shape);
                _particles.push(particle);
            }
            
            startAnimation();
        }
        
        /**
         * Emit dust particles (for construction)
         */
        public function emitDust(x:Number, y:Number, count:int = 20):void {
            _emitterX = x;
            _emitterY = y;
            
            for (var i:int = 0; i < count; i++) {
                if (_particles.length >= _maxParticles) break;
                
                var particle:Object = {
                    shape: createDustShape(),
                    x: x + (Math.random() - 0.5) * 30,
                    y: y,
                    vx: (Math.random() - 0.5) * 3,
                    vy: -Math.random() * 2 - 1,
                    rotation: 0,
                    rotationSpeed: 0,
                    gravity: -0.02, // Float up
                    friction: 0.98,
                    life: 1.0,
                    decay: 0.01 + Math.random() * 0.01,
                    type: TYPE_DUST,
                    originalScale: 0.5 + Math.random() * 0.5
                };
                
                addChild(particle.shape);
                _particles.push(particle);
            }
            
            startAnimation();
        }
        
        // ============ PARTICLE SHAPES ============
        
        private function createConfettiShape(color:uint):Shape {
            var shape:Shape = new Shape();
            var g:* = shape.graphics;
            
            // Random confetti shape (rectangle or square)
            var w:Number = 6 + Math.random() * 6;
            var h:Number = 4 + Math.random() * 8;
            
            g.beginFill(color);
            g.drawRect(-w / 2, -h / 2, w, h);
            g.endFill();
            
            return shape;
        }
        
        private function createSparkleShape():Shape {
            var shape:Shape = new Shape();
            var g:* = shape.graphics;
            
            // Four-pointed star
            var size:Number = 3 + Math.random() * 3;
            
            g.beginFill(0xFFFFFF);
            g.moveTo(0, -size);
            g.lineTo(size * 0.3, -size * 0.3);
            g.lineTo(size, 0);
            g.lineTo(size * 0.3, size * 0.3);
            g.lineTo(0, size);
            g.lineTo(-size * 0.3, size * 0.3);
            g.lineTo(-size, 0);
            g.lineTo(-size * 0.3, -size * 0.3);
            g.lineTo(0, -size);
            g.endFill();
            
            return shape;
        }
        
        private function createDustShape():Shape {
            var shape:Shape = new Shape();
            var g:* = shape.graphics;
            
            // Simple circle dust
            var size:Number = 2 + Math.random() * 4;
            var gray:int = 180 + Math.random() * 50;
            var color:uint = (gray << 16) | (gray << 8) | gray;
            
            g.beginFill(color, 0.6);
            g.drawCircle(0, 0, size);
            g.endFill();
            
            return shape;
        }
        
        // ============ ANIMATION ============
        
        private function startAnimation():void {
            if (!_active) {
                _active = true;
                addEventListener(Event.ENTER_FRAME, onFrame);
            }
        }
        
        private function onFrame(e:Event):void {
            var i:int = _particles.length;
            
            while (i--) {
                var p:Object = _particles[i];
                
                // Update physics
                p.vx *= p.friction;
                p.vy *= p.friction;
                p.vy += p.gravity;
                
                p.x += p.vx;
                p.y += p.vy;
                p.rotation += p.rotationSpeed;
                
                // Update life
                p.life -= p.decay;
                
                // Type-specific updates
                if (p.type == TYPE_SPARKLE) {
                    p.twinkle += 0.3;
                    p.shape.alpha = p.life * (0.5 + Math.sin(p.twinkle) * 0.5);
                    p.shape.scaleX = p.life;
                    p.shape.scaleY = p.life;
                } else if (p.type == TYPE_DUST) {
                    p.shape.alpha = p.life * 0.6;
                    p.shape.scaleX = p.originalScale * (1 + (1 - p.life) * 0.5);
                    p.shape.scaleY = p.shape.scaleX;
                } else {
                    p.shape.alpha = p.life;
                }
                
                // Apply position
                p.shape.x = p.x;
                p.shape.y = p.y;
                p.shape.rotation = p.rotation;
                
                // Remove dead particles
                if (p.life <= 0 || p.y > _boundsHeight + 50) {
                    removeChild(p.shape);
                    _particles.splice(i, 1);
                }
            }
            
            // Stop animation when no particles
            if (_particles.length == 0) {
                _active = false;
                removeEventListener(Event.ENTER_FRAME, onFrame);
            }
        }
        
        /**
         * Clear all particles
         */
        public function clear():void {
            for (var i:int = _particles.length - 1; i >= 0; i--) {
                if (_particles[i].shape.parent) {
                    removeChild(_particles[i].shape);
                }
            }
            _particles = [];
            _active = false;
            removeEventListener(Event.ENTER_FRAME, onFrame);
        }
        
        /**
         * Update bounds
         */
        public function setBounds(width:Number, height:Number):void {
            _boundsWidth = width;
            _boundsHeight = height;
        }
        
        public function get particleCount():int {
            return _particles.length;
        }
        
        public function get isActive():Boolean {
            return _active;
        }
    }
}
