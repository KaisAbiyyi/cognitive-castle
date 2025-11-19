# Week 4 – Detailed Task Breakdown

Branches:  
- `feature/audio-polish/week-4`  
- `feature/deployment-ops/week-4`

Primary owners: **Kais**, **Nazar**, **Jarwo**

## Scope
- Add **audio feedback**, polish UX, and finalize builds for Android and Windows.
- Ensure documentation and deployment pipeline are ready for an Alpha release.

## Tasks by Area

### 1. Audio System & Integration
- [ ] Specify sound categories: Correct, Wrong, Build/Construction, Alarm/Siege, Ambient BGM *(Nazar)*
- [ ] Implement `SoundManager` with simple API (`play(id)`, `stop(id)`, set volume) *(Nazar)*
- [ ] Load sound assets efficiently (preload vs lazy-load decisions) *(Jarwo)*
- [ ] Hook sounds into key events: sequence success/fail, castle build, siege warning, siege result *(Nazar)*
- [ ] Add master volume and SFX/BGM sliders to settings (if feasible within scope) *(Kais)*

### 2. Visual Polish & FX
- [ ] Implement lightweight particle effect or burst when player completes a sequence correctly *(Jarwo)*
- [ ] Add subtle effects for castle upgrades and repairs (e.g. glow, dust, shimmer) *(Nazar)*
- [ ] Ensure effects are performance-friendly and re-use pooled objects where possible *(Jarwo)*
- [ ] Review color usage for accessibility and consistency with earlier design *(Nazar)*

### 3. UX Refinements
- [ ] Implement robust Pause/Resume behavior, especially on Android activity lifecycle transitions *(Kais)*
- [ ] Ensure timers, siege states, and animations pause correctly and resume without glitches *(Kais)*
- [ ] Review and refine instructional copy and labels across HUD, siege, and menus *(Nazar)*
- [ ] Add simple onboarding or first-run hints if time allows *(All)*

### 4. Assets for Deployment
- [ ] Create or refine app icons for Android and Windows (required resolutions) *(Nazar)*
- [ ] Design splash/loading screen visual matching Cognitive Castle theme *(Nazar)*
- [ ] Configure splash usage in `CognitiveCastle-app.xml` as needed *(Kais)*

### 5. Packaging Configuration
- [ ] Review and finalize `CognitiveCastle-app.xml` (ID, version, permissions, profiles) *(Kais)*
- [ ] Generate or update self-signed certificate/keystore for signing builds *(Kais)*
- [ ] Document certificate/keystore location and passwords in a secure, non-repo channel *(Kais)*

### 6. Build Pipeline (APK & EXE)
- [ ] Define repeatable build commands for debug and release (adt / Ant scripts) *(Kais)*
- [ ] Build Android `.apk` and verify installation and launch on at least one physical device *(Jarwo)*
- [ ] Build Windows `.exe` (or packaged directory) and verify launch on Windows 10/11 *(Nazar)*
- [ ] Check framerate, input latency, and basic stability on both platforms *(All)*

### 7. Final QA & Bug Bash
- [ ] Create short test checklist (core loop, siege, progression, save/load, audio, visuals) *(Kais)*
- [ ] Run internal bug bash session and log findings in a simple shared list *(All)*
- [ ] Fix high-priority issues affecting stability or core gameplay feedback *(All)*

### 8. Documentation & Handover
- [ ] Update `README.md` with final run/build instructions and known limitations *(Kais)*
- [ ] Update `DEVELOPMENT_PLAN.md` Week 4 items to reflect actual completion *(Nazar)*
- [ ] Capture short "Alpha Release" notes: features included, major gaps, and future directions *(All)*
