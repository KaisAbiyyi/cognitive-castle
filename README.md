# **PROJECT DOCUMENTATION: COGNITIVE CASTLE**

Project Title: Cognitive Castle: An Adaptive Simulation for Working Memory Enhancement via Structural Evolution Visualization  
Version: 1.1.0 (Alpha)  
Classification: Cognitive Training Software / Educational Technology  
Development Platform: Adobe AIR (Harman) / ActionScript 3.0

## **1.0 EXECUTIVE SUMMARY**

**Cognitive Castle** represents a synthesis of cognitive psychology principles and interactive simulation designed to address the declining attention spans and working memory capacities observed in the contemporary digital era. By leveraging the concept of neuroplasticity through gamified repetition, this software functions as an intervention tool. It translates abstract cognitive performance metrics—specifically the retention, manipulation of information, and **resilience under pressure**—into concrete visual output, manifested as the architectural evolution of a castle. The project utilizes ActionScript 3.0 to ensure precise handling of object-oriented logic and vector-based rendering across Android and Windows platforms.

## **2.0 THEORETICAL FRAMEWORK & BACKGROUND**

### **2.1 The Cognitive Deficit Problem**

The pervasive exposure to high-frequency information streams in modern society has been correlated with a fragmentation of the **Central Executive** function within the brain. This degradation impairs the ability to filter distractions and process complex logic sequences, leading to a measurable decline in mental productivity.

### **2.2 Working Memory Model Implementation**

This simulation is grounded in the established Baddeley & Hitch model of Working Memory, targeting three specific cognitive sub-processes:

1. **Phonological Loop / Visuo-Spatial Sketchpad:** The capacity to temporarily hold sensory data.  
2. **Central Executive Processing:** The active manipulation and transformation of held data.  
3. **Episodic Buffer:** The integration of new data into long-term retention, symbolized by the permanent growth of the castle structure.

## **3.0 SYSTEM ARCHITECTURE & MECHANICS**

The application operates on a feedback loop comprising stimulus presentation, user response, and architectural rendering. The user assumes the role of a "Mind Architect," where every architectural component correlates to a confirmed cognitive success.

### **3.1 Core Gameplay Loops**

#### **3.1.1 Serial Recall Protocols (Sequence Challenge)**

The system presents a randomized sequence of symbols, chromatic patterns, or auditory cues. The user must reproduce this sequence with high fidelity. This mechanism specifically targets short-term retention limits.

#### **3.1.2 Operational Transformation (Manipulation Task)**

Unlike simple recall, this mechanic requires the user to modify the input before outputting it (e.g., "Reverse the sequence" or "Sort by magnitude"). This engages the processing power of the Working Memory, surpassing mere storage functions.

#### **3.1.3 Entropy & Defense Protocols (Stochastic Stressors)**

To simulate real-world cognitive load, the system introduces a variable interval countdown mechanism ("The Siege").

* **The Event:** A random countdown triggers a threat to the castle's structural integrity.  
* **The Response:** The user must engage in forced "Maintenance Tasks" (Repair) or "Fortification Tasks" (Upgrade) to counteract the entropy.  
* **Cognitive Goal:** This trains **Anticipatory Anxiety Management**, forcing the user to maintain high-performance focus despite looming deadlines or threats.

### **3.2 The Adaptive Progression Algorithm**

The software employs a dynamic difficulty adjustment algorithm:

* **Success State:** Accurate completion triggers structural expansion (e.g., the addition of a turret or fortification) and incrementally increases the sequence length ($n+1$).  
* **Failure State:** Inaccuracies result in a stabilization of difficulty, preventing cognitive overload while encouraging mastery of the current tier.  
* **Visual Metaphor:** The castle acts as a real-time data visualization of the user's cognitive state. A complex, fortified castle represents a robust, disciplined mind.

## **4.0 TECHNICAL SPECIFICATIONS**

This project prioritizes performance reliability and cross-platform consistency by utilizing a compiled, strict-typed codebase within the Adobe AIR ecosystem.

### **4.1 Development Stack**

* **Programming Language:** ActionScript 3.0 (AS3) – Selected for its robust Event-Driven architecture and superior handling of 2D vector graphics.  
* **Runtime Environment:** Adobe AIR (Harman SDK 51.2.2) – Enables native execution on Android (APK) and Windows (EXE) from a single codebase.  
* **Integrated Development Environment (IDE):** Visual Studio Code.  
* **Compiler Infrastructure:** Apache Flex SDK merged with AIR SDK (Overlay method).

### **4.2 Hardware Requirements**

* **Android:** ARMv7/x86 Processor, Android 5.0+, 2GB RAM.  
* **Windows:** x64 Architecture, Windows 10/11, 4GB RAM.

## **5.0 INSTALLATION AND ENVIRONMENT PROTOCOLS**

To ensure development consistency across the team, all workstations must adhere to the following installation procedures.

### **5.1 Prerequisites**

Before initializing the project, ensure the following dependencies are installed:

1. **Java Development Kit (JDK):** Version 1.8 or 11 (Required for the Android build tools).  
2. **Visual Studio Code:** Latest stable build.  
3. **VS Code Extension:** "ActionScript & MXML" by Bowler Hat LLC.

### **5.2 AIR SDK Installation (Harman \+ Flex Overlay)**

Due to legacy tooling dependencies, a pure AIR SDK installation may cause pathing issues. The **"Flex Overlay"** method is mandatory.

1. **Download SDKs:**  
   * Obtain the **Apache Flex SDK 4.16.1** (Binary distribution).  
   * Obtain the latest **AIR SDK** from the official Harman website (e.g., v51.x).  
2. **The Overlay Process:**  
   * Extract the Apache Flex SDK to a permanent directory (e.g., C:\\SDKS\\Flex\_4.16).  
   * Extract the Harman AIR SDK.  
   * **Copy** all contents of the AIR SDK folder and **Paste** them into the Flex SDK folder, selecting **"Replace All"** when prompted.  
   * *Result:* A single hybrid SDK folder containing the structure of Flex but the modern runtime of AIR.

### **5.3 IDE Configuration**

1. Open the project in Visual Studio Code.  
2. Access the Command Palette (Ctrl \+ Shift \+ P).  
3. Execute: ActionScript: Select Workspace SDK.  
4. Select **"Add New SDK..."** and navigate to the hybrid SDK folder created in Step 5.2.

### **5.4 Launch Configuration (launch.json)**

Since the SDK path varies by machine, the .vscode/launch.json file is ignored in git. You must create this file manually in your local environment to enable debugging.

**Template for .vscode/launch.json:**

{  
    "version": "0.2.0",  
    "configurations": \[  
        {  
            "name": "DEBUG: Mode Android (Nexus)",  
            "type": "swf",  
            "request": "launch",  
            "program": "bin/CognitiveCastle.swf",  
            "profile": "mobileDevice",  
            "screensize": "NexusOne",  
            "screenDPI": 252,  
            "args": \[\],  
            "runtimeExecutable": "C:\\\\AIR\\\\SDK\\\\AIRSDK\_51.2.2\\\\bin\\\\adl.exe"  
        },  
        {  
            "name": "DEBUG: Mode Desktop (Windows)",  
            "type": "swf",  
            "request": "launch",  
            "program": "bin/CognitiveCastle.swf",  
            "profile": "extendedDesktop",  
            "args": \[\],  
            "runtimeExecutable": "C:\\\\AIR\\\\SDK\\\\AIRSDK\_51.2.2\\\\bin\\\\adl.exe"  
        }  
    \]  
}

**Critical Configuration Note:**

* **runtimeExecutable:** You MUST replace C:\\\\AIR\\\\SDK\\\\AIRSDK\_51.2.2\\\\bin\\\\adl.exe with the actual absolute path to the adl.exe file on your specific machine.  
* **Windows Paths:** Ensure you use double backslashes (\\\\) as separators in the JSON string.

## **6.0 DEPLOYMENT AND EXECUTION**

The following procedures outline the method for compiling the source code into a binary executable and initiating the simulation via the AIR Debug Launcher (ADL).

### **6.1 Compilation Process (Build)**

The build process utilizes the mxmlc compiler to generate a SWF file.

1. Clean Build Artifacts:  
   Initiate the clean command to purge previous build artifacts.  
   * *Command:* Ctrl+Shift+B \-\> ActionScript: clean  
2. Compile Source:  
   Initiate the compilation sequence.  
   * *Command:* Ctrl+Shift+B \-\> ActionScript: compile debug  
3. Verification:  
   Confirm the generation of CognitiveCastle.swf within the /bin directory.

### **6.2 Simulation Execution (Run)**

The application supports dual-target simulation defined in the .vscode/launch.json configuration.

#### **Option A: Android Simulation (Mobile Profile)**

* **Target Profile:** mobileDevice  
* **Screen Emulation:** NexusOne (or equivalent high-density display).  
* **Procedure:** Select "DEBUG: Mode Android (Nexus)" from the debug panel and execute (F5). This mode emulates touch input and mobile aspect ratios.

#### **Option B: Desktop Simulation (Extended Desktop Profile)**

* **Target Profile:** extendedDesktop  
* **Procedure:** Select "DEBUG: Mode Desktop (Windows)" from the debug panel and execute (F5). This mode validates mouse interaction and window resizing logic.

**Troubleshooting:** If the runtime fails to launch with a "Runtime not found" error, verify that the runtimeExecutable path in your local launch.json points to the adl.exe located within your SDK bin folder.

## **7.0 FUTURE TRAJECTORY**

### **7.1 Cognitive Impact Assessment**

Upon regular usage, the subject is expected to exhibit improved **Working Memory Capacity (WMC)**, manifested as an increased ability to maintain focus during complex problem-solving tasks in external environments.

### **7.2 Development Roadmap**

* **Phase 2:** Implementation of Fluid Intelligence (Gf) tasks involving pattern recognition matrices.  
* **Phase 3:** Integration of telemetry data to provide users with analytical graphs of their cognitive performance over time.

Principal Investigator / Developer: Kais Abiyyi, Nazar Muhammad, Jarwo Wicaksono
License: Proprietary / Educational Use Only  
Date: November 2025# **PROJECT DOCUMENTATION: COGNITIVE CASTLE**

Project Title: Cognitive Castle: An Adaptive Simulation for Working Memory Enhancement via Structural Evolution Visualization  
Version: 1.1.0 (Alpha)  
Classification: Cognitive Training Software / Educational Technology  
Development Platform: Adobe AIR (Harman) / ActionScript 3.0

## **1.0 EXECUTIVE SUMMARY**

**Cognitive Castle** represents a synthesis of cognitive psychology principles and interactive simulation designed to address the declining attention spans and working memory capacities observed in the contemporary digital era. By leveraging the concept of neuroplasticity through gamified repetition, this software functions as an intervention tool. It translates abstract cognitive performance metrics—specifically the retention, manipulation of information, and **resilience under pressure**—into concrete visual output, manifested as the architectural evolution of a castle. The project utilizes ActionScript 3.0 to ensure precise handling of object-oriented logic and vector-based rendering across Android and Windows platforms.

## **2.0 THEORETICAL FRAMEWORK & BACKGROUND**

### **2.1 The Cognitive Deficit Problem**

The pervasive exposure to high-frequency information streams in modern society has been correlated with a fragmentation of the **Central Executive** function within the brain. This degradation impairs the ability to filter distractions and process complex logic sequences, leading to a measurable decline in mental productivity.

### **2.2 Working Memory Model Implementation**

This simulation is grounded in the established Baddeley & Hitch model of Working Memory, targeting three specific cognitive sub-processes:

1. **Phonological Loop / Visuo-Spatial Sketchpad:** The capacity to temporarily hold sensory data.  
2. **Central Executive Processing:** The active manipulation and transformation of held data.  
3. **Episodic Buffer:** The integration of new data into long-term retention, symbolized by the permanent growth of the castle structure.

## **3.0 SYSTEM ARCHITECTURE & MECHANICS**

The application operates on a feedback loop comprising stimulus presentation, user response, and architectural rendering. The user assumes the role of a "Mind Architect," where every architectural component correlates to a confirmed cognitive success.

### **3.1 Core Gameplay Loops**

#### **3.1.1 Serial Recall Protocols (Sequence Challenge)**

The system presents a randomized sequence of symbols, chromatic patterns, or auditory cues. The user must reproduce this sequence with high fidelity. This mechanism specifically targets short-term retention limits.

#### **3.1.2 Operational Transformation (Manipulation Task)**

Unlike simple recall, this mechanic requires the user to modify the input before outputting it (e.g., "Reverse the sequence" or "Sort by magnitude"). This engages the processing power of the Working Memory, surpassing mere storage functions.

#### **3.1.3 Entropy & Defense Protocols (Stochastic Stressors)**

To simulate real-world cognitive load, the system introduces a variable interval countdown mechanism ("The Siege").

* **The Event:** A random countdown triggers a threat to the castle's structural integrity.  
* **The Response:** The user must engage in forced "Maintenance Tasks" (Repair) or "Fortification Tasks" (Upgrade) to counteract the entropy.  
* **Cognitive Goal:** This trains **Anticipatory Anxiety Management**, forcing the user to maintain high-performance focus despite looming deadlines or threats.

### **3.2 The Adaptive Progression Algorithm**

The software employs a dynamic difficulty adjustment algorithm:

* **Success State:** Accurate completion triggers structural expansion (e.g., the addition of a turret or fortification) and incrementally increases the sequence length ($n+1$).  
* **Failure State:** Inaccuracies result in a stabilization of difficulty, preventing cognitive overload while encouraging mastery of the current tier.  
* **Visual Metaphor:** The castle acts as a real-time data visualization of the user's cognitive state. A complex, fortified castle represents a robust, disciplined mind.

## **4.0 TECHNICAL SPECIFICATIONS**

This project prioritizes performance reliability and cross-platform consistency by utilizing a compiled, strict-typed codebase within the Adobe AIR ecosystem.

### **4.1 Development Stack**

* **Programming Language:** ActionScript 3.0 (AS3) – Selected for its robust Event-Driven architecture and superior handling of 2D vector graphics.  
* **Runtime Environment:** Adobe AIR (Harman SDK 51.2.2) – Enables native execution on Android (APK) and Windows (EXE) from a single codebase.  
* **Integrated Development Environment (IDE):** Visual Studio Code.  
* **Compiler Infrastructure:** Apache Flex SDK merged with AIR SDK (Overlay method).

### **4.2 Hardware Requirements**

* **Android:** ARMv7/x86 Processor, Android 5.0+, 2GB RAM.  
* **Windows:** x64 Architecture, Windows 10/11, 4GB RAM.

## **5.0 INSTALLATION AND ENVIRONMENT PROTOCOLS**

To ensure development consistency across the team, all workstations must adhere to the following installation procedures.

### **5.1 Prerequisites**

Before initializing the project, ensure the following dependencies are installed:

1. **Java Development Kit (JDK):** Version 1.8 or 11 (Required for the Android build tools).  
2. **Visual Studio Code:** Latest stable build.  
3. **VS Code Extension:** "ActionScript & MXML" by Bowler Hat LLC.

### **5.2 AIR SDK Installation (Harman \+ Flex Overlay)**

Due to legacy tooling dependencies, a pure AIR SDK installation may cause pathing issues. The **"Flex Overlay"** method is mandatory.

1. **Download SDKs:**  
   * Obtain the **Apache Flex SDK 4.16.1** (Binary distribution).  
   * Obtain the latest **AIR SDK** from the official Harman website (e.g., v51.x).  
2. **The Overlay Process:**  
   * Extract the Apache Flex SDK to a permanent directory (e.g., C:\\SDKS\\Flex\_4.16).  
   * Extract the Harman AIR SDK.  
   * **Copy** all contents of the AIR SDK folder and **Paste** them into the Flex SDK folder, selecting **"Replace All"** when prompted.  
   * *Result:* A single hybrid SDK folder containing the structure of Flex but the modern runtime of AIR.

### **5.3 IDE Configuration**

1. Open the project in Visual Studio Code.  
2. Access the Command Palette (Ctrl \+ Shift \+ P).  
3. Execute: ActionScript: Select Workspace SDK.  
4. Select **"Add New SDK..."** and navigate to the hybrid SDK folder created in Step 5.2.

### **5.4 Launch Configuration (launch.json)**

Since the SDK path varies by machine, the .vscode/launch.json file is ignored in git. You must create this file manually in your local environment to enable debugging.

**Template for .vscode/launch.json:**

{  
    "version": "0.2.0",  
    "configurations": \[  
        {  
            "name": "DEBUG: Mode Android (Nexus)",  
            "type": "swf",  
            "request": "launch",  
            "program": "bin/CognitiveCastle.swf",  
            "profile": "mobileDevice",  
            "screensize": "NexusOne",  
            "screenDPI": 252,  
            "args": \[\],  
            "runtimeExecutable": "C:\\\\AIR\\\\SDK\\\\AIRSDK\_51.2.2\\\\bin\\\\adl.exe"  
        },  
        {  
            "name": "DEBUG: Mode Desktop (Windows)",  
            "type": "swf",  
            "request": "launch",  
            "program": "bin/CognitiveCastle.swf",  
            "profile": "extendedDesktop",  
            "args": \[\],  
            "runtimeExecutable": "C:\\\\AIR\\\\SDK\\\\AIRSDK\_51.2.2\\\\bin\\\\adl.exe"  
        }  
    \]  
}

**Critical Configuration Note:**

* **runtimeExecutable:** You MUST replace C:\\\\AIR\\\\SDK\\\\AIRSDK\_51.2.2\\\\bin\\\\adl.exe with the actual absolute path to the adl.exe file on your specific machine.  
* **Windows Paths:** Ensure you use double backslashes (\\\\) as separators in the JSON string.

## **6.0 DEPLOYMENT AND EXECUTION**

The following procedures outline the method for compiling the source code into a binary executable and initiating the simulation via the AIR Debug Launcher (ADL).

### **6.1 Compilation Process (Build)**

The build process utilizes the mxmlc compiler to generate a SWF file.

1. Clean Build Artifacts:  
   Initiate the clean command to purge previous build artifacts.  
   * *Command:* Ctrl+Shift+B \-\> ActionScript: clean  
2. Compile Source:  
   Initiate the compilation sequence.  
   * *Command:* Ctrl+Shift+B \-\> ActionScript: compile debug  
3. Verification:  
   Confirm the generation of CognitiveCastle.swf within the /bin directory.

### **6.2 Simulation Execution (Run)**

The application supports dual-target simulation defined in the .vscode/launch.json configuration.

#### **Option A: Android Simulation (Mobile Profile)**

* **Target Profile:** mobileDevice  
* **Screen Emulation:** NexusOne (or equivalent high-density display).  
* **Procedure:** Select "DEBUG: Mode Android (Nexus)" from the debug panel and execute (F5). This mode emulates touch input and mobile aspect ratios.

#### **Option B: Desktop Simulation (Extended Desktop Profile)**

* **Target Profile:** extendedDesktop  
* **Procedure:** Select "DEBUG: Mode Desktop (Windows)" from the debug panel and execute (F5). This mode validates mouse interaction and window resizing logic.

**Troubleshooting:** If the runtime fails to launch with a "Runtime not found" error, verify that the runtimeExecutable path in your local launch.json points to the adl.exe located within your SDK bin folder.

## **7.0 FUTURE TRAJECTORY**

### **7.1 Cognitive Impact Assessment**

Upon regular usage, the subject is expected to exhibit improved **Working Memory Capacity (WMC)**, manifested as an increased ability to maintain focus during complex problem-solving tasks in external environments.

### **7.2 Development Roadmap**

* **Phase 2:** Implementation of Fluid Intelligence (Gf) tasks involving pattern recognition matrices.  
* **Phase 3:** Integration of telemetry data to provide users with analytical graphs of their cognitive performance over time.

Principal Investigator / Developer: Kais Abiyyi, Nazar Muhammad, Jarwo Wicaksono  
License: Proprietary / Educational Use Only  
Date: November 2025