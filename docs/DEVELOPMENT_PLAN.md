# **Comprehensive Development Plan: Cognitive Castle**

Project: Cognitive Castle (Cognitive Training Simulation)  
Duration: 4 Weeks  
Methodology: Agile / Scrum-like  
Format: Task List with Checkboxes, Unique IDs, and Assignments  
Team Members: Kais, Nazar, Jarwo

## **Branch Naming Convention**

All branches must strictly follow this format:  
feature/\[feature-name\]/week-\[week-number\]  
Examples:

- feature/project-setup/week-1
- feature/castle-mechanics/week-2
- feature/siege-mode/week-3

## **Week 1: Environment Setup, Core Loop & Input System**

Focus: Project foundation, AIR SDK configuration, and basic Stimulus-Response loop.  
Goal: Functional prototype where users can receive stimulus and input answers.

### **Branch: feature/environment-init/week-1**

**Objective:** Initialize AS3 project and configure development environment.

- \[ \] **T1-001** (Kais): Initialize Git repository, setup .gitignore, and configure asconfig.json for AIR Mobile & Desktop targets.
- \[ \] **T1-002** (Nazar): Setup folder structure (src, assets, bin) and create base "Main" Sprite with responsive scaling logic (StageScaleMode.NO_SCALE).
- \[ \] **T1-003** (Jarwo): Create basic "Debugger" UI overlay to display FPS and Memory usage for performance monitoring.
- \[ \] **T1-004** (Kais): Configure launch.json in VS Code for dual-target debugging (Android Nexus & Windows Desktop).

### **Branch: feature/core-gameplay-loop/week-1**

**Objective:** Implement the Sequence Challenge and Validation logic.

- \[ \] **T1-005** (Jarwo): Develop SequenceGenerator class to create random arrays of symbols/colors based on difficulty level.
- \[ \] **T1-006** (Nazar): Develop StimulusView component to render the sequence items (Shapes/Colors) with precise timing (800ms duration).
- \[ \] **T1-007** (Kais): Implement InputManager class to handle both Touch (Android) and Mouse (Windows) events consistently.
- \[ \] **T1-008** (Jarwo): Implement Validator logic to compare User Input vs Generated Sequence and return Boolean result.
- \[ \] **T1-009** (Nazar): Develop Basic HUD (Heads-Up Display) showing current Score and Level.

## **Week 2: Procedural Castle & Adaptive Progression**

Focus: Visualizing cognitive growth and implementing the complexity algorithm.  
Goal: The castle grows visually based on user performance.

### **Branch: feature/castle-logic/week-2**

**Objective:** Procedural generation of the castle structure.

- \[ \] **T2-001** (Nazar): Create Vector Assets (Graphics) for Castle parts: Foundation, Wall, Tower, Keep, and Flag (Modular Sprite System).
- \[ \] **T2-002** (Kais): Develop CastleArchitect class to interpret "Score" into "Visual Structure" (e.g., Score 10 \= Add Tower).
- \[ \] **T2-003** (Jarwo): Implement logic for "Castle States" (Healthy vs Damaged) using frame labels or texture swapping.
- \[ \] **T2-004** (Nazar): Implement "Construction Animation" (Tweening) when a new block is added to the stage.

### **Branch: feature/progression-algo/week-2**

**Objective:** Adaptive difficulty and Data Persistence.

- \[ \] **T2-005** (Kais): Implement "N-Back" / "Span" algorithm (1-Up / 2-Down rule) to adjust Sequence Length dynamically.
- \[ \] **T2-006** (Jarwo): Develop SaveSystem using SharedObject to store User High Score, Castle State, and Settings locally.
- \[ \] **T2-007** (Kais): Implement Data Encryption helper to prevent simple modification of the save file (Anti-Cheat basic).

## **Week 3: Entropy (Siege) & Stress Mechanics**

Focus: Implementing the "Random Countdown" and Defense mechanics.  
Goal: Users must manage stress and perform maintenance tasks.

### **Branch: feature/siege-mechanic/week-3**

**Objective:** Logic for the Countdown Timer and Attack Events.

- \[ \] **T3-001** (Kais): Develop EntropyTimer class (Stochastic Timer) that triggers an event randomly between 45s-120s.
- \[ \] **T3-002** (Nazar): Design UI for "Siege Alert" (Visual Warning / Screen Shake effect) when timer approaches zero.
- \[ \] **T3-003** (Jarwo): Implement SiegeEvent logic: Pause main game \-\> Present "Fortify" or "Repair" choice \-\> Apply Penalty if failed.
- \[ \] **T3-004** (Kais): Integrate "Penalty Logic" (e.g., remove top-most Tower) into the CastleArchitect class.

### **Branch: feature/stress-ui-ux/week-3**

**Objective:** User Interface for defensive actions.

- \[ \] **T3-005** (Nazar): Develop "Defense Panel" UI containing "Fortify" (Upgrade) and "Repair" (Fix) buttons.
- \[ \] **T3-006** (Jarwo): Implement "Maintenance Task" mini-game (Speed-based sorting) required to repair the castle.
- \[ \] **T3-007** (Kais): Tune the "Panic Factor" variables (Timer speed vs Reward) to ensure fair difficulty curve.

## **Week 4: Audio, Polish & Final Deployment**

Focus: UX refinement, Sound integration, and Building the artifact.  
Goal: Production-ready .apk and .exe files.

### **Branch: feature/audio-polish/week-4**

**Objective:** Audio feedback and visual refinement.

- \[ \] **T4-001** (Nazar): Integrate SoundManager system and source assets for: Correct, Wrong, Build, Alarm, and Ambient BGM.
- \[ \] **T4-002** (Jarwo): Implement Particle Effects (Confetti/Sparkles) on successful sequence completion.
- \[ \] **T4-003** (Kais): Implement "Pause & Resume" handling, especially for Android Activity Lifecycle (minimize/restore).

### **Branch: feature/deployment-ops/week-4**

**Objective:** Final Build and Documentation.

- \[ \] **T4-004** (Nazar): Create App Icons (Adaptive Icons for Android) and Loading Screen (Splash Screen).
- \[ \] **T4-005** (Jarwo): Perform End-to-End testing on physical Android Device to verify Touch Latency and FPS.
- \[ \] **T4-006** (Kais): Finalize CognitiveCastle-app.xml permissions (Write Storage, etc.) and generate Self-Signed Certificate.
- \[ \] **T4-007** (Kais): Run final build command (adt \-package) to produce CognitiveCastle.apk and CognitiveCastle.exe.
- \[ \] **T4-008** (All): Conduct final "Bug Bash" session and wrap up documentation (README/Manual).
