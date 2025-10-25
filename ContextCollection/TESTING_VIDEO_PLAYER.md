# Testing the Skeleton Video Player 🎬

## Quick Test Guide

### ✅ Prerequisites (Already Done)
- Backend running on port 8080 ✓
- Flutter app running in Chrome ✓
- Alert with skeleton data exists ✓

### 🧪 Test Steps

1. **Open the Flutter app in Chrome**
   - Should already be open at `http://localhost:xxxxx`
   - If not, run: `cd Frontend && flutter run -d chrome`

2. **Navigate to Alerts Screen**
   - Click on "Alerts" in the navigation

3. **Select an Alert**
   - Click on any alert in the left panel
   - The alert details will load on the right

4. **What You'll See**

   **Expected Behavior:**
   - Loading indicator while fetching skeleton data
   - Background image from the camera
   - Video player controls at the bottom:
     - ⏮️ Previous Frame
     - ▶️/⏸️ Play/Pause button
     - ⏭️ Next Frame
     - 🔄 Restart button
   - Frame slider to scrub through frames
   - Frame counter (e.g., "Frame 1 of 54")
   - Person count (e.g., "1 person(s) detected")

   **Current Known Issue:**
   - Video player may show "No skeleton frames available" 
   - This is because the backend decoder is returning 0 frames
   - The UI is ready, but the data isn't being decoded properly

### 🔍 Debug Info

You can check the browser console (F12) to see:
```
🦴 Fetching decoded skeleton for alert: 68f166168eeae9e50d48e58a
📥 Skeleton response status: 200
✅ Decoded skeleton data received
📦 Parsing X frames
```

If it says "Parsing 0 frames", that confirms the decoder issue.

### 🎯 What Should Work

Even with the decoder issue, you should see:
- ✅ Alert list loading correctly
- ✅ Alert selection working
- ✅ Background image displaying
- ✅ Video player UI (even if no frames)
- ✅ Console logs showing API calls

### 📊 Backend Status Check

Open a terminal and run:
```bash
# Check if backend is responding
curl -s http://localhost:8080/api/skeleton/cameras | jq '.[0].friendly_name'

# Check if alert has skeleton data
curl -s "http://localhost:8080/api/skeleton/alerts/68f166168eeae9e50d48e58a" \
  | jq '{has_skeleton: (.skeleton_file != null)}'

# Check decoder output (currently returns 0 frames)
curl -s "http://localhost:8080/api/skeleton/alerts/68f166168eeae9e50d48e58a/skeleton-decoded" \
  | jq '{totalFrames}'
```

### 🐛 Known Issues

1. **Decoder Returns 0 Frames**: The `SkeletonDecoder.decodeSingleFrame()` is silently failing
   - Alert has 4592 bytes of skeleton data
   - Should produce ~28-29 frames
   - Currently returns empty array

2. **No Error Messages**: Decoder catches exceptions and returns null silently
   - Makes debugging harder
   - Need to add logging

### 💡 Next Steps (After Testing)

If you confirm the UI is working but no frames show:
1. Add debug logging to `SkeletonDecoder.java`
2. Print binary data format details
3. Verify frame size calculations
4. Test with sample data

---

**Ready to test!** Open Chrome and navigate through the app to see the video player UI.
