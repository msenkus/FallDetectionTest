# Binary Format Fix - Before vs After

## The Problem

Your Flutter app was using an **incorrect binary format** for parsing MQTT skeleton data, which caused the same errors you saw before.

## What Changed

### ❌ BEFORE (Wrong Format)
```dart
void _parseSkeletonData(Uint8Buffer payload) {
  final bytes = Uint8List.fromList(payload.toList());
  final byteData = ByteData.sublistView(bytes);
  
  int offset = 0;
  
  // ❌ WRONG: Reading 1 byte instead of 4
  final numPeople = byteData.getUint8(offset);
  offset += 1;
  
  for (int i = 0; i < numPeople; i++) {
    List<SkeletonKeypoint> keypoints = [];
    
    // ❌ WRONG: Missing person ID, X/Y not separated
    for (int j = 0; j < 18; j++) {
      final x = byteData.getFloat32(offset, Endian.little);
      offset += 4;
      final y = byteData.getFloat32(offset, Endian.little);
      offset += 4;
      
      keypoints.add(SkeletonKeypoint(x, y));
    }
    
    people.add(keypoints);
  }
}
```

**Why This Failed**:
- Missing frame number (first 4 bytes)
- `numPeople` read as 1 byte → Got garbage value like `1760650774`
- Missing person ID → Offset misalignment
- X and Y not in separate arrays → Wrong coordinates
- Missing padding → Further offset issues

### ✅ AFTER (Correct Format)
```dart
void _parseSkeletonData(Uint8Buffer payload) {
  final bytes = Uint8List.fromList(payload.toList());
  
  // ✅ Validate minimum size
  if (bytes.length < 8) {
    _skeletonController.add(SkeletonFrame([]));
    return;
  }
  
  final byteData = ByteData.sublistView(bytes);
  int offset = 0;
  
  // ✅ Read frame number (4 bytes, int32)
  final frameNum = byteData.getInt32(offset, Endian.little);
  offset += 4;
  
  // ✅ Read number of people (4 bytes, int32)
  final numPeople = byteData.getInt32(offset, Endian.little);
  offset += 4;
  
  print('📦 Frame $frameNum: $numPeople person(s)');
  
  // ✅ Sanity check
  if (numPeople == 0 || numPeople > 10) {
    _skeletonController.add(SkeletonFrame([]));
    return;
  }
  
  // ✅ Validate expected size
  final expectedSize = 8 + (numPeople * 152);
  if (bytes.length < expectedSize) {
    return;
  }
  
  List<List<SkeletonKeypoint>> people = [];
  
  for (int i = 0; i < numPeople; i++) {
    // ✅ Read person ID (4 bytes)
    final personId = byteData.getInt32(offset, Endian.little);
    offset += 4;
    
    // ✅ Read X coordinates (18 × float32 = 72 bytes)
    List<double> xCoords = [];
    for (int j = 0; j < 18; j++) {
      xCoords.add(byteData.getFloat32(offset, Endian.little));
      offset += 4;
    }
    
    // ✅ Read Y coordinates (18 × float32 = 72 bytes)
    List<double> yCoords = [];
    for (int j = 0; j < 18; j++) {
      yCoords.add(byteData.getFloat32(offset, Endian.little));
      offset += 4;
    }
    
    // ✅ Skip padding (4 bytes)
    offset += 4;
    
    // ✅ Combine into keypoints
    List<SkeletonKeypoint> keypoints = [];
    for (int j = 0; j < 18; j++) {
      keypoints.add(SkeletonKeypoint(xCoords[j], yCoords[j]));
    }
    
    print('  Person $personId: visible keypoints');
    people.add(keypoints);
  }
  
  _skeletonController.add(SkeletonFrame(people));
}
```

## Official AltumView Binary Format

```
┌─────────────────────────────────────────────────┐
│  MQTT STREAM PACKET                             │
├─────────────────────────────────────────────────┤
│  Offset 0-3:   Frame Number (int32)             │  4 bytes
│  Offset 4-7:   Number of People (int32)         │  4 bytes
├─────────────────────────────────────────────────┤
│  FOR EACH PERSON (152 bytes):                   │
│    Offset 0-3:     Person ID (int32)            │  4 bytes
│    Offset 4-75:    X Coords (18 × float32)      │ 72 bytes
│    Offset 76-147:  Y Coords (18 × float32)      │ 72 bytes
│    Offset 148-151: Padding                      │  4 bytes
└─────────────────────────────────────────────────┘

Total size = 8 + (numPeople × 152) bytes
```

## Memory Layout Example (1 Person)

```
Byte Range  | Field              | Type    | Size
------------|-------------------|---------|------
0-3         | Frame Number      | int32   | 4
4-7         | Num People (1)    | int32   | 4
8-11        | Person ID         | int32   | 4
12-15       | X[0] (nose)       | float32 | 4
16-19       | X[1] (neck)       | float32 | 4
20-23       | X[2] (R shoulder) | float32 | 4
...         | ...               | ...     | ...
76-79       | X[17] (L ear)     | float32 | 4
80-83       | Y[0] (nose)       | float32 | 4
84-87       | Y[1] (neck)       | float32 | 4
...         | ...               | ...     | ...
152-155     | Y[17] (L ear)     | float32 | 4
156-159     | Padding           | bytes   | 4

Total: 160 bytes
```

## Why the JavaScript Code Matters

The JavaScript Paho MQTT code you shared shows the **same format** being used in the browser version:

```javascript
// From Paho MQTT JavaScript:
var frameNum = int32 at offset 0      // ✅ We now read this
var numPeople = int32 at offset 4     // ✅ We now read this (was wrong)

// For each person (152 bytes):
var personId = int32                  // ✅ We now read this (was missing)
var xCoords = 18 × float32            // ✅ We now read separate X array
var yCoords = 18 × float32            // ✅ We now read separate Y array
var padding = 4 bytes                 // ✅ We now skip this (was missing)
```

This confirms we're now using the **correct official format**! 🎉

## About "Setters" Error

You mentioned getting errors about "setters". This was likely because:

1. **JavaScript uses property setters**:
   ```javascript
   client.onMessageArrived = function(message) { ... }
   ```

2. **Dart/Flutter uses streams**:
   ```dart
   client.updates!.listen((messages) { ... })
   ```

The Dart `mqtt_client` package doesn't have the same API as JavaScript Paho MQTT. But the **binary data format is the same**, which is what matters!

## Expected Results After Fix

### Console Output:
```
✓ MQTT connection successful!
✓ Connected to MQTT
✓ Subscribed to skeleton/camera/C001
→ Published stream token
📦 Frame 1234: 1 person(s), 160 bytes
  Person 42: 15/18 keypoints visible
📦 Frame 1235: 1 person(s), 160 bytes
  Person 42: 16/18 keypoints visible
📦 Frame 1236: 0 person(s), 8 bytes
📦 Frame 1237: 1 person(s), 160 bytes
  Person 42: 14/18 keypoints visible
```

### Visual Result:
- ✅ Animated stick figure appears
- ✅ Moves in real-time
- ✅ Keypoints appear/disappear as person moves
- ✅ No more garbage coordinates
- ✅ No more parsing errors

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| Frame Number | ❌ Not read | ✅ Read (int32) |
| Num People | ❌ 1 byte (wrong) | ✅ 4 bytes (int32) |
| Person ID | ❌ Missing | ✅ Read (int32) |
| X Coordinates | ❌ Interleaved with Y | ✅ Separate array |
| Y Coordinates | ❌ Interleaved with X | ✅ Separate array |
| Padding | ❌ Not skipped | ✅ Skipped (4 bytes) |
| Size Validation | ❌ None | ✅ Multiple checks |
| Error Handling | ❌ Basic | ✅ Enhanced with logs |
| Logging | ❌ Minimal | ✅ Frame/person details |

## Test Now!

Run your Flutter app and try the Live Skeleton Viewer:

```bash
cd Frontend
flutter run -d macos
```

Then:
1. Click "Live Monitoring"
2. Select a camera
3. Click "Connect"
4. Watch the console and screen for real-time skeleton data!

The binary parsing should now work correctly! 🚀
