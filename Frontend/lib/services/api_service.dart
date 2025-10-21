import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/camera.dart';
import '../models/skeleton_stream_config.dart';
import '../models/alert.dart';

class ApiService {
  final String baseUrl;

  // Constructor with default baseUrl
  ApiService({String? baseUrl}) 
      : baseUrl = baseUrl ?? _getDefaultBaseUrl();

  // Automatically detect the right base URL
  static String _getDefaultBaseUrl() {
    // For macOS development (you're on Mac)
    return 'http://localhost:8080';
    
    // For Android Emulator, use: 'http://10.0.2.2:8080'
    // For physical device, use: 'http://YOUR_MAC_IP:8080'
  }

  Future<List<Camera>> getCameras() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/cameras'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Camera.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cameras: ${response.statusCode}');
    }
  }

  Future<SkeletonStreamConfig> getStreamConfig(int cameraId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/stream-config/$cameraId'),
    );

    if (response.statusCode == 200) {
      return SkeletonStreamConfig.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load stream config: ${response.statusCode}');
    }
  }

  Future<List<Alert>> getAlerts({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/alerts?limit=$limit'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Alert.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load alerts: ${response.statusCode}');
    }
  }

  Future<Alert> getAlertById(String alertId) async {
    print('🔍 Fetching alert: $alertId from $baseUrl/api/skeleton/alerts/$alertId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/alerts/$alertId'),
    );

    print('📥 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ Response body length: ${response.body.length}');
      final jsonData = jsonDecode(response.body);
      print('📝 Parsed JSON keys: ${jsonData.keys.toList()}');
      print('📝 Alert ID from response: ${jsonData['id']}');
      return Alert.fromJson(jsonData);
    } else {
      print('❌ Error response: ${response.body}');
      throw Exception('Failed to load alert: ${response.statusCode}');
    }
  }

  /// Get decoded skeleton data for an alert
  /// Returns the skeleton data in JSON format (already decoded from binary)
  Future<Map<String, dynamic>> getAlertSkeletonDecoded(String alertId) async {
    print('🦴 Fetching decoded skeleton for alert: $alertId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/alerts/$alertId/skeleton-decoded'),
    );

    print('📥 Skeleton response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      print('✅ Decoded skeleton data received');
      return jsonData as Map<String, dynamic>;
    } else {
      print('❌ Error getting skeleton: ${response.body}');
      throw Exception('Failed to load skeleton data: ${response.statusCode}');
    }
  }

  /// Get fresh background image URL for an alert
  /// This fetches a new pre-signed S3 URL that won't be expired
  Future<String> getAlertBackgroundUrl(String alertId) async {
    print('🖼️ Fetching fresh background URL for alert: $alertId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/alerts/$alertId/background-url'),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final url = jsonData['background_url'] as String;
      print('✅ Fresh background URL received');
      return url;
    } else {
      print('❌ Error getting background URL: ${response.body}');
      throw Exception('Failed to load background URL: ${response.statusCode}');
    }
  }

  /// Get video clip URL for an alert
  Future<String> getAlertVideoUrl(String alertId) async {
    print('🎥 Fetching video URL for alert: $alertId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/alerts/$alertId/video-url'),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final url = jsonData['video_url'] as String;
      print('✅ Video URL received');
      return url;
    } else {
      print('❌ Error getting video URL: ${response.body}');
      throw Exception('Failed to load video URL: ${response.statusCode}');
    }
  }

  /// Get current view/snapshot from camera
  /// Returns the image as bytes
  Future<Uint8List> getCameraView(int cameraId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/cameras/$cameraId/view'),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load camera view: ${response.statusCode}');
    }
  }

  /// Get background image from camera
  /// Returns the image as bytes
  Future<Uint8List> getCameraBackground(int cameraId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/cameras/$cameraId/background'),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load camera background: ${response.statusCode}');
    }
  }
}