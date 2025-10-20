// lib/widgets/skeleton_painter.dart
import 'package:flutter/material.dart';
import '../models/skeleton_frame.dart';

class SkeletonPainter extends CustomPainter {
  final SkeletonFrame? frame;
  
  // Skeleton connections
  static const List<List<int>> connections = [
    [0, 1], [1, 2], [2, 3], [3, 4],     // Head to right arm
    [1, 5], [5, 6], [6, 7],             // Left arm
    [1, 8], [8, 9], [9, 10],            // Right torso to leg
    [8, 11], [11, 12], [12, 13],        // Left leg
    [1, 14], [14, 15], [15, 16], [16, 17] // Spine
  ];

  SkeletonPainter(this.frame);

  @override
  void paint(Canvas canvas, Size size) {
    if (frame == null || frame!.people.isEmpty) {
      return;
    }

    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (var person in frame!.people) {
      // Draw connections
      for (var connection in connections) {
        final p1 = person[connection[0]];
        final p2 = person[connection[1]];
        
        // Flip horizontally and convert to screen coordinates
        final x1 = (1 - p1.x) * size.width;
        final y1 = p1.y * size.height;
        final x2 = (1 - p2.x) * size.width;
        final y2 = p2.y * size.height;
        
        // Only draw if both points are valid
        if (x1 > 5 && y1 > 5 && x2 > 5 && y2 > 5) {
          canvas.drawLine(
            Offset(x1, y1),
            Offset(x2, y2),
            linePaint,
          );
        }
      }

      // Draw keypoints
      for (var keypoint in person) {
        final x = (1 - keypoint.x) * size.width;
        final y = keypoint.y * size.height;
        
        if (x > 5 && y > 5) {
          canvas.drawCircle(Offset(x, y), 5, pointPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) => true;
}