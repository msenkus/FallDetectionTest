# Xcode Setup Required for macOS Development

## Error
```
xcrun: error: unable to find utility "xcodebuild", not a developer tool or in PATH
```

## Solution: Install Xcode Command Line Tools

### Option 1: Quick Install (Recommended)
Run this command in Terminal:
```bash
xcode-select --install
```

This will:
1. Show a popup dialog
2. Click "Install"
3. Wait 5-10 minutes for download/install
4. Done!

### Option 2: Full Xcode (If you want the full IDE)
1. Open **App Store**
2. Search for **"Xcode"**
3. Click **"Get"** or **"Install"**
4. Wait for download (12+ GB, takes a while)
5. Open Xcode once to accept license
6. Run: `sudo xcodebuild -license accept`

## After Installation

### Verify Installation:
```bash
xcode-select -p
```

Should show:
```
/Library/Developer/CommandLineTools
```
or
```
/Applications/Xcode.app/Contents/Developer
```

### Then Run Your App:
```bash
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Frontend
flutter doctor
flutter run -d macos
```

## Alternative: Use Chrome Web (Temporary)

While Xcode installs, you can test the Alerts and Camera Images features (not Live Skeleton) on web:

```bash
cd Frontend
flutter run -d chrome
```

**Note**: Live Skeleton won't work on web, but you can test:
- ✅ Alerts screen
- ✅ Camera Images screen
- ✅ Alert details
- ✅ Background images
- ✅ Navigation and UI

## Why Xcode is Needed

Flutter macOS apps are built using:
- Xcode build tools
- macOS SDK
- Swift/Objective-C compilers
- Code signing tools

Without Xcode Command Line Tools, Flutter can't compile native macOS code.

## Quick Commands Summary

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
xcode-select -p

# Check Flutter setup
flutter doctor

# Run on macOS
cd Frontend
flutter run -d macos

# Or run on Chrome (temporary)
flutter run -d chrome
```

## What to Expect

After installing Xcode Command Line Tools:

```bash
flutter run -d macos
```

Output:
```
Launching lib/main.dart on macOS in debug mode...
Building macOS application...
✓ Built build/macos/Build/Products/Debug/skeleton_viewer.app
```

Then a native macOS window opens with your app! 🎉

## Troubleshooting

### If flutter doctor shows issues:
```bash
flutter doctor -v
```

### Accept Xcode license:
```bash
sudo xcodebuild -license accept
```

### Reset if needed:
```bash
sudo xcode-select --reset
```
