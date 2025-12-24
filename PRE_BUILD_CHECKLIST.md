# CoreFitness Pre-Build Verification Checklist

Use this checklist before attempting to build CoreFitness.

## ✅ Code-Level Fixes (Completed Automatically)

- [x] **Info.plist created** with HealthKit privacy descriptions
- [x] **HealthKitManager.swift updated** to include activeEnergyBurned write permission
- [x] **Test suite created** (CoreFitnessTests.swift)
- [x] **All syntax errors resolved**

---

## 📋 Manual Steps Required

### Step 1: Clean Build Environment
Run the cleanup script:
```bash
cd /path/to/CoreFitness
chmod +x cleanup_build.sh
./cleanup_build.sh
```

Or manually:
```bash
# Close Xcode first!
rm -rf ~/Library/Developer/Xcode/DerivedData/CoreFitness-*
rm -rf ~/Library/Caches/com.apple.dt.Xcode
```

**Status:** [ ] Done

---

### Step 2: Open Project in Xcode
```bash
open CoreFitness.xcodeproj
```

**Status:** [ ] Done

---

### Step 3: Verify Info.plist Target Membership

1. In Project Navigator, select `Info.plist`
2. Open File Inspector (⌥⌘1 or View → Inspectors → File)
3. Under "Target Membership", ensure your main app target is checked
4. If Info.plist already existed, merge the HealthKit keys:
   - `NSHealthShareUsageDescription`
   - `NSHealthUpdateUsageDescription`

**Status:** [ ] Done

---

### Step 4: Add HealthKit Capability

1. Select your project in Project Navigator
2. Select your app target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" button
5. Search for "HealthKit"
6. Add HealthKit capability

**Status:** [ ] Done

---

### Step 5: Verify Code Signing

1. In "Signing & Capabilities" tab
2. Ensure "Automatically manage signing" is checked
3. Select your development team
4. Verify provisioning profile is valid

**Status:** [ ] Done

---

### Step 6: Add Test File to Test Target (Optional)

1. Select `CoreFitnessTests.swift` in Project Navigator
2. Open File Inspector (⌥⌘1)
3. Under "Target Membership", check your test target
4. If no test target exists, create one:
   - File → New → Target → iOS Unit Testing Bundle

**Status:** [ ] Done / [ ] Skipped

---

### Step 7: Clean Build Folder

In Xcode menu:
- Product → Clean Build Folder (⇧⌘K)

Or use keyboard shortcut: **⇧⌘K**

**Status:** [ ] Done

---

### Step 8: Select Build Destination

1. In Xcode toolbar, click the device menu
2. Choose a simulator (recommended: iPhone 15) or physical device
3. Ensure iOS 17.0+ is selected

**Status:** [ ] Done

---

### Step 9: Build the Project

**Option A:** Build only
```
Product → Build (⌘B)
```

**Option B:** Build and Run
```
Product → Run (⌘R)
```

**Status:** [ ] Done

---

### Step 10: Run Tests (Optional)

Run all tests:
```
Product → Test (⌘U)
```

Or in Test Navigator (⌘6):
- Click play button next to test suite

**Status:** [ ] Done / [ ] Skipped

---

## 🔍 Verification After Build

### App Launch
- [ ] App launches without crashing
- [ ] No Info.plist errors in console
- [ ] HealthKit permission dialog appears (or was previously granted)

### HealthKit Integration
- [ ] Can tap "Allow" on HealthKit permissions
- [ ] Health data displays in app (if available)
- [ ] No authorization errors in console

### Core Functionality
- [ ] Can navigate through app screens
- [ ] Can create/view workouts
- [ ] Authentication works (mock mode)

### Tests (if running)
- [ ] All tests pass
- [ ] No test failures in Test Navigator
- [ ] Test coverage shows green checkmarks

---

## 🐛 If Build Fails

### Common Issues & Solutions

**Issue:** "Info.plist not found"
- **Solution:** Check Step 3 - ensure Info.plist is added to target

**Issue:** "HealthKit framework not found"
- **Solution:** Check Step 4 - add HealthKit capability

**Issue:** "Code signing error"
- **Solution:** Check Step 5 - verify team and provisioning

**Issue:** "Build database I/O error" (still occurring)
- **Solution:** Repeat Step 1 - ensure DerivedData fully deleted
- Try: `rm -rf ~/Library/Developer/Xcode/DerivedData/*` (removes ALL projects)

**Issue:** "Duplicate symbol" errors
- **Solution:** Clean build folder (Step 7) and rebuild

**Issue:** Tests won't run
- **Solution:** Check Step 6 - ensure test file is in test target

---

## 📞 Additional Help

### Console Logs
View build errors and runtime logs:
- Open Console: View → Debug Area → Activate Console (⇧⌘C)
- Or click bottom panel icon in Xcode

### Build Report
See detailed build information:
- View → Navigators → Report Navigator (⌘9)
- Click on latest build to see all steps

### Documentation
See full details in:
- `BUILD_FIX_SUMMARY.md` - Complete list of fixes and changes
- Project comments - Inline documentation in code

---

## ✨ Success Criteria

Your build is successful when:
- ✅ Xcode shows "Build Succeeded" message
- ✅ No red errors in Issue Navigator (⌘5)
- ✅ App launches in Simulator/Device
- ✅ HealthKit permissions dialog appears
- ✅ App functions normally

---

## 🎯 Final Pre-Build Command

Run this single command to verify everything:

```bash
# From project directory
cd /path/to/CoreFitness

# Make script executable
chmod +x cleanup_build.sh

# Run cleanup
./cleanup_build.sh

# Open Xcode
open CoreFitness.xcodeproj

echo "✅ Now follow steps 3-9 in Xcode!"
```

---

**Last Updated:** December 24, 2025  
**Status:** Ready for test build after completing manual steps
