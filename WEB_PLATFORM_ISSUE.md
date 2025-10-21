# Web Platform Issue - MQTT Client Not Supported ⚠️

## The Problem

You've been running the Flutter app in **Chrome (web)**, but the `mqtt_client` package uses `dart:io` which is **NOT available on web platforms**.

### Why This Fails on Web:

```dart
import 'dart:io';  // ❌ This import FAILS on web!
```

**Error**: "Unsupported operation: default SecurityContext getter"

This isn't actually a SecurityContext issue - it's that **`dart:io` doesn't exist in web browsers**.

## Platform Differences

| Feature | macOS/Desktop | Web (Chrome) |
|---------|--------------|--------------|
| `dart:io` | ✅ Available | ❌ **Not available** |
| MQTT over TCP | ✅ Supported | ❌ Not supported |
| MQTT over WebSocket | ✅ Supported | ✅ **Supported** |
| SecurityContext | ✅ Available | ❌ Not needed |

## Solutions

### Option 1: Run on Desktop (macOS) ✅ **Recommended**

The app is designed for **desktop**, not web. Run it on macOS:

```bash
cd Frontend
flutter run -d macos
```

**Why this works**:
- ✅ Full `dart:io` support
- ✅ Direct MQTT connection
- ✅ Better performance
- ✅ No CORS issues

---

### Option 2: Use Web-Compatible MQTT Package

If you **must** use web, you need a different MQTT package that doesn't use `dart:io`.

**Install web-compatible package**:
```bash
cd Frontend
flutter pub remove mqtt_client
flutter pub add mqtt_web_client
```

**Then rewrite `mqtt_service.dart`** to use the web client (significant changes required).

---

### Option 3: Use Backend Proxy (No Direct MQTT)

Instead of direct MQTT connection, proxy through your backend:

```
Flutter Web App → Backend API → MQTT Broker
```

**This requires**:
- Backend WebSocket endpoint
- Server-side MQTT connection
- Streaming skeleton data through HTTP/WebSocket

---

## Recommended Approach

Since you have a **Spring Boot backend**, the best architecture is:

### For Web (Chrome):
```
Flutter Web → HTTP/WebSocket → Spring Boot → MQTT Broker
```

### For Desktop (macOS):
```
Flutter Desktop → Direct MQTT → MQTT Broker
```

Both can use the same Flutter codebase with **platform detection**:

```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Use HTTP/WebSocket backend proxy
} else {
  // Use direct MQTT connection
}
```

## Quick Fix: Just Use Desktop

The **easiest solution** is to run on macOS as intended:

```bash
cd Frontend

# Clean build
flutter clean

# Run on macOS
flutter run -d macos
```

This is a **desktop application** that:
- ✅ Manages security camera feeds
- ✅ Handles real-time MQTT streams
- ✅ Processes binary skeleton data
- ✅ Shows live monitoring dashboards

Web browsers have limitations that make this difficult.

## Why Desktop is Better for This App

| Feature | Desktop | Web |
|---------|---------|-----|
| Direct MQTT | ✅ | ❌ |
| Binary data | ✅ | Limited |
| File system | ✅ | ❌ |
| Performance | ✅ Excellent | ⚠️ Slower |
| Security | ✅ Full control | ⚠️ CORS issues |
| Installation | Download | Browser only |

## Current App Architecture

```
┌─────────────────────────────────────────────┐
│  Flutter Desktop App (macOS/Windows/Linux)  │
│  ┌─────────────────────────────────────┐   │
│  │  Live Skeleton Viewer               │   │
│  │  - Direct MQTT connection           │   │
│  │  - Binary data parsing              │   │
│  │  - Real-time rendering              │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │  Alerts Screen                       │   │
│  │  - HTTP API calls                    │   │
│  │  - Background images                 │   │
│  │  - Alert history                     │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
           ↓                    ↓
    MQTT Broker         Spring Boot Backend
   (AltumView)          (localhost:8080)
```

## How to Switch to macOS

1. **Check available devices**:
```bash
flutter devices
```

You should see:
```
macOS (desktop) • macos • darwin-x64 • macOS 14.x.x
Chrome (web)    • chrome • web-javascript • Google Chrome 119.x
```

2. **Run on macOS**:
```bash
flutter run -d macos
```

3. **Or create macOS build**:
```bash
flutter build macos
```

The app will open as a native macOS application window (not a browser tab).

## If You Must Use Web

You'll need to:

1. **Remove `dart:io` dependency**:
   - Remove `mqtt_client` package
   - Use `mqtt_web_client` or similar
   - Or remove direct MQTT and use backend proxy

2. **Update `mqtt_service.dart`**:
   - Remove `import 'dart:io';`
   - Remove SecurityContext code
   - Use web-compatible MQTT client

3. **Handle CORS issues**:
   - Backend needs CORS headers
   - S3 images need CORS configuration

4. **Accept limitations**:
   - Slower performance
   - More complex architecture
   - Browser security restrictions

## Summary

🎯 **The app is designed for desktop, not web.**

✅ **Best solution**: Run on macOS
```bash
flutter run -d macos
```

⚠️ **Web is possible but complex**: Requires significant rewrites

## Next Steps

1. Close Chrome
2. Run `flutter devices` to confirm macOS is available
3. Run `flutter run -d macos`
4. App will open as native window
5. All features will work correctly!

The `dart:io` import and MQTT client are **correct for desktop** - they just don't work in web browsers.
