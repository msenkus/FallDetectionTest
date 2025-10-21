# AltumView Skeleton Viewer

A full-stack application for viewing skeleton data from AltumView cameras. The project consists of a **Spring Boot backend** (Java) and a **Flutter frontend**.

## Project Structure

```
FallDetectionTest/
├── Backend/           # Spring Boot REST API
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/example/demo/
│   │   │   │   ├── DemoApplication.java
│   │   │   │   ├── config/WebConfig.java
│   │   │   │   ├── controller/SkeletonController.java
│   │   │   │   ├── service/AltumViewService.java
│   │   │   │   └── dto/
│   │   │   └── resources/application.properties
│   │   └── test/
│   └── pom.xml
└── Frontend/          # Flutter mobile/web app
    ├── lib/
    │   ├── main.dart
    │   ├── models/
    │   ├── screens/
    │   ├── services/
    │   └── widgets/
    └── pubspec.yaml
```

## Prerequisites

### Backend
- **Java 17** or higher
- **Maven 3.6+** (included via `mvnw`)

### Frontend
- **Flutter 3.0+** (already installed)
- **Chrome** or **Android Studio/Xcode** for running the app

## Setup & Configuration

### 1. Backend Configuration

Edit `Backend/src/main/resources/application.properties`:

```properties
# AltumView API Configuration
altumview.client-id=YOUR_CLIENT_ID_HERE
altumview.client-secret=YOUR_CLIENT_SECRET_HERE
```

Replace `YOUR_CLIENT_ID_HERE` and `YOUR_CLIENT_SECRET_HERE` with your actual AltumView API credentials.

### 2. Frontend Configuration

Edit `Frontend/lib/services/api_service.dart` and update the `baseUrl`:

```dart
final ApiService apiService = ApiService(baseUrl: 'http://localhost:8080');
```

If running on a physical device, replace `localhost` with your computer's IP address.

## Running the Application

### First Time Setup

If this is your first time running the Flutter app, enable web and macOS support:

```bash
cd Frontend
flutter create . --platforms web,macos
```

### Start the Backend

1. Navigate to the Backend directory:
   ```bash
   cd Backend
   ```

2. Run the Spring Boot application:
   ```bash
   ./mvnw spring-boot:run
   ```

   The backend will start on **http://localhost:8080**

### Start the Frontend

1. Open a new terminal and navigate to the Frontend directory:
   ```bash
   cd Frontend
   ```

2. Run the Flutter app:
   - **For Web (Chrome):**
     ```bash
     flutter run -d chrome
     ```
   
   - **For macOS Desktop:**
     ```bash
     flutter run -d macos
     ```
   
   - **For Android (with device/emulator connected):**
     ```bash
     flutter run
     ```
   
   - **For iOS (Mac only, with simulator):**
     ```bash
     flutter run -d ios
     ```

## API Endpoints

The backend exposes the following REST endpoints:

- `GET /api/skeleton/cameras` - Get list of available cameras
- `GET /api/skeleton/stream-config/{cameraId}` - Get streaming configuration for a camera
- `GET /api/skeleton/alerts?limit=10` - Get recent alerts
- `GET /api/skeleton/alerts/{alertId}` - Get specific alert by ID

## Features

- **Camera Selection**: View and select from available AltumView cameras
- **Real-time Skeleton Streaming**: Connect to MQTT broker and receive skeleton data
- **Skeleton Visualization**: Display skeleton keypoints and connections in real-time
- **Person Detection**: Show number of people detected
- **Fall Detection**: View alerts and skeleton data from fall detection events

## Technology Stack

### Backend
- Spring Boot 3.2.0
- Spring WebFlux (for reactive WebClient)
- Java 17
- Maven

### Frontend
- Flutter 3.35.4
- Dart
- MQTT Client (for real-time streaming)
- HTTP package (for REST API calls)

## Development

### Backend Development

To compile only (without running):
```bash
cd Backend
./mvnw clean compile
```

To run tests:
```bash
./mvnw test
```

To package as JAR:
```bash
./mvnw clean package
```

### Frontend Development

To get dependencies:
```bash
cd Frontend
flutter pub get
```

To run in debug mode:
```bash
flutter run --debug
```

To build for production:
- Web: `flutter build web`
- Android: `flutter build apk`
- iOS: `flutter build ios`

## Troubleshooting

### Backend Issues

1. **Port already in use**: Change the port in `application.properties`:
   ```properties
   server.port=8081
   ```

2. **Authentication failed**: Verify your AltumView API credentials

3. **CORS errors**: The WebConfig is already set up to allow all origins in development

### Frontend Issues

1. **Cannot connect to backend**: 
   - Verify backend is running on port 8080
   - Check the `baseUrl` in `api_service.dart`
   - On Android emulator, use `10.0.2.2` instead of `localhost`

2. **MQTT connection failed**:
   - Ensure you have valid MQTT credentials from the backend
   - Check firewall settings

3. **Flutter dependencies not found**:
   ```bash
   flutter pub get
   flutter clean
   flutter pub get
   ```

## Status

✅ Backend: Successfully compiled and ready to run
✅ Frontend: Dependencies installed and error-free
✅ Configuration: Requires API credentials to be added

## Next Steps

1. Add your AltumView API credentials to `application.properties`
2. Start the backend server
3. Run the Flutter app
4. Select a camera and start streaming!

## License

This project is for demonstration purposes.
