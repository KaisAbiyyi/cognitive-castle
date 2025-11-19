# Week 3 – Detailed Task Breakdown

Branches:  
- `feature/siege-mechanic/week-3`  
- `feature/stress-ui-ux/week-3`

Primary owners: **Kais**, **Nazar**, **Jarwo**

## Scope
- Implement **Entropy / Siege mechanics**: stochastic countdown, attack events, penalties.
- Provide clear **defense UI/UX** and mini-task(s) representing Fortify and Repair actions.

## Tasks by Area

### 1. Entropy Timer & Event Model
- [ ] Define configuration ranges for random siege timer (min/max seconds, early-game vs late-game) *(Kais)*
- [ ] Implement `EntropyTimer` class that can start, pause, reset, and emit events when reaching thresholds *(Kais)*
- [ ] Add warning threshold events (e.g. 10s remaining) for pre-attack alerts *(Jarwo)*
- [ ] Ensure timer respects game pause/resume (e.g. when app minimized on Android) *(Kais)*
- [ ] Expose timer state to HUD/UX (remaining time, alert level) via observer/callback pattern *(Nazar)*

### 2. Siege Alert Presentation
- [ ] Design visual language for danger (screen tint, subtle shake, color scheme) *(Nazar)*
- [ ] Implement `SiegeAlertView` displaying countdown and short explanatory text *(Nazar)*
- [ ] Add mild screen shake or pulsing effect as timer approaches zero *(Nazar)*
- [ ] Ensure alerts do not overlap stimulus phase visuals excessively (respect cognitive load) *(Kais)*

### 3. Siege Event Flow & Choices
- [ ] Design state diagram for Siege: `NORMAL -> WARNING -> CHOICE -> RESOLUTION -> COOLDOWN` *(Kais)*
- [ ] Implement central controller to transition game into **Siege Choice** state when timer hits zero *(Jarwo)*
- [ ] Freeze main sequence challenge loop during choice and mini-task execution *(Kais)*
- [ ] Define numeric consequences for success/failure in Fortify vs Repair (castle damage, score modifiers, timer reset) *(Kais)*

### 4. Defense Panel UI (Fortify / Repair)
- [ ] Create `DefensePanel` UI with two clear, accessible buttons: **Fortify** and **Repair** *(Nazar)*
- [ ] Add short tooltips or labels explaining what each option means in gameplay terms *(Nazar)*
- [ ] Wire buttons to trigger respective mini-task flows *(Jarwo)*
- [ ] Disable/gray out panel when not in Siege state *(Nazar)*

### 5. Mini-Tasks Implementation
- [ ] Design **Fortify Task** as a higher-load cognitive mini-challenge (e.g. longer span or manipulation variant) *(Kais)*
- [ ] Design **Repair Task** as a speed-based challenge (e.g. quick small sequence, or tap-matching) *(Nazar)*
- [ ] Implement reusable mini-task framework (start/stop, success/fail callback) *(Jarwo)*
- [ ] Ensure mini-tasks reuse as much of existing input and validation logic as possible *(Jarwo)*
- [ ] Tune task difficulty and time limits so that they are challenging but fair *(All)*

### 6. Penalty & Castle Integration
- [ ] Define how castle health/state is tracked at a high level (e.g. global `castleHealth` or per-element health) *(Kais)*
- [ ] Implement penalty logic on failure: remove or downgrade specific castle elements via `CastleArchitect` *(Jarwo)*
- [ ] Implement reward logic on success: reinforce or upgrade elements, or add defensive structures *(Nazar)*
- [ ] Ensure visual feedback (e.g. crumble animation or repair glow) accompanies changes *(Nazar)*

### 7. Balancing & User Experience
- [ ] Ensure the first siege occurs only after the player has experienced a few normal trials *(Kais)*
- [ ] Add configurable cooldown between siege events to avoid back-to-back stress *(Kais)*
- [ ] Gather internal feedback from 10–15 minute playtests focusing on stress vs motivation *(All)*
- [ ] Adjust timers, penalties, and rewards based on perceived cognitive load *(All)*

### 8. Documentation & Cleanup
- [ ] Document the siege mechanic flow (diagrams or markdown) for future tuning *(Kais)*
- [ ] Update `DEVELOPMENT_PLAN.md` Week 3 task statuses once implemented *(Nazar)*
- [ ] Remove any throwaway debug UI created during siege experiments *(Jarwo)*
