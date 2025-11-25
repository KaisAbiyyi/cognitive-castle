# **WEEK 1 - ARCHITECTURE & STRUCTURE OVERVIEW**

## **Package Dependency Diagram**

```
┌─────────────────────────────────────────────────────────────────┐
│ CONFIGURATION LAYER                                             │
│ ┌──────────────────────────┬──────────────────────────────────┐ │
│ │ config/SequenceConfig    │ config/StimulusConfig            │ │
│ │ • SYMBOL_POOL[]          │ • SHOW_DURATION (800ms)          │ │
│ │ • COLORS[]               │ • INTER_STIMULUS_INTERVAL (500ms)│ │
│ │ • Difficulty Tiers       │ • CENTER_X, CENTER_Y             │ │
│ │ • Min/Max lengths        │ • STIMULUS_SIZE                  │ │
│ └──────────────────────────┴──────────────────────────────────┘ │
│                                △                                  │
│                                │ (uses)                           │
└────────────────────────────────┼──────────────────────────────────┘
                                 │
┌────────────────────────────────┼──────────────────────────────────┐
│ DOMAIN LAYER (Pure Business)   │                                  │
│ ┌──────────────────────────────┴─────────────────────────────┐  │
│ │ domain/StimulusItem (id, symbol, color, value, type)      │  │
│ └─────────────────────────────────────────────────────────────┘  │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ domain/ValidationResult (isCorrect, errors, accuracy)     │  │
│ └────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
                                △                                     
                                │ (uses)                             
┌────────────────────────────────┼──────────────────────────────────┐
│ SERVICE LAYER                  │                                  │
│                                │                                  │
│  ┌────────────────────────────┴──────────────────────────┐     │
│  │ generation/SequenceGenerator                          │     │
│  │ • generateSequence(level): Vector.<StimulusItem>     │     │
│  │ • getDifficultyTier(level)                           │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐     │
│  │ game/Validator                                       │     │
│  │ • validate(input, sequence): ValidationResult       │     │
│  │ • Modes: FORWARD, REVERSE, SORT                    │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐     │
│  │ game/ScoreManager                                    │     │
│  │ • addScore(points), getScore()                      │     │
│  │ • logTrialResult(ValidationResult)                  │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                  │
└────────────────────────────────────────────────────────────────────┘
                △                              △                     
                │ (uses)                       │ (uses)              
                │                              │                     
┌───────────────┴──────────┐   ┌───────────────┴────────────────┐  
│ ABSTRACTION LAYER        │   │ INPUT ABSTRACTION LAYER       │  
│                          │   │                               │  
│ ┌────────────────────┐  │   │ ┌─────────────────────────┐   │  
│ │ ui/StimulusView    │  │   │ │ input/InputAction       │   │  
│ │ • presentSequence()│  │   │ │ • type (PRESS/RELEASE)  │   │  
│ │ • renderStimulus() │  │   │ │ • stimulusId            │   │  
│ │ • Timing controls  │  │   │ │ • x, y, timestamp       │   │  
│ └────────────────────┘  │   │ └─────────────────────────┘   │  
│                          │   │         △                      │  
│ ┌────────────────────┐  │   │         │ (uses)               │  
│ │ ui/HUD             │  │   │         │                      │  
│ │ • setScore()       │  │   │ ┌───────┴──────────────────┐   │  
│ │ • setLevel()       │  │   │ │ input/InputManager       │   │  
│ │ • setStateText()   │  │   │ │ • startInputPhase()      │   │  
│ │ • setInstruction() │  │   │ │ • submitInput()          │   │  
│ └────────────────────┘  │   │ │ • Touch + Mouse support  │   │  
│                          │   │ │ • Visual feedback        │   │  
└──────────────┬───────────┘   │ │ • Timeout handling       │   │  
               │                │ └──────────────────────────┘   │  
               │                └──────────────────────────────────┘  
               │                                                    
┌──────────────┴────────────────────────────────────────────────┐  
│ ORCHESTRATION LAYER (FSM)                                     │  
│                                                                │  
│  ┌───────────────────────────────────────────────────────┐   │  
│  │ game/GameController (Singleton + FSM)                │   │  
│  │                                                        │   │  
│  │ States: IDLE → STIMULUS → INPUT → RESULT → NEXT      │   │  
│  │                                                        │   │  
│  │ • initialize(HUD)                                     │   │  
│  │ • startNextTrial()                                   │   │  
│  │ • Orchestrates all services                          │   │  
│  │ • Manages game state & progression                   │   │  
│  │                                                        │   │  
│  └───────────────────────────────────────────────────────┘   │  
│                                                                │  
│  ┌───────────────────────────────────────────────────────┐   │  
│  │ game/GameLoop (Trial Integration)                     │   │  
│  │ • processTrial(userInput, sequence)                  │   │  
│  │ • Integrates Validator & ScoreManager                │   │  
│  └───────────────────────────────────────────────────────┘   │  
│                                                                │  
└────────────────────────────────────────────────────────────────┘  
                                △
                                │ (uses all)
                                │
┌───────────────────────────────┴──────────────────────────────┐  
│ ENTRY POINT                                                 │  
│                                                              │  
│ Main.as (Sprite)                                           │  
│ • Stage initialization (1920×1080)                         │  
│ • Component wiring                                         │  
│ • Singleton initialization                                │  
│ • Event delegation                                        │  
│                                                              │  
└──────────────────────────────────────────────────────────────┘  
```

---

## **Data Flow Diagram (Complete Game Loop)**

```
┌──────────────────────────────────────────────────────────────────┐
│ START: Player clicks "Start Trial"                                │
└──────────────────┬───────────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│ SequenceGenerator.generateSequence(level)                        │
│ ↓                                                                 │
│ Returns: Vector.<StimulusItem>                                   │
│ [{id:0, symbol:"circle", color:0xFF0000},                       │
│  {id:1, symbol:"square", color:0x00FF00},                       │
│  {id:2, symbol:"triangle", color:0x0000FF}]                    │
└──────────────────┬───────────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│ StimulusView.presentSequence(sequence)                           │
│ ↓                                                                 │
│ For each item:                                                   │
│ ├─ renderStimulus() → draw shape with color                     │
│ ├─ Timer(800ms) → show stimulus                                 │
│ ├─ Fade out                                                     │
│ ├─ Timer(500ms) → inter-stimulus interval                       │
│ └─ Next item                                                    │
│ ↓                                                                 │
│ Dispatch: Event(PRESENTATION_COMPLETE)                          │
└──────────────────┬───────────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│ InputManager.startInputPhase(onInputReceived, onTimeout, 10000) │
│ ├─ Enable button grid (6 buttons)                               │
│ ├─ Visual feedback: alpha changes on press                      │
│ └─ Timeout timer starts                                         │
│ ↓                                                                 │
│ Player taps buttons → _inputBuffer: [0, 1, 2]                  │
│ ↓                                                                 │
│ inputManager.submitInput()                                      │
└──────────────────┬───────────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│ Validator.validate(userInput, correctSequence)                  │
│ ├─ Mode: FORWARD (exact order match)                            │
│ ├─ Compare: [0,1,2] vs [0,1,2] → MATCH                         │
│ ↓                                                                 │
│ Return: ValidationResult {                                      │
│   isCorrect: true,                                              │
│   errors: 0,                                                    │
│   accuracy: 1.0                                                 │
│ }                                                               │
└──────────────────┬───────────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│ GameController.onEnterResult()                                  │
│ ├─ ScoreManager.addScore(1)                                     │
│ ├─ HUD.setScore(1)                                              │
│ ├─ HUD.setStateText("Correct!")                                 │
│ ├─ Determine level progression                                  │
│ ├─ Auto-advance timer (3 seconds)                               │
│ └─ Display "Next Trial" button                                  │
│ ↓                                                                 │
│ Player clicks "Next Trial"                                      │
└──────────────────┬───────────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│ GameController.enterState(STATE_STIMULUS) ← LOOP                │
│                                                                  │
│ (Repeat indefinitely with adaptive difficulty)                 │
└──────────────────────────────────────────────────────────────────┘
```

---

## **Class Interaction Matrix**

```
                 │ Seq │ Stim│ Input│ Val │ Score│ GameC│ Game │ HUD │
                 │ Gen │ View│ Mgr  │tor  │ Mgr  │ ntrl │ Loop │     │
─────────────────┼─────┼─────┼──────┼─────┼──────┼──────┼──────┼─────┤
SequenceConfig   │  ▲  │  ▲  │      │     │      │      │      │     │
StimulusConfig   │     │  ▲  │      │     │      │      │      │     │
StimulusItem     │  ●  │  ◆  │      │  ◆  │      │      │      │     │
ValidationResult │     │     │  ◆   │  ●  │  ◆   │  ◆   │      │     │
─────────────────┼─────┼─────┼──────┼─────┼──────┼──────┼──────┼─────┤
SequenceGen      │  ▼  │     │      │     │      │  ◆   │      │     │
StimulusView     │     │  ▼  │      │     │      │  ◆   │      │  ◆  │
InputManager     │     │     │  ▼   │     │      │  ◆   │      │  ◆  │
InputAction      │     │     │  ●   │     │      │  ◆   │      │     │
─────────────────┼─────┼─────┼──────┼─────┼──────┼──────┼──────┼─────┤
Validator        │     │     │      │  ▼  │      │  ◆   │  ◆   │     │
ScoreManager     │     │     │      │     │  ▼   │  ◆   │  ◆   │  ◆  │
GameController   │  ◆  │  ◆  │  ◆   │  ◆  │  ◆   │  ▼   │  ◆   │  ◆  │
GameLoop         │     │     │      │  ◆  │  ◆   │  ◆   │  ▼   │     │
HUD              │     │     │      │     │      │  ◆   │      │  ▼  │
─────────────────┴─────┴─────┴──────┴─────┴──────┴──────┴──────┴─────┘

Legend:
▼ = Uses/Depends on (incoming)
▲ = Provides (outgoing)
● = Instantiates
◆ = Uses/Calls
```

---

## **SOLID Principle Application Examples**

### **1. Single Responsibility**

```
❌ BAD (Violates SRP)
class SequenceGenerator {
    function generateSequence() { /* generation */ }
    function validateInput() { /* validation */ }    ← Wrong!
    function calculateScore() { /* scoring */ }      ← Wrong!
    function displayResult() { /* UI */ }            ← Wrong!
}

✅ GOOD (Follows SRP)
class SequenceGenerator {
    function generateSequence() { /* generation only */ }
}
class Validator {
    function validate() { /* validation only */ }
}
class ScoreManager {
    function addScore() { /* scoring only */ }
}
class HUD {
    function setScore() { /* display only */ }
}
```

### **2. Open/Closed**

```
❌ BAD (Violates OCP)
class Validator {
    function validate(mode: String) {
        if (mode == "forward") { /* ... */ }
        else if (mode == "reverse") { /* ... */ }
        else if (mode == "sort") { /* ... */ }
        else { /* add new mode? */ }  ← Must modify class!
    }
}

✅ GOOD (Follows OCP)
class Validator {
    private var _validationMode: String = MODE_FORWARD;
    
    function setMode(mode: String) {
        _validationMode = mode;  ← Extensible without modification
    }
    
    function validate() {
        switch(_validationMode) {
            case MODE_FORWARD: /* ... */
            case MODE_REVERSE: /* ... */
            case MODE_SORT: /* ... */
        }
    }
}
```

### **3. Liskov Substitution**

```
✅ GOOD (Follows LSP)
interface ISequenceItem {
    id: int;
    symbol: String;
}

class StimulusItem implements ISequenceItem {
    public id: int;
    public symbol: String;
    public color: uint;
}

// Can use anywhere Vector.<ISequenceItem> is expected
var items: Vector.<StimulusItem> = generateSequence();
// ↓
var sequence: Vector.<ISequenceItem> = items;  ✓ Substitutable
```

### **4. Interface Segregation**

```
❌ BAD (Violates ISP)
interface IGameController {
    initialize(hud: HUD);
    startTrial();
    setState(state: String);
    renderUI();              ← Client shouldn't care
    saveData();              ← Client shouldn't care
    calculateDifficulty();   ← Client shouldn't care
}

✅ GOOD (Follows ISP)
interface IGameController {
    initialize(hud: HUD);
    startTrial();
}
// Other concerns handled by other classes
```

### **5. Dependency Inversion**

```
❌ BAD (Violates DIP)
class GameController {
    private var _hud: HUD;           ← Depends on concrete class
    private var _validator: Validator;
    private var _inputManager: InputManager;
    
    function initialize() {
        _hud = new HUD();  ← Direct instantiation
    }
}

✅ GOOD (Follows DIP)
class GameController {
    private var _hud: HUD;    ← Depends on interface/abstraction
    
    function initialize(hud: HUD) {
        _hud = hud;           ← Injected dependency
    }
}
```

---

## **File Organization Benefits**

### **Before Week 1 (Flat Structure)**
```
src/
├── Main.as
├── SequenceGenerator.as
├── StimulusView.as
├── InputManager.as
├── Validator.as
├── HUD.as
├── GameController.as
├── StimulusItem.as
└── ValidationResult.as
     
Problem: Hard to find related classes
         Unclear responsibility hierarchy
         Difficult to add features
```

### **After Week 1 (SOLID Organization)**
```
src/
├── config/          ← All configuration in one place
├── domain/          ← Pure business entities
├── generation/      ← Generation service
├── input/           ← Input abstractions
├── game/            ← Application services
├── ui/              ← Presentation layer
└── Main.as          ← Entry point

Benefit: Easy navigation
         Clear responsibility
         Simple to extend
         Scalable structure
```

---

## **Compilation & Deployment Status**

```
┌─────────────────────────────────────────────┐
│ BUILD PIPELINE                              │
│                                             │
│ Source Code (14 .as files)                 │
│        ↓                                    │
│ asconfigc.jar (ActionScript Compiler)      │
│        ↓                                    │
│ ✅ No Errors                                │
│ ✅ No Warnings                              │
│ ✅ No Import Issues                         │
│        ↓                                    │
│ CognitiveCastle.swf (17,593 bytes)        │
│        ↓                                    │
│ ✅ Ready for Testing                        │
│ ✅ Ready for Week 2 Development             │
│                                             │
└─────────────────────────────────────────────┘
```

---

## **Technology Stack**

```
┌─────────────────────────────────────────┐
│ Language & Runtime                      │
├─────────────────────────────────────────┤
│ ActionScript 3.0                        │
│ Adobe AIR (Harman SDK 51.2.2)          │
│ Target: Android + Windows               │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Build Tools                             │
├─────────────────────────────────────────┤
│ asconfigc.jar (AS3 Compiler)            │
│ Apache Flex SDK (overlay)               │
│ Java 17                                 │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Development Environment                 │
├─────────────────────────────────────────┤
│ VS Code                                 │
│ bowlerhatllc.vscode-as3mxml extension  │
│ Git version control                     │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Libraries & Frameworks                  │
├─────────────────────────────────────────┤
│ Flash API (display, events, text)      │
│ AIR API (system, storage)              │
│ No external dependencies                │
└─────────────────────────────────────────┘
```

---

## **Performance Characteristics**

```
┌──────────────────────────────────────────────┐
│ Build Performance                            │
├──────────────────────────────────────────────┤
│ Compilation Time: ~0.8 seconds              │
│ SWF Size: 17,593 bytes (17.2 KB)           │
│ No optimization flags yet (debug build)     │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ Memory Footprint (Estimated)                │
├──────────────────────────────────────────────┤
│ Runtime: ~8-10 MB (AIR runtime)            │
│ Application: ~2-3 MB (14 classes)          │
│ Game Session: ~1-2 MB (game state)         │
│ Total: ~12-15 MB (typical phone)           │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ Responsiveness                               │
├──────────────────────────────────────────────┤
│ Target: 60 FPS (desktop)                    │
│ Target: 30 FPS (mobile)                     │
│ Input Latency: < 100ms (goal)              │
│ State Transitions: < 50ms (typical)        │
└──────────────────────────────────────────────┘
```

---

**Status:** ✅ WEEK 1 COMPLETE - Ready for Testing & Week 2 Development
