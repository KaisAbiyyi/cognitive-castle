# Week 2 – Siege Mechanics & Audio Sprint 🔥

Branches:  
- `feature/siege-mechanic/week-2`  
- `feature/audio-system/week-2`

## 🎯 Scope Overview

Week 2 fokus pada **stress mechanics** dan **audio/polish**:
- ✅ Complete Siege/Entropy System (Random Timer + Attacks)
- ✅ Fortify & Repair Mini-Games
- ✅ Full Audio System (SFX + BGM)
- ✅ Advanced Visual Effects
- ✅ Achievement System
- ✅ Tutorial/Onboarding Flow
- ✅ Multiple Castle Themes

**Target**: Game dengan tension mechanics dan full audio experience!

---

## ⚔️ PHASE 1: Siege System & Mechanics ━ **KAIS** (Day 1-3)

**Owner: Kais** handles ALL siege logic, timers, and stress mechanics.

### 1.1 Entropy Timer System
- [ ] **T2-001**: Design timer configuration:
  ```actionscript
  class EntropyConfig {
    minInterval: int,       // 45 seconds
    maxInterval: int,       // 120 seconds
    warningThreshold: int,  // 10 seconds before
    gracePeriod: int,       // Early game protection
    difficultyScaling: Number  // Timer gets faster
  }
  ```
- [ ] **T2-002**: Implement `EntropyTimer` class:
  - `start()`, `pause()`, `resume()`, `reset()`
  - Random interval generation
  - Warning event emission
  - Attack event emission
- [ ] **T2-003**: Handle app lifecycle (pause when minimized)
- [ ] **T2-004**: Implement difficulty scaling (faster timers at higher levels)

### 1.2 Siege State Machine
- [ ] **T2-005**: Design siege flow:
  ```
  NORMAL → WARNING → CHOICE → MINI_TASK → RESOLUTION → COOLDOWN → NORMAL
  ```
- [ ] **T2-006**: Implement `SiegeController`:
  - State transitions
  - Choice handling (Fortify vs Repair)
  - Result processing
  - Cooldown management
- [ ] **T2-007**: Freeze main game during siege
- [ ] **T2-008**: Implement siege history tracking

### 1.3 Consequence System
- [ ] **T2-009**: Define penalty logic:
  ```actionscript
  class SiegePenalty {
    damageAmount: int,       // Per structure
    targetSelection: String, // "random", "newest", "weakest"
    cascadeEffect: Boolean,  // Affects neighbors
    recoveryTime: int        // Cooldown before next siege
  }
  ```
- [ ] **T2-010**: Integrate with `CastleArchitect`:
  - Remove/downgrade parts on failure
  - Reinforce/upgrade on success
- [ ] **T2-011**: Implement "last stand" mechanic (near-destruction warning)
- [ ] **T2-012**: Add siege statistics to metrics

### 1.4 Mini-Task: Fortify
- [ ] **T2-013**: Design Fortify challenge:
  - Longer sequence (current + 2)
  - Higher stakes bonus
  - Time pressure
- [ ] **T2-014**: Implement Fortify task:
  - Reuse sequence generation
  - Reuse validation
  - Custom difficulty modifier
- [ ] **T2-015**: Success: Prevent damage + bonus shield
- [ ] **T2-016**: Failure: Double damage

### 1.5 Mini-Task: Repair
- [ ] **T2-017**: Design Repair challenge:
  - Speed-based matching
  - Simpler patterns
  - Quick reactions required
- [ ] **T2-018**: Implement Repair task:
  - Rapid-fire short sequences
  - Timer per sequence
  - Combo scoring
- [ ] **T2-019**: Success: Restore 50% damage
- [ ] **T2-020**: Failure: No additional penalty

### 1.6 Balancing & Config
- [ ] **T2-021**: First siege grace period (5 trials minimum)
- [ ] **T2-022**: Cooldown between sieges (2-3 minutes)
- [ ] **T2-023**: Difficulty curve tuning
- [ ] **T2-024**: Debug tools for siege testing

---

## 🎵 PHASE 2: Audio System ━ **JARWO** (Day 2-4)

**Owner: Jarwo** handles ALL audio implementation and management.

### 2.1 Audio Architecture
- [ ] **T2-025**: Implement `SoundManager`:
  ```actionscript
  class SoundManager {
    // Playback
    playSFX(id: String): void
    playBGM(id: String, loop: Boolean): void
    stopBGM(): void
    stopAll(): void
    
    // Volume control
    setMasterVolume(v: Number): void
    setSFXVolume(v: Number): void
    setBGMVolume(v: Number): void
    
    // State
    mute(): void
    unmute(): void
    fadeOut(duration: Number): void
  }
  ```
- [ ] **T2-026**: Implement sound pooling for performance
- [ ] **T2-027**: Handle audio context (mobile requirements)
- [ ] **T2-028**: Preload vs lazy-load strategy

### 2.2 Sound Categories & Assets
- [ ] **T2-029**: Define sound library:
  ```actionscript
  // UI Sounds
  BUTTON_CLICK, BUTTON_HOVER, MENU_OPEN, MENU_CLOSE
  
  // Gameplay Sounds
  STIMULUS_SHOW, INPUT_TAP, INPUT_CORRECT, INPUT_WRONG
  SEQUENCE_COMPLETE, SEQUENCE_FAIL
  TIMEOUT_WARNING, TIMEOUT_EXPIRE
  
  // Castle Sounds
  BLOCK_PLACE, BLOCK_UPGRADE, BLOCK_DAMAGE, BLOCK_DESTROY
  CONSTRUCTION_COMPLETE, CASTLE_CRUMBLE
  
  // Siege Sounds
  SIEGE_WARNING, SIEGE_ALARM, SIEGE_ATTACK
  FORTIFY_SUCCESS, REPAIR_SUCCESS
  VICTORY_FANFARE, DEFEAT_SOUND
  
  // Ambient
  BGM_MENU, BGM_GAMEPLAY, BGM_SIEGE, BGM_VICTORY
  ```
- [ ] **T2-030**: Source/create audio assets (royalty-free)
- [ ] **T2-031**: Audio compression settings

### 2.3 Sound Integration
- [ ] **T2-032**: Hook sounds to game events:
  - FSM state transitions
  - Input actions
  - Validation results
- [ ] **T2-033**: Hook sounds to castle events:
  - Construction
  - Damage
  - Upgrades
- [ ] **T2-034**: Hook sounds to siege events:
  - Warning phases
  - Attack
  - Resolution
- [ ] **T2-035**: Dynamic music (intensity based on game state)

### 2.4 Audio Settings
- [ ] **T2-036**: Implement audio preferences:
  - Master volume slider
  - SFX volume slider
  - BGM volume slider
  - Mute toggle
- [ ] **T2-037**: Persist audio settings in save data
- [ ] **T2-038**: Audio accessibility (visual cues when muted)

### 2.5 Achievement System
- [ ] **T2-039**: Define achievements:
  ```actionscript
  class Achievement {
    id: String,
    name: String,
    description: String,
    icon: String,
    requirement: Object,  // Condition to unlock
    reward: Object,       // Bonus granted
    isSecret: Boolean,
    unlockedAt: Number
  }
  ```
- [ ] **T2-040**: Achievement list (20+ achievements):
  - First Correct Answer
  - 10 Streak
  - First Tower Built
  - Survived First Siege
  - Perfect Session (100% accuracy)
  - Speed Demon (under 1s average)
  - Castle Complete
  - etc.
- [ ] **T2-041**: Implement `AchievementManager`:
  - Track progress
  - Check unlock conditions
  - Emit unlock events
- [ ] **T2-042**: Achievement persistence

### 2.6 Tutorial System
- [ ] **T2-043**: Design onboarding flow:
  - Welcome screen
  - Stimulus explanation
  - Input tutorial
  - First guided trial
  - Castle introduction
  - Siege preview (later)
- [ ] **T2-044**: Implement `TutorialManager`:
  - Step tracking
  - Skip option
  - Resume capability
- [ ] **T2-045**: Tutorial hints (contextual)
- [ ] **T2-046**: First-run detection

---

## 🎨 PHASE 3: Visual Polish & Themes ━ **NAZAR** (Day 3-6)

**Owner: Nazar** handles ALL visual polish, themes, and advanced effects.

### 3.1 Siege UI/UX
- [ ] **T2-047**: Design siege visual language:
  - Screen tint (red/orange gradient)
  - Edge vignette effect
  - Pulsing border
- [ ] **T2-048**: Implement `SiegeAlertView`:
  - Countdown display
  - Warning icons
  - Intensity animation
- [ ] **T2-049**: Screen shake implementation:
  - Subtle (warning)
  - Intense (attack)
  - Configurable intensity
- [ ] **T2-050**: Enemy visualization (abstract threat indicators)

### 3.2 Defense Panel UI
- [ ] **T2-051**: Create `DefensePanel`:
  - Fortify button (shield icon)
  - Repair button (wrench icon)
  - Clear visual distinction
  - Disable when inactive
- [ ] **T2-052**: Button hover/press states
- [ ] **T2-053**: Tooltip explanations
- [ ] **T2-054**: Panel animation (slide in/out)

### 3.3 Mini-Task UI
- [ ] **T2-055**: Fortify task UI:
  - High-pressure visual theme
  - Larger countdown
  - Stakes indicator
- [ ] **T2-056**: Repair task UI:
  - Speed-focused design
  - Combo counter
  - Progress bar

### 3.4 Castle Themes
- [ ] **T2-057**: Design theme system:
  ```actionscript
  class CastleTheme {
    id: String,
    name: String,
    palette: Object,
    partSprites: Object,
    unlockRequirement: Object
  }
  ```
- [ ] **T2-058**: Create themes:
  - **Classic** (default stone castle)
  - **Desert** (sandstone, pyramid style)
  - **Ice** (frozen, crystal towers)
  - **Dark** (obsidian, gothic)
  - **Fantasy** (magical, floating elements)
- [ ] **T2-059**: Theme-specific construction effects
- [ ] **T2-060**: Theme unlock conditions

### 3.5 Advanced Visual Effects
- [ ] **T2-061**: Weather system:
  - Clear (default)
  - Rain (during siege warning)
  - Storm (during siege attack)
  - Snow (ice theme)
- [ ] **T2-062**: Day/night cycle (aesthetic only)
- [ ] **T2-063**: Ambient particles:
  - Floating dust/leaves
  - Fireflies (night)
  - Snowflakes (ice theme)
- [ ] **T2-064**: Camera effects:
  - Subtle zoom on important events
  - Pan to castle on construction

### 3.6 Achievement UI
- [ ] **T2-065**: Achievement popup:
  - Trophy/badge icon
  - Name and description
  - Slide-in animation
  - Auto-dismiss
- [ ] **T2-066**: Achievement gallery screen:
  - Grid of achievements
  - Locked vs unlocked states
  - Progress indicators
- [ ] **T2-067**: Achievement detail view

### 3.7 Tutorial Visuals
- [ ] **T2-068**: Tutorial overlays:
  - Highlight specific UI elements
  - Dim rest of screen
  - Arrow/pointer indicators
- [ ] **T2-069**: Tutorial mascot/character (optional)
- [ ] **T2-070**: Step indicator dots

### 3.8 Polish & Testing
- [ ] **T2-071**: Siege visual testing
- [ ] **T2-072**: Theme consistency check
- [ ] **T2-073**: Performance with effects
- [ ] **T2-074**: Visual documentation

---

## 📋 Week 2 Deliverables

| Feature | Owner | Target |
|---------|-------|--------|
| Entropy timer system | Kais | ✅ |
| Siege state machine | Kais | ✅ |
| Fortify mini-game | Kais | ✅ |
| Repair mini-game | Kais | ✅ |
| Penalty/reward system | Kais | ✅ |
| Full SoundManager | Jarwo | ✅ |
| 30+ sound effects | Jarwo | ✅ |
| BGM tracks | Jarwo | ✅ |
| Achievement system (20+) | Jarwo | ✅ |
| Tutorial/onboarding | Jarwo | ✅ |
| Siege UI/UX | Nazar | ✅ |
| Defense panel | Nazar | ✅ |
| 5 castle themes | Nazar | ✅ |
| Weather effects | Nazar | ✅ |
| Achievement UI | Nazar | ✅ |

---

## 📊 Success Criteria

- **Siege**: Complete flow works without breaking game
- **Audio**: All events have appropriate sounds
- **Achievements**: 20+ trackable, unlockable achievements
- **Themes**: 5 distinct visual themes
- **Tutorial**: New player can learn game in under 2 minutes
- **Performance**: 60 FPS maintained with all effects
