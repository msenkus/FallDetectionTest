class Alert {
  final String id;
  final String alertType;
  final String cameraSerialNumber;
  final int createdAt;
  final String? skeletonFile;

  Alert({
    required this.id,
    required this.alertType,
    required this.cameraSerialNumber,
    required this.createdAt,
    this.skeletonFile,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      alertType: json['alert_type'],
      cameraSerialNumber: json['camera_serial_number'],
      createdAt: json['created_at'],
      skeletonFile: json['skeleton_file'],
    );
  }
}