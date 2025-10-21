# Quick Start Guide

## ✅ Status: Ready to Run!

Your project has been checked and is error-free! Follow these steps to get it running.

## 1. Configure Your API Credentials

Edit this file: `Backend/src/main/resources/application.properties`

Replace these values with your AltumView API credentials:
```properties
altumview.client-id=YOUR_CLIENT_ID_HERE
altumview.client-secret=YOUR_CLIENT_SECRET_HERE
```

## 2. Start the Backend

Open a terminal in the `Backend` directory and run:

```bash
cd Backend
./mvnw spring-boot:run
```

Wait for the message: `Started DemoApplication in X seconds`

The backend is now running on: **http://localhost:8080**

## 3. Start the Frontend

Open a **new terminal** in the `Frontend` directory and run:

```bash
cd Frontend
flutter run -d chrome
```

This will start the Flutter app in Chrome.

## What You Should See

1. **Backend Terminal**: Spring Boot logs showing the server is running
2. **Browser**: The Skeleton Viewer app with a dropdown to select cameras

## Using the App

1. Select a camera from the dropdown
2. Click "Connect" to start streaming
3. You'll see skeleton data visualized in real-time
4. The status bar shows the number of people detected

## Troubleshooting

### Backend Won't Start
- Make sure Java 17+ is installed: `java --version`
- Check if port 8080 is already in use
- Verify your API credentials are correct

### Frontend Won't Connect
- Make sure the backend is running first
- Check the browser console for errors (F12)
- Verify the API base URL in `lib/services/api_service.dart`

### No Skeleton Data Appearing
- Ensure the camera is online
- Check MQTT credentials are valid
- Look for error messages in both terminals

## Development Tips

### Backend Changes
- The app auto-restarts when you save changes
- Check logs in the terminal for debugging
- API docs at `http://localhost:8080/api/skeleton`

### Frontend Changes
- Hot reload: Press `r` in the Flutter terminal
- Full restart: Press `R`
- Debug tools: Available in Chrome DevTools

## Project Health

✅ Backend compiled successfully  
✅ Frontend dependencies installed  
✅ No errors in Dart/Flutter code  
✅ Configuration files ready  
⚠️  Needs API credentials to run

## Next Steps

Once running, you can:
- View real-time skeleton tracking
- See fall detection alerts
- Monitor multiple cameras
- Export skeleton data

For more details, see the main README.md file.
