# Skeleton Format Analysis

Based on hex dump analysis and official example:

## Hex Data (first 32 bytes):
```
00000000: 0300 0000 1666 f168 feff ffff 3700 0000  .....f.h....7...
00000010: a400 5c00 3a00 1700 0500 2f00 0000 000c  ..\.:...../.....
```

## Analysis:
- `03 00 00 00` (offset 0) = int32 value 3
- `16 66 f1 68` (offset 4) = int32 value 1760650774 or timestamp
- `fe ff ff ff` (offset 8) = int32 value -2
- `37 00 00 00` (offset 12) = int32 value 55
- `a4 00` (offset 16) = int16 value 164
- `5c 00` (offset 18) = int16 value 92

## Official Format (from AltumView example):
```javascript
const frameNum = parseStringInt32(byteList, 0);      // Offset 0
const numPeople = parseStringInt32(byteList, 4);    // Offset 4
for (let i = 0; i < numPeople; i++) {
  const pos = 8 + 152 * i;
  const personId = parseStringInt32(byteList, pos); // Offset 8 + 152*i
  // X coords at pos + 8
  // Y coords at pos + 80
}
```

## Problem:
The alert skeleton_file format appears DIFFERENT from live MQTT stream format!

## Hypothesis 1: Alert uses different format
- Maybe alert stores multiple frames
- First 4 bytes = frame count (3 frames?)
- Then frame data

## Hypothesis 2: Coordinate system
- Maybe coordinates are int16 not float32 in alerts
- Live stream uses float32 normalized
- Alerts use int16 pixel coordinates

Let me check with alert data size: 4592 bytes

If 3 frames with official format:
- Header: 8 bytes (frameNum + numPeople)
- Per frame: If 1 person → 152 bytes
- Total for 3 frames: 8 + (3 * 152) = 464 bytes ❌ Too small

If different format with int16:
- 4592 bytes / 3 frames = 1530 bytes per frame
- 1530 bytes / 18 keypoints = 85 bytes per keypoint ❌ Doesn't match

The data might be compressed or use a completely different format for alerts vs live stream.
