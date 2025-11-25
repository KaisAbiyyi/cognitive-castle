# Week 1 – Detailed Task Breakdown

Branch: `feature/core-gameplay-loop/week-1`
Primary owners: **Kais**, **Nazar**  
(Note: All environment-init tasks for Week 1 under `feature/environment-init/week-1` are already completed by Kais.)

## Scope

- Implement the **Sequence Challenge** core loop from PRD (FR-01, FR-02, FR-03 basics).
- Ensure basic HUD feedback for score/level and smooth input on both Android (touch) and Windows (mouse).

## Tasks by Area

### 1. Sequence Generation Logic

- [x] Design sequence difficulty tiers (symbol pool, length curve, color variation) _(Kais)_
- [x] Define data structure for a single stimulus item (e.g. `{id, type, color, value}`) _(Kais)_
- [x] Implement `SequenceGenerator` class skeleton with public API (e.g. `generateSequence(difficultyLevel:int):Vector.<StimulusItem>`) _(Kais)_
- [x] Add randomness rules (no immediate triple repetition, min/max length per tier) _(Kais)_
- [x] Hook generator difficulty input to a simple `currentLevel` or `spanLength` variable (non-adaptive placeholder) _(Kais)_
- [x] Add unit-style test harness or debug screen log to verify generated sequences visually in dev build _(Kais)_

### 2. Stimulus Presentation (View & Timing)

- [x] Define visual style for symbols (shapes, colors) aligned with PRD constraints (color + shape, no color-only cues) _(Nazar)_
- [x] Implement `StimulusView` class to render a queue of items sequentially in the center of the screen _(Nazar)_
- [x] Implement configurable timing constants (show duration, inter-stimulus interval) as shared config values _(Nazar)_
- [x] Ensure stimulus phase **disables** input (HUD and input area hidden or locked) _(Nazar)_
- [x] Add simple transition/animation (fade in/out) between items to reduce visual noise _(Nazar)_
- [x] Add dev-only overlay to show current index / total items during playback _(Nazar)_

### 3. Cross-Platform Input Handling

- [x] Design unified input event model that abstracts Touch vs Mouse into a single semantic event (e.g. `InputAction`) _(Kais)_
- [x] Implement `InputManager` class with handlers for `MouseEvent.CLICK` and `TouchEvent.TOUCH_BEGIN` _(Kais)_
- [x] Map on-screen buttons / tiles to logical stimulus IDs (e.g. by `name`, `id`, or `customData`) _(Kais)_
- [x] Add visual feedback states for input widgets (pressed, released, disabled) _(Kais)_
- [x] Implement input buffer collection (`Vector.<StimulusItem>` or `Vector.<int>`) while user is answering _(Kais)_
- [x] Add timeout handling for user response (simple fixed timer; if expired, treat as incorrect) _(Kais)_

### 4. Validation & Result Handling

- [ ] Implement `Validator` class or function to compare generated sequence vs user input (order-sensitive) _(Nazar)_
- [ ] Support multiple validation modes: forward recall (week-1 focus), reverse recall and sort (basic stubs only) _(Nazar)_
- [ ] Add result object structure (e.g. `{isCorrect:Boolean, errors:int, accuracy:Number}`) _(Nazar)_
- [ ] Integrate validation into main loop: Stimulus -> Input -> Validate -> Result callback _(Nazar)_
- [ ] Define simple scoring rule (e.g. +1 correct trial, 0 on fail) and update score variable _(Nazar)_
- [ ] Log each trial result to console / debug overlay for tuning _(Nazar)_

### 5. Basic HUD & Game Loop Orchestration

- [ ] Implement minimal HUD component showing **Score**, **Current Level/Span**, and basic instructions _(Kais)_
- [ ] Add "Ready / Observe / Answer" state text to guide user phase-by-phase _(Kais)_
- [ ] Implement simple finite state machine in `Main` (or controller class) for phases: `IDLE -> STIMULUS -> INPUT -> RESULT -> NEXT` _(Kais)_
- [ ] Wire HUD updates to FSM transitions (e.g. highlight active phase) _(Kais)_
- [ ] Add a basic "Next Trial" button or auto-advance delay after result display _(Kais)_

### 6. Integration & Platform Checks

- [ ] Integrate all new classes into `Main.as` entry flow without breaking existing environment-init logic _(Nazar)_
- [ ] Verify input and stimulus timing on **Windows desktop** build (mouse) _(Nazar)_
- [ ] Verify input and stimulus timing on **Android** target (touch) using ADL or device build _(Nazar)_
- [ ] Adjust constants (durations, spacing, sizes) to look acceptable on both aspect ratios _(Nazar)_

### 7. Documentation & Cleanup

- [ ] Update `DEVELOPMENT_PLAN.md` status for Week 1 core gameplay tasks after completion _(Kais)_
- [ ] Add inline developer notes (short) in core classes explaining public APIs and expected usage _(Kais)_
- [ ] Ensure no debug-only assets or logs ship in release configuration (guard with flags or simple `if (DEBUG)`) _(Kais)_
