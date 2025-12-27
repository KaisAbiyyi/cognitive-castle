package tests {
    
    import castle.CastleState;
    import castle.AdditionTower;
    import game.ProgressionManager;
    import game.ProgressionResult;
    import generation.QuestionGenerator;
    import generation.NumberQuestion;
    
    /**
     * AcceptanceTests - Validates the reconstructed gameplay system.
     * 
     * Run these tests to verify:
     * - Test A: 12 consecutive wins produce 4 towers with correct placement
     * - Test B: Losing damages newest tower first
     * - Test C: Horde targets newest tower
     * - Test D: Story checkpoint fallback works correctly
     * 
     * Usage:
     *   var tests:AcceptanceTests = new AcceptanceTests();
     *   tests.runAll();
     */
    public class AcceptanceTests {
        
        private var _results:Array;
        private var _passed:int;
        private var _failed:int;
        
        public function AcceptanceTests() {
            _results = [];
            _passed = 0;
            _failed = 0;
        }
        
        /**
         * Run all acceptance tests
         */
        public function runAll():String {
            _results = [];
            _passed = 0;
            _failed = 0;
            
            trace("========== ACCEPTANCE TESTS ==========");
            
            testA_TwelveWins();
            testB_LoseDamagesNewest();
            testC_HordeTargetsNewest();
            testD_StoryCheckpointFallback();
            testE_StoryQuestionMapping();
            testF_RandomQuestionDistribution();
            testG_TowerPlacementRules();
            
            trace("========================================");
            trace("PASSED: " + _passed + " / " + (_passed + _failed));
            trace("FAILED: " + _failed);
            trace("========================================");
            
            return getSummary();
        }
        
        // ========== TEST A: 12 Consecutive Wins ==========
        
        private function testA_TwelveWins():void {
            trace("\n--- Test A: 12 Consecutive Wins ---");
            
            var pm:ProgressionManager = new ProgressionManager();
            pm.reset();
            
            var state:CastleState = pm.state;
            var initialMainSize:int = state.mainCastleSizeLevel;
            
            // Win 12 times consecutively
            for (var i:int = 0; i < 12; i++) {
                var result:ProgressionResult = pm.processCorrect();
                trace("Win " + (i + 1) + ": winStreak=" + state.winStreak + 
                      ", towers=" + state.towerCount +
                      ", mainSize=" + state.mainCastleSizeLevel);
            }
            
            // Verify results
            assertEqual("A1: 12 wins should produce winStreak=12", 12, state.winStreak);
            assertEqual("A2: 12 wins should produce 4 towers (at 3,6,9,12)", 4, state.towerCount);
            assertEqual("A3: Main castle should have grown", true, state.mainCastleSizeLevel > initialMainSize);
            
            // Verify tower 2 is opposite of tower 1
            if (state.towerCount >= 2) {
                var at1:AdditionTower = state.towerCastle[0];
                var at2:AdditionTower = state.towerCastle[1];
                assertEqual("A4: Tower 2 side should be opposite of tower 1", true, at1.side != at2.side);
            }
            
            // Verify tower order in creation array
            for (var j:int = 0; j < state.towerCount; j++) {
                var tower:AdditionTower = state.towerCastle[j];
                assertEqual("A5: Tower " + (j+1) + " should have createdAtIndex=" + (j+1), 
                           j + 1, tower.createdAtIndex);
            }
            
            // Verify leftTowers and rightTowers are populated correctly
            var totalInSideLists:int = state.leftTowers.length + state.rightTowers.length;
            assertEqual("A6: All towers should be in side lists", state.towerCount, totalInSideLists);
        }
        
        // ========== TEST B: Lose Damages Newest Tower ==========
        
        private function testB_LoseDamagesNewest():void {
            trace("\n--- Test B: Lose Damages Newest Tower ---");
            
            var pm:ProgressionManager = new ProgressionManager();
            pm.reset();
            
            // Build up 4 towers (12 wins)
            for (var i:int = 0; i < 12; i++) {
                pm.processCorrect();
            }
            
            var state:CastleState = pm.state;
            assertEqual("B0: Should have 4 towers", 4, state.towerCount);
            
            var at4:AdditionTower = state.towerCastle[3]; // Newest tower
            var at4Id:String = at4.id;
            var at4InitialSize:int = at4.sizeStage;
            
            trace("Before lose: newest tower sizeStage=" + at4InitialSize);
            
            // Lose once - should damage newest only
            var result:ProgressionResult = pm.processWrong();
            
            assertEqual("B1: After 1 loss, newest tower should be damaged", 
                       at4InitialSize - 1, state.getTowerById(at4Id).sizeStage);
            assertEqual("B2: Result should indicate tower shrink", 
                       ProgressionResult.SHRINK_TOWER, result.upgradeType);
            assertEqual("B3: Damaged tower should be newest", at4Id, result.damagedTowerId);
            
            // Previous tower should be unchanged
            var at3:AdditionTower = state.towerCastle[2];
            assertEqual("B4: Previous tower should still be full", AdditionTower.SIZE_FULL, at3.sizeStage);
            
            // Lose 2 more times - newest should be destroyed
            pm.processWrong(); // sizeStage: 2 -> 1
            var result3:ProgressionResult = pm.processWrong(); // sizeStage: 1 -> 0 (destroyed)
            
            assertEqual("B5: After 3 losses, newest tower should be removed", 3, state.towerCount);
            assertEqual("B6: Result should indicate tower removal", 
                       ProgressionResult.REMOVE_TOWER, result3.upgradeType);
            
            trace("After 3 losses: towers=" + state.towerCount);
        }
        
        // ========== TEST C: Horde Targets Newest Tower ==========
        
        private function testC_HordeTargetsNewest():void {
            trace("\n--- Test C: Horde Targets Newest Tower ---");
            
            var pm:ProgressionManager = new ProgressionManager();
            pm.reset();
            
            // Build up 4 towers
            for (var i:int = 0; i < 12; i++) {
                pm.processCorrect();
            }
            
            var state:CastleState = pm.state;
            var at4:AdditionTower = state.getNewestTower();
            var at4Id:String = at4.id;
            
            trace("Newest tower before horde: " + at4Id);
            
            // Simulate horde damage
            var result:ProgressionResult = pm.applyHordeDamage();
            
            assertEqual("C1: Horde should damage newest tower", at4Id, result.damagedTowerId);
            assertEqual("C2: isHordeDamage flag should be true", true, result.isHordeDamage);
            
            // Destroy newest with horde
            pm.applyHordeDamage(); // 2
            var result3:ProgressionResult = pm.applyHordeDamage(); // 3 - destroyed
            
            assertEqual("C3: After 3 horde hits, newest removed", 3, state.towerCount);
            
            // Next horde hit should target the new newest
            var at3:AdditionTower = state.getNewestTower();
            var result4:ProgressionResult = pm.applyHordeDamage();
            
            assertEqual("C4: Next horde should target newest", at3.id, result4.damagedTowerId);
            
            trace("After horde attacks: towers=" + state.towerCount);
        }
        
        // ========== TEST D: Story Checkpoint Fallback ==========
        
        private function testD_StoryCheckpointFallback():void {
            trace("\n--- Test D: Story Checkpoint Fallback ---");
            
            var pm:ProgressionManager = new ProgressionManager();
            
            // Test various story index fallbacks
            var testCases:Array = [
                { storyIndex: 3, expectedFallback: 1 },  // Block 2 -> Block 0 (clamped to 1)
                { storyIndex: 4, expectedFallback: 1 },  // Block 2 -> Block 0 (clamped to 1)
                { storyIndex: 5, expectedFallback: 3 },  // Block 3 -> Block 1
                { storyIndex: 6, expectedFallback: 3 },  // Block 3 -> Block 1
                { storyIndex: 11, expectedFallback: 9 }, // Block 6 -> Block 4
                { storyIndex: 12, expectedFallback: 9 }  // Block 6 -> Block 4
            ];
            
            for each (var tc:Object in testCases) {
                pm.reset();
                
                // Advance to target story index
                pm.state.storyIndex = tc.storyIndex;
                
                // Lose once
                pm.processWrong();
                
                assertEqual("D: storyIndex " + tc.storyIndex + " fallback to " + tc.expectedFallback,
                           tc.expectedFallback, pm.state.storyIndex);
            }
        }
        
        // ========== TEST E: Story Question Mapping ==========
        
        private function testE_StoryQuestionMapping():void {
            trace("\n--- Test E: Story Question Mapping ---");
            
            var qg:QuestionGenerator = QuestionGenerator.getInstance();
            qg.reset();
            
            var expectedMappings:Array = [
                { index: 1, combo: 4, level: NumberQuestion.LEVEL_EASY },
                { index: 2, combo: 4, level: NumberQuestion.LEVEL_EASY },
                { index: 3, combo: 6, level: NumberQuestion.LEVEL_EASY },
                { index: 4, combo: 6, level: NumberQuestion.LEVEL_EASY },
                { index: 5, combo: 4, level: NumberQuestion.LEVEL_MEDIUM },
                { index: 6, combo: 4, level: NumberQuestion.LEVEL_MEDIUM },
                { index: 7, combo: 6, level: NumberQuestion.LEVEL_MEDIUM },
                { index: 8, combo: 6, level: NumberQuestion.LEVEL_MEDIUM },
                { index: 9, combo: 4, level: NumberQuestion.LEVEL_HARD },
                { index: 10, combo: 4, level: NumberQuestion.LEVEL_HARD },
                { index: 11, combo: 6, level: NumberQuestion.LEVEL_HARD },
                { index: 12, combo: 6, level: NumberQuestion.LEVEL_HARD }
            ];
            
            for each (var m:Object in expectedMappings) {
                var q:NumberQuestion = qg.getStoryQuestion(m.index);
                assertEqual("E" + m.index + "a: storyIndex " + m.index + " combo", m.combo, q.combination);
                assertEqual("E" + m.index + "b: storyIndex " + m.index + " level", m.level, q.level);
            }
        }
        
        // ========== TEST F: Random Question Constraints ==========
        
        private function testF_RandomQuestionDistribution():void {
            trace("\n--- Test F: Random Question Distribution ---");
            
            var qg:QuestionGenerator = QuestionGenerator.getInstance();
            qg.reset();
            
            var consecutiveSwitch:int = 0;
            var consecutiveSix:int = 0;
            
            for (var i:int = 0; i < 120; i++) {
                var q:NumberQuestion = qg.getRandomQuestion(3);
                
                // Validate combination and level are within expected set
                var validCombo:Boolean = (q.combination == 4 || q.combination == 6);
                var validLevel:Boolean = (q.level == NumberQuestion.LEVEL_EASY ||
                                          q.level == NumberQuestion.LEVEL_MEDIUM ||
                                          q.level == NumberQuestion.LEVEL_HARD);
                assertEqual("F1." + i + ": combo should be 4 or 6", true, validCombo);
                assertEqual("F2." + i + ": level should be easy/medium/hard", true, validLevel);
                
                // Track consecutive constraints
                if (q.level == NumberQuestion.LEVEL_HARD) {
                    consecutiveSwitch++;
                } else {
                    consecutiveSwitch = 0;
                }
                
                if (q.combination == 6) {
                    consecutiveSix++;
                } else {
                    consecutiveSix = 0;
                }
                
                assertEqual("F3." + i + ": no 3 switch in a row", true, consecutiveSwitch <= 2);
                assertEqual("F4." + i + ": no 4 size-6 in a row", true, consecutiveSix <= 3);
            }
        }
        
        // ========== TEST G: Tower Placement Rules ==========
        
        private function testG_TowerPlacementRules():void {
            trace("\n--- Test G: Tower Placement Rules ---");
            
            var state:CastleState = new CastleState();
            
            // Add first tower (should be random side)
            var at1:AdditionTower = state.addTower();
            var expectedAt1Id:String = (at1.side == CastleState.SIDE_LEFT) ? "L1" : "R1";
            assertEqual("G1: Tower 1 should have correct side ID", expectedAt1Id, at1.id);
            assertEqual("G2: Tower 1 should have sizeStage FULL", AdditionTower.SIZE_FULL, at1.sizeStage);
            
            var at1Side:String = at1.side;
            trace("Tower 1 placed on: " + at1Side);
            
            // Add second tower (fills the other main-castle slot)
            var at2:AdditionTower = state.addTower();
            var expectedAt2Side:String = (at1Side == CastleState.SIDE_LEFT) ? CastleState.SIDE_RIGHT : CastleState.SIDE_LEFT;
            assertEqual("G3: Tower 2 must be opposite of tower 1", expectedAt2Side, at2.side);
            var expectedAt2Id:String = (expectedAt2Side == CastleState.SIDE_LEFT) ? "L1" : "R1";
            assertEqual("G3b: Tower 2 should have correct side ID", expectedAt2Id, at2.id);
            
            // Verify side lists
            if (at1Side == CastleState.SIDE_LEFT) {
                assertEqual("G4a: leftTowers should contain L1", true, state.leftTowers.indexOf("L1") >= 0);
                assertEqual("G4b: rightTowers should contain R1", true, state.rightTowers.indexOf("R1") >= 0);
            } else {
                assertEqual("G4a: rightTowers should contain R1", true, state.rightTowers.indexOf("R1") >= 0);
                assertEqual("G4b: leftTowers should contain L1", true, state.leftTowers.indexOf("L1") >= 0);
            }
            
            // Add more towers and verify they're always added as outermost (last in side array)
            var at3:AdditionTower = state.addTower();
            var at3Side:String = at3.side;
            var at3SideList:Vector.<String> = (at3Side == CastleState.SIDE_LEFT) ? state.leftTowers : state.rightTowers;
            var expectedAt3Id:String = (at3Side == CastleState.SIDE_LEFT) ? "L2" : "R2";
            assertEqual("G5: Tower 3 should be last in its side list (outermost)", 
                       expectedAt3Id, at3SideList[at3SideList.length - 1]);
            
            trace("Final state: " + state.toString());
        }
        
        // ========== HELPER METHODS ==========
        
        private function assertEqual(testName:String, expected:*, actual:*):void {
            if (expected == actual) {
                _passed++;
                trace("  ✓ " + testName);
            } else {
                _failed++;
                trace("  ✗ " + testName + " - Expected: " + expected + ", Actual: " + actual);
            }
            
            _results.push({
                name: testName,
                passed: (expected == actual),
                expected: expected,
                actual: actual
            });
        }
        
        public function getSummary():String {
            var summary:String = "Acceptance Tests: " + _passed + "/" + (_passed + _failed) + " passed\n";
            
            if (_failed > 0) {
                summary += "\nFailed tests:\n";
                for each (var r:Object in _results) {
                    if (!r.passed) {
                        summary += "  - " + r.name + "\n";
                    }
                }
            }
            
            return summary;
        }
    }
}
