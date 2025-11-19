# Week 2 – Detailed Task Breakdown

Branches:  
- `feature/castle-logic/week-2`  
- `feature/progression-algo/week-2`

Primary owners: **Kais**, **Nazar**, **Jarwo**

## Scope
- Translate cognitive performance into **castle growth** (procedural visuals).
- Implement early version of **adaptive progression** (1-Up / 2-Down style) and persistence of user/castle state.

## Tasks by Area

### 1. Castle Visual Assets & Structure Model
- [ ] Define castle component taxonomy (foundation, wall, tower, keep, decorative elements) *(Nazar)*
- [ ] Create base vector assets or placeholder shapes for each component type *(Nazar)*
- [ ] Define data model for a castle element (e.g. `{id, type, tier, x, y, health}`) *(Jarwo)*
- [ ] Decide on coordinate system and anchoring rules (grid vs free placement) *(Kais)*
- [ ] Create a simple `CastleConfig` or constants file for thresholds (e.g. score ranges to unlock new tiers) *(Kais)*

### 2. `CastleArchitect` Core Logic
- [ ] Implement `CastleArchitect` class skeleton (public API: `applyTrialResult(result)`, `getCastleState()`, `renderTo(container)`) *(Kais)*
- [ ] Map cumulative score / streaks to **construction events** (e.g. every N correct trials adds a block) *(Kais)*
- [ ] Implement logic for different “levels” of structure (foundation -> walls -> towers -> keep) *(Jarwo)*
- [ ] Add basic handling for “damaged” vs “healthy” states (simple flag or enum) *(Jarwo)*
- [ ] Ensure `CastleArchitect` can rebuild the full castle from a saved state object *(Kais)*
- [ ] Add debug mode to instantly simulate several successful/failed trials and visualize resulting castle *(Nazar)*

### 3. Construction Animation & Feedback
- [ ] Implement tween/animation when a new block is added (scale-in or fade-in) *(Nazar)*
- [ ] Add simple particle or glow effect around newly constructed segments *(Nazar)*
- [ ] Ensure animations do not block the main game loop (non-blocking or callback-based) *(Jarwo)*
- [ ] Add option to skip animations in a `FAST_DEV` or accessibility mode *(Kais)*

### 4. Adaptive Progression Algorithm
- [ ] Design configuration for difficulty levels (min/max span length, progression thresholds) *(Kais)*
- [ ] Implement progression manager (e.g. `ProgressionController` or methods in gameplay controller) using 1-Up / 2-Down heuristic *(Kais)*
- [ ] Track rolling accuracy over last N trials for more stable difficulty decisions *(Jarwo)*
- [ ] Ensure minimum and maximum bounds for sequence length and difficulty tier are respected *(Kais)*
- [ ] Expose current difficulty state to HUD (show span length / level number) *(Nazar)*
- [ ] Log progression decisions to debug console for early balancing *(Jarwo)*

### 5. Save & Load System (`SharedObject`)
- [ ] Define overall save schema (user metrics + castle state + settings) consistent with PRD *(Kais)*
- [ ] Implement `SaveSystem` wrapper around `SharedObject` with `saveState()` and `loadState()` APIs *(Jarwo)*
- [ ] Handle first-run case (no existing save; create default state) *(Jarwo)*
- [ ] Ensure castle state serialization/deserialization works with `CastleArchitect` model *(Kais)*
- [ ] Store key metrics: highest span, average accuracy, resilience score placeholders *(Kais)*
- [ ] Add basic try/catch around SharedObject operations and log failures *(Jarwo)*

### 6. Basic Anti-Tamper / Obfuscation
- [ ] Implement lightweight obfuscation or checksum for saved data (e.g. hash of core fields) *(Kais)*
- [ ] Validate save integrity at load time; if invalid, fallback to safe defaults *(Jarwo)*
- [ ] Avoid storing any sensitive information (only local, non-personal metrics) *(Kais)*

### 7. Integration, Testing & Tuning
- [ ] Integrate `CastleArchitect` calls into the main post-validation flow (trigger build events on correct trials) *(Nazar)*
- [ ] Integrate progression manager so sequence length updates over time instead of being static *(Kais)*
- [ ] Verify that difficulty feels neither too easy nor too punishing over a 10–15 minute test session *(All)*
- [ ] Test save/load by quitting and restarting app; confirm castle and progression resume correctly *(Jarwo)*
- [ ] Adjust numeric constants (thresholds, mapping functions) based on feedback *(All)*

### 8. Documentation & Cleanliness
- [ ] Document `CastleArchitect`, progression controller, and save schema in short markdown or code comments *(Kais)*
- [ ] Update `DEVELOPMENT_PLAN.md` to reflect completed Week 2 tasks *(Nazar)*
- [ ] Remove or gate any one-off debug buttons used during castle visualization experiments *(Jarwo)*
