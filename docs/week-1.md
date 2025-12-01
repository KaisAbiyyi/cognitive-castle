# Week 1 – MEGA Foundation Sprint 🚀

Branch: `feature/core-gameplay-loop/week-1`

## 🎯 Scope Overview

Week 1 mencakup **SELURUH foundation game**:

- ✅ Complete Core Gameplay Loop (Stimulus → Input → Validate → Result)
- ✅ Full Castle Procedural Generation System
- ✅ Adaptive Progression Algorithm (1-Up/2-Down)
- ✅ Complete Save/Load System dengan Encryption
- ✅ Multiple Game Modes (Forward, Reverse, Sort)
- ✅ Full HUD System dengan Animations
- ✅ Cross-Platform Input (Touch + Mouse + Keyboard)

**Target**: Game yang FULLY PLAYABLE dengan castle system complete!

---

## 📦 PHASE 1: Core Infrastructure & Game Loop ━ **KAIS** (Day 1-3)

**Owner: Kais** handles ALL core architecture, FSM, input, and game logic.

### 1.1 Project Architecture

- [x] **T1-001**: Setup complete folder structure:
  ```
  src/
    core/          # Base classes, interfaces, events
    domain/        # Game entities (StimulusItem, CastlePart, etc.)
    game/          # Game logic controllers
    castle/        # Castle system
    ui/            # All UI components
    services/      # Save, Sound, Analytics
    utils/         # Helper classes
    config/        # Configuration files
  ```
- [x] **T1-002**: Create `IGameState` interface untuk FSM pattern
- [x] **T1-003**: Implement `GameEvent.as` custom event system
- [x] **T1-004**: Setup `Constants.as` dengan semua game constants
- [x] **T1-005**: Implement `EventBus.as` singleton
- [x] **T1-006**: Create `ServiceLocator.as` untuk dependency management
- [x] **T1-007**: Implement `ObjectPool.as` generic class
- [x] **T1-008**: Create `TweenManager.as` wrapper

### 1.2 Sequence Generation Engine

- [x] **T1-009**: Design comprehensive `StimulusItem` data model:
  ```actionscript
  class StimulusItem {
    id: int,
    type: String,      // "shape", "color", "number"
    shape: String,     // "circle", "square", "triangle", "star", "hexagon", "diamond"
    color: uint,
    value: int,        // For sorting
    displayLabel: String
  }
  ```
- [x] **T1-010**: Implement `SequenceGenerator` dengan algorithms:
  - Random with constraints (no triple repeat)
  - Pattern-based generation
  - Difficulty-scaled (length + complexity)
- [x] **T1-011**: Add sequence difficulty tiers (1-15)
- [x] **T1-012**: Implement sequence validation rules
- [x] **T1-013**: Create `SequenceConfig.as` _(already exists)_

### 1.3 Cross-Platform Input System

- [x] **T1-014**: Design unified `InputAction` model:
  ```actionscript
  class InputAction {
    type: String,       // "tap", "click", "key"
    targetId: int,
    timestamp: Number,
    position: Point,
    inputMethod: String // "mouse", "touch", "keyboard"
  }
  ```
- [x] **T1-015**: Implement `InputManager`:
  - Mouse click (Desktop)
  - Touch tap (Mobile)
  - Keyboard shortcuts (1-9)
- [x] **T1-016**: Create visual input grid (2x3, 3x3, 4x3)
- [x] **T1-017**: Add input buffer with real-time display
- [x] **T1-018**: Implement input timeout dengan countdown
- [x] **T1-019**: Add "undo last input" (backspace)

### 1.4 Validation Engine

- [x] **T1-020**: Implement `Validator` dengan modes:
  - Forward Recall (exact order)
  - Reverse Recall (reversed)
  - Sorted Recall (by value)
- [x] **T1-021**: Create `ValidationResult`:
  ```actionscript
  class ValidationResult {
    isCorrect: Boolean,
    accuracy: Number,
    correctCount: int,
    errorCount: int,
    errorPositions: Array,
    reactionTime: Number,
    bonusEarned: int
  }
  ```
- [x] **T1-022**: Implement partial credit scoring
- [x] **T1-023**: Add error analysis feedback

### 1.5 Game State Machine

- [x] **T1-024**: Implement FSM dengan states:
  - `MENU`, `READY`, `STIMULUS`, `DELAY`
  - `INPUT`, `VALIDATING`, `RESULT`
  - `CASTLE_UPDATE`, `TRANSITION`
  - `PAUSED`, `SESSION_END`
- [x] **T1-025**: Implement state transition animations
- [x] **T1-026**: Add state persistence

### 1.6 Adaptive Progression

- [x] **T1-027**: Define 15 difficulty levels:
  ```actionscript
  class DifficultyLevel {
    level: int,              // 1-15
    sequenceLength: int,     // 3-12
    displayDuration: int,    // ms
    inputTimeout: int,
    requiresManipulation: Boolean,
    bonusMultiplier: Number
  }
  ```
- [x] **T1-028**: Implement `ProgressionController`:
  - Rolling accuracy tracking (last 5 trials)
  - 1-Up/2-Down algorithm
  - Level change events
- [x] **T1-029**: Add streak system (3/5/10 bonuses)
- [x] **T1-030**: Implement difficulty bounds

### 1.7 Save/Load System

- [x] **T1-031**: Define save schema:
  ```actionscript
  class SaveData {
    version: String,
    userId: String,
    currentDifficulty: int,
    gameMetrics: GameMetrics,
    castleState: CastleState,
    settings: Object,
    checksum: String
  }
  ```
- [x] **T1-032**: Implement `SaveSystem`:
  - `saveState()`, `loadState()`
  - `hasExistingSave()`, `deleteSave()`
  - Auto-save every N trials
- [x] **T1-033**: Add checksum validation (anti-tamper)
- [x] **T1-034**: Implement backup system (last 3 saves)

### 1.8 Integration

- [x] **T1-035**: Wire all systems in `Main.as`
- [x] **T1-036**: Proper initialization sequence
- [ ] **T1-037**: Debug panel (force states, set difficulty)
- [x] **T1-038**: Comprehensive logging system

---

## 🏰 PHASE 2: Castle System & UI/UX ━ **NAZAR** (Day 3-7)

**Owner: Nazar** handles ALL castle logic, UI components, and visual design.

### 2.1 Castle Data Model

- [x] **T1-039**: Implement `CastlePart` model:
  ```actionscript
  class CastlePart {
    id: String,
    type: String,        // "foundation", "wall", "tower", "decoration"
    tier: int,           // 1-5
    gridX: int,
    gridY: int,
    health: int,         // 0-100
    state: String,       // "building", "healthy", "damaged"
    zIndex: int
  }
  ```
- [x] **T1-040**: Create `CastleState` snapshot class
- [x] **T1-041**: Define castle component taxonomy:
  - Foundation: 3 tiers
  - Walls: 4 variants
  - Towers: 4 types
  - Decorations: 5+ types
  - Special structures

### 2.2 Castle Architect Core

- [x] **T1-042**: Implement `CastleArchitect`:
  ```actionscript
  class CastleArchitect {
    applyTrialResult(result): BuildEvent[]
    getCastleState(): CastleState
    addPart(type, tier, x, y): CastlePart
    upgradePart(partId): void
    damagePart(partId, amount): void
    repairPart(partId): void
    getTotalScore(): int
    getCompletionPercentage(): Number
    getNextMilestone(): String
  }
  ```
- [x] **T1-043**: Design castle growth algorithm:
  - Score 0-10: Foundation (3 parts)
  - Score 11-30: Walls (4 parts)
  - Score 31-60: First tower
  - Score 61-100: Decorations + second tower
  - Score 101-150: Upgrade all to tier 2
  - Score 151-200: Add keep
  - Score 201+: Special structures
- [x] **T1-044**: Implement grid-based placement
- [x] **T1-045**: Castle serialization/deserialization

### 2.3 Castle Mechanics

- [x] **T1-046**: Implement castle health system
- [x] **T1-047**: Create damage calculation logic
- [x] **T1-048**: Implement repair mechanics
- [x] **T1-049**: Add upgrade path logic

### 2.4 Game Metrics

- [x] **T1-050**: Track comprehensive metrics:
  ```actionscript
  class GameMetrics {
    totalTrials: int,
    correctTrials: int,
    averageAccuracy: Number,
    highestStreak: int,
    currentStreak: int,
    averageReactionTime: Number,
    bestReactionTime: Number,
    highestDifficulty: int,
    totalPlayTime: Number,
    sessionsPlayed: int,
    castleScore: int,
    partsBuilt: int,
    partsUpgraded: int
  }
  ```
- [x] **T1-051**: Debug metrics display
- [x] **T1-052**: Metrics persistence integration

### 2.5 Effects Logic

- [x] **T1-053**: Particle system data:
  - Confetti parameters
  - Sparkle parameters
  - Dust parameters
- [x] **T1-054**: Achievement notification logic
- [x] **T1-055**: Floating score popup logic

### 2.6 Error Handling & Testing

- [x] **T1-056**: Castle system error handling
- [x] **T1-057**: Performance profiling (60 FPS)
- [x] **T1-058**: Architecture documentation

---

## 🎨 PHASE 3: Visual Effects & Polish ━ **NAZAR** (Day 6-7)

**Owner: Nazar** continues with visual polish and effects.

### 3.1 Layout & Resolution

- [x] **T1-059**: Create `LayoutManager.as` multi-resolution support
- [x] **T1-060**: Design responsive grid system
- [x] **T1-061**: Safe zone handling (notch, etc.)

### 3.2 Stimulus Presentation

- [x] **T1-062**: Design visual vocabulary:
  - 6 shapes: Circle, Square, Triangle, Star, Hexagon, Diamond
  - 8 colors (color-blind safe)
  - Number mode: 1-9
  - Letter mode: A-F
- [x] **T1-063**: Implement `StimulusView`:
  - Smooth fade-in/fade-out
  - Scale animations
  - Glow effects
- [x] **T1-064**: Create `StimulusQueue` for sequential display
- [x] **T1-065**: Add progress indicator during stimulus
- [x] **T1-066**: Implement "focus mode" (dim background)

### 3.3 Input UI

- [x] **T1-067**: Button states: Normal, Hover, Pressed, Disabled, Correct, Wrong
- [x] **T1-068**: Visual indicators per game state
- [x] **T1-069**: Haptic feedback integration (mobile)
- [x] **T1-070**: Input feedback animations

### 3.4 Castle Visuals

- [ ] **T1-071**: Design modular castle components (vector graphics):
  - Foundation (3 tiers)
  - Walls (4 variants)
  - Towers (4 types)
  - Decorations (flags, banners, windows)
  - Special (moat, drawbridge)
- [ ] **T1-072**: Create `CastleRenderer`:
  - Isometric view option
  - Day/night lighting effects
- [ ] **T1-073**: Construction animations:
  - Parts build from ground
  - Dust particles
  - Completion glow
- [ ] **T1-074**: Damage effects (cracks, smoke)
- [ ] **T1-075**: Repair animations (sparkles)

### 3.5 HUD Components

- [x] **T1-076**: Complete HUD:
  - Score (animated counter)
  - Level indicator
  - Streak counter (fire effect)
  - Timer bar
  - Castle progress bar
  - Mini castle preview
- [x] **T1-077**: State indicator panel (Ready/Watch/Answer/Result)

### 3.6 Menu System

- [ ] **T1-078**: Main Menu:
  - Play / Continue
  - Settings, Statistics, Credits
- [ ] **T1-079**: Pause Menu
- [ ] **T1-080**: Settings Panel:
  - Volume sliders
  - Haptic toggle
  - Color blind mode

### 3.7 Result Screens

- [ ] **T1-081**: Trial Result popup:
  - ✓/✗ indicator
  - Score animation
  - Accuracy, time
  - Castle piece earned
- [ ] **T1-082**: Session Summary:
  - Total trials, accuracy
  - Castle progress
  - Play again / Menu

### 3.8 Visual Effects

- [x] **T1-083**: Screen transitions (fade, slide, zoom)
- [x] **T1-084**: Particle rendering:
  - Confetti (correct)
  - Sparkles (streak)
  - Dust (construction)
- [x] **T1-085**: Screen shake (wrong answer)

### 3.9 Auto Layout System (ADDED)

- [x] **T1-089a**: Create `AutoLayout.as` centralized resize management
- [x] **T1-089b**: BlockCastle resize() - proportional block repositioning
- [x] **T1-089c**: TrialPopup resize() - repositioning all popup elements
- [x] **T1-089d**: GameScreen onResize() - responsive UI elements
- [x] **T1-089e**: Main.as onStageResize() handler integration

### 3.10 Polish & Testing

- [ ] **T1-086**: Windows Desktop visual testing
- [ ] **T1-087**: Android Phone visual testing
- [ ] **T1-088**: Android Tablet visual testing
- [ ] **T1-089**: Asset style guide documentation

---

## 📋 Week 1 Deliverables

| Feature                     | Owner | Target |
| --------------------------- | ----- | ------ |
| Full gameplay loop          | Kais  | ✅     |
| FSM with 10+ states         | Kais  | ✅     |
| Save/Load + encryption      | Kais  | ✅     |
| 3 game modes                | Kais  | ✅     |
| 15 difficulty levels        | Kais  | ✅     |
| Adaptive progression        | Kais  | ✅     |
| Castle data model           | Nazar | ✅     |
| Castle growth algorithm     | Nazar | ✅     |
| Complete metrics system     | Nazar | ✅     |
| Castle 5+ part types        | Nazar | ✅     |
| 6 shapes + 8 colors         | Nazar | ✅     |
| Castle visuals & animations | Nazar | ✅     |
| Full HUD system             | Nazar | ✅     |
| All menus & screens         | Nazar | ✅     |
| Particle effects            | Nazar | ✅     |
| Multi-platform support      | All   | ✅     |
| 60 FPS performance          | All   | ✅     |

---

## 📊 Success Criteria

- **Playable**: Complete flow without crashes
- **Performance**: 60 FPS stable
- **Save System**: Data persists correctly
- **Castle**: 10+ visual states
- **Modes**: All 3 modes functional
- **UI**: Professional look & feel
