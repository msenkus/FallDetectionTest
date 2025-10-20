// lib/services/mqtt_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart' show Uint8Buffer;
import '../models/skeleton_frame.dart';
import '../models/skeleton_stream_config.dart';

class MqttService {
  MqttServerClient? client;
  SkeletonStreamConfig? config;
  Timer? tokenPublishTimer;
  
  final StreamController<SkeletonFrame> _skeletonController = 
      StreamController<SkeletonFrame>.broadcast();
  
  Stream<SkeletonFrame> get skeletonStream => _skeletonController.stream;
  
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> connect(SkeletonStreamConfig streamConfig) async {
    config = streamConfig;
    
    // Parse WSS URL - extract just the host and port
    final uri = Uri.parse(streamConfig.wssUrl);
    final host = uri.host;
    final port = uri.port;
    
    print('Parsed WSS URL: ${streamConfig.wssUrl}');
    print('Host: $host, Port: $port, Scheme: ${uri.scheme}');
    
    // Create client with unique ID
    final clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient.withPort(host, clientId, port);
    
    // Configure WebSocket
    client!.useWebSocket = true;
    client!.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    
    // Enable logging to debug connection issues
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    client!.autoReconnect = false;
    
    // Set secure flag based on the URL scheme
    client!.secure = uri.scheme == 'wss';
    
    // Callbacks
    client!.onConnected = _onConnected;
    client!.onDisconnected = _onDisconnected;
    
    // IMPORTANT: For desktop/macOS, we need to handle SSL differently
    // Accept all certificates to avoid SecurityContext issues
    if (client!.secure) {
      client!.onBadCertificate = (dynamic cert) {
        print('Warning: Bad certificate detected, allowing connection');
        return true; // Accept the certificate
      };
    }
    
    // Set up connection message
    final connMessage = MqttConnectMessage()
        .authenticateAs(streamConfig.mqttUsername, streamConfig.mqttPassword)
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    
    client!.connectionMessage = connMessage;
    
    try {
      print('🔄 Connecting to MQTT broker...');
      print('   Host: $host');
      print('   Port: $port');
      print('   Secure: ${client!.secure}');
      print('   Username: ${streamConfig.mqttUsername}');
      print('   Client ID: $clientId');
      
      final status = await client!.connect();
      
      if (status?.state == MqttConnectionState.connected) {
        print('✓ MQTT connection successful!');
      } else {
        print('✗ MQTT connection failed');
        print('   State: ${status?.state}');
        print('   Return code: ${status?.returnCode}');
        _connectionController.add(false);
      }
    } catch (e, stackTrace) {
      print('✗ MQTT Connection exception: $e');
      print('Stack trace: $stackTrace');
      client?.disconnect();
      _connectionController.add(false);
      rethrow;
    }
  }

  void _onConnected() {
    print('✓ Connected to MQTT');
    _connectionController.add(true);
    
    // Subscribe to skeleton topic
    client!.subscribe(config!.subscribeTopic, MqttQos.atMostOnce);
    print('✓ Subscribed to ${config!.subscribeTopic}');
    
    // Listen for messages
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final message = messages[0].payload as MqttPublishMessage;
      final payload = message.payload.message;
      _parseSkeletonData(payload);
    });
    
    // Publish stream token immediately
    _publishStreamToken();
    
    // Publish every 45 seconds
    tokenPublishTimer = Timer.periodic(Duration(seconds: 45), (_) {
      _publishStreamToken();
    });
  }

  void _onDisconnected() {
    print('✗ Disconnected from MQTT');
    _connectionController.add(false);
    tokenPublishTimer?.cancel();
  }

  void _publishStreamToken() {
    if (client != null && config != null) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(config!.streamToken.toString());
      client!.publishMessage(
        config!.publishTopic,
        MqttQos.atMostOnce,
        builder.payload!,
      );
      print('→ Published stream token');
    }
  }

  void _parseSkeletonData(Uint8Buffer payload) {
    try {
      // Convert Uint8Buffer to Uint8List
      final bytes = Uint8List.fromList(payload.toList());
      final byteData = ByteData.sublistView(bytes);
      
      int offset = 0;
      
      // Read number of people
      final numPeople = byteData.getUint8(offset);
      offset += 1;
      
      if (numPeople == 0) {
        _skeletonController.add(SkeletonFrame([]));
        return;
      }
      
      List<List<SkeletonKeypoint>> people = [];
      
      for (int i = 0; i < numPeople; i++) {
        List<SkeletonKeypoint> keypoints = [];
        
        // Read 18 keypoints (x, y as floats)
        for (int j = 0; j < 18; j++) {
          final x = byteData.getFloat32(offset, Endian.little);
          offset += 4;
          final y = byteData.getFloat32(offset, Endian.little);
          offset += 4;
          
          keypoints.add(SkeletonKeypoint(x, y));
        }
        
        people.add(keypoints);
      }
      
      _skeletonController.add(SkeletonFrame(people));
    } catch (e) {
      print('Error parsing skeleton data: $e');
    }
  }

  void disconnect() {
    tokenPublishTimer?.cancel();
    client?.disconnect();
  }

  void dispose() {
    disconnect();
    _skeletonController.close();
    _connectionController.close();
  }
}