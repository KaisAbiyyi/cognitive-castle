package castle {
    
    /**
     * CastleConfig - Configuration constants for castle system.
     * Defines milestones, growth thresholds, and part types.
     */
    public class CastleConfig {
        
        // ========== GRID SETTINGS ==========
        public static const GRID_WIDTH:int = 7;
        public static const GRID_HEIGHT:int = 5;
        public static const CELL_SIZE:int = 60;
        
        // ========== MILESTONES ==========
        // Score thresholds for each milestone
        public static const MILESTONES:Array = [
            { score: 0,   name: "Empty Land",     description: "Start your journey" },
            { score: 10,  name: "Foundation",     description: "Lay the groundwork" },
            { score: 30,  name: "Walls Rising",   description: "Defenses take shape" },
            { score: 60,  name: "First Tower",    description: "Watchtower complete" },
            { score: 100, name: "Decorated",      description: "Adding beauty" },
            { score: 150, name: "Twin Towers",    description: "Second tower rises" },
            { score: 200, name: "The Keep",       description: "Heart of the castle" },
            { score: 300, name: "Fortified",      description: "Tier 2 upgrades" },
            { score: 450, name: "Grand Castle",   description: "Tier 3 majesty" },
            { score: 600, name: "Royal Fortress", description: "Tier 4 power" },
            { score: 800, name: "Legendary",      description: "Tier 5 glory" },
            { score: 1000, name: "Divine Citadel", description: "Maximum glory!" }
        ];
        
        // Flat array of just score thresholds for quick lookup
        public static const SCORE_MILESTONES:Array = [0, 10, 30, 60, 100, 150, 200, 300, 450, 600, 800, 1000];
        
        // ========== GROWTH ALGORITHM ==========
        // Score ranges and what to build
        public static const GROWTH_STAGES:Array = [
            // Stage 1: Foundation (score 0-10)
            { minScore: 0, maxScore: 10, 
              build: [
                  { type: "foundation", gridX: 2, gridY: 3, variant: "center" },
                  { type: "foundation", gridX: 3, gridY: 3, variant: "center" },
                  { type: "foundation", gridX: 4, gridY: 3, variant: "center" }
              ]
            },
            // Stage 2: Walls (score 11-30)
            { minScore: 11, maxScore: 30,
              build: [
                  { type: "wall", gridX: 1, gridY: 3, variant: "left" },
                  { type: "wall", gridX: 5, gridY: 3, variant: "right" },
                  { type: "wall", gridX: 2, gridY: 2, variant: "back" },
                  { type: "wall", gridX: 4, gridY: 2, variant: "back" }
              ]
            },
            // Stage 3: First Tower (score 31-60)
            { minScore: 31, maxScore: 60,
              build: [
                  { type: "tower", gridX: 1, gridY: 2, variant: "round" }
              ]
            },
            // Stage 4: Decorations + Second Tower (score 61-100)
            { minScore: 61, maxScore: 100,
              build: [
                  { type: "tower", gridX: 5, gridY: 2, variant: "round" },
                  { type: "decoration", gridX: 3, gridY: 2, variant: "flag" },
                  { type: "decoration", gridX: 2, gridY: 4, variant: "garden" }
              ]
            },
            // Stage 5: Upgrade to Tier 2 (score 101-150)
            { minScore: 101, maxScore: 150,
              upgrade: true, targetTier: 2, build: []
            },
            // Stage 6: Add Keep (score 151-200)
            { minScore: 151, maxScore: 200,
              build: [
                  { type: "keep", gridX: 3, gridY: 1, variant: "main" }
              ]
            },
            // Stage 7: Special structures (score 201+)
            { minScore: 201, maxScore: 300,
              build: [
                  { type: "special", gridX: 0, gridY: 3, variant: "moat" },
                  { type: "special", gridX: 6, gridY: 3, variant: "moat" },
                  { type: "decoration", gridX: 3, gridY: 4, variant: "drawbridge" }
              ]
            },
            // Stage 8: Tier 3 upgrades (score 301-450)
            { minScore: 301, maxScore: 450,
              upgrade: true, targetTier: 3, build: []
            },
            // Stage 9: More decorations (score 451-600)
            { minScore: 451, maxScore: 600,
              build: [
                  { type: "decoration", gridX: 1, gridY: 4, variant: "banner_left" },
                  { type: "decoration", gridX: 5, gridY: 4, variant: "banner_right" },
                  { type: "decoration", gridX: 1, gridY: 1, variant: "turret" },
                  { type: "decoration", gridX: 5, gridY: 1, variant: "turret" }
              ]
            },
            // Stage 10: Tier 4 upgrades (score 601-800)
            { minScore: 601, maxScore: 800,
              upgrade: true, targetTier: 4, build: []
            },
            // Stage 11: Final decorations (score 801-1000)
            { minScore: 801, maxScore: 1000,
              build: [
                  { type: "special", gridX: 3, gridY: 0, variant: "spire" },
                  { type: "decoration", gridX: 2, gridY: 1, variant: "window" },
                  { type: "decoration", gridX: 4, gridY: 1, variant: "window" }
              ]
            },
            // Stage 12: Tier 5 - Max glory (score 1001+)
            { minScore: 1001, maxScore: 999999,
              upgrade: true, targetTier: 5, build: []
            }
        ];
        
        // ========== PART TAXONOMY ==========
        
        // Foundation variants
        public static const FOUNDATION_VARIANTS:Array = [
            "center", "left", "right", "corner_left", "corner_right"
        ];
        
        // Wall variants
        public static const WALL_VARIANTS:Array = [
            "left", "right", "back", "front", "gate"
        ];
        
        // Tower variants
        public static const TOWER_VARIANTS:Array = [
            "round", "square", "pointed", "wide"
        ];
        
        // Decoration variants
        public static const DECORATION_VARIANTS:Array = [
            "flag", "banner_left", "banner_right", "garden", "fountain",
            "statue", "window", "turret", "drawbridge", "torch"
        ];
        
        // Keep variants
        public static const KEEP_VARIANTS:Array = [
            "main", "tall", "wide"
        ];
        
        // Special structure variants
        public static const SPECIAL_VARIANTS:Array = [
            "moat", "spire", "gate_grand", "throne_room"
        ];
        
        // ========== HEALTH & DAMAGE ==========
        public static const MAX_HEALTH:int = 100;
        public static const DAMAGE_THRESHOLD_LIGHT:int = 75;  // Cosmetic damage
        public static const DAMAGE_THRESHOLD_MEDIUM:int = 50; // Visible damage
        public static const DAMAGE_THRESHOLD_SEVERE:int = 25; // Critical damage
        
        // Damage amounts
        public static const DAMAGE_MINOR:int = 10;
        public static const DAMAGE_NORMAL:int = 25;
        public static const DAMAGE_HEAVY:int = 50;
        
        // Repair amounts
        public static const REPAIR_SMALL:int = 15;
        public static const REPAIR_MEDIUM:int = 30;
        public static const REPAIR_FULL:int = 100;
        
        // ========== SCORING ==========
        // Points per correct trial (base)
        public static const POINTS_PER_TRIAL:int = 2;
        
        // Streak bonuses
        public static const STREAK_BONUS_3:int = 5;   // 3 in a row
        public static const STREAK_BONUS_5:int = 10;  // 5 in a row
        public static const STREAK_BONUS_10:int = 25; // 10 in a row
        
        // Difficulty multipliers
        public static const DIFFICULTY_MULTIPLIERS:Array = [
            1.0,  // Level 1
            1.1,  // Level 2
            1.2,  // Level 3
            1.3,  // Level 4
            1.5,  // Level 5
            1.7,  // Level 6
            2.0,  // Level 7
            2.3,  // Level 8
            2.6,  // Level 9
            3.0,  // Level 10
            3.5,  // Level 11
            4.0,  // Level 12
            4.5,  // Level 13
            5.0,  // Level 14
            6.0   // Level 15
        ];
        
        /**
         * Get milestone for given score
         */
        public static function getMilestoneForScore(score:int):Object {
            var milestone:Object = MILESTONES[0];
            for each (var m:Object in MILESTONES) {
                if (score >= m.score) {
                    milestone = m;
                }
            }
            return milestone;
        }
        
        /**
         * Get next milestone after given score
         */
        public static function getNextMilestone(score:int):Object {
            for each (var m:Object in MILESTONES) {
                if (m.score > score) {
                    return m;
                }
            }
            return MILESTONES[MILESTONES.length - 1];
        }
        
        /**
         * Get growth stage for score
         */
        public static function getGrowthStage(score:int):Object {
            for each (var stage:Object in GROWTH_STAGES) {
                if (score >= stage.minScore && score <= stage.maxScore) {
                    return stage;
                }
            }
            return GROWTH_STAGES[GROWTH_STAGES.length - 1];
        }
        
        /**
         * Calculate points earned for a trial
         */
        public static function calculateTrialPoints(isCorrect:Boolean, streak:int, difficulty:int):int {
            if (!isCorrect) return 0;
            
            var base:int = POINTS_PER_TRIAL;
            
            // Add streak bonus
            if (streak >= 10) base += STREAK_BONUS_10;
            else if (streak >= 5) base += STREAK_BONUS_5;
            else if (streak >= 3) base += STREAK_BONUS_3;
            
            // Apply difficulty multiplier
            var multiplierIndex:int = Math.min(difficulty - 1, DIFFICULTY_MULTIPLIERS.length - 1);
            var multiplier:Number = DIFFICULTY_MULTIPLIERS[Math.max(0, multiplierIndex)];
            
            return Math.round(base * multiplier);
        }
        
        /**
         * Get completion percentage for score
         */
        public static function getCompletionPercent(score:int):Number {
            var maxScore:int = MILESTONES[MILESTONES.length - 1].score;
            return Math.min(100, (score / maxScore) * 100);
        }
    }
}
