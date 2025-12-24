# CoreFitness - Xcode Project Setup

Follow these steps to create the Xcode project and add the prepared files.

---

## Step 1: Create New Xcode Project

1. Open **Xcode**
2. Go to **File > New > Project...**
3. Select **iOS > App**
4. Configure the project:
   - **Product Name:** `CoreFitness`
   - **Team:** Your Apple Developer Team
   - **Organization Identifier:** `com.jmillergroup`
   - **Bundle Identifier:** Will auto-fill as `com.jmillergroup.CoreFitness`
   - **Interface:** `SwiftUI`
   - **Language:** `Swift`
   - **Storage:** `None` (we'll use Firebase)
   - **Include Tests:** Check both boxes
5. Click **Next**
6. Save to: `/Users/jeffmiller/Projects/Fitness_iOS`
7. Click **Create**

---

## Step 2: Delete Default Files

Delete these auto-generated files from Xcode (move to trash):
- `ContentView.swift` (we have our own)
- `CoreFitnessApp.swift` (we have our own)

---

## Step 3: Add Existing Files

1. In Xcode, right-click on the **CoreFitness** folder in the navigator
2. Select **Add Files to "CoreFitness"...**
3. Navigate to the `CoreFitness` folder we created
4. Select all folders:
   - `App`
   - `Views`
   - `Models`
   - `ViewModels`
   - `Services`
   - `Utilities`
   - `Extensions`
   - `Resources`
   - `Navigation`
   - `Info.plist`
5. Make sure **"Copy items if needed"** is **unchecked** (files are already in place)
6. Make sure **"Create groups"** is selected
7. Click **Add**

---

## Step 4: Configure Capabilities

1. Select the **CoreFitness** project in the navigator
2. Select the **CoreFitness** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** and add:
   - [x] **HealthKit** - Check "Clinical Health Records" if needed
   - [x] **Sign in with Apple**
   - [x] **Push Notifications**
   - [x] **Background Modes** - Enable:
     - Background fetch
     - Remote notifications
     - Location updates
     - Background processing
   - [x] **App Groups** (for Watch/Widget sharing)
     - Add: `group.com.jmillergroup.CoreFitness`

---

## Step 5: Add Firebase SDK

### Option A: Swift Package Manager (Recommended)

1. Go to **File > Add Package Dependencies...**
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Click **Add Package**
4. Select these packages:
   - [x] FirebaseAnalytics
   - [x] FirebaseAuth
   - [x] FirebaseFirestore
   - [x] FirebaseStorage
   - [x] FirebaseMessaging
   - [x] FirebaseRemoteConfig
5. Click **Add Package**

### Option B: CocoaPods

If you prefer CocoaPods, create a `Podfile`:

```ruby
platform :ios, '18.0'

target 'CoreFitness' do
  use_frameworks!

  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Messaging'
  pod 'Firebase/RemoteConfig'
end
```

Then run: `pod install`

---

## Step 6: Set Up Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Add Project**
3. Name it: `CoreFitness`
4. Enable Google Analytics (optional)
5. Click **Create Project**

### Add iOS App to Firebase:

1. Click the **iOS+** button
2. Enter Bundle ID: `com.jmillergroup.CoreFitness`
3. Enter App nickname: `CoreFitness iOS`
4. Download `GoogleService-Info.plist`
5. Drag `GoogleService-Info.plist` into Xcode (into the CoreFitness folder)
6. Make sure **"Copy items if needed"** is checked
7. Click **Finish**

### Enable Firebase Services:

1. **Authentication:**
   - Go to Authentication > Sign-in method
   - Enable **Apple** sign-in
   - Enable **Google** sign-in

2. **Firestore:**
   - Go to Firestore Database
   - Click **Create database**
   - Start in **test mode** (for development)
   - Choose region closest to you

3. **Storage:**
   - Go to Storage
   - Click **Get started**
   - Start in **test mode**

---

## Step 7: Add Apple Watch Target

1. Go to **File > New > Target...**
2. Select **watchOS > App**
3. Configure:
   - **Product Name:** `CoreFitnessWatch`
   - **Bundle Identifier:** `com.jmillergroup.CoreFitness.watchkitapp`
   - **Interface:** `SwiftUI`
   - **Watch App:** `Watch App`
   - **Include Notification Scene:** Yes
4. Click **Finish**

---

## Step 8: Add Widget Target

1. Go to **File > New > Target...**
2. Select **iOS > Widget Extension**
3. Configure:
   - **Product Name:** `CoreFitnessWidgets`
   - **Bundle Identifier:** `com.jmillergroup.CoreFitness.widgets`
   - **Include Live Activity:** Yes
   - **Include Configuration App Intent:** Yes
4. Click **Finish**

---

## Step 9: Build Settings

1. Select the **CoreFitness** target
2. Go to **Build Settings**
3. Search for and set:
   - **iOS Deployment Target:** `18.0`
   - **Swift Language Version:** `Swift 5` or `Swift 6`

---

## Step 10: Info.plist Configuration

The `Info.plist` file has been pre-configured with:
- HealthKit usage descriptions
- Camera/Photo Library permissions
- Location permissions
- Background modes
- Required device capabilities

---

## Project Structure

```
CoreFitness/
├── App/
│   └── CoreFitnessApp.swift          # Main app entry point
├── Navigation/
│   └── ContentView.swift             # Tab navigation, custom tab bar
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift            # Home dashboard
│   │   └── DailyCheckInView.swift    # Daily mood/health check-in
│   ├── Programs/
│   │   └── ProgramsView.swift        # Workout programs
│   ├── Health/
│   │   └── HealthView.swift          # Health metrics
│   ├── Settings/
│   │   └── SettingsView.swift        # App settings
│   ├── Onboarding/
│   │   └── OnboardingView.swift      # Sign-in flow
│   ├── Workout/                      # (To be built)
│   └── Components/                   # (Reusable UI components)
├── Models/                           # (Data models)
├── ViewModels/                       # (View models)
├── Services/
│   ├── Firebase/
│   │   └── AuthManager.swift         # Authentication
│   ├── HealthKit/
│   │   └── HealthKitManager.swift    # Apple Health
│   ├── Gemini/                       # (AI workout generation)
│   └── ThemeManager.swift            # Themes & preferences
├── Utilities/                        # (Helper functions)
├── Extensions/                       # (Swift extensions)
├── Resources/
│   ├── Assets/                       # (Images, colors)
│   └── Fonts/                        # (Custom fonts)
└── Info.plist                        # App configuration
```

---

## Run the App

1. Select an iPhone simulator (iPhone 15 Pro recommended)
2. Press **Cmd + R** or click the **Play** button
3. The app should launch with the onboarding flow

---

## Next Steps

1. [ ] Add `GoogleService-Info.plist` from Firebase
2. [ ] Complete the onboarding UI polish
3. [ ] Build out the AI workout creation flow
4. [ ] Implement Firestore data persistence
5. [ ] Add the Exercise Library database
6. [ ] Build the active workout screen
7. [ ] Implement Apple Watch companion app
8. [ ] Add widgets and Live Activities

---

## Troubleshooting

### Firebase errors
- Make sure `GoogleService-Info.plist` is added to the target
- Ensure Firebase packages are properly linked

### HealthKit errors
- HealthKit only works on real devices, not simulators
- Test on a physical iPhone for full functionality

### Build errors
- Clean build folder: **Cmd + Shift + K**
- Delete derived data if needed

---

*Setup guide for CoreFitness v1.0*
