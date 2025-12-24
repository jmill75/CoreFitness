# Fitness iOS App - Project Requirements

> **Goal:** Build a AAA-quality fitness app with recurring monthly subscriptions that feels premium, immersive, and comprehensive.

---

## Design & UX Principles

### Visual Identity
- [ ] Clean, professional app icons
- [ ] Dark mode support
- [ ] Light mode support
- [ ] Theme options:
  - [ ] Masculine color palette
  - [ ] Feminine color palette

### Haptics
- [ ] Light haptics for subtle interactions
- [ ] Medium haptics for confirmations
- [ ] Hard haptics for important actions
- Premium, immersive feel throughout

### Animations
- [ ] Loading/calculating data animations
- [ ] Progress celebration animations
- [ ] Welcome/greeting animations
- [ ] Screen transition animations
- [ ] Typing animations
- [ ] Section-specific micro-animations

---

## Navigation Structure

**Nav Bar:** Apple Liquid Glass style (reference: Athlytic Fitness app)

| Tab | Purpose |
|-----|---------|
| Home | Dashboard, calendar, daily overview |
| Programs | Saved workouts, current program, stats |
| Health | Metrics, scores, tracking |
| Settings | User preferences, app configuration |

---

## Home Screen

### Layout (top to bottom)
1. **Welcome Section** - Personalized greeting with user info
2. **Calendar View** - Shows daily Overall Score for tracking
3. **Daily Overview** - Key metrics at a glance
4. **+ Button** - Opens daily check-in screen

### Daily Check-In Screen (via + button)
- [ ] Mood check-in
- [ ] Soreness level
- [ ] Stress level
- [ ] Sick/skipping workout toggle
- [ ] Additional health metrics

---

## Core Features

### Overall Score System
Aggregates all metrics into a single daily UI score:
- [ ] User-answered questions (mood, stress, soreness, etc.)
- [ ] Apple Health data:
  - [ ] HRV (Heart Rate Variability)
  - [ ] Sleep data
  - [ ] Resting heart rate
  - [ ] Recovery metrics
- [ ] All data saved to database
- [ ] Calendar view showing scores by day/week/month

### Health & Metrics Tracking
- [ ] Mood tracker
- [ ] Water intake tracker
- [ ] Stress levels
- [ ] Soreness levels
- [ ] Sleep quality
- [ ] Recovery status
- [ ] Food tracker *(Coming Soon)*

### Workout Features
- [ ] Easy-to-use workout screen
- [ ] Workout timer
- [ ] Stats tracking:
  - [ ] Date
  - [ ] Start time
  - [ ] End time
  - [ ] Weekday vs weekend
  - [ ] Duration
- [ ] Support for:
  - [ ] Gym workouts
  - [ ] Home workouts
  - [ ] Treadmill
  - [ ] Outdoor runs
  - [ ] Custom workouts
- [ ] Create workouts from predefined database with filters:
  - [ ] Beginner / Intermediate / Advanced
  - [ ] Gym / Home
  - [ ] Running / Treadmill
- [ ] Rep and weight entry
- [ ] Location tracking for workouts
- [ ] Partner workout support (share with non-app users)

---

## AI Workout Creation (Gemini)

### How It Works
1. User answers guided questions to build their workout prompt
2. Prompt is sent to Gemini API
3. Gemini generates personalized workout program
4. Program is returned and saved to user's Programs

### Question Flow (Prompt Builder)
- [ ] Fitness goal (strength, weight loss, endurance, etc.)
- [ ] Experience level
- [ ] Available equipment
- [ ] Workout frequency (days per week)
- [ ] Session duration preference
- [ ] Any injuries or limitations
- [ ] Focus areas (upper body, lower body, full body, etc.)
- [ ] *Additional questions TBD*

### AI Program Rules
- [ ] All AI-created workouts saved in Programs section
- [ ] **Only ONE program can be active at any time**
- [ ] User can switch active program anytime
- [ ] AI programs stored in database with metadata

### AI Generation Limits (by Subscription)

| Tier | AI Generations | Reset |
|------|----------------|-------|
| Free | 1 per week | Weekly |
| Basic | 3 per week | Weekly |
| Premium | Unlimited (max 3/day) | Daily |

- [ ] Track generation count per user in Firebase
- [ ] Display remaining generations in UI
- [ ] Show upgrade prompt when limit reached
- [ ] Fallback: Offer pre-made programs if limit hit

---

## Quick Workouts

> One-off workouts that **do not affect** the current active program.

### Purpose
- Fast workout selection based on immediate goal
- No commitment to full program
- Flexible for busy days or supplemental training

### Quick Workout Options
- [ ] Goal-based selection (burn calories, build strength, stretch, etc.)
- [ ] Time-based options (15 min, 30 min, 45 min, 60 min)
- [ ] Equipment filters (bodyweight, dumbbells, full gym, etc.)
- [ ] Intensity levels (light, moderate, intense)
- [ ] Muscle group focus

### Tracking
- [ ] Quick workouts logged in history
- [ ] Marked separately from program workouts
- [ ] Still count toward daily activity/Overall Score

---

## Exercise Library

> Complete database of **all available exercises** (hundreds)

### Library Features
- [ ] Browsable list of 100s of exercises
- [ ] Search functionality
- [ ] Filter by:
  - [ ] Muscle group (chest, back, legs, shoulders, arms, core)
  - [ ] Equipment (barbell, dumbbell, cable, machine, bodyweight)
  - [ ] Difficulty (beginner, intermediate, advanced)
  - [ ] Movement type (push, pull, squat, hinge, carry)
  - [ ] Location (gym, home)
- [ ] Each exercise includes:
  - [ ] Name
  - [ ] Description / instructions
  - [ ] Primary muscles worked
  - [ ] Secondary muscles worked
  - [ ] Video demonstration *(optional/future)*
  - [ ] Image/animation
  - [ ] Tips for proper form

### Exercise Data Source
- [ ] Predefined database (server-side)
- [ ] Regularly updated with new exercises
- [ ] Used by AI workout generation
- [ ] Used by manual workout creation

---

## Programs Tab

- [ ] User's saved workouts (database-stored)
- [ ] **AI-generated programs section**
- [ ] Current active program *(only one at a time)*
- [ ] Program stats:
  - [ ] Current day in program
  - [ ] Today's workout
  - [ ] Next workout preview
- [ ] Effort recommendation based on Overall Score
- [ ] Quick access to Quick Workouts
- [ ] Link to Exercise Library

---

## Progress Tab

- [ ] Workout history
- [ ] Overall Score trends (increasing/decreasing)
- [ ] Personal Records (PRs) for exercises
- [ ] Progress selfies attached to daily data

---

## Settings Tab

### Layout
1. **User Info Card** (top section)
2. **App Settings** (below)

### Settings Options
- [ ] Theme selection
- [ ] Rest timer duration
- [ ] Units: lbs / kg
- [ ] Haptics: on / off
- [ ] Sounds: on / off
- [ ] Notification preferences

---

## Social & Sharing

- [ ] Beautiful UI for sharing updates
- [ ] Share to friends and family
- [ ] Referral links for app download
- [ ] Referral discount for successful signups
- [ ] Send workout/program to partner (non-app users)
- [ ] Progress selfies (privacy-controlled sharing)

---

## Platform Integrations

### Apple Ecosystem
- [ ] Apple Sign-In
- [ ] Apple Health integration
- [ ] iOS Home Screen widgets
- [ ] Live Activities (match Watch view)
- [ ] Siri commands
- [ ] Apple Watch app:
  - [ ] Current workout display
  - [ ] Workout timer
  - [ ] Heart rate
  - [ ] Breathing
  - [ ] Rep/weight entry
  - [ ] Music controls

### Google
- [ ] Google Sign-In

### Music
- [ ] Music control from app
- [ ] Music control from Watch

---

## Notifications

- [ ] Daily reminders
- [ ] Weekly summaries
- [ ] End of month summaries
- [ ] Custom notification types

---

## Monetization & Access Control

### Subscription Tiers

| Feature | Free | Basic | Premium |
|---------|------|-------|---------|
| **Price** | $0 | $X.XX/mo | $X.XX/mo |
| AI Workout Generation | 1/week | 3/week | Unlimited (3/day) |
| Quick Workouts | Limited | Full Access | Full Access |
| Exercise Library | View Only | Full Access | Full Access |
| Health Tracking | Basic | Full | Full |
| Apple Watch | No | Yes | Yes |
| Widgets | No | Yes | Yes |
| Progress Photos | 5 max | Unlimited | Unlimited |
| Partner Sharing | No | Yes | Yes |
| Detailed Analytics | No | Basic | Advanced |
| Themes | 2 | All | All |
| Ads | Yes | No | No |

### Subscription Features
- [ ] Recurring monthly subscription via App Store
- [ ] Feature flags (Firebase Remote Config)
- [ ] Promo codes support
- [ ] Feature gating based on subscription level
- [ ] User testing feature toggles
- [ ] Graceful downgrade (keep data, limit features)

### Referral Program
- [ ] Shareable referral links
- [ ] Discount for successful referrals
- [ ] Track referrals in Firebase

---

## Rewards & Achievements

Tiered difficulty system:
- [ ] **Easy:** First daily health log, etc.
- [ ] **Medium:** Consistency streaks, etc.
- [ ] **Hard:** Long-term goals, PRs, etc.

---

## Interactive Avatar

- [ ] Personable app companion
- [ ] Enhances user engagement
- [ ] *Details TBD*

---

## Coming Soon

- [ ] **Food Tracker** - Future update
- [ ] **Onboarding Flow:**
  - All info visible without scrolling on first page
  - Clear value proposition
  - Drive subscription conversion

---

## Tech Stack

### Core Technologies

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Platform** | iOS (Swift/SwiftUI) | Native iOS app |
| **Database** | Firebase (Firestore) | Cloud database, realtime sync |
| **Auth** | Firebase Auth | Apple Sign-In, Google Sign-In |
| **AI** | Gemini API | AI workout generation |
| **Health** | HealthKit | Apple Health integration |
| **Watch** | WatchKit / WatchOS | Apple Watch companion app |
| **Notifications** | Firebase Cloud Messaging | Push notifications |
| **Analytics** | Firebase Analytics | User behavior tracking |
| **Storage** | Firebase Storage | Progress photos, media |
| **Remote Config** | Firebase Remote Config | Feature flags, A/B testing |

### Firebase Services (Free Tier)

| Service | Free Limit | Our Usage |
|---------|------------|-----------|
| Firestore | 1GB storage, 50K reads/day, 20K writes/day | User data, workouts, programs |
| Auth | Unlimited users | Apple/Google Sign-In |
| Storage | 5GB | Progress selfies |
| Cloud Messaging | Unlimited | Push notifications |
| Remote Config | Unlimited | Feature flags |
| Analytics | Unlimited | Usage tracking |

### Database Collections (Firestore)

```
/users/{userId}
  - profile info
  - settings
  - subscription tier
  - ai_generations_count
  - ai_generation_reset_date

/users/{userId}/daily_checkins/{date}
  - mood, stress, soreness
  - overall_score
  - health_data (from HealthKit)
  - selfie_url (optional)

/users/{userId}/programs/{programId}
  - program_name
  - created_by (ai | manual | premade)
  - is_active (only one true)
  - workouts[]
  - current_day
  - created_at

/users/{userId}/workout_history/{workoutId}
  - date, start_time, end_time
  - exercises performed
  - is_quick_workout (bool)
  - program_id (if part of program)

/users/{userId}/personal_records/{exerciseId}
  - exercise_name
  - best_weight
  - best_reps
  - date_achieved

/exercises (global collection)
  - 100s of exercises
  - name, description, muscles, equipment
  - difficulty, movement_type

/premade_programs (global collection)
  - Pre-built workout programs
  - Fallback when AI limit reached
```

### API Integration

**Gemini API Flow:**
```
User Answers → Build Prompt → Gemini API → Parse Response → Save to Firestore
```

- [ ] Gemini API key stored securely (not in client)
- [ ] Use Firebase Cloud Functions to call Gemini (keeps API key server-side)
- [ ] Rate limiting handled at function level
- [ ] Response parsed into structured workout format

### Data Philosophy
- Highly data-driven backend
- Simple, intuitive user experience
- All user data synced to cloud
- Offline support for active workout
- Extended thinking for each section during development

---

## Development Process

> **Note:** Ask clarifying questions at each step to ensure precision.

- [ ] Each section requires thorough planning
- [ ] This document will evolve as development progresses
- [ ] Feature prioritization TBD

---

*Last Updated: December 22, 2025 - v3 (Added Firebase tech stack, subscription tiers, AI limits, database schema)*
