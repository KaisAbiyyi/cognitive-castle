# Cognitive Castle - Release Notes

## Version 1.0.0

**Release Date:** January 9, 2026  
**Status:** Production Release  
**Platforms:** Android, Windows

---

## Overview

Cognitive Castle is an adaptive cognitive training application that visualizes mental structural growth through an interactive castle-building mechanic. Users engage in working memory tasks (N-Back and Span Tasks) where performance directly correlates with architectural progression of a digital castle.

---

## Features

### Core Gameplay

- **Sequence Challenge System**
  - Visual stimulus presentation with configurable duration (800ms - 1500ms)
  - Inter-stimulus interval of 500ms for optimal cognitive processing
  - Support for forward recall, reverse recall, and sorting operations

- **Castle Progression System**
  - Dynamic castle growth based on user performance
  - Tower addition system for consecutive correct answers
  - Visual feedback for upgrades and damage states

- **Siege Protocol (Stressor System)**
  - Variable interval countdown timer (45s - 120s)
  - Horde attack visualization representing cognitive pressure
  - Castle integrity management under stress conditions

### User Interface

- **Main Menu**
  - Play, Settings, Lessons, and About Us navigation
  - Opening video introduction sequence

- **Game Screen**
  - 16:9 aspect ratio container with letterboxing support
  - Pause system with save functionality
  - Upgrade popup with challenge interface
  - Orb HUD for streak visualization

- **Settings Panel**
  - Master volume control with persistent save
  - Audio level adjustment (0-10 scale)

- **Lessons Panel**
  - Educational video content on IQ and Working Memory
  - Video player with play, pause, and seek controls
  - Progress indicator and timestamp display

- **About Us Panel**
  - Team information and credits

### Audio System

- Background music for lobby and game states
- Sound effects for:
  - Castle spawn and upgrade events
  - Button interactions (hover in/out)
  - Damage and destruction feedback

### Save System

- Automatic state persistence
- Castle state serialization (scale, tower positions, integrity)
  - Difficulty and progression tracking
- Volume settings retention

---

## Technical Specifications

| Component | Specification |
|-----------|---------------|
| Runtime | Adobe AIR (Harman SDK 51.2.2) |
| Language | ActionScript 3.0 |
| Target FPS | 60 |
| Design Resolution | 16:9 Aspect Ratio |
| Minimum Android | API Level 21 (Android 5.0) |
| Windows Support | Windows 10 and above |

---

## Architecture

The application follows SOLID principles with the following module structure:

- **core/** - Constants, EventBus, ServiceLocator
- **castle/** - Castle state management, effects, tower system
- **game/** - Game controller, progression, state machine
- **generation/** - Question generation and sequence logic
- **services/** - Audio, save system, game settings
- **ui/** - All user interface components
- **config/** - Stimulus and visual configuration

---

## Known Limitations

- Large asset files (FLA, MP4) exceed GitHub recommended file size limits
- Debug flags are enabled in this build (DEBUG, SHOW_FPS, SHOW_MEMORY)

---

## Installation

### Android

1. Download the APK file from the releases page
2. Enable installation from unknown sources in device settings
3. Install the APK file
4. Launch Cognitive Castle from the application drawer

### Windows

1. Download the Windows installer or AIR package
2. Ensure Adobe AIR runtime is installed
3. Run the installer or AIR package
4. Launch Cognitive Castle from the Start Menu or Desktop shortcut

---

## Build Information

| Property | Value |
|----------|-------|
| Version | 1.0.0 |
| Build Number | 1 |
| Commit | 90bc77b |
| Branch | main |

---

## Credits

Developed by the Cognitive Castle Team.

For bug reports and feature requests, please open an issue on the GitHub repository.

---

## License

All rights reserved.
