# **PRODUCT REQUIREMENTS DOCUMENT (PRD)**

Project Name: Cognitive Castle  
Version: 1.1  
Status: In Development  
Document Type: Technical Specification & Requirements  
Date: November 2025

## **1\. INTRODUCTION**

### **1.1 Problem Statement**

In the contemporary digital landscape, "Continuous Partial Attention" has become a prevalent cognitive deficit. The rapid intake of fragmented information degrades the **Working Memory Capacity (WMC)**, specifically affecting the Central Executive's ability to filter distractions and manipulate transient information. Existing cognitive training solutions often suffer from low retention rates due to a lack of immersive feedback mechanisms.

### **1.2 Product Vision**

**Cognitive Castle** is an adaptive software application that visualizes cognitive structural growth. It serves as an interface between neuropsychological training protocols (specifically N-Back and Span Tasks) and procedural generation. The user's ability to retain and manipulate data is directly correlated with the architectural complexity of a digital castle. Furthermore, the system introduces **external stressors** to simulate real-world pressure, requiring users to maintain focus amidst looming threats.

### **1.3 Scope**

This document defines the requirements for the **Alpha Release (MVP)**.

- **Target Platforms:** Android (Mobile) and Windows (Desktop).
- **Core Technology:** Adobe AIR (Harman SDK), ActionScript 3\.
- **Primary Metric:** User accuracy in Sequence Recall, Manipulation, and Stress Resistance tasks.

## **2\. USER PERSONAS**

### **2.1 The Cognitive Optimiser (Primary)**

- **Profile:** Professional or student aged 18-35.
- **Motivation:** Seeks to improve focus, reading comprehension, and logical reasoning for career/academic advancement.
- **Behavior:** Uses the app in short, intensive bursts (15-minute sessions).

### **2.2 The Neuro-Rehabilitator (Secondary)**

- **Profile:** Individuals seeking to maintain mental acuity or recover from cognitive fatigue.
- **Motivation:** Prevention of cognitive decline; structured mental exercise.

## **3\. FUNCTIONAL REQUIREMENTS**

### **3.1 Core Loop: The Construction & Defense Cycle**

The application operates on a cyclical state machine: Stimulus \-\> Retention \-\> Manipulation \-\> Response \-\> Architectural Feedback \-\> Entropy Event (Attack).

#### **FR-01: Sequence Challenge (Stimulus)**

- **Description:** The system shall display a sequence of visual or auditory items.
- **Parameters:**
  - _Item Types:_ Geometric symbols, Color codes, Phonological sounds.
  - _Duration:_ Each item displayed for 800ms \- 1200ms (adaptive).
  - _Inter-Stimulus Interval (ISI):_ 500ms.

#### **FR-02: Manipulation Task (Processing)**

- **Description:** Unlike simple recall, the system shall require cognitive transformation of data.
- **Operations:**
  - _Forward Recall:_ Reproduce sequence $A \\to B \\to C$.
  - _Reverse Recall:_ Reproduce sequence $C \\to B \\to A$.
  - _Sorting:_ Sort items by defined logic (e.g., numerical value) before output.

#### **FR-03: Response Interface**

- **Description:** A non-distracting UI panel allowing users to input the processed sequence.
- **Constraints:** The input method must be consistent across Touch (Android) and Mouse (Windows) interfaces.

#### **FR-04: Architectural Procedural Generation**

- **Description:** Successful trial completion triggers the instantiation of visual assets.
- **Logic:**
  - _Foundation Level:_ Success establishes base walls.
  - _Elevation Level:_ Consecutive successes generate verticality (towers).
  - _Complexity Level:_ Manipulation tasks generate intricate details (bridges, fortifications).
- **Failure Handling:** Errors do not destroy the castle but halt construction and invoke a "Stability Check" (difficulty plateau).

#### **FR-05: Stochastic Stressors (The Siege Protocol)**

- **Description:** To simulate cognitive resilience under pressure, the system employs a "Variable Interval" countdown timer representing external entropy (visualized as enemy forces or environmental decay).
- **Mechanism:**
  - _Countdown:_ A random timer (e.g., between 45s to 120s) runs in the background.
  - _The Event:_ Upon reaching zero, an "Attack" phase initiates.
  - _Player Action:_ The user is forced to choose between **"Fortify"** (Upgrade task) or **"Repair"** (Maintenance task).
    - _Fortify:_ Prevents damage before it happens (requires High-Load Task).
    - _Repair:_ Fixes damage after it happens (requires Speed Task).
  - _Consequence:_ Failure to respond results in the degradation of the castle structure (e.g., a tower collapses), symbolizing loss of focus.

### **3.2 Adaptive Progression Algorithm**

- **Logic:** The system uses a **1-Up / 2-Down** staircase algorithm or similar adaptive heuristic.
  - If Accuracy \> 85% over 3 trials: Increase Sequence Length ($N+1$).
  - If Accuracy \< 60% over 3 trials: Decrease Sequence Length ($N-1$).

## **4\. TECHNICAL ARCHITECTURE**

### **4.1 Development Stack**

- **Language:** ActionScript 3.0 (Strict Mode).
- **Compiler:** Apache Flex SDK merged with Harman AIR SDK 51.2.2.
- **IDE:** Visual Studio Code with ActionScript & MXML Extension.
- **Build System:** Apache Ant / ADL (AIR Debug Launcher).

### **4.2 Rendering Engine**

- **Mode:** renderMode: direct (GPU Acceleration).
- **Framework:** Native DisplayList or Starling Framework (Stage3D) for high-performance vector rasterization.
- **Resolution:** Responsive design handling aspect ratios from 16:9 (Mobile) to variable Desktop windows.

### **4.3 Data Persistence**

- **Local Storage:** Utilizing flash.net.SharedObject for storing:
  - User Progression State (Current Level, Castle JSON structure).
  - Settings (Volume, Accessibility).
- **Data Structure:**  
  {  
   "user_id": "local_uuid",  
   "session_metrics": {  
   "highest_span": 7,  
   "accuracy_average": 0.82,  
   "resilience_score": 0.75  
   },  
   "castle_state": \[  
   {"id": "tower_01", "x": 200, "y": 400, "tier": 3, "health": 100}  
   \]  
  }

## **5\. NON-FUNCTIONAL REQUIREMENTS**

### **5.1 Performance**

- **Frame Rate:** The application must maintain a steady 60 FPS on mid-range Android devices (Snapdragon 6 series equivalent or higher) to ensure stimulus timing accuracy.
- **Latency:** Input latency must be under 50ms.
- **Startup Time:** Cold start to interactive menu within 4 seconds.

### **5.2 Compatibility**

- **Android:** Minimum API Level 21 (Android 5.0). Support for ARMv8 and x86_64 architectures.
- **Windows:** Windows 10/11 (64-bit).

### **5.3 Usability & Accessibility**

- **Color Blindness:** Stimuli must use shape \+ color duality, not relying solely on color.
- **Distraction Free:** The interface must adhere to "Cognitive Load Theory," minimizing extraneous decorative elements during the stimulus phase.

## **6\. UI/UX SPECIFICATIONS**

### **6.1 The Canvas (Main View)**

- **Visual Style:** Minimalist, vector-based, high contrast.
- **Layout:**
  - _Center:_ The Castle (Dynamic Object).
  - _Top:_ Cognitive Meter (Focus Bar) & **Entropy Timer (Countdown)**.
  - _Bottom:_ Input Interface (Hidden during Stimulus phase).

### **6.2 Feedback Mechanisms**

- **Visual:** Particle effects upon placement of new blocks (Positive). Screenshake or desaturation effects during "Siege" events (Negative/Urgency).
- **Auditory:** Subtle, non-intrusive tones. Alarm pulses during low-countdown states.

## **7\. ROADMAP & MILESTONES**

### **Phase 1: Foundation (Weeks 1-2)**

- \[x\] Environment Setup (VS Code, SDK, ADL).
- \[ \] Implementation of Core Game Loop (Stimulus \-\> Input \-\> Validate).
- \[ \] Basic rendering of static assets.

### **Phase 2: Logic & Adaptation (Weeks 3-4)**

- \[ \] Implementation of Adaptive Difficulty Algorithm.
- \[ \] Development of Procedural Castle Logic (Sprite Management).
- \[ \] Implementation of **Stochastic Timer & Siege Logic**.
- \[ \] Save/Load System (SharedObject).

### **Phase 3: Polish & Build (Weeks 5-6)**

- \[ \] Integration of Sound and Particle Effects.
- \[ \] UI/UX Refinement for Touch vs. Mouse.
- \[ \] Final Compilation to .apk and .exe.

## **8\. RISKS AND MITIGATION**

| Risk                          | Impact                      | Mitigation Strategy                                                                                     |
| :---------------------------- | :-------------------------- | :------------------------------------------------------------------------------------------------------ |
| **Fragmented Android Specs**  | UI Scaling issues           | Implement StageScaleMode.NO_SCALE and responsive coordinate math relative to stage.stageWidth.          |
| **Garbage Collection Spikes** | Frame drops during stimulus | Object Pooling for stimuli and particles; Avoid new keyword inside the game loop.                       |
| **Touch Latency**             | Inaccurate input timing     | Use TouchEvent.TOUCH_BEGIN instead of CLICK for immediate response on mobile.                           |
| **Anxiety Overload**          | User churn due to stress    | Ensure the "Attack" mechanic is introduced gradually only after the user reaches a baseline competency. |

**Approved By:** \[Development Lead\]
