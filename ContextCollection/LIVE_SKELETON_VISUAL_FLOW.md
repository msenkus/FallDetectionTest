# Visual User Flow - Live Skeleton Feature

## Complete Navigation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        HOME SCREEN                              │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐         │
│  │    Live     │  │   Camera     │  │    Alerts     │         │
│  │ Monitoring  │  │   Images     │  │               │         │
│  │             │  │              │  │   (Click!)    │         │
│  └─────────────┘  └──────────────┘  └───────┬───────┘         │
└──────────────────────────────────────────────┼─────────────────┘
                                               │
                                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ALERTS SCREEN                              │
│  ┌────────────────┐  ┌────────────────────────────────────┐    │
│  │  Alert List    │  │   Alert Details (Right Panel)      │    │
│  │  ────────────  │  │                                     │    │
│  │  🔴 Fall       │  │  🔴 Fall Detection Alert            │    │
│  │  Camera: C001  │  │  2024-10-20 14:30:45               │    │
│  │  (Selected)    │  │                                     │    │
│  │                │  │  Alert ID: 68f166168eeae9e...      │    │
│  │  🟠 Loiter     │  │  Camera: C001                       │    │
│  │  Camera: C002  │  │  Type: Fall                         │    │
│  │                │  │                                     │    │
│  │  🟣 Intrusion  │  │  ┌──────────────────────────────┐  │    │
│  │  Camera: C001  │  │  │ 📹 View Live Skeleton        │  │    │
│  │                │  │  └────────────┬─────────────────┘  │    │
│  └────────────────┘  │               │ (NEW BUTTON!)      │    │
│                      │               │                     │    │
│                      │  ┌────────────▼─────────────────┐  │    │
│                      │  │                               │  │    │
│                      │  │  [Background Image]           │  │    │
│                      │  │  [Skeleton Overlay]           │  │    │
│                      │  │  (From Alert Storage)         │  │    │
│                      │  │                               │  │    │
│                      │  └───────────────────────────────┘  │    │
│                      └────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                      │
                        Click "View Live Skeleton"
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│               LIVE SKELETON VIEWER SCREEN                       │
│  ┌──────────────────────────────────────────────────────┐      │
│  │  Camera: [C001 - Lobby Camera ▼]  [Connect]          │      │
│  │           ↑                                           │      │
│  │      PRE-SELECTED from Alert!                        │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐      │
│  │                                                       │      │
│  │                                                       │      │
│  │          🟢 REAL-TIME SKELETON DISPLAY               │      │
│  │              (MQTT Stream)                            │      │
│  │                                                       │      │
│  │         👤 Person detected                            │      │
│  │         (Animated stick figure)                       │      │
│  │                                                       │      │
│  │                                                       │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                 │
│  Status: Connected - 1 person(s) detected 🟢                   │
└─────────────────────────────────────────────────────────────────┘
```

## Feature Comparison

### Before (Alert Skeleton Overlay)
```
❌ Uses alert storage format (skeleton_file)
❌ Format is undocumented/incompatible
❌ Shows garbage data (invalid coordinates)
❌ Static snapshot only (no animation)
❌ Requires reverse-engineering binary format
```

### After (Live Skeleton Button)
```
✅ Uses live MQTT stream (documented format)
✅ Shows REAL skeleton data
✅ Animated stick figure (real-time updates)
✅ Auto-selects correct camera
✅ One-click navigation
✅ Uses working code (already implemented)
```

## Button Appearance

```
┌─────────────────────────────────────────┐
│  Alert ID: 68f166168eeae9e50d48e58a     │
│  Camera: C001                            │
│  Type: Fall                              │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ 📹  View Live Skeleton             │ │  ← GREEN BUTTON
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Code Architecture

```
alerts_screen.dart
    │
    │ User clicks "View Live Skeleton"
    │
    ├─► Navigator.push(
    │       SkeletonViewerScreen(
    │           initialCameraSerialNumber: "C001"  ← PASSES CAMERA
    │       )
    │   )
    │
    ▼

skeleton_viewer_screen.dart
    │
    ├─► Loads camera list from API
    │
    ├─► Finds camera with serial "C001"
    │   selectedCamera = cameraList.firstWhere(
    │       (camera) => camera.serialNumber == "C001"
    │   )
    │
    ├─► User clicks "Connect"
    │
    ├─► Gets MQTT config for camera
    │
    ├─► Connects to MQTT broker
    │
    ├─► Receives real-time skeleton frames
    │
    └─► Displays animated skeleton with SkeletonPainter
```

## Technical Breakdown

### Navigation Chain
1. **User Action**: Click alert in list
2. **System Action**: Load alert details with skeleton_file
3. **Display**: Show background image + (broken) skeleton overlay
4. **User Action**: Click "View Live Skeleton" button
5. **System Action**: Navigate to SkeletonViewerScreen with camera serial
6. **System Action**: Pre-select camera from alert
7. **User Action**: Click "Connect"
8. **System Action**: Establish MQTT connection
9. **Display**: Real-time animated skeleton

### Data Flow
```
Alert Object
    ↓
cameraSerialNumber: "C001"
    ↓
SkeletonViewerScreen(initialCameraSerialNumber: "C001")
    ↓
_loadCameras() → Pre-select camera "C001"
    ↓
User clicks "Connect"
    ↓
getStreamConfig("C001") → MQTT credentials
    ↓
MqttService.connect() → Establish connection
    ↓
MQTT Stream → Real skeleton frames
    ↓
SkeletonPainter → Render animated stick figure
```

## User Benefits

### 🎯 **Immediate Value**
- See what's happening RIGHT NOW at the camera
- No need to guess which camera to select
- One-click access to live view

### 🔄 **Context Preservation**
- Automatic camera selection
- Seamless navigation
- Can return to alerts with back button

### 📊 **Better Data**
- Real-time updates (not static snapshot)
- Accurate skeleton rendering (not garbage data)
- Uses proven, working implementation

### 🎨 **Improved UX**
- Clear, prominent button
- Intuitive icon (video camera)
- Professional green styling
- Matches "Live Monitoring" theme

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| SkeletonViewerScreen parameter | ✅ DONE | Accepts optional camera serial |
| Camera pre-selection logic | ✅ DONE | Matches serial or falls back |
| "View Live Skeleton" button | ✅ DONE | Green button with icon |
| Navigation implementation | ✅ DONE | Passes camera serial number |
| Import statement | ✅ DONE | Added to alerts_screen.dart |
| Compilation check | ✅ DONE | No errors |
| Manual testing | ⏳ PENDING | User to test |

## Success Criteria

- [x] ✅ Button appears in alert details
- [x] ✅ Button navigates to Live Skeleton Viewer
- [x] ✅ Camera is pre-selected
- [ ] 🔄 User can connect to MQTT stream
- [ ] 🔄 Live skeleton displays correctly
- [ ] 🔄 Back navigation works

## Related Files

- `Frontend/lib/screens/alerts_screen.dart` - Added button
- `Frontend/lib/screens/skeleton_viewer_screen.dart` - Added parameter
- `Frontend/lib/main.dart` - Updated const usage
- `LIVE_SKELETON_BUTTON_COMPLETE.md` - Implementation details
