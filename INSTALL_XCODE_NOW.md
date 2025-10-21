# Installing Xcode Command Line Tools - Step by Step

## Copy and Paste This Command

Open your Terminal (the one you're using now) and run:

```bash
xcode-select --install
```

## What Will Happen

1. **A popup window will appear** asking "Install Command Line Developer Tools?"
2. Click **"Install"** button
3. Click **"Agree"** to the license agreement
4. Wait 5-10 minutes while it downloads and installs
5. You'll see "The software was installed" when done

## After Installation

Once you see "The software was installed", run these commands:

```bash
# Verify installation worked
xcode-select -p

# Should show: /Library/Developer/CommandLineTools

# Check Flutter is happy
flutter doctor

# Navigate to your project
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Frontend

# Run on macOS!
flutter run -d macos
```

## If You See an Error

If you get "command line tools are already installed", then run:

```bash
# Check what's installed
xcode-select -p

# If it shows a path, you're good! Skip to running flutter:
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Frontend
flutter run -d macos
```

## Screenshot of What to Expect

When you run `xcode-select --install`, you'll see:

```
┌─────────────────────────────────────────────┐
│  Install Command Line Developer Tools?      │
│                                             │
│  The "xcode-select" command requires       │
│  the command line developer tools.         │
│  Would you like to install the tools now?  │
│                                             │
│         [  Not Now  ]  [  Install  ]      │
└─────────────────────────────────────────────┘
```

Click **[Install]**

Then:

```
┌─────────────────────────────────────────────┐
│  Installing Command Line Tools              │
│                                             │
│  [===========                    ]  45%    │
│                                             │
│  Time remaining: About 5 minutes           │
└─────────────────────────────────────────────┘
```

## Quick Reference

```bash
# 1. Install tools
xcode-select --install

# 2. Wait for installation (5-10 minutes)

# 3. Verify
xcode-select -p

# 4. Run app
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Frontend
flutter run -d macos
```

---

## Start Here 👇

Copy this command and paste it in your Terminal:

```bash
xcode-select --install
```

Then tell me what you see!
