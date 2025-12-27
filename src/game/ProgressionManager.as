package game {
    
    import generation.NumberQuestion;
    import generation.QuestionGenerator;
    import castle.CastleState;
    import castle.AdditionTower;
    
    /**
     * ProgressionManager - Core game logic for win/lose handling
     * 
     * STORY MODE (12 questions):
     * - Soal 1-2:   4 digit, urut sesuai (forward)
     * - Soal 3-4:   6 digit, urut sesuai (forward)
     * - Soal 5-6:   4 digit, urut reverse
     * - Soal 7-8:   6 digit, urut reverse
     * - Soal 9-10:  4 digit, switch ganjil/genap
     * - Soal 11-12: 6 digit, switch ganjil/genap
     * 
     * RANDOM MODE (after question 12):
     * - Random size: 4 or 6
     * - Random type: forward / reverse / switch
     * - Constraints applied in QuestionGenerator (no 3 switch in a row, no 4 size-6 in a row)
     * 
     * WIN LOGIC:
     * 1. winStreak++
     * 2. mainCastle grows
     * 3. Heal most recent damaged tower (optional)
     * 4. Every 3 wins: add new tower
     * 5. Advance story/random progress
     * 
     * LOSE LOGIC:
     * 1. winStreak = 0
     * 2. Damage newest tower (sizeStage--)
     * 3. If sizeStage == 0: remove tower
     * 4. If no towers: shrink mainCastle
     * 5. Story checkpoint fallback (go back 2 blocks)
     */
    public class ProgressionManager {
        
        // Singleton
        private static var _instance:ProgressionManager;
        
        // References
        private var _state:CastleState;
        private var _questionGenerator:QuestionGenerator;
        
        // Current question
        private var _currentQuestion:NumberQuestion;
        
        /**
         * Get singleton instance
         */
        public static function getInstance():ProgressionManager {
            if (!_instance) {
                _instance = new ProgressionManager();
            }
            return _instance;
        }
        
        public function ProgressionManager() {
            _questionGenerator = QuestionGenerator.getInstance();
            _state = new CastleState();
        }
        
        /**
         * Initialize with existing state (for load game)
         */
        public function initializeWithState(state:CastleState):void {
            _state = state;
        }
        
        /**
         * Get current game state
         */
        public function get state():CastleState {
            return _state;
        }
        
        /**
         * Reset to fresh game state
         */
        public function reset():void {
            _state.reset();
            _questionGenerator.reset();
            _currentQuestion = null;
        }
        
        // ========== QUESTION MANAGEMENT ==========
        
        /**
         * Get next question based on current mode and progress
         */
        public function getNextQuestion():NumberQuestion {
            _state.recordPlayerAction();
            
            if (_state.mode == CastleState.MODE_STORY) {
                _currentQuestion = _questionGenerator.getStoryQuestion(_state.storyIndex);
            } else {
                _currentQuestion = _questionGenerator.getRandomQuestion(_state.difficultyRank, _state.lastAnswerWasWrong);
            }
            
            return _currentQuestion;
        }
        
        /**
         * Get current question (without generating new)
         */
        public function getCurrentQuestion():NumberQuestion {
            return _currentQuestion;
        }
        
        /**
         * Reroll current question (same mode, new sequence)
         */
        public function rerollCurrentQuestion():void {
            if (!_currentQuestion) return;
            
            if (_state.mode == CastleState.MODE_STORY) {
                _currentQuestion = _questionGenerator.getStoryQuestion(_state.storyIndex);
            } else {
                _currentQuestion = _questionGenerator.getRandomQuestion(_state.difficultyRank, _state.lastAnswerWasWrong);
            }
        }
        
        // ========== WIN HANDLER ==========
        
        /**
         * Process correct answer - THE CORE WIN LOOP
         * 
         * TARGETING RULES:
         * - If towers exist (or a new tower spawns this win): mainCastle stays still and newest tower grows
         * - If no towers and no tower spawns: mainCastle grows
         * 
         * Order of effects:
         * 1. winStreak++
         * 2. If tower mode: mainCastle unchanged (heal newest if damaged)
         * 3. If winStreak % 3 == 0: add new tower
         * 4. Grow newest tower base scale
         * 5. Advance story/random progress
         * 
         * @return ProgressionResult with upgrade details
         */
        public function processCorrect():ProgressionResult {
            var result:ProgressionResult = new ProgressionResult();
            result.wasCorrect = true;
            
            _state.recordPlayerAction();
            _state.totalCorrect++;
            
            // Step 1: Increment win streak
            _state.winStreak++;
            _state.lastAnswerWasWrong = false;
            
            // If this win will spawn a new tower, we treat the win as "tower mode" (mainCastle stays still).
            // This prevents "empty" wins right after tower unlock and keeps UI + state consistent.
            var willAddTower:Boolean = (_state.winStreak % 3 == 0);
            
            // Step 2 & 3: Scale up based on tower existence (or imminent tower spawn)
            if (_state.hasTowers || willAddTower) {
                // TOWERS EXIST (or will exist after this win): mainCastle stays unchanged.
                
                // If we already have towers, heal newest if damaged first.
                if (_state.hasTowers) {
                    var healedTower:AdditionTower = _state.healNewestTower();
                    if (healedTower) {
                        trace("[ProgressionManager] WIN: Healed newest tower " + healedTower.id + " to stage " + healedTower.sizeStage);
                    }
                }
                
                trace("[ProgressionManager] WIN: MainCastle UNCHANGED (tower mode)");
            } else {
                // NO TOWERS: Scale up mainCastle
                _state.growMainCastle();
                result.mainCastleLevel = _state.mainCastleSizeLevel;
                
                // Also repair integrity if damaged
                if (_state.mainCastleIntegrityStage < 5) {
                    _state.repairMainCastle();
                    result.mainCastleIntegrity = _state.mainCastleIntegrityStage;
                    trace("[ProgressionManager] WIN: MainCastle grown + integrity repaired to " + _state.mainCastleIntegrityStage);
                } else {
                    trace("[ProgressionManager] WIN: MainCastle grown to level " + _state.mainCastleSizeLevel);
                }
            }
            
            // Step 4: Every 3 wins, add new tower
            result.newTower = null;
            if (willAddTower) {
                result.newTower = _state.addTower();
                result.upgradeType = ProgressionResult.UPGRADE_NEW_TOWER;
                result.towerBatch = result.newTower.createdAtIndex;
                result.towerSide = result.newTower.side.toLowerCase();
            } else {
                result.upgradeType = _state.hasTowers ? ProgressionResult.UPGRADE_TOWER : ProgressionResult.UPGRADE_MAIN_CASTLE;
            }
            
            // Tower mode: after any tower add, newest tower always grows (or pulses at max on the UI side).
            if (_state.hasTowers) {
                var grownTower:AdditionTower = _state.growNewestTower();
                if (grownTower) {
                    result.healedTowerId = grownTower.id; // UI target
                    trace("[ProgressionManager] WIN: Grew newest tower " + grownTower.id + " baseScale=" + grownTower.baseScale.toFixed(3) + "/" + grownTower.maxScale.toFixed(3));
                }
            }
            
            // Step 5: Advance story/random progress
            if (_state.mode == CastleState.MODE_STORY) {
                var storyCompleted:Boolean = _state.advanceStory();
                result.storyCompleted = storyCompleted;
                result.storyIndex = _state.storyIndex;
                
                if (storyCompleted) {
                    result.modeChanged = true;
                    result.newMode = CastleState.MODE_RANDOM;
                }
            } else {
                // Random mode: increase difficulty on 2+ win streak
                if (_state.winStreak >= 2 && _state.difficultyRank < 6) {
                    _state.difficultyRank++;
                }
                result.difficultyRank = _state.difficultyRank;
            }
            
            _state.lastUpdated = new Date().getTime();
            
            return result;
        }
        
        // ========== LOSE HANDLER ==========
        
        /**
         * Process wrong answer - THE CORE PUNISHMENT LOOP
         * 
         * Order of effects:
         * 1. winStreak = 0
         * 2. Damage newest tower (sizeStage--)
         *    - If sizeStage == 0: remove tower
         *    - If no towers: damage mainCastle integrity
         * 3. Check game over (mainCastle integrity == 0)
         * 4. Story: checkpoint fallback (go back 2 blocks)
         *    Random: decrease difficulty rank
         * 
         * @return ProgressionResult with damage details
         */
        public function processWrong():ProgressionResult {
            var result:ProgressionResult = new ProgressionResult();
            result.wasCorrect = false;
            
            _state.recordPlayerAction();
            _state.totalWrong++;
            
            // Step 1: Reset win streak
            _state.winStreak = 0;
            _state.lastAnswerWasWrong = true;
            
            // Step 2: Apply damage to newest tower OR main castle
            if (_state.hasTowers) {
                var newestTower:AdditionTower = _state.getNewestTower();
                result.damagedTowerId = newestTower.id;
                result.towerBatch = newestTower.createdAtIndex;
                result.towerSide = newestTower.side.toLowerCase();
                
                var wasDestroyed:Boolean = _state.damageNewestTower();
                
                if (wasDestroyed) {
                    result.upgradeType = ProgressionResult.REMOVE_TOWER;
                    result.shouldRemoveTower = true;
                    result.removedTowerId = newestTower.id;
                } else {
                    result.upgradeType = ProgressionResult.SHRINK_TOWER;
                    result.targetSizeStage = newestTower.sizeStage;
                }
            } else {
                // No towers - damage main castle integrity
                _state.damageMainCastle();
                result.upgradeType = ProgressionResult.SHRINK_MAIN_CASTLE;
                result.mainCastleIntegrity = _state.mainCastleIntegrityStage;
                result.isCastleCritical = _state.isMainCastleCritical;
                
                // Check game over
                if (_state.mainCastleIntegrityStage == 0) {
                    result.isGameOver = true;
                    _state.lastUpdated = new Date().getTime();
                    return result; // Stop here, don't advance questions
                }
            }
            
            // Step 3: Story/Random fallback logic
            if (_state.mode == CastleState.MODE_STORY) {
                // Checkpoint fallback: go back 2 blocks (4 questions)
                var fallbackIndex:int = _state.getStoryFallbackIndex();
                result.resetToQuestion = fallbackIndex;
                _state.storyIndex = fallbackIndex;
                result.storyIndex = _state.storyIndex;
            } else {
                // Random mode: decrease difficulty rank
                if (_state.difficultyRank > 1) {
                    _state.difficultyRank--;
                }
                result.difficultyRank = _state.difficultyRank;
            }
            
            // Reroll current question (same difficulty, new sequence)
            rerollCurrentQuestion();
            
            _state.lastUpdated = new Date().getTime();
            
            return result;
        }
        
        // ========== HORDE DAMAGE HANDLER ==========
        
        /**
         * Apply horde damage - uses SAME priority as puzzle lose
         * 
         * Target priority:
         * 1. Newest tower (towerCastle[last])
         * 2. Main castle integrity (if no towers)
         * 
         * @return ProgressionResult with damage details
         */
        public function applyHordeDamage():ProgressionResult {
            var result:ProgressionResult = new ProgressionResult();
            result.wasCorrect = false;
            result.isHordeDamage = true;
            
            // Same logic as processWrong for damage
            if (_state.hasTowers) {
                var newestTower:AdditionTower = _state.getNewestTower();
                result.damagedTowerId = newestTower.id;
                result.towerBatch = newestTower.createdAtIndex;
                result.towerSide = newestTower.side.toLowerCase();
                
                var wasDestroyed:Boolean = _state.damageNewestTower();
                
                if (wasDestroyed) {
                    result.upgradeType = ProgressionResult.REMOVE_TOWER;
                    result.shouldRemoveTower = true;
                    result.removedTowerId = newestTower.id;
                } else {
                    result.upgradeType = ProgressionResult.SHRINK_TOWER;
                    result.targetSizeStage = newestTower.sizeStage;
                }
            } else {
                // No towers - damage main castle integrity
                _state.damageMainCastle();
                result.upgradeType = ProgressionResult.SHRINK_MAIN_CASTLE;
                result.mainCastleIntegrity = _state.mainCastleIntegrityStage;
                result.isCastleCritical = _state.isMainCastleCritical;
                
                // Check game over
                if (_state.mainCastleIntegrityStage == 0) {
                    result.isGameOver = true;
                }
            }
            
            _state.lastUpdated = new Date().getTime();
            
            return result;
        }
        
        // ========== HORDE IDLE DETECTION ==========
        
        /**
         * Check if horde should spawn based on idle time
         * @param thresholdMs Idle threshold in milliseconds (120000-180000)
         * @return true if player has been idle longer than threshold
         */
        public function isPlayerIdle(thresholdMs:Number):Boolean {
            var now:Number = new Date().getTime();
            var idleTime:Number = now - _state.lastPlayerActionTime;
            return idleTime >= thresholdMs;
        }
        
        /**
         * Get time until horde spawns (for UI countdown)
         * @param thresholdMs Idle threshold in milliseconds
         * @return Remaining time in ms, or 0 if should spawn now
         */
        public function getTimeUntilHorde(thresholdMs:Number):Number {
            var now:Number = new Date().getTime();
            var idleTime:Number = now - _state.lastPlayerActionTime;
            return Math.max(0, thresholdMs - idleTime);
        }
        
        /**
         * Record player activity (resets idle timer)
         */
        public function recordActivity():void {
            _state.recordPlayerAction();
        }
        
        // ========== TOWER QUERY HELPERS ==========
        
        /**
         * Get newest tower (same as horde target)
         */
        public function getNewestTower():AdditionTower {
            return _state.getNewestTower();
        }
        
        /**
         * Get tower count
         */
        public function getTowerCount():int {
            return _state.towerCount;
        }
        
        /**
         * Check if tower exists by ID
         */
        public function hasTowerById(id:String):Boolean {
            return _state.getTowerById(id) != null;
        }
        
        /**
         * Get all towers for rendering
         * Returns in creation order (newest = last)
         */
        public function getAllTowers():Vector.<AdditionTower> {
            return _state.towerCastle;
        }
        
        /**
         * Get towers on left side (inner to outer)
         */
        public function getLeftTowerIds():Vector.<String> {
            return _state.leftTowers;
        }
        
        /**
         * Get towers on right side (inner to outer)
         */
        public function getRightTowerIds():Vector.<String> {
            return _state.rightTowers;
        }
        
        // ========== GETTERS ==========
        
        public function get currentQuestionNumber():int {
            return _state.storyIndex;
        }
        
        public function get mode():String {
            return _state.mode;
        }
        
        public function get storyIndex():int {
            return _state.storyIndex;
        }
        
        public function get difficultyRank():int {
            return _state.difficultyRank;
        }
        
        public function get winStreak():int {
            return _state.winStreak;
        }
        
        public function get totalCorrect():int {
            return _state.totalCorrect;
        }
        
        public function get totalWrong():int {
            return _state.totalWrong;
        }
        
        public function get mainCastleLevel():int {
            return _state.mainCastleSizeLevel;
        }
        
        public function get isStoryMode():Boolean {
            return _state.mode == CastleState.MODE_STORY;
        }
        
        public function get isRandomMode():Boolean {
            return _state.mode == CastleState.MODE_RANDOM;
        }
        
        public function get isGameOver():Boolean {
            return _state.isMainCastleCritical && !_state.hasTowers;
        }
    }
}
