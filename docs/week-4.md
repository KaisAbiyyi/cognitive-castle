# Week 4 – Production & Marketplace Ready Sprint 🚀

Branches:  
- `feature/production-polish/week-4`  
- `feature/deployment/week-4`

## 🎯 Scope Overview

Week 4 adalah **final sprint** untuk production-ready release:
- ✅ Performance Optimization & Profiling
- ✅ Full Localization (Multi-language)
- ✅ Accessibility Compliance (WCAG)
- ✅ Security Hardening
- ✅ Store Listing Assets
- ✅ APK & EXE Final Builds
- ✅ QA & Bug Bash
- ✅ Documentation Complete

**Target**: App siap publish ke Google Play & Windows Store!

---

## ⚡ PHASE 1: Optimization & Security ━ **KAIS** (Day 1-3)

**Owner: Kais** handles ALL performance, security, and build configuration.

### 1.1 Performance Profiling
- [ ] **T4-001**: Profile memory usage:
  - Identify memory leaks
  - Object lifecycle analysis
  - Peak usage mapping
- [ ] **T4-002**: Profile CPU usage:
  - Hot path identification
  - Frame time analysis
  - Bottleneck detection
- [ ] **T4-003**: Profile GPU/rendering:
  - Draw call optimization
  - Overdraw reduction
  - Batch rendering

### 1.2 Memory Optimization
- [ ] **T4-004**: Implement object pooling everywhere:
  - Particles
  - UI elements
  - Sound instances
- [ ] **T4-005**: Asset unloading:
  - Screen-based unloading
  - Theme asset swapping
  - Audio cleanup
- [ ] **T4-006**: Garbage collection optimization:
  - Reduce allocations in game loop
  - Reuse arrays/objects
  - Pre-allocate buffers
- [ ] **T4-007**: Memory budget:
  - Target: <150MB peak
  - Warning at 100MB
  - Force cleanup at 120MB

### 1.3 Rendering Optimization
- [ ] **T4-008**: Sprite batching:
  - Same texture batching
  - Reduce draw calls to <50
- [ ] **T4-009**: Particle optimization:
  - Particle count limits
  - LOD for particles
  - Pool recycling
- [ ] **T4-010**: UI optimization:
  - Flatten static containers
  - Cache complex shapes
  - Lazy rendering

### 1.4 Loading & Startup
- [ ] **T4-011**: Startup optimization:
  - Critical path first
  - Async asset loading
  - Target: <3 seconds cold start
- [ ] **T4-012**: Loading screen:
  - Progress indication
  - Tips/hints display
  - Smooth transitions
- [ ] **T4-013**: Level streaming (themes):
  - Load on demand
  - Preload next likely theme
  - Unload unused

### 1.5 Security Hardening
- [ ] **T4-014**: Save data security:
  - Enhanced encryption (AES)
  - Key obfuscation
  - Integrity validation
- [ ] **T4-015**: Anti-cheat measures:
  - Score validation
  - Time sanity checks
  - Session verification
- [ ] **T4-016**: Leaderboard security:
  - Server-side validation hooks
  - Rate limiting
  - Suspicious activity detection
- [ ] **T4-017**: Code protection:
  - Obfuscation (SWF Encrypt)
  - Anti-debugging (basic)
  - Tamper detection

### 1.6 Build Configuration
- [ ] **T4-018**: Release build settings:
  - Debug symbols stripped
  - Optimization flags
  - Minification
- [ ] **T4-019**: Platform configurations:
  - Android: target API 33+, min API 21
  - Windows: x64 only
  - Resolution handling
- [ ] **T4-020**: Certificate management:
  - Production keystore
  - Secure storage
  - Backup procedure
- [ ] **T4-021**: Version management:
  - Semantic versioning
  - Build number auto-increment
  - Version display in app

### 1.7 App Lifecycle
- [ ] **T4-022**: Android lifecycle:
  - onPause handling
  - onResume handling
  - Background limits
  - Task killer recovery
- [ ] **T4-023**: Windows lifecycle:
  - Minimize handling
  - Close confirmation
  - System tray option
- [ ] **T4-024**: Crash recovery:
  - State autosave
  - Graceful degradation
  - Crash reporting hooks

---

## 🌍 PHASE 2: Localization & Accessibility ━ **JARWO** (Day 2-4)

**Owner: Jarwo** handles ALL localization, accessibility, and compliance.

### 2.1 Localization Infrastructure
- [ ] **T4-025**: Implement `LocalizationManager`:
  ```actionscript
  class LocalizationManager {
    setLanguage(code: String): void
    getString(key: String): String
    getString(key: String, params: Object): String
    getAvailableLanguages(): Array
    getCurrentLanguage(): String
  }
  ```
- [ ] **T4-026**: String extraction:
  - All UI text to keys
  - All messages to keys
  - Tutorial content
  - Achievements
- [ ] **T4-027**: Localization file format (JSON)
- [ ] **T4-028**: Dynamic text sizing

### 2.2 Language Support
- [ ] **T4-029**: English (default)
- [ ] **T4-030**: Indonesian (Bahasa)
- [ ] **T4-031**: Spanish (Español)
- [ ] **T4-032**: German (Deutsch)
- [ ] **T4-033**: French (Français)
- [ ] **T4-034**: Japanese (日本語)
- [ ] **T4-035**: Korean (한국어)
- [ ] **T4-036**: Simplified Chinese (简体中文)
- [ ] **T4-037**: RTL support infrastructure (Arabic future)

### 2.3 Localization QA
- [ ] **T4-038**: Text overflow testing
- [ ] **T4-039**: Font compatibility
- [ ] **T4-040**: Number formatting
- [ ] **T4-041**: Date formatting
- [ ] **T4-042**: Pluralization rules

### 2.4 Accessibility - Visual
- [ ] **T4-043**: Color blind modes:
  - Deuteranopia (red-green)
  - Protanopia (red-green)
  - Tritanopia (blue-yellow)
- [ ] **T4-044**: High contrast mode
- [ ] **T4-045**: Adjustable font sizes (3 levels)
- [ ] **T4-046**: Reduce motion option
- [ ] **T4-047**: Screen reader labels (TalkBack/VoiceOver hooks)

### 2.5 Accessibility - Audio
- [ ] **T4-048**: Closed captions for audio stimuli
- [ ] **T4-049**: Visual indicators for all sounds
- [ ] **T4-050**: Volume normalization
- [ ] **T4-051**: Mono audio option

### 2.6 Accessibility - Motor
- [ ] **T4-052**: Adjustable touch targets (larger buttons)
- [ ] **T4-053**: Extended timeouts option
- [ ] **T4-054**: One-handed mode
- [ ] **T4-055**: External keyboard support

### 2.7 Privacy & Compliance
- [ ] **T4-056**: Privacy policy:
  - Data collection statement
  - Local-only data emphasis
  - Contact information
- [ ] **T4-057**: Terms of service
- [ ] **T4-058**: Age rating preparation:
  - ESRB: E (Everyone)
  - PEGI: 3
  - Content questionnaires
- [ ] **T4-059**: GDPR compliance (data export/delete)
- [ ] **T4-060**: COPPA considerations

### 2.8 Legal & Credits
- [ ] **T4-061**: Open source licenses:
  - List all libraries used
  - License text inclusion
  - Attribution
- [ ] **T4-062**: Credits screen:
  - Team members
  - Special thanks
  - Asset attributions
- [ ] **T4-063**: Copyright notices

---

## 🎨 PHASE 3: Store Assets & Final Polish ━ **NAZAR** (Day 3-6)

**Owner: Nazar** handles ALL store assets, final visuals, and marketing materials.

### 3.1 App Icons
- [ ] **T4-064**: Android icons:
  - Adaptive icon (foreground + background)
  - Legacy icons (48, 72, 96, 144, 192, 512)
  - Round icon variant
- [ ] **T4-065**: Windows icons:
  - ICO file (16, 32, 48, 256)
  - Tile images
- [ ] **T4-066**: Icon design:
  - Castle silhouette
  - Brain/cognitive element
  - Vibrant colors
  - Readable at small sizes

### 3.2 Splash Screen
- [ ] **T4-067**: Splash design:
  - Logo centered
  - Loading indicator
  - Version number
- [ ] **T4-068**: Splash sizes:
  - Portrait orientations
  - Landscape options
  - Tablet dimensions
- [ ] **T4-069**: Animated splash (optional)

### 3.3 Store Screenshots
- [ ] **T4-070**: Screenshot strategy:
  - Gameplay action shot
  - Castle building
  - Menu/dashboard
  - N-Back mode
  - Achievement unlock
- [ ] **T4-071**: Screenshot sizes:
  - Phone: 1080x1920
  - Tablet: 1600x2560
  - Feature graphic: 1024x500
- [ ] **T4-072**: Screenshot captions:
  - Localized text overlays
  - Call-to-action phrases
  - Feature highlights
- [ ] **T4-073**: 8+ screenshots per platform

### 3.4 Promotional Graphics
- [ ] **T4-074**: Feature graphic (Google Play)
- [ ] **T4-075**: Promo video (30-60 seconds):
  - Gameplay footage
  - Feature highlights
  - Castle progression
  - Call to action
- [ ] **T4-076**: Thumbnail for video
- [ ] **T4-077**: Banner ads (various sizes)

### 3.5 Store Listing Content
- [ ] **T4-078**: App name variants:
  - Full: "Cognitive Castle: Brain Training"
  - Short: "Cognitive Castle"
- [ ] **T4-079**: Short description (80 chars)
- [ ] **T4-080**: Full description (4000 chars):
  - Feature bullets
  - Gameplay explanation
  - Benefits
  - Call to action
- [ ] **T4-081**: Keywords/tags
- [ ] **T4-082**: Localized descriptions (8 languages)

### 3.6 Final UI Polish
- [ ] **T4-083**: Pixel-perfect alignment check
- [ ] **T4-084**: Animation timing review
- [ ] **T4-085**: Color consistency audit
- [ ] **T4-086**: Typography audit
- [ ] **T4-087**: Touch target size verification

### 3.7 Error States & Edge Cases
- [ ] **T4-088**: Empty state designs:
  - No achievements yet
  - No sessions yet
  - No save data
- [ ] **T4-089**: Error state designs:
  - Load failed
  - Save failed
  - Network error (if any)
- [ ] **T4-090**: Confirmation dialogs:
  - Delete save
  - Reset progress
  - Exit game

### 3.8 Visual Documentation
- [ ] **T4-091**: Style guide finalization
- [ ] **T4-092**: Asset inventory
- [ ] **T4-093**: Color palette documentation
- [ ] **T4-094**: Animation specifications

---

## 🔧 PHASE 4: QA & Deployment ━ **ALL TEAM** (Day 5-7)

**Shared responsibility** for final testing and release.

### 4.1 Test Matrix (Kais)
- [ ] **T4-095**: Test case documentation:
  - Core gameplay (50+ cases)
  - Castle system (30+ cases)
  - Siege mechanics (20+ cases)
  - Save/load (15+ cases)
  - N-Back modes (20+ cases)
  - Settings (10+ cases)
- [ ] **T4-096**: Device matrix:
  - Android: 5 devices (low/mid/high)
  - Windows: 2 configurations
  - Screen sizes: phone, tablet, desktop
- [ ] **T4-097**: Automated test scripts (if time)

### 4.2 Bug Bash (All)
- [ ] **T4-098**: Bug tracking setup:
  - Issue template
  - Severity levels
  - Assignment process
- [ ] **T4-099**: 4-hour bug bash session
- [ ] **T4-100**: Bug triage & prioritization
- [ ] **T4-101**: Critical bug fixes
- [ ] **T4-102**: Regression testing

### 4.3 Performance Testing (Jarwo)
- [ ] **T4-103**: Long session test (1 hour continuous)
- [ ] **T4-104**: Memory leak verification
- [ ] **T4-105**: Battery usage testing (Android)
- [ ] **T4-106**: Low-end device testing
- [ ] **T4-107**: Frame rate logging

### 4.4 Build Process (Kais)
- [ ] **T4-108**: Android APK build:
  - Release keystore signing
  - ProGuard/R8 configuration
  - APK size optimization (<50MB target)
- [ ] **T4-109**: Android App Bundle (AAB):
  - Split APKs
  - Play Asset Delivery (if needed)
- [ ] **T4-110**: Windows EXE build:
  - Installer creation
  - Self-contained runtime
  - Portable option
- [ ] **T4-111**: Build verification:
  - Install from scratch
  - Upgrade from previous version
  - Fresh vs existing save

### 4.5 Store Submission (Nazar)
- [ ] **T4-112**: Google Play Console:
  - App creation
  - Asset upload
  - Content rating
  - Target audience
  - Internal testing track
- [ ] **T4-113**: Microsoft Store:
  - App submission
  - Age rating
  - Category selection
- [ ] **T4-114**: Review preparation:
  - Test accounts
  - Demo instructions
  - Known issues list

### 4.6 Launch Preparation (All)
- [ ] **T4-115**: Version 1.0.0 tagging
- [ ] **T4-116**: Release notes:
  - Feature list
  - Known issues
  - Support contact
- [ ] **T4-117**: Support documentation:
  - FAQ
  - Troubleshooting guide
  - Contact method

### 4.7 Documentation (All)
- [ ] **T4-118**: README finalization:
  - Project overview
  - Build instructions
  - Architecture summary
- [ ] **T4-119**: CHANGELOG creation
- [ ] **T4-120**: Developer documentation:
  - Code structure
  - Key classes
  - Extension points
- [ ] **T4-121**: User manual (basic)

### 4.8 Post-Launch Preparation
- [ ] **T4-122**: Analytics dashboard setup
- [ ] **T4-123**: Crash reporting integration
- [ ] **T4-124**: Feedback collection method
- [ ] **T4-125**: Update roadmap (v1.1+)

---

## 📋 Week 4 Deliverables

| Feature | Owner | Target |
|---------|-------|--------|
| Performance optimization | Kais | ✅ |
| Security hardening | Kais | ✅ |
| Release build config | Kais | ✅ |
| App lifecycle handling | Kais | ✅ |
| 8 language support | Jarwo | ✅ |
| Accessibility compliance | Jarwo | ✅ |
| Privacy policy & ToS | Jarwo | ✅ |
| Legal compliance | Jarwo | ✅ |
| App icons (all sizes) | Nazar | ✅ |
| Store screenshots (8+) | Nazar | ✅ |
| Promo video | Nazar | ✅ |
| Store descriptions | Nazar | ✅ |
| Test case documentation | Kais | ✅ |
| Bug bash completion | All | ✅ |
| Final APK build | Kais | ✅ |
| Final EXE build | Kais | ✅ |
| Store submission | Nazar | ✅ |
| Documentation complete | All | ✅ |

---

## 📊 Release Criteria

### Must Have (P0)
- [ ] Zero critical bugs
- [ ] 60 FPS on mid-range devices
- [ ] <3 second cold start
- [ ] <50MB APK size
- [ ] All core features functional
- [ ] Save/load working perfectly
- [ ] No memory leaks
- [ ] 2+ languages

### Should Have (P1)
- [ ] All 8 languages
- [ ] All accessibility features
- [ ] Promo video ready
- [ ] All store assets polished

### Nice to Have (P2)
- [ ] Additional themes unlockable
- [ ] Social sharing working
- [ ] Cloud leaderboards active

---

## 🚀 Launch Checklist

```
[ ] All code reviewed and merged
[ ] Version 1.0.0 tagged
[ ] APK signed with production key
[ ] EXE installer tested
[ ] Store listings complete (all languages)
[ ] Screenshots uploaded
[ ] Promo video uploaded
[ ] Privacy policy URL live
[ ] Support email active
[ ] Internal testing passed
[ ] Store submission complete
[ ] Launch announcement prepared
```

---

## 📅 Post-Launch Plan (v1.1+)

- Week 5: Bug fixes from user feedback
- Week 6: Multiplayer foundation
- Week 7: Cloud sync implementation
- Week 8: Social features (friends, challenges)
- Future: VR mode exploration
