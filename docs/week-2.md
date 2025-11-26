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

- [ ] Define castle component taxonomy (foundation, wall, tower, keep, decorative elements) _(Nazar)_
- [ ] Create base vector assets or placeholder shapes for each component type _(Jarwo)_
- [ ] Define data model for a castle element (e.g. `{id, type, tier, x, y, health}`) _(Jarwo)_
- [ ] Decide on coordinate system and anchoring rules (grid vs free placement) _(Jarwo)_
- [ ] Create a simple `CastleConfig` or constants file for thresholds (e.g. score ranges to unlock new tiers) _(Kais)_

### 2. `CastleArchitect` Core Logic

- [ ] Implement `CastleArchitect` class skeleton (public API: `applyTrialResult(result)`, `getCastleState()`, `renderTo(container)`) _(Kais)_
- [ ] Map cumulative score / streaks to **construction events** (e.g. every N correct trials adds a block) _(Jarwo)_
- [ ] Implement logic for different “levels” of structure (foundation -> walls -> towers -> keep) _(Jarwo)_
- [ ] Add basic handling for “damaged” vs “healthy” states (simple flag or enum) _(Jarwo)_
- [ ] Ensure `CastleArchitect` can rebuild the full castle from a saved state object _(Kais)_
- [ ] Add debug mode to instantly simulate several successful/failed trials and visualize resulting castle _(Jarwo)_

### 3. Construction Animation & Feedback

- [ ] Implement tween/animation when a new block is added (scale-in or fade-in) _(Jarwo)_
- [ ] Add simple particle or glow effect around newly constructed segments _(Jarwo)_
- [ ] Ensure animations do not block the main game loop (non-blocking or callback-based) _(Jarwo)_
- [ ] Add option to skip animations in a `FAST_DEV` or accessibility mode _(Kais)_

### 4. Adaptive Progression Algorithm

- [ ] Design configuration for difficulty levels (min/max span length, progression thresholds) _(Kais)_
- [ ] Implement progression manager (e.g. `ProgressionController` or methods in gameplay controller) using 1-Up / 2-Down heuristic _(Kais)_
- [ ] Track rolling accuracy over last N trials for more stable difficulty decisions _(Jarwo)_
- [ ] Ensure minimum and maximum bounds for sequence length and difficulty tier are respected _(Jarwo)_
- [ ] Expose current difficulty state to HUD (show span length / level number) _(Nazar)_
- [ ] Log progression decisions to debug console for early balancing _(Jarwo)_

### 5. Save & Load System (`SharedObject`)

- [ ] Define overall save schema (user metrics + castle state + settings) consistent with PRD _(Kais)_
- [ ] Implement `SaveSystem` wrapper around `SharedObject` with `saveState()` and `loadState()` APIs _(Jarwo)_
- [ ] Handle first-run case (no existing save; create default state) _(Jarwo)_
- [ ] Ensure castle state serialization/deserialization works with `CastleArchitect` model _(Kais)_
- [ ] Store key metrics: highest span, average accuracy, resilience score placeholders _(Kais)_
- [ ] Add basic try/catch around SharedObject operations and log failures _(Jarwo)_

### 6. Basic Anti-Tamper / Obfuscation

- [ ] Implement lightweight obfuscation or checksum for saved data (e.g. hash of core fields) _(Kais)_
- [ ] Validate save integrity at load time; if invalid, fallback to safe defaults _(Jarwo)_
- [ ] Avoid storing any sensitive information (only local, non-personal metrics) _(Kais)_

### 7. Integration, Testing & Tuning

- [ ] Integrate `CastleArchitect` calls into the main post-validation flow (trigger build events on correct trials) _(Jarwo)_
- [ ] Integrate progression manager so sequence length updates over time instead of being static _(Kais)_
- [ ] Verify that difficulty feels neither too easy nor too punishing over a 10–15 minute test session _(All)_
- [ ] Test save/load by quitting and restarting app; confirm castle and progression resume correctly _(Jarwo)_
- [ ] Adjust numeric constants (thresholds, mapping functions) based on feedback _(All)_

### 8. Documentation & Cleanliness

- [ ] Document `CastleArchitect`, progression controller, and save schema in short markdown or code comments _(Kais)_
- [ ] Update `DEVELOPMENT_PLAN.md` to reflect completed Week 2 tasks _(Jarwo)_
- [ ] Remove or gate any one-off debug buttons used during castle visualization experiments _(Jarwo)_
