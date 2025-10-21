# Quick Setup to Run on macOS

## You're Almost There! ✅

Command line tools are installed, but you need **CocoaPods** for macOS Flutter apps.

## Install CocoaPods

Run this command and **enter your Mac password** when prompted:

```bash
sudo gem install cocoapods
```

This will take 1-2 minutes.

## Then Run Your App

```bash
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Frontend
flutter run -d macos
```

## Full Commands

```bash
# 1. Install CocoaPods (enter password when asked)
sudo gem install cocoapods

# 2. Navigate to project
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Frontend

# 3. Clean build (optional but recommended)
flutter clean

# 4. Get dependencies
flutter pub get

# 5. Run on macOS!
flutter run -d macos
```

## What to Expect

After running `flutter run -d macos`, you'll see:

```
Launching lib/main.dart on macOS in debug mode...
Building macOS application...
✓ Built build/macos/Build/Products/Debug/skeleton_viewer.app
```

Then a **native macOS window** will open with your app!

## If CocoaPods Install is Slow

CocoaPods installation can take 1-2 minutes. You'll see:

```
Fetching gem metadata from https://rubygems.org/........
Successfully installed cocoapods-1.x.x
```

Be patient, it's working!

## Alternative: Use Homebrew (Faster)

If `sudo gem install cocoapods` is slow, try Homebrew:

```bash
# Install CocoaPods via Homebrew (usually faster)
brew install cocoapods

# Then run your app
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Frontend
flutter run -d macos
```

---

## Start Here 👇

Copy and paste:

```bash
sudo gem install cocoapods
```

Enter your Mac password when prompted, then let me know when it's done! 🚀
