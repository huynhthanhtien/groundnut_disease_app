import 'package:flutter/material.dart';

import '../models/detection.dart';
import '../theme/app_colors.dart';
import '../utils/box_mapping.dart';

/// Draws detection boxes + labels over an image displayed at an arbitrary
/// rendered size. [originalImageWidth]/[originalImageHeight] must be the
/// pixel dimensions of the *decoded* image the [detections] boxes are
/// expressed in (see YoloModelService.runInference), and [fit] must match
/// the `BoxFit` the image underneath is painted with.
class BoundingBoxOverlay extends StatelessWidget {
  final List<Detection> detections;
  final int originalImageWidth;
  final int originalImageHeight;
  final BoxFit fit;

  /// Index into [detections] to emphasise (others are dimmed), or null.
  final int? highlighted;

  const BoundingBoxOverlay({
    super.key,
    required this.detections,
    required this.originalImageWidth,
    required this.originalImageHeight,
    this.fit = BoxFit.cover,
    this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _BoundingBoxPainter(
        detections: detections,
        imageSize: Size(originalImageWidth.toDouble(), originalImageHeight.toDouble()),
        fit: fit,
        highlighted: highlighted,
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;
  final BoxFit fit;
  final int? highlighted;

  _BoundingBoxPainter({
    required this.detections,
    required this.imageSize,
    required this.fit,
    required this.highlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    for (int i = 0; i < detections.length; i++) {
      final Detection detection = detections[i];
      final bool dimmed = highlighted != null && highlighted != i;
      final Color color = AppColors.forClass(detection.className).withValues(alpha: dimmed ? 0.35 : 1);
      final Rect scaledRect = mapImageRectToView(detection.box, imageSize, size, fit: fit);

      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlighted == i ? 4 : 3
          ..color = color,
      );

      final String label = '${(detection.confidence * 100).toStringAsFixed(0)}%';
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: dimmed ? 0.6 : 1),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double labelTop = (scaledRect.top - textPainter.height - 10).clamp(0, size.height);
      final double labelLeft = scaledRect.left.clamp(0, size.width - textPainter.width - 14);
      final Rect labelBgRect = Rect.fromLTWH(
        labelLeft,
        labelTop,
        textPainter.width + 14,
        textPainter.height + 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelBgRect, const Radius.circular(6)),
        Paint()..color = color,
      );
      textPainter.paint(canvas, Offset(labelBgRect.left + 7, labelBgRect.top + 3));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.fit != fit ||
        oldDelegate.highlighted != highlighted;
  }
}
