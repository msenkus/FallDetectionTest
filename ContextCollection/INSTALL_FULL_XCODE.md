# Install Full Xcode for Flutter macOS Development

## The Issue

Flutter macOS apps require **full Xcode**, not just Command Line Tools.

Error: `tool 'xcodebuild' requires Xcode`

## Solution: Install Xcode from App Store

### Option 1: App Store (Recommended)

1. **Open App Store** on your Mac
2. **Search** for "Xcode"
3. Click **"Get"** or **"Install"**
4. **Wait** 30-60 minutes (it's 12+ GB)
5. **Open Xcode** once to accept license
6. Run: `sudo xcodebuild -license accept`

### Option 2: Download Directly from Apple

1. Go to: https://developer.apple.com/xcode/
2. Click **"Download"**
3. Sign in with Apple ID
4. Download Xcode.xip
5. Double-click to extract
6. Move to Applications folder
7. Open Xcode to accept license
8. Run: `sudo xcodebuild -license accept`

## After Xcode Installation

```bash
# 1. Accept license
sudo xcodebuild -license accept

# 2. Set Xcode path
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# 3. Run first launch (installs additional components)
sudo xcodebuild -runFirstLaunch

# 4. Install CocoaPods
sudo gem install cocoapods

# 5. Verify Flutter setup
flutter doctor

# 6. Run your app!
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Frontend
flutter run -d macos
```

## Alternative: Use Chrome Web (No Xcode Needed)

If you don't want to install Xcode right now, you can test some features on web:

```bash
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Frontend
flutter run -d chrome
```

**What works on Chrome**:
- ✅ Alerts screen (viewing alerts)
- ✅ Camera Images
- ✅ Navigation and UI
- ✅ Background images

**What doesn't work on Chrome**:
- ❌ Live Skeleton Viewer (requires desktop for MQTT)

## Why Full Xcode is Needed

Flutter macOS apps require:
- Xcode build system
- macOS SDK
- Swift/Objective-C compilers
- Code signing tools
- CocoaPods integration

Command Line Tools alone aren't sufficient for macOS app development.

## Time Required

- **Xcode Download**: 30-60 minutes (12+ GB)
- **Installation**: 5-10 minutes
- **Setup**: 2-3 minutes
- **Total**: ~45-75 minutes

## Quick Decision

### Want to use the app NOW?
→ Use Chrome web version (limited features)
```bash
flutter run -d chrome
```

### Want full features?
→ Install Xcode (45-75 minutes)
1. Open App Store
2. Search "Xcode"
3. Click Install
4. Come back when done!

## Summary

**Current situation**: You have Command Line Tools, but need full Xcode

**Options**:
1. Install Xcode (45-75 min) → Full features ✅
2. Use Chrome web (now) → Limited features ⚠️

Choose what works best for you! 🚀
