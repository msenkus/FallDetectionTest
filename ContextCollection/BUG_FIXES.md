# Bug Fixes - Camera Images and Live Monitoring

## Issues Fixed

### 1. Camera Images 500 Error
**Problem**: Getting a 500 error when trying to view camera images.

**Root Cause**: The backend was using `StreamToken` instead of `PreviewToken` for camera view/snapshot endpoints.

**Solution**:
- Updated `AltumViewService.getCameraView()` to use `getPreviewToken()` instead of `getStreamToken()`
- Added better error handling and logging with stack traces
- Added try-catch blocks in the controller endpoints

**Files Modified**:
- `/Backend/src/main/java/com/example/demo/service/AltumViewService.java`
- `/Backend/src/main/java/com/example/demo/controller/SkeletonController.java`

### 2. Live Monitoring SecurityContext Error
**Problem**: "Failed to connect: Unsupported operation: Default SecurityContext getter" error when connecting to MQTT.

**Root Cause**: The `mqtt_client` library on macOS/desktop doesn't properly handle SSL/TLS certificates by default. The library needs explicit configuration for secure WebSocket connections.

**Solution**:
- Set `client!.secure = uri.scheme == 'wss'` to explicitly enable secure mode for WSS connections
- Kept the `onBadCertificate` callback to accept self-signed certificates
- Added better logging to debug connection issues

**Files Modified**:
- `/Frontend/lib/services/mqtt_service.dart`

## Changes Made

### Backend Changes

#### AltumViewService.java
```java
// Before: Used stream token (incorrect)
StreamToken streamToken = getStreamToken(cameraId);
String url = apiUrl + "/cameras/" + cameraId + "/view?preview_token=" + streamToken.getStreamToken();

// After: Uses preview token (correct)
PreviewToken previewToken = getPreviewToken(cameraId);
String url = apiUrl + "/cameras/" + cameraId + "/view?preview_token=" + previewToken.getPreviewToken();
```

#### SkeletonController.java
```java
// Added try-catch error handling for both endpoints
@GetMapping("/cameras/{cameraId}/view")
public ResponseEntity<byte[]> getCameraView(@PathVariable Long cameraId) {
    try {
        byte[] imageBytes = altumViewService.getCameraView(cameraId);
        // ... return response
    } catch (Exception e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
    }
}
```

### Frontend Changes

#### mqtt_service.dart
```dart
// Added explicit secure flag
client!.secure = uri.scheme == 'wss';

// Kept bad certificate handler for self-signed certs
if (client!.secure) {
  client!.onBadCertificate = (dynamic cert) {
    print('Warning: Bad certificate detected, allowing connection');
    return true;
  };
}
```

## Testing

### Camera Images
1. Navigate to the Camera Images page
2. Select a camera from the dropdown
3. Verify that both "Current View" and "Background Image" load successfully
4. Click the refresh button to reload images

### Live Monitoring
1. Navigate to the Live Monitoring page
2. Select a camera
3. Click "Start Streaming"
4. Verify connection establishes without SecurityContext error
5. Verify skeleton data streams appear on the video feed

## Expected Behavior

### Camera Images
- Camera view should load successfully (may take a few seconds)
- Background image should load successfully from S3
- If images fail to load, snackbar error messages will appear
- Refresh button reloads both images

### Live Monitoring
- MQTT connection should establish without SSL/TLS errors
- WebSocket should connect using WSS (secure)
- Self-signed certificates are accepted automatically
- Skeleton overlay should appear on video feed when people are detected
- Stream token is published every 45 seconds to maintain connection

## Notes

- The backend must be restarted after code changes (already rebuilt)
- The Flutter app must be hot-restarted or rebuilt to apply MQTT changes
- Port 8080 must be available for the backend
- The MQTT broker uses self-signed certificates which are now properly handled

## Additional Improvements

1. **Better Error Messages**: Added stack traces to backend logging for easier debugging
2. **Error Handling**: Frontend shows user-friendly snackbar messages on failures
3. **Connection Logging**: Added detailed MQTT connection logs including host, port, and secure flag

## Known Limitations

- Camera view images require a valid preview token which may expire
- Background images are fetched from S3 with pre-signed URLs that expire
- MQTT connection requires accepting self-signed certificates (security trade-off)
