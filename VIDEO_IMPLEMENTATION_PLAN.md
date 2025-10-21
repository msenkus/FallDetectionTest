# Alert Video Playback Implementation Plan

##

 Problem
The system needs to:
1. Display video clips from fall detection alerts
2. Maintain MQTT connection for live video streaming (expires after 45s)
3. Handle token refresh for long-running sessions

## Altumview API Endpoints for Video

Based on the API documentation, alerts can have associated video content accessed via:

1. **Alert Background Image**: `GET /alerts/{alertId}` → `background_url` field
2. **Alert Video Clip**: Likely `GET /alerts/{alertId}/clip` or similar
3. **Live Camera Stream**: Via MQTT with stream tokens (45s expiry)

## Implementation Steps

### 1. Add Alert Video Clip Endpoint (Backend)

```java
/**
 * Get video clip URL for an alert
 */
public String getAlertVideoClip(String alertId) {
    String token = getAccessToken();
    
    HttpHeaders headers = new HttpHeaders();
    headers.set("Authorization", "Bearer " + token);
    HttpEntity<String> entity = new HttpEntity<>(headers);
    
    try {
        ResponseEntity<Map> response = restTemplate.exchange(
            apiUrl + "/alerts/" + alertId + "/clip",  // or /video
            HttpMethod.GET,
            entity,
            Map.class
        );
        
        Map<String, Object> body = response.getBody();
        
        if (body != null && body.containsKey("data")) {
            Map<String, Object> data = (Map<String, Object>) body.get("data");
            String clipUrl = (String) data.get("clip_url");
            
            if (clipUrl != null && !clipUrl.isEmpty()) {
                log.info("✓ Retrieved video clip URL for alert {}", alertId);
                return clipUrl;
            }
        }
        
        throw new RuntimeException("No video clip available for alert");
        
    } catch (Exception e) {
        log.error("✗ Error getting alert video clip: {}", e.getMessage());
        throw new RuntimeException("Failed to get alert video clip: " + e.getMessage(), e);
    }
}
```

### 2. Add Video Clip to Alert DTO

```java
@Data
public class Alert {
    // ... existing fields ...
    
    @JsonProperty("video_clip_url")
    private String videoClipUrl;
    
    @JsonProperty("background_url")
    private String backgroundUrl;
}
```

### 3. Add Controller Endpoint

```java
@GetMapping("/alerts/{alertId}/video")
public ResponseEntity<Map<String, String>> getAlertVideo(@PathVariable String alertId) {
    try {
        String videoUrl = altumViewService.getAlertVideoClip(alertId);
        return ResponseEntity.ok(Map.of("video_url", videoUrl));
    } catch (Exception e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", e.getMessage()));
    }
}
```

### 4. MQTT Session Management

For live streaming that expires after 45 seconds:

```java
@Service
public class MqttSessionManager {
    private final AltumViewService altumViewService;
    private final Map<Long, MqttSession> activeSessions = new ConcurrentHashMap<>();
    
    @Scheduled(fixedRate = 30000) // Refresh every 30 seconds
    public void refreshExpiringSessions() {
        long now = System.currentTimeMillis() / 1000;
        
        activeSessions.forEach((cameraId, session) -> {
            if (session.getExpiresAt() - now < 15) {  // Refresh 15s before expiry
                try {
                    log.info("Refreshing MQTT session for camera {}", cameraId);
                    MqttCredentials newCreds = altumViewService.getMqttCredentials();
                    StreamToken newToken = altumViewService.getStreamToken(cameraId);
                    session.update(newCreds, newToken);
                } catch (Exception e) {
                    log.error("Failed to refresh MQTT session: {}", e.getMessage());
                }
            }
        });
    }
}
```

### 5. Frontend Video Player (Flutter)

```dart
// Add video_player dependency to pubspec.yaml
dependencies:
  video_player: ^2.8.0

// In alerts_screen.dart
import 'package:video_player/video_player.dart';

class AlertVideoPlayer extends StatefulWidget {
  final String videoUrl;
  
  @override
  _AlertVideoPlayerState createState() => _AlertVideoPlayerState();
}

class _AlertVideoPlayerState extends State<AlertVideoPlayer> {
  late VideoPlayerController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }
  
  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Center(child: CircularProgressIndicator());
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Next Steps

1. **Verify Alert Video Endpoint**: Test if `/alerts/{alertId}/clip` exists in Altumview API
2. **Add Backend Support**: Implement video clip retrieval
3. **Update Frontend**: Add video player widget to alerts screen
4. **Implement MQTT Session Management**: Auto-refresh tokens before expiry
5. **Add Error Handling**: Handle missing videos, expired tokens, network errors

## Immediate Action

The current 500 error is likely because:
1. The Altumview API token might be expiring
2. There might be rate limiting
3. The video endpoint might not exist or requires different auth

Let me first check what the actual error is and fix it.
