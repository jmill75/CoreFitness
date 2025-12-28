# Core Fitness - Exercise Database Integration

Complete exercise database integration for your iOS fitness app with **1,300+ exercises**, **animated GIFs**, and **video support**.

## 📦 What's Included

```
CoreFitnessExercises/
├── Models/
│   └── Exercise.swift          # Core data models
├── Services/
│   └── ExerciseService.swift   # API & data loading service
├── Views/
│   └── ExerciseViews.swift     # SwiftUI views matching your app
└── Data/
    └── exercises.json          # 30 sample exercises
```

## 🎬 Data Sources with Video/GIF Support

### Option 1: ExerciseDB API (Recommended)

**1,300+ exercises with animated GIFs**

```swift
// In your app, load from ExerciseDB API
let service = ExerciseService()

// Using RapidAPI (requires API key)
await service.loadFromExerciseDB(apiKey: "YOUR_RAPIDAPI_KEY")

// Or self-host the free V1 API (see below)
await service.loadFromURL("https://your-api.vercel.app/api/v1/exercises")
```

**Get a free API key:**
1. Go to https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb
2. Sign up for free tier (500 requests/month)
3. Copy your API key

### Option 2: Self-Host ExerciseDB V1 (Free, Unlimited)

Deploy your own API in 1 click:

1. Go to https://github.com/ExerciseDB/exercisedb-api
2. Click "Deploy to Vercel" button
3. Your API will be at: `https://your-app.vercel.app/api/v1/exercises`

### Option 3: Bundle Locally

Include the JSON data in your app bundle for offline access:

```swift
await service.loadFromBundle()
```

## 🏋️ Exercise Data Structure

Each exercise includes:

```json
{
  "id": "0025",
  "name": "Barbell Bench Press",
  "bodyPart": "chest",
  "equipment": "barbell",
  "target": "pectorals",
  "secondaryMuscles": ["triceps", "shoulders"],
  "instructions": ["Step 1...", "Step 2..."],
  "gifUrl": "https://v2.exercisedb.io/image/GiQSHxYRwL-Vex"
}
```

## 📱 Category Mapping

Your app categories map to the database:

| App Category | Database Mapping |
|--------------|------------------|
| **Strength** | Most exercises with weights |
| **Cardio** | `bodyPart: "cardio"` |
| **Calisthenics** | `equipment: "body weight"` |
| **HIIT** | Cardio + plyometric exercises |
| **Stretching** | Stretching-focused exercises |
| **Yoga** | Body weight + flexibility |
| **Pilates** | Stability ball exercises |

## 🎨 UI Components

### Category Browse (Grid View)
```swift
ExerciseBrowseView()
```
Displays colorful category cards with exercise counts.

### Exercise List
```swift
ExerciseListView(category: .strength, exercises: exercises)
```
Filtered list with favorites, difficulty badges, and search.

### Exercise Detail
```swift
ExerciseDetailView(exercise: exercise)
```
Full exercise view with animated GIF and instructions.

## 🔍 Search & Filter

```swift
// Search by name
let results = service.search(query: "bench press")

// Filter by multiple criteria
let filtered = service.filter(
    category: .strength,
    bodyPart: .chest,
    equipment: .barbell,
    difficulty: .intermediate
)

// Get exercises for specific muscle
let chestExercises = service.exercises(targetingMuscle: "pectorals")
```

## 📊 Available Data

### Body Parts (10)
- back, cardio, chest, lower arms, lower legs
- neck, shoulders, upper arms, upper legs, waist

### Equipment (25+)
- body weight, barbell, dumbbell, cable, machine
- kettlebell, resistance band, medicine ball, etc.

### Difficulty Levels
- Beginner, Intermediate, Advanced

## 🚀 Quick Start

1. **Add files to your Xcode project**

2. **Add exercises.json to your bundle**
   - Drag to Xcode
   - Check "Copy items if needed"
   - Add to target

3. **Load exercises in your app**

```swift
import SwiftUI

@main
struct CoreFitnessApp: App {
    @StateObject private var exerciseService = ExerciseService()
    
    var body: some Scene {
        WindowGroup {
            ExerciseBrowseView()
                .environmentObject(exerciseService)
                .task {
                    await exerciseService.loadFromBundle()
                }
        }
    }
}
```

## 🖼️ GIF/Video Display

The `gifUrl` field contains animated GIFs showing exercise movement:

```swift
// Using AsyncImage (iOS 15+)
AsyncImage(url: URL(string: exercise.gifUrl)) { image in
    image.resizable().aspectRatio(contentMode: .fit)
} placeholder: {
    ProgressView()
}

// For better GIF support, use SDWebImageSwiftUI:
// import SDWebImageSwiftUI
// AnimatedImage(url: URL(string: exercise.gifUrl))
```

## 📦 Recommended Dependencies

For smooth GIF playback, add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.0.0")
]
```

## 🔄 Syncing Full Database

To get the complete 1,300+ exercise database:

```swift
// Option 1: Download once and cache
func downloadFullDatabase() async {
    let url = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"
    await service.loadFromURL(url)
    
    // Save to documents for offline use
    saveToDocuments(service.exercises)
}

// Option 2: Use ExerciseDB API for real-time data
await service.loadFromExerciseDB(apiKey: "your-key")
```

## 📝 License

- **ExerciseDB V1**: AGPL-3.0 (free for personal/commercial use)
- **free-exercise-db**: Public Domain (Unlicense)
- **This integration code**: MIT License

## 🔗 Resources

- [ExerciseDB API](https://exercisedb.dev)
- [ExerciseDB GitHub](https://github.com/ExerciseDB/exercisedb-api)
- [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
- [RapidAPI ExerciseDB](https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb)
