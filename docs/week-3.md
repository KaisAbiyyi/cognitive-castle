# Week 3 – Advanced Modes & Social Features Sprint 🌟

Branches:  
- `feature/advanced-modes/week-3`  
- `feature/social-features/week-3`

## 🎯 Scope Overview

Week 3 fokus pada **advanced gameplay** dan **social/competitive features**:
- ✅ N-Back Challenge Mode
- ✅ Dual N-Back (Audio + Visual)
- ✅ Daily Challenges System
- ✅ Leaderboard System (Local + Cloud)
- ✅ Statistics Dashboard
- ✅ Progress Analytics & Graphs
- ✅ Share/Export Features
- ✅ Customization Options

**Target**: Full-featured cognitive training app dengan competitive elements!

---

## 🧠 PHASE 1: Advanced Game Modes ━ **KAIS** (Day 1-4)

**Owner: Kais** handles ALL advanced mode logic and implementations.

### 1.1 N-Back Mode Architecture
- [ ] **T3-001**: Design N-Back configuration:
  ```actionscript
  class NBackConfig {
    nLevel: int,           // 1, 2, 3, etc.
    targetType: String,    // "position", "audio", "dual"
    sequenceLength: int,   // Total items in session
    targetPercentage: Number,  // 20-30% targets
    responseWindow: int,   // ms to respond
    feedbackType: String   // "immediate", "delayed", "none"
  }
  ```
- [ ] **T3-002**: Implement `NBackGenerator`:
  - Guaranteed target distribution
  - Lure prevention (N-1, N+1 distractors)
  - Balanced non-target spacing
- [ ] **T3-003**: Implement `NBackValidator`:
  - Hit detection
  - Miss detection
  - False alarm tracking
  - D-prime calculation

### 1.2 Visual N-Back
- [ ] **T3-004**: Implement position-based N-Back:
  - 3x3 grid
  - Single position highlight
  - "Match if same position as N items ago"
- [ ] **T3-005**: Implement color N-Back:
  - Center stimulus
  - Color matching
- [ ] **T3-006**: Implement shape N-Back:
  - Center stimulus
  - Shape matching
- [ ] **T3-007**: Response mechanics:
  - Tap/click when match detected
  - No action when no match
  - Response timing tracking

### 1.3 Audio N-Back
- [ ] **T3-008**: Design audio stimulus set:
  - 8 distinct phonemes/sounds
  - Clear discrimination
  - Consistent volume
- [ ] **T3-009**: Implement audio playback:
  - Precise timing
  - No overlap
  - Volume normalization
- [ ] **T3-010**: Audio match detection

### 1.4 Dual N-Back (Ultimate Challenge)
- [ ] **T3-011**: Combine visual + audio:
  - Simultaneous presentation
  - Independent matching
  - Two response buttons
- [ ] **T3-012**: Implement dual response:
  - "Position Match" button
  - "Audio Match" button
  - Both can be pressed same trial
- [ ] **T3-013**: Dual scoring:
  - Visual accuracy
  - Audio accuracy
  - Combined score
  - D-prime per modality
- [ ] **T3-014**: Adaptive dual N-Back:
  - Independent N level per modality
  - Level up when >80% both
  - Level down when <60% either

### 1.5 Daily Challenges
- [ ] **T3-015**: Design daily challenge system:
  ```actionscript
  class DailyChallenge {
    date: String,          // YYYY-MM-DD
    seed: int,             // For reproducible generation
    mode: String,          // Random mode selection
    difficulty: int,       // Fixed difficulty
    target: Object,        // Goal to achieve
    rewards: Array,        // Bonus for completion
    leaderboardId: String
  }
  ```
- [ ] **T3-016**: Daily challenge generation:
  - Deterministic from date seed
  - Variety of modes
  - Escalating weekly difficulty
- [ ] **T3-017**: Challenge types:
  - "Perfect 10" (10 correct in a row)
  - "Speed Run" (complete 20 trials in X time)
  - "Endurance" (maintain 80% for 50 trials)
  - "N-Back Master" (reach N=3 in session)
  - "Castle Builder" (build 5 parts in session)
- [ ] **T3-018**: Daily reward system:
  - Streak bonuses (7 days, 30 days)
  - Exclusive theme unlocks
  - Achievement integration

### 1.6 Endless Mode
- [ ] **T3-019**: Implement endless gameplay:
  - No session limit
  - Progressive difficulty
  - Life system (3 strikes)
- [ ] **T3-020**: Endless scoring:
  - Cumulative score
  - Milestone bonuses
  - Distance tracking
- [ ] **T3-021**: Endless-specific achievements

### 1.7 Training Programs
- [ ] **T3-022**: Design training program:
  ```actionscript
  class TrainingProgram {
    id: String,
    name: String,
    description: String,
    duration: int,        // Days
    schedule: Array,      // Daily tasks
    targetImprovement: Object,
    completionReward: Object
  }
  ```
- [ ] **T3-023**: Pre-built programs:
  - "Working Memory Boost" (2 weeks)
  - "Focus Training" (1 week)
  - "N-Back Mastery" (3 weeks)
- [ ] **T3-024**: Program progress tracking
- [ ] **T3-025**: Program completion certificates

---

## 📊 PHASE 2: Analytics & Statistics ━ **JARWO** (Day 2-5)

**Owner: Jarwo** handles ALL analytics, data processing, and exports.

### 2.1 Analytics Engine
- [ ] **T3-026**: Implement `AnalyticsManager`:
  ```actionscript
  class AnalyticsManager {
    // Data collection
    trackEvent(event: String, data: Object): void
    trackSession(sessionData: SessionData): void
    
    // Aggregation
    getDailyStats(date: String): DayStats
    getWeeklyStats(): WeekStats
    getMonthlyStats(): MonthStats
    getAllTimeStats(): AllTimeStats
    
    // Trends
    getAccuracyTrend(days: int): Array
    getReactionTimeTrend(days: int): Array
    getStreakTrend(days: int): Array
    getNBackProgress(): Array
  }
  ```
- [ ] **T3-027**: Session data structure:
  ```actionscript
  class SessionData {
    id: String,
    startTime: Number,
    endTime: Number,
    duration: Number,
    mode: String,
    trialsCompleted: int,
    trialsCorrect: int,
    accuracy: Number,
    averageReactionTime: Number,
    bestReactionTime: Number,
    worstReactionTime: Number,
    streakMax: int,
    nBackLevel: int,
    castlePartsBuilt: int,
    siegesSurvived: int,
    achievementsUnlocked: Array
  }
  ```
- [ ] **T3-028**: Aggregate calculations
- [ ] **T3-029**: Trend analysis algorithms

### 2.2 Leaderboard System
- [ ] **T3-030**: Design leaderboard structure:
  ```actionscript
  class LeaderboardEntry {
    rank: int,
    playerId: String,
    playerName: String,
    score: int,
    date: Number,
    mode: String,
    verified: Boolean
  }
  ```
- [ ] **T3-031**: Local leaderboards:
  - Personal best per mode
  - Daily high scores
  - All-time high scores
- [ ] **T3-032**: Leaderboard categories:
  - Highest single score
  - Best accuracy
  - Fastest average reaction
  - Longest streak
  - Highest N-Back level
  - Largest castle
- [ ] **T3-033**: Cloud leaderboard integration (optional):
  - Anonymous submission
  - Regional boards
  - Friend boards (future)

### 2.3 Progress Tracking
- [ ] **T3-034**: Daily summary generation:
  - Sessions played
  - Total time
  - Accuracy average
  - Improvement vs yesterday
- [ ] **T3-035**: Weekly report:
  - Day-by-day breakdown
  - Best day
  - Areas for improvement
- [ ] **T3-036**: Monthly report:
  - Progress graphs
  - Milestones reached
  - Comparison to previous month
- [ ] **T3-037**: Cognitive performance indicators:
  - Working memory span
  - Processing speed
  - Attention consistency
  - Improvement rate

### 2.4 Data Visualization
- [ ] **T3-038**: Chart components:
  - Line chart (trends)
  - Bar chart (comparisons)
  - Pie chart (mode distribution)
  - Heat map (activity calendar)
- [ ] **T3-039**: Interactive graphs:
  - Zoom/pan
  - Tooltips
  - Time range selection
- [ ] **T3-040**: Performance sparklines (mini graphs)

### 2.5 Export & Share
- [ ] **T3-041**: Export formats:
  - CSV (raw data)
  - JSON (structured)
  - PDF report (formatted)
- [ ] **T3-042**: Share functionality:
  - Share score card image
  - Share achievement
  - Share progress summary
- [ ] **T3-043**: Social integration hooks (future):
  - Twitter/X
  - Facebook
  - Instagram Stories

### 2.6 Notifications & Reminders
- [ ] **T3-044**: Reminder system:
  - Daily training reminder
  - Streak protection alert
  - Weekly summary notification
- [ ] **T3-045**: In-app notifications:
  - New daily challenge
  - Friend beat your score (future)
  - Achievement near completion
- [ ] **T3-046**: Notification preferences

---

## 🎨 PHASE 3: Dashboard & Customization ━ **NAZAR** (Day 3-7)

**Owner: Nazar** handles ALL dashboard UI, customization, and presentation.

### 3.1 Statistics Dashboard
- [ ] **T3-047**: Dashboard layout:
  - Today's summary card
  - Quick stats row
  - Performance graphs
  - Recent sessions list
  - Achievements showcase
- [ ] **T3-048**: Summary cards:
  - Total sessions
  - Accuracy trend (↑↓)
  - Current streak
  - Best scores
- [ ] **T3-049**: Interactive elements:
  - Tap to drill down
  - Swipe between views
  - Pull to refresh

### 3.2 Graphs & Visualizations
- [ ] **T3-050**: Accuracy over time graph:
  - 7-day default view
  - 30-day option
  - Goal line overlay
- [ ] **T3-051**: Reaction time graph:
  - Average per session
  - Best times highlighted
- [ ] **T3-052**: Activity heat map:
  - Calendar view
  - Color intensity = activity
  - Streak visualization
- [ ] **T3-053**: N-Back progress chart:
  - Level over time
  - Per-modality breakdown
- [ ] **T3-054**: Castle growth timeline

### 3.3 Leaderboard UI
- [ ] **T3-055**: Leaderboard screen:
  - Tab for each category
  - Highlight player position
  - Scroll to view more
- [ ] **T3-056**: Entry display:
  - Rank badge (🥇🥈🥉)
  - Player name
  - Score
  - Date achieved
- [ ] **T3-057**: Personal best indicators
- [ ] **T3-058**: Daily challenge leaderboard

### 3.4 Customization System
- [ ] **T3-059**: Avatar system:
  - 20+ avatar options
  - Unlock through achievements
  - Custom color options
- [ ] **T3-060**: Castle customization:
  - Banner/flag colors
  - Decoration placement
  - Name your castle
- [ ] **T3-061**: UI themes:
  - Light mode
  - Dark mode
  - OLED black
  - High contrast (accessibility)
- [ ] **T3-062**: Font size options

### 3.5 N-Back Mode UI
- [ ] **T3-063**: N-Back game screen:
  - 3x3 grid (visual)
  - Clear audio indicator
  - Response buttons
  - N-level display
- [ ] **T3-064**: Dual N-Back layout:
  - Split screen design
  - Two response zones
  - Combined score display
- [ ] **T3-065**: N-Back feedback:
  - Hit indicator
  - Miss indicator
  - False alarm indicator
- [ ] **T3-066**: N-Back results screen:
  - D-prime score
  - Hit rate
  - False alarm rate
  - Performance breakdown

### 3.6 Daily Challenge UI
- [ ] **T3-067**: Challenge hub:
  - Today's challenge card
  - Streak counter
  - Reward preview
- [ ] **T3-068**: Challenge complete screen:
  - Score vs target
  - Rank on leaderboard
  - Reward granted
- [ ] **T3-069**: Streak celebration:
  - Special animation at 7/30 days
  - Bonus reward display

### 3.7 Training Program UI
- [ ] **T3-070**: Program browser:
  - Program cards
  - Duration/difficulty
  - Start button
- [ ] **T3-071**: Active program display:
  - Today's task
  - Progress bar
  - Days remaining
- [ ] **T3-072**: Program completion:
  - Certificate display
  - Share option
  - Next program suggestion

### 3.8 Export & Share UI
- [ ] **T3-073**: Export screen:
  - Format selection
  - Date range picker
  - Preview
  - Export button
- [ ] **T3-074**: Share card generator:
  - Score card template
  - Achievement card template
  - Progress summary template
- [ ] **T3-075**: Share preview & confirmation

### 3.9 Polish & Testing
- [ ] **T3-076**: Dashboard performance
- [ ] **T3-077**: Graph rendering optimization
- [ ] **T3-078**: Customization persistence
- [ ] **T3-079**: Visual documentation update

---

## 📋 Week 3 Deliverables

| Feature | Owner | Target |
|---------|-------|--------|
| Visual N-Back (position, color, shape) | Kais | ✅ |
| Audio N-Back | Kais | ✅ |
| Dual N-Back | Kais | ✅ |
| Daily challenge system | Kais | ✅ |
| Endless mode | Kais | ✅ |
| Training programs | Kais | ✅ |
| Analytics engine | Jarwo | ✅ |
| Leaderboard system | Jarwo | ✅ |
| Progress tracking | Jarwo | ✅ |
| Data visualization | Jarwo | ✅ |
| Export/share features | Jarwo | ✅ |
| Statistics dashboard | Nazar | ✅ |
| Leaderboard UI | Nazar | ✅ |
| Customization system | Nazar | ✅ |
| N-Back mode UI | Nazar | ✅ |
| Share card generator | Nazar | ✅ |

---

## 📊 Success Criteria

- **N-Back**: All 3 types (visual, audio, dual) functional
- **Daily Challenges**: New challenge every day, reproducible
- **Leaderboards**: 6+ categories, proper sorting
- **Analytics**: 30+ days of data visualization
- **Export**: CSV, JSON, and shareable image working
- **Customization**: 20+ avatars, 4+ UI themes
- **Performance**: Dashboard loads in under 1 second
