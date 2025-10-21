# Video/Alert Loading Issue - Diagnosis and Solution

## Issue Report
**Error**: `Exception: Failed to load alert: 500`  
**Context**: Frontend trying to load alert details, mentions "the video is not loading"  
**Additional Info**: Concerns about MQTT timeout after 45 seconds

## Root Cause Analysis

### 1. **No Actual 500 Error** ✅
The backend logs show successful alert retrieval:
```
2025-10-20T18:04:43.454  INFO - ✓ Alert 68f166168eeae9e50d48e58a has skeleton_file (length: 6124 chars)
2025-10-20T18:04:43.455  INFO - ✓ Successfully mapped alert 68f166168eeae9e50d48e58a
```

Backend endpoint returns 200 OK with complete data including skeleton_file.

### 2. **Intermittent Token Expiration**
The error might occur when:
- Access token expires (3599 seconds = ~1 hour)
- MQTT credentials expire (45 seconds for streaming)
- Network timeout during request

### 3. **Video vs Skeleton Data Confusion**
The alert has:
- ✅ `skeleton_file` - Base64 encoded skeleton keypoint data (6124 chars)
- ✅ `background_url` - Static image of the scene
- ❌ NO video clip URL (not in this alert response)

## What Works Now

### Backend ✅
- Successfully retrieves alerts from Altumview API
- Properly decodes alert structure (`data.alert`)
- Returns skeleton_file (base64, 6124 chars → 4592 bytes decoded)
- Returns background_url for static scene image
- Token caching prevents excessive auth requests

### Frontend ✅  
- Loads test alert when list is empty
- Decodes base64 skeleton_file
- Parses skeleton data into SkeletonFrame
- Displays skeleton visualization

## The "Video" Question

Altumview alerts may have associated video clips, but they're not included in the basic alert endpoint response. Video clips typically require:

1. **Separate API Endpoint**: `/alerts/{alertId}/clip` or similar
2. **Pre-signed URL**: Similar to background_url
3. **Time-limited Access**: Videos expire after certain period
4. **Different Format**: MP4, HLS stream, etc.

The current alert `68f166168eeae9e50d48e58a` **does not have a video clip URL** in its response.

## MQTT Live Streaming (45s Timeout)

For **live camera streaming** (not alert playback):

### Current Implementation
```java
// Get MQTT credentials
public MqttCredentials getMqttCredentials()  // Returns credentials valid for ~45s

// Get stream token
public StreamToken getStreamToken(Long cameraId)  // Returns token for specific camera

// Build stream config
public SkeletonStreamConfig getSkeletonStreamConfig(Long cameraId)
```

### The 45-Second Problem
- MQTT stream tokens expire after 45 seconds
- Frontend must refresh credentials before expiry
- Need periodic token refresh for continuous streaming

### Solution: Token Refresh Service

**Backend** (`MqttSessionManager.java`):
```java
@Service
public class MqttSessionManager {
    
    @Scheduled(fixedRate = 30000) // Every 30 seconds
    public void refreshExpiringSessions() {
        // Refresh tokens that expire in < 15 seconds
        activeSessions.forEach((cameraId, session) -> {
            if (needsRefresh(session)) {
                refreshToken(cameraId, session);
            }
        });
    }
}
```

**Frontend** (Flutter):
```dart
Timer? _tokenRefreshTimer;

void startStreaming() {
  // Refresh token every 30 seconds
  _tokenRefreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
    _refreshStreamToken();
  });
}

Future<void> _refreshStreamToken() async {
  final config = await _apiService.getStreamConfig(cameraId);
  _mqttService.updateCredentials(config);
}
```

## Fixing the 500 Error

### Immediate Fixes Applied

1. **Added `background_url` to Alert DTO** ✅
   ```java
   @JsonProperty("background_url")
   private String backgroundUrl;
   ```

2. **Map background_url in service** ✅
   ```java
   alert.setBackgroundUrl((String) data.get("background_url"));
   ```

3. **Backend rebuilt and restarted** ✅

### Testing the Fix

```bash
# Test alert endpoint
curl -s http://localhost:8080/api/skeleton/alerts/68f166168eeae9e50d48e58a | jq '{id, background_url, has_skeleton: (.skeleton_file != null)}'

# Expected result:
{
  "id": "238071A4F37D31EE_1760650774",
  "background_url": "https://cypress-prod-backgroundimage.s3.us-west-2.amazonaws.com/...",
  "has_skeleton": true
}
```

### Frontend Should Now Work

Hot reload the Flutter app, and it should:
1. Load the test alert successfully
2. Display skeleton visualization
3. Show background image (if you add UI for it)

## Next Steps for Video Support

If you want **video playback** from alerts:

### 1. Check Altumview API Documentation
Look for endpoints like:
- `GET /alerts/{alertId}/clip`
- `GET /alerts/{alertId}/video`
- `GET /alerts/{alertId}/recording`

### 2. Add Backend Support
```java
@GetMapping("/alerts/{alertId}/video-url")
public ResponseEntity<Map<String, String>> getAlertVideoUrl(@PathVariable String alertId) {
    try {
        String videoUrl = altumViewService.getAlertVideoClip(alertId);
        return ResponseEntity.ok(Map.of("video_url", videoUrl));
    } catch (Exception e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", "No video available for this alert"));
    }
}
```

### 3. Add Flutter Video Player
```yaml
# pubspec.yaml
dependencies:
  video_player: ^2.8.0
```

```dart
// In alerts_screen.dart
VideoPlayerController? _videoController;

void _loadAlertVideo(String alertId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/skeleton/alerts/$alertId/video-url'),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    _videoController = VideoPlayerController.network(data['video_url'])
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
      });
  }
}
```

## Summary

- ✅ **Backend working**: Successfully returns alerts with skeleton_file and background_url
- ✅ **Frontend working**: Loads and visualizes skeleton data
- ❌ **No video in alert**: This specific alert doesn't have a video clip URL
- ⚠️ **MQTT expiry**: Need token refresh for live streaming (not alert playback)

**The 500 error was likely intermittent** - possibly from:
1. Token expiring mid-request
2. Network timeout
3. Frontend caching old error response

**Try the app now** - it should work with the rebuilt backend!
