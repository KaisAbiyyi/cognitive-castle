package castle {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    
    /**
     * EffectsManager - Manages visual effects for castle and game events.
     * Handles particles, floating text, screen effects, and notifications.
     */
    public class EffectsManager extends Sprite {
        
        // Debug flag
        private static const DEBUG:Boolean = true;
        
        // Singleton instance
        private static var _instance:EffectsManager;
        
        // Active particles
        private var _particles:Vector.<Object>;
        
        // Active floating texts
        private var _floatingTexts:Vector.<Object>;
        
        // Update timer
        private var _updateTimer:Timer;
        
        // Container references
        private var _particleLayer:Sprite;
        private var _textLayer:Sprite;
        
        /**
         * Get singleton instance
         */
        public static function getInstance():EffectsManager {
            if (!_instance) {
                _instance = new EffectsManager();
            }
            return _instance;
        }
        
        /**
         * Constructor
         */
        public function EffectsManager() {
            _particles = new Vector.<Object>();
            _floatingTexts = new Vector.<Object>();
            
            // Create layers
            _particleLayer = new Sprite();
            _textLayer = new Sprite();
            addChild(_particleLayer);
            addChild(_textLayer);
            
            // Setup update timer (60 FPS)
            _updateTimer = new Timer(1000 / 60);
            _updateTimer.addEventListener(TimerEvent.TIMER, onUpdate);
            _updateTimer.start();
        }
        
        /**
         * Set parent container for effects
         * @param parent Parent sprite to add this manager to
         */
        public function setParent(parent:Sprite):void {
            if (parent && !this.parent) {
                parent.addChild(this);
                if (DEBUG) {
                    trace("EffectsManager added to parent");
                }
            }
        }
        
        /**
         * Update all active effects
         */
        private function onUpdate(e:TimerEvent):void {
            updateParticles();
            updateFloatingTexts();
        }
        
        // ========== PARTICLES ==========
        
        /**
         * Spawn particle effect at position
         * @param type Effect type (confetti, sparkles, dust, etc.)
         * @param x X position
         * @param y Y position
         */
        public function spawnParticles(type:String, x:Number, y:Number):void {
            var config:Object = getParticleConfig(type);
            if (!config) return;
            
            var count:int = config.count;
            
            for (var i:int = 0; i < count; i++) {
                createParticle(config, x, y);
            }
            
            if (DEBUG) {
                trace("Spawned " + count + " " + type + " particles at (" + x + ", " + y + ")");
            }
        }
        
        /**
         * Get particle configuration by type
         */
        private function getParticleConfig(type:String):Object {
            switch (type.toLowerCase()) {
                case "confetti": return ParticleConfig.CONFETTI;
                case "sparkles": return ParticleConfig.SPARKLES;
                case "dust": return ParticleConfig.DUST;
                case "smoke": return ParticleConfig.SMOKE;
                case "glow": return ParticleConfig.GLOW;
                case "repair": return ParticleConfig.REPAIR;
                case "fire": return ParticleConfig.FIRE;
                case "celebration": return ParticleConfig.CELEBRATION;
                default: return ParticleConfig.CONFETTI;
            }
        }
        
        /**
         * Create single particle
         */
        private function createParticle(config:Object, originX:Number, originY:Number):void {
            var particle:Shape = new Shape();
            var colors:Array = config.colors;
            var color:uint = colors[Math.floor(Math.random() * colors.length)];
            var size:Number = config.minSize + Math.random() * (config.maxSize - config.minSize);
            
            // Draw particle shape
            var shapes:Array = config.shapes;
            var shapeType:String = shapes[Math.floor(Math.random() * shapes.length)];
            drawParticleShape(particle, shapeType, size, color);
            
            // Calculate initial position with spread
            var spreadX:Number = (Math.random() - 0.5) * config.spread;
            var spreadY:Number = (Math.random() - 0.5) * config.spread * 0.5;
            
            particle.x = originX + spreadX;
            particle.y = originY + spreadY;
            
            // Calculate velocity
            var angle:Number = Math.random() * Math.PI * 2;
            var speed:Number = config.minSpeed + Math.random() * (config.maxSpeed - config.minSpeed);
            
            // Burst effect
            if (config.burst) {
                speed *= config.burstForce;
            }
            
            var vx:Number = Math.cos(angle) * speed;
            var vy:Number = Math.sin(angle) * speed;
            
            // Store particle data
            var data:Object = {
                shape: particle,
                vx: vx,
                vy: vy,
                gravity: config.gravity,
                fadeRate: config.fadeRate,
                rotation: config.rotation,
                rotationSpeed: config.rotationSpeed || 0,
                twinkle: config.twinkle,
                twinkleRate: config.twinkleRate || 0,
                grow: config.grow,
                growRate: config.growRate || 1,
                pulse: config.pulse,
                pulseRate: config.pulseRate || 0,
                pulseAmount: config.pulseAmount || 0,
                pulsePhase: Math.random() * Math.PI * 2,
                startTime: new Date().getTime(),
                duration: config.duration
            };
            
            _particles.push(data);
            _particleLayer.addChild(particle);
        }
        
        /**
         * Draw particle shape
         */
        private function drawParticleShape(shape:Shape, type:String, size:Number, color:uint):void {
            var g:* = shape.graphics;
            g.beginFill(color, 1);
            
            switch (type) {
                case "circle":
                    g.drawCircle(0, 0, size / 2);
                    break;
                case "square":
                    g.drawRect(-size / 2, -size / 2, size, size);
                    break;
                case "star":
                    drawStar(g, 0, 0, size / 2, size / 4, 5);
                    break;
                case "ribbon":
                    g.drawRect(-size / 2, -size / 6, size, size / 3);
                    break;
                case "triangle":
                    g.moveTo(0, -size / 2);
                    g.lineTo(size / 2, size / 2);
                    g.lineTo(-size / 2, size / 2);
                    g.lineTo(0, -size / 2);
                    break;
                case "cloud":
                    g.drawEllipse(-size / 2, -size / 4, size, size / 2);
                    break;
                case "plus":
                    var thickness:Number = size / 3;
                    g.drawRect(-size / 2, -thickness / 2, size, thickness);
                    g.drawRect(-thickness / 2, -size / 2, thickness, size);
                    break;
                default:
                    g.drawCircle(0, 0, size / 2);
            }
            
            g.endFill();
        }
        
        /**
         * Draw star shape
         */
        private function drawStar(g:*, cx:Number, cy:Number, outerR:Number, innerR:Number, points:int):void {
            var angle:Number = -Math.PI / 2;
            var step:Number = Math.PI / points;
            
            g.moveTo(cx + Math.cos(angle) * outerR, cy + Math.sin(angle) * outerR);
            
            for (var i:int = 0; i < points * 2; i++) {
                var r:Number = (i % 2 == 0) ? innerR : outerR;
                angle += step;
                g.lineTo(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r);
            }
        }
        
        /**
         * Update all particles
         */
        private function updateParticles():void {
            var now:Number = new Date().getTime();
            var toRemove:Vector.<int> = new Vector.<int>();
            
            for (var i:int = 0; i < _particles.length; i++) {
                var p:Object = _particles[i];
                var shape:Shape = p.shape as Shape;
                
                // Check duration
                if (now - p.startTime > p.duration) {
                    toRemove.push(i);
                    continue;
                }
                
                // Apply velocity
                shape.x += p.vx;
                shape.y += p.vy;
                
                // Apply gravity
                p.vy += p.gravity;
                
                // Apply fade
                shape.alpha -= p.fadeRate;
                if (shape.alpha <= 0) {
                    toRemove.push(i);
                    continue;
                }
                
                // Apply rotation
                if (p.rotation) {
                    shape.rotation += p.rotationSpeed;
                }
                
                // Apply twinkle
                if (p.twinkle) {
                    if (Math.random() < p.twinkleRate) {
                        shape.visible = !shape.visible;
                    }
                }
                
                // Apply grow
                if (p.grow) {
                    shape.scaleX *= p.growRate;
                    shape.scaleY *= p.growRate;
                }
                
                // Apply pulse
                if (p.pulse) {
                    p.pulsePhase += p.pulseRate;
                    var pulseFactor:Number = 1 + Math.sin(p.pulsePhase) * p.pulseAmount;
                    shape.scaleX = pulseFactor;
                    shape.scaleY = pulseFactor;
                }
            }
            
            // Remove expired particles (in reverse order)
            for (var j:int = toRemove.length - 1; j >= 0; j--) {
                var idx:int = toRemove[j];
                var deadShape:Shape = _particles[idx].shape as Shape;
                if (deadShape.parent) {
                    deadShape.parent.removeChild(deadShape);
                }
                _particles.splice(idx, 1);
            }
        }
        
        // ========== FLOATING TEXT ==========
        
        /**
         * Show floating score popup
         * @param text Text to display
         * @param x X position
         * @param y Y position
         * @param color Text color
         * @param size Font size
         */
        public function showFloatingText(text:String, x:Number, y:Number, color:uint = 0xFFFFFF, size:int = 24):void {
            var tf:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = size;
            format.color = color;
            format.bold = true;
            format.align = TextFormatAlign.CENTER;
            
            tf.defaultTextFormat = format;
            tf.text = text;
            tf.width = 200;
            tf.height = 50;
            tf.x = x - 100;
            tf.y = y;
            tf.selectable = false;
            
            var data:Object = {
                textField: tf,
                startY: y,
                targetY: y - 80,
                startTime: new Date().getTime(),
                duration: 1500,
                fadeStart: 1000
            };
            
            _floatingTexts.push(data);
            _textLayer.addChild(tf);
            
            if (DEBUG) {
                trace("Floating text: " + text + " at (" + x + ", " + y + ")");
            }
        }
        
        /**
         * Show score popup with + prefix
         */
        public function showScorePopup(score:int, x:Number, y:Number):void {
            var color:uint = score > 0 ? 0x00FF00 : 0xFF0000;
            var prefix:String = score > 0 ? "+" : "";
            showFloatingText(prefix + score, x, y, color, 28);
        }
        
        /**
         * Show milestone notification
         */
        public function showMilestoneNotification(milestoneName:String, x:Number, y:Number):void {
            showFloatingText("🏆 " + milestoneName + "!", x, y, 0xFFD700, 32);
            spawnParticles("celebration", x, y);
        }
        
        /**
         * Update floating texts
         */
        private function updateFloatingTexts():void {
            var now:Number = new Date().getTime();
            var toRemove:Vector.<int> = new Vector.<int>();
            
            for (var i:int = 0; i < _floatingTexts.length; i++) {
                var data:Object = _floatingTexts[i];
                var tf:TextField = data.textField as TextField;
                var elapsed:Number = now - data.startTime;
                
                // Check duration
                if (elapsed > data.duration) {
                    toRemove.push(i);
                    continue;
                }
                
                // Animate Y position (float upward)
                var progress:Number = elapsed / data.duration;
                tf.y = data.startY + (data.targetY - data.startY) * easeOutQuad(progress);
                
                // Fade out in last portion
                if (elapsed > data.fadeStart) {
                    var fadeProgress:Number = (elapsed - data.fadeStart) / (data.duration - data.fadeStart);
                    tf.alpha = 1 - fadeProgress;
                }
            }
            
            // Remove expired texts
            for (var j:int = toRemove.length - 1; j >= 0; j--) {
                var idx:int = toRemove[j];
                var deadTf:TextField = _floatingTexts[idx].textField as TextField;
                if (deadTf.parent) {
                    deadTf.parent.removeChild(deadTf);
                }
                _floatingTexts.splice(idx, 1);
            }
        }
        
        /**
         * Easing function
         */
        private function easeOutQuad(t:Number):Number {
            return t * (2 - t);
        }
        
        // ========== EFFECT SHORTCUTS ==========
        
        /**
         * Play correct answer effects
         */
        public function playCorrectEffect(x:Number, y:Number, score:int):void {
            spawnParticles("confetti", x, y);
            showScorePopup(score, x, y - 30);
        }
        
        /**
         * Play wrong answer effects
         */
        public function playWrongEffect(x:Number, y:Number):void {
            spawnParticles("smoke", x, y);
        }
        
        /**
         * Play streak effects
         */
        public function playStreakEffect(x:Number, y:Number, streak:int):void {
            spawnParticles("sparkles", x, y);
            showFloatingText("🔥 " + streak + " Streak!", x, y - 30, 0xFF6600, 26);
        }
        
        /**
         * Play construction effect
         */
        public function playConstructionEffect(x:Number, y:Number, partName:String):void {
            spawnParticles("dust", x, y);
            showFloatingText("Built: " + partName, x, y - 20, 0xD4C4A8, 20);
        }
        
        /**
         * Play upgrade effect
         */
        public function playUpgradeEffect(x:Number, y:Number, tier:int):void {
            spawnParticles("sparkles", x, y);
            showFloatingText("⬆ Tier " + tier, x, y - 20, 0xFFD700, 22);
        }
        
        /**
         * Play damage effect
         */
        public function playDamageEffect(x:Number, y:Number, amount:int):void {
            spawnParticles("fire", x, y);
            showFloatingText("-" + amount + " HP", x, y - 20, 0xFF4444, 20);
        }
        
        /**
         * Play repair effect
         */
        public function playRepairEffect(x:Number, y:Number, amount:int):void {
            spawnParticles("repair", x, y);
            showFloatingText("+" + amount + " HP", x, y - 20, 0x44FF44, 20);
        }
        
        /**
         * Clear all effects
         */
        public function clearAll():void {
            // Clear particles
            while (_particleLayer.numChildren > 0) {
                _particleLayer.removeChildAt(0);
            }
            _particles.length = 0;
            
            // Clear texts
            while (_textLayer.numChildren > 0) {
                _textLayer.removeChildAt(0);
            }
            _floatingTexts.length = 0;
        }
        
        /**
         * Stop update timer (cleanup)
         */
        public function dispose():void {
            _updateTimer.stop();
            _updateTimer.removeEventListener(TimerEvent.TIMER, onUpdate);
            clearAll();
        }
    }
}
