#!/bin/bash

# CoreFitness Build Cleanup Script
# This script cleans Xcode caches and prepares for a fresh build

echo "🧹 CoreFitness Build Cleanup Script"
echo "===================================="
echo ""

# Check if Xcode is running
if pgrep -x "Xcode" > /dev/null; then
    echo "⚠️  WARNING: Xcode is currently running!"
    echo "Please close Xcode before running this script."
    echo ""
    read -p "Press Enter to quit Xcode and continue, or Ctrl+C to cancel..."
    
    # Try to quit Xcode gracefully
    osascript -e 'quit app "Xcode"'
    
    # Wait a moment for Xcode to close
    sleep 2
    
    # Check if it's still running
    if pgrep -x "Xcode" > /dev/null; then
        echo "❌ Failed to quit Xcode automatically."
        echo "Please quit Xcode manually and run this script again."
        exit 1
    fi
    
    echo "✅ Xcode closed successfully"
    echo ""
fi

# Remove CoreFitness DerivedData
echo "🗑️  Removing CoreFitness DerivedData..."
if rm -rf ~/Library/Developer/Xcode/DerivedData/CoreFitness-* 2>/dev/null; then
    echo "✅ CoreFitness DerivedData removed"
else
    echo "ℹ️  No CoreFitness DerivedData found (this is OK)"
fi
echo ""

# Remove Xcode caches
echo "🗑️  Clearing Xcode caches..."
if rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null; then
    echo "✅ Xcode caches cleared"
else
    echo "ℹ️  No Xcode caches found (this is OK)"
fi
echo ""

# Remove Module Cache
echo "🗑️  Clearing Swift module cache..."
if rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex 2>/dev/null; then
    echo "✅ Module cache cleared"
else
    echo "ℹ️  No module cache found (this is OK)"
fi
echo ""

# Optional: Reset Simulator
echo "📱 Reset iOS Simulator? (This will erase all simulator data)"
read -p "Type 'yes' to reset simulator, or press Enter to skip: " reset_sim

if [ "$reset_sim" = "yes" ]; then
    echo "🗑️  Resetting all simulators..."
    xcrun simctl shutdown all 2>/dev/null
    xcrun simctl erase all 2>/dev/null
    echo "✅ Simulators reset"
    echo ""
else
    echo "⏭️  Skipped simulator reset"
    echo ""
fi

echo "======================================"
echo "✨ Cleanup Complete!"
echo ""
echo "Next steps:"
echo "1. Open your project in Xcode"
echo "2. Clean Build Folder (⇧⌘K)"
echo "3. Build (⌘B) or Run (⌘R)"
echo ""
echo "If you still have issues:"
echo "- Check Info.plist is added to your app target"
echo "- Verify HealthKit capability is enabled"
echo "- Review BUILD_FIX_SUMMARY.md for details"
echo ""
echo "🚀 Ready to build CoreFitness!"
