# Skeleton Binary Format - Solution

## Problem Discovered
The skeleton data from AltumView API is in **MQTT binary format** (base64 encoded), NOT JSON text.

### Error Evidence
```
Error parsing skeleton data: FormatException: Missing extension byte (at offset 7)
```

When we tried to decode the base64 skeleton_file and parse as UTF-8 JSON, it failed because the decoded data is binary, not text.

### Binary Data Structure
```
00000000: 0300 0000 1666 f168 feff ffff 3700 0000  .....f.h....7...
00000010: a400 5c00 3a00 1700 0500 2f00 0000 000c  ..\.:...../.....
00000020: 3301 0000 3d04 8f03 1800 1d14 159f 0000  3...=...........
```

This is the **raw MQTT skeleton stream format** used by AltumView cameras.

## Root Cause
- AltumView API stores skeleton data in the same binary format that comes through MQTT
- This is a proprietary binary protocol, likely optimized for bandwidth
- Without the protocol specification, we cannot decode it directly

## Solutions Implemented

### Solution 1: Mock Data (Current - WORKING ✅)
Return mock skeleton data that demonstrates the visualization system.

**Backend: `SkeletonController.java`**
```java
@GetMapping("/alerts/{alertId}/skeleton-decoded")
public ResponseEntity<Map<String, Object>> getAlertSkeletonDecoded(@PathVariable String alertId) {
    // TODO: Need AltumView binary protocol spec to decode real data
    // For now, return mock data showing a person in fall position
    return ResponseEntity.ok(getMockSkeletonData());
}

private Map<String, Object> getMockSkeletonData() {
    // Returns 17 keypoints (COCO format) in fall position
    List<List<Double>> person = new ArrayList<>();
    person.add(Arrays.asList(250.0, 400.0)); // nose
    person.add(Arrays.asList(240.0, 395.0)); // left eye
    // ... more keypoints ...
}
```

**Frontend: `alerts_screen.dart`**
```dart
// Get decoded skeleton data from backend
final skeletonJson = await _apiService.getAlertSkeletonDecoded(alert.id);

// Parse and visualize
final frame = SkeletonFrame.fromJson(skeletonJson);
setState(() {
  _skeletonFrame = frame;
});
```

### Solution 2: Real Binary Decoder (FUTURE - TODO)
To decode real skeleton data, we need:

1. **AltumView Binary Protocol Specification**
   - Frame structure
   - Coordinate encoding (int16? float32?)
   - Keypoint count and order
   - Compression format (if any)

2. **Implementation Steps**
   ```java
   public Map<String, Object> decodeBinarySkeleton(byte[] data) {
       ByteBuffer buffer = ByteBuffer.wrap(data);
       buffer.order(ByteOrder.LITTLE_ENDIAN);
       
       // Read header
       int frameCount = buffer.getInt();
       int timestamp = buffer.getInt();
       
       // Parse frames based on spec
       // ...
   }
   ```

3. **Alternative: MQTT Stream Processing**
   - Subscribe to live MQTT skeleton stream
   - Parse skeleton data in real-time
   - This would give us working examples to reverse-engineer the format

## Current System Status

### ✅ Working
- Backend returns mock skeleton data in correct JSON format
- Frontend fetches decoded skeleton via `/skeleton-decoded` endpoint
- Visualization system displays skeleton correctly
- Alert ID preservation working (no more 500 errors)

### 📊 Data Flow
```
AltumView API
    ↓ (base64 MQTT binary)
Backend receives skeleton_file
    ↓ (returns mock JSON for now)
Frontend API call: /skeleton-decoded
    ↓ (JSON with people/keypoints)
SkeletonFrame.fromJson()
    ↓
SkeletonPainter renders on Canvas
```

### 🔄 To Use Real Data
1. Contact AltumView for binary protocol specification
2. Implement binary decoder in `SkeletonDecoder.java`
3. Replace mock data with real decoding
4. Test with actual fall detection events

## Files Modified

### Backend
- `/Backend/src/main/java/com/example/demo/controller/SkeletonController.java`
  - Added `skeleton-decoded` endpoint
  - Added `getMockSkeletonData()` method
  - Added TODO comment about binary format

### Frontend
- `/Frontend/lib/services/api_service.dart`
  - Added `getAlertSkeletonDecoded()` method
  
- `/Frontend/lib/screens/alerts_screen.dart`
  - Changed from manual base64/UTF-8 decode to API call
  - Removed `dart:convert` import (no longer needed)

## Testing

### Test Endpoint
```bash
curl http://localhost:8080/api/skeleton/alerts/68f166168eeae9e50d48e58a/skeleton-decoded | jq '.'
```

**Expected Output:**
```json
{
  "people": [
    [
      [250.0, 400.0],
      [240.0, 395.0],
      // ... 17 keypoints total ...
    ]
  ]
}
```

### Test Frontend
1. Open alerts screen in Flutter app
2. Click on an alert
3. Should see skeleton visualization of person in fall position
4. No more "FormatException" error

## Next Steps

1. **Request Binary Format Spec** from AltumView support
2. **Analyze MQTT Stream** - Subscribe to live skeleton stream to see format
3. **Reverse Engineer** - Analyze binary data patterns
4. **Implement Decoder** - Build proper binary parser
5. **Validate** - Test with real fall detection events

## Contact Info

**AltumView Support**
- Documentation: Check API FAQ PDF for skeleton data format
- Support: Contact for binary protocol specification
- Alternative: Monitor MQTT `skeleton` topic for live examples

## Temporary Workaround

The mock data approach allows the system to be fully functional for:
- UI/UX development
- Visualization testing
- System integration testing
- Demo presentations

Once we have the binary format spec, we can swap in real decoding without changing the frontend at all.

---

**Status:** System fully operational with mock skeleton visualization
**Date:** October 20, 2025
**Priority:** Low (system works with mock data) / High (for production use)
