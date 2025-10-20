import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/alert.dart';
import '../models/skeleton_frame.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_painter.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _apiService = ApiService();
  List<Alert> _alerts = [];
  bool _isLoading = true;
  String? _error;
  Alert? _selectedAlert;
  SkeletonFrame? _skeletonFrame;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final alerts = await _apiService.getAlerts(limit: 50);
      
      // DEBUG: If no alerts found, try loading a test alert by ID
      if (alerts.isEmpty) {
        print('No alerts from API, attempting to load test alert...');
        try {
          final testAlert = await _apiService.getAlertById('68f166168eeae9e50d48e58a');
          print('Successfully loaded test alert: ${testAlert.id}');
          setState(() {
            _alerts = [testAlert];
            _isLoading = false;
          });
          return;
        } catch (e) {
          print('Failed to load test alert: $e');
        }
      }
      
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading alerts: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAlertDetails(Alert alert) async {
    setState(() {
      _selectedAlert = alert;
      _skeletonFrame = null;
    });

    try {
      print('Loading details for alert: ${alert.id}');
      
      // Fetch full alert details with skeleton file
      final fullAlert = await _apiService.getAlertById(alert.id);
      
      print('Alert details loaded, has skeleton file: ${fullAlert.skeletonFile != null}');
      
      if (fullAlert.skeletonFile != null && fullAlert.skeletonFile!.isNotEmpty) {
        print('Skeleton file length: ${fullAlert.skeletonFile!.length}');
        
        try {
          // Decode base64 skeleton file
          final decodedBytes = base64Decode(fullAlert.skeletonFile!);
          print('Decoded ${decodedBytes.length} bytes');
          
          final decodedString = utf8.decode(decodedBytes);
          print('Decoded string length: ${decodedString.length}');
          
          final jsonData = jsonDecode(decodedString);
          print('JSON decoded successfully');
          
          // Parse skeleton data
          final frame = SkeletonFrame.fromJson(jsonData);
          final totalKeypoints = frame.people.fold<int>(0, (sum, person) => sum + person.length);
          print('Skeleton frame parsed: ${frame.people.length} people, $totalKeypoints total keypoints');
          
          setState(() {
            _skeletonFrame = frame;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded skeleton: ${frame.people.length} people, $totalKeypoints keypoints'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          print('Error parsing skeleton data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error parsing skeleton data: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        print('No skeleton file in alert');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This alert does not have skeleton data'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error loading alert details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading skeleton data: $e')),
      );
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Detection Alerts'),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAlerts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _alerts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text('No alerts found', style: TextStyle(fontSize: 18)),
                          SizedBox(height: 8),
                          Text('System is operating normally', 
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        // Left panel - Alert list
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  color: Colors.grey.shade100,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_alerts.length} Alerts',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _alerts.length,
                                    itemBuilder: (context, index) {
                                      final alert = _alerts[index];
                                      final isSelected = _selectedAlert?.id == alert.id;
                                      
                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: Colors.blue.shade50,
                                        leading: Icon(
                                          _getAlertIcon(alert.alertType),
                                          color: _getAlertColor(alert.alertType),
                                          size: 32,
                                        ),
                                        title: Text(
                                          _formatAlertType(alert.alertType),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Camera: ${alert.cameraSerialNumber}'),
                                            Text(
                                              _formatTimestamp(alert.createdAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => _loadAlertDetails(alert),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Right panel - Alert details
                        Expanded(
                          flex: 2,
                          child: _selectedAlert == null
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.touch_app, size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'Select an alert to view details',
                                        style: TextStyle(fontSize: 18, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildAlertDetails(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildAlertDetails() {
    if (_selectedAlert == null) return const SizedBox();

    return Column(
      children: [
        // Alert header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getAlertColor(_selectedAlert!.alertType).withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getAlertIcon(_selectedAlert!.alertType),
                    size: 48,
                    color: _getAlertColor(_selectedAlert!.alertType),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatAlertType(_selectedAlert!.alertType),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTimestamp(_selectedAlert!.createdAt),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Alert ID:', _selectedAlert!.id),
              _buildInfoRow('Camera:', _selectedAlert!.cameraSerialNumber),
              _buildInfoRow('Type:', _selectedAlert!.alertType),
            ],
          ),
        ),
        
        // Skeleton visualization
        Expanded(
          child: _skeletonFrame == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading skeleton data...'),
                    ],
                  ),
                )
              : _skeletonFrame!.people.isEmpty
                  ? const Center(
                      child: Text('No skeleton data available'),
                    )
                  : Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomPaint(
                          painter: SkeletonPainter(_skeletonFrame!),
                          size: Size.infinite,
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  IconData _getAlertIcon(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'fall':
        return Icons.person_off;
      case 'loitering':
        return Icons.access_time;
      case 'intrusion':
        return Icons.warning;
      default:
        return Icons.notification_important;
    }
  }

  Color _getAlertColor(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'fall':
        return Colors.red;
      case 'loitering':
        return Colors.orange;
      case 'intrusion':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _formatAlertType(String alertType) {
    return alertType.split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
