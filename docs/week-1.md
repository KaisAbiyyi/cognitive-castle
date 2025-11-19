# Week 1 – Detailed Task Breakdown

Branch: `feature/core-gameplay-loop/week-1`
Primary owners: **Nazar**, **Jarwo**  
(Note: All environment-init tasks for Week 1 under `feature/environment-init/week-1` are already completed by Kais.)

## Scope
- Implement the **Sequence Challenge** core loop from PRD (FR-01, FR-02, FR-03 basics).
- Ensure basic HUD feedback for score/level and smooth input on both Android (touch) and Windows (mouse).

## Tasks by Area

### 1. Sequence Generation Logic
- [ ] Design sequence difficulty tiers (symbol pool, length curve, color variation) *(Nazar, support: Jarwo)*
- [ ] Define data structure for a single stimulus item (e.g. `{id, type, color, value}`) *(Jarwo)*
- [ ] Implement `SequenceGenerator` class skeleton with public API (e.g. `generateSequence(difficultyLevel:int):Vector.<StimulusItem>`) *(Jarwo)*
- [ ] Add randomness rules (no immediate triple repetition, min/max length per tier) *(Jarwo)*
- [ ] Hook generator difficulty input to a simple `currentLevel` or `spanLength` variable (non-adaptive placeholder) *(Nazar)*
- [ ] Add unit-style test harness or debug screen log to verify generated sequences visually in dev build *(Nazar)*

### 2. Stimulus Presentation (View & Timing)
- [ ] Define visual style for symbols (shapes, colors) aligned with PRD constraints (color + shape, no color-only cues) *(Nazar)*
- [ ] Implement `StimulusView` class to render a queue of items sequentially in the center of the screen *(Nazar)*
- [ ] Implement configurable timing constants (show duration, inter-stimulus interval) as shared config values *(Nazar)*
- [ ] Ensure stimulus phase **disables** input (HUD and input area hidden or locked) *(Nazar)*
- [ ] Add simple transition/animation (fade in/out) between items to reduce visual noise *(Nazar)*
- [ ] Add dev-only overlay to show current index / total items during playback *(Nazar)*

### 3. Cross-Platform Input Handling
- [ ] Design unified input event model that abstracts Touch vs Mouse into a single semantic event (e.g. `InputAction`) *(Nazar)*
- [ ] Implement `InputManager` class with handlers for `MouseEvent.CLICK` and `TouchEvent.TOUCH_BEGIN` *(Jarwo)*
- [ ] Map on-screen buttons / tiles to logical stimulus IDs (e.g. by `name`, `id`, or `customData`) *(Jarwo)*
- [ ] Add visual feedback states for input widgets (pressed, released, disabled) *(Nazar)*
- [ ] Implement input buffer collection (`Vector.<StimulusItem>` or `Vector.<int>`) while user is answering *(Jarwo)*
- [ ] Add timeout handling for user response (simple fixed timer; if expired, treat as incorrect) *(Jarwo)*

### 4. Validation & Result Handling
- [ ] Implement `Validator` class or function to compare generated sequence vs user input (order-sensitive) *(Jarwo)*
- [ ] Support multiple validation modes: forward recall (week-1 focus), reverse recall and sort (basic stubs only) *(Nazar)*
- [ ] Add result object structure (e.g. `{isCorrect:Boolean, errors:int, accuracy:Number}`) *(Jarwo)*
- [ ] Integrate validation into main loop: Stimulus -> Input -> Validate -> Result callback *(Nazar)*
- [ ] Define simple scoring rule (e.g. +1 correct trial, 0 on fail) and update score variable *(Nazar)*
- [ ] Log each trial result to console / debug overlay for tuning *(Nazar)*

### 5. Basic HUD & Game Loop Orchestration
- [ ] Implement minimal HUD component showing **Score**, **Current Level/Span**, and basic instructions *(Nazar)*
- [ ] Add "Ready / Observe / Answer" state text to guide user phase-by-phase *(Nazar)*
- [ ] Implement simple finite state machine in `Main` (or controller class) for phases: `IDLE -> STIMULUS -> INPUT -> RESULT -> NEXT` *(Nazar)*
- [ ] Wire HUD updates to FSM transitions (e.g. highlight active phase) *(Nazar)*
- [ ] Add a basic "Next Trial" button or auto-advance delay after result display *(Jarwo)*

### 6. Integration & Platform Checks
- [ ] Integrate all new classes into `Main.as` entry flow without breaking existing environment-init logic *(Nazar)*
- [ ] Verify input and stimulus timing on **Windows desktop** build (mouse) *(Jarwo)*
- [ ] Verify input and stimulus timing on **Android** target (touch) using ADL or device build *(Nazar)*
- [ ] Adjust constants (durations, spacing, sizes) to look acceptable on both aspect ratios *(Nazar, support: Jarwo)*

### 7. Documentation & Cleanup
- [ ] Update `DEVELOPMENT_PLAN.md` status for Week 1 core gameplay tasks after completion *(Nazar)*
- [ ] Add inline developer notes (short) in core classes explaining public APIs and expected usage *(Jarwo)*
- [ ] Ensure no debug-only assets or logs ship in release configuration (guard with flags or simple `if (DEBUG)`) *(Nazar)*
