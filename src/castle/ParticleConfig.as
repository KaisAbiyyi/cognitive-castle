package castle {
    
    /**
     * ParticleConfig - Configuration for particle effects used in castle system.
     * Defines parameters for confetti, sparkles, dust, and other effects.
     */
    public class ParticleConfig {
        
        // ========== CONFETTI (Correct Answer) ==========
        public static const CONFETTI:Object = {
            count: 50,                   // Number of particles
            colors: [0xFF6B6B, 0x4ECDC4, 0xFFE66D, 0x95E1D3, 0xF38181, 0xAA96DA],
            minSize: 4,                  // Minimum particle size
            maxSize: 12,                 // Maximum particle size
            minSpeed: 2,                 // Minimum fall speed
            maxSpeed: 6,                 // Maximum fall speed
            spread: 200,                 // Horizontal spread
            gravity: 0.15,               // Gravity acceleration
            fadeRate: 0.02,              // Alpha fade per frame
            rotation: true,              // Particles rotate
            rotationSpeed: 5,            // Degrees per frame
            duration: 2000,              // Effect duration (ms)
            shapes: ["square", "circle", "ribbon"] // Particle shapes
        };
        
        // ========== SPARKLES (Streak/Upgrade) ==========
        public static const SPARKLES:Object = {
            count: 30,
            colors: [0xFFD700, 0xFFF8DC, 0xFFFFE0, 0xFFFACD],
            minSize: 2,
            maxSize: 8,
            minSpeed: 1,
            maxSpeed: 3,
            spread: 100,
            gravity: -0.05,              // Float upward slightly
            fadeRate: 0.03,
            rotation: false,
            twinkle: true,               // Flash on/off
            twinkleRate: 0.2,            // Twinkle frequency
            duration: 1500,
            shapes: ["star", "circle"]
        };
        
        // ========== DUST (Construction) ==========
        public static const DUST:Object = {
            count: 20,
            colors: [0xD4C4A8, 0xC9B896, 0xBEAD84, 0xA39572],
            minSize: 3,
            maxSize: 10,
            minSpeed: 0.5,
            maxSpeed: 2,
            spread: 80,
            gravity: 0.08,
            fadeRate: 0.015,
            rotation: true,
            rotationSpeed: 2,
            duration: 1800,
            shapes: ["circle", "cloud"]
        };
        
        // ========== SMOKE (Damage) ==========
        public static const SMOKE:Object = {
            count: 15,
            colors: [0x333333, 0x555555, 0x777777, 0x999999],
            minSize: 8,
            maxSize: 25,
            minSpeed: 0.3,
            maxSpeed: 1.5,
            spread: 60,
            gravity: -0.1,               // Rise upward
            fadeRate: 0.01,
            rotation: false,
            grow: true,                  // Particles expand
            growRate: 1.02,              // Growth multiplier per frame
            duration: 2500,
            shapes: ["cloud"]
        };
        
        // ========== GLOW (Milestone) ==========
        public static const GLOW:Object = {
            count: 40,
            colors: [0x00FF00, 0x7FFF00, 0xADFF2F, 0xFFFF00],
            minSize: 5,
            maxSize: 15,
            minSpeed: 1,
            maxSpeed: 4,
            spread: 150,
            gravity: -0.02,
            fadeRate: 0.025,
            rotation: false,
            pulse: true,                 // Pulse size
            pulseRate: 0.1,
            pulseAmount: 0.3,
            duration: 2000,
            shapes: ["circle", "star"]
        };
        
        // ========== REPAIR SPARKLES ==========
        public static const REPAIR:Object = {
            count: 25,
            colors: [0x00BFFF, 0x87CEEB, 0xADD8E6, 0xB0E0E6],
            minSize: 3,
            maxSize: 10,
            minSpeed: 0.5,
            maxSpeed: 2,
            spread: 60,
            gravity: -0.08,
            fadeRate: 0.02,
            rotation: false,
            twinkle: true,
            twinkleRate: 0.3,
            duration: 1200,
            shapes: ["plus", "star"]
        };
        
        // ========== FIRE (Siege/Attack) ==========
        public static const FIRE:Object = {
            count: 35,
            colors: [0xFF4500, 0xFF6600, 0xFF8C00, 0xFFD700, 0xFFFF00],
            minSize: 4,
            maxSize: 16,
            minSpeed: 1,
            maxSpeed: 4,
            spread: 40,
            gravity: -0.2,               // Rise quickly
            fadeRate: 0.03,
            rotation: false,
            grow: true,
            growRate: 0.98,              // Shrink as they rise
            duration: 1500,
            shapes: ["circle", "triangle"]
        };
        
        // ========== CELEBRATION (Major Achievement) ==========
        public static const CELEBRATION:Object = {
            count: 100,
            colors: [0xFF0000, 0xFF7F00, 0xFFFF00, 0x00FF00, 0x0000FF, 0x8B00FF],
            minSize: 5,
            maxSize: 15,
            minSpeed: 3,
            maxSpeed: 8,
            spread: 300,
            gravity: 0.12,
            fadeRate: 0.015,
            rotation: true,
            rotationSpeed: 8,
            burst: true,                 // Explode outward
            burstForce: 10,
            duration: 3000,
            shapes: ["square", "circle", "star", "ribbon"]
        };
    }
}
