import 'dart:typed_data';
import 'dart:ui';

import '../models/detection.dart';
import '../utils/nms.dart';
import 'image_preprocessor.dart';

/// Matches scripts/verify_tflite.py's default confidence threshold so Dart
/// results are directly comparable to the Python reference run.
const double kConfidenceThreshold = 0.25;

/// Ultralytics' default NMS IoU threshold.
const double kIouThreshold = 0.45;

/// Decodes the raw (no built-in NMS) YOLOv8 TFLite output — empirically
/// confirmed shape [1, 4 + numClasses, numAnchors] = [1, 10, 8400] for this
/// 6-class model, boxes normalized to [0,1] in cx,cy,w,h form relative to the
/// model's 640x640 input — into detections in the original image's
/// coordinate space.
///
/// [rawOutput] is that tensor flattened row-major (batch 0 only), i.e.
/// value (channel c, anchor a) lives at `c * numAnchors + a`.
List<Detection> postprocess({
  required Float32List rawOutput,
  required int numAnchors,
  required List<String> labels,
  required PreprocessResult preprocess,
}) {
  final int numClasses = rawOutput.length ~/ numAnchors - 4;
  double pred(int c, int a) => rawOutput[c * numAnchors + a];

  final List<Rect> candidateBoxes = [];
  final List<double> candidateScores = [];
  final List<int> candidateClassIds = [];

  for (int a = 0; a < numAnchors; a++) {
    double bestScore = -1;
    int bestClass = -1;
    for (int c = 0; c < numClasses; c++) {
      final double score = pred(4 + c, a);
      if (score > bestScore) {
        bestScore = score;
        bestClass = c;
      }
    }
    if (bestScore < kConfidenceThreshold) continue;

    final double cx = pred(0, a);
    final double cy = pred(1, a);
    final double w = pred(2, a);
    final double h = pred(3, a);

    // Normalized [0,1] relative to the model's 640x640 input canvas -> pixel
    // coords within that same canvas.
    final double x1 = (cx - w / 2) * kModelInputSize;
    final double y1 = (cy - h / 2) * kModelInputSize;
    final double x2 = (cx + w / 2) * kModelInputSize;
    final double y2 = (cy + h / 2) * kModelInputSize;

    candidateBoxes.add(Rect.fromLTRB(x1, y1, x2, y2));
    candidateScores.add(bestScore);
    candidateClassIds.add(bestClass);
  }

  final List<int> keepIdx = nonMaxSuppression(
    boxes: candidateBoxes,
    scores: candidateScores,
    classIds: candidateClassIds,
    iouThreshold: kIouThreshold,
  );

  final List<Detection> results = [];
  for (final int idx in keepIdx) {
    final Rect box = candidateBoxes[idx];

    // Undo letterbox padding/scale to land back in the original image's
    // pixel coordinate space.
    final double origX1 =
        ((box.left - preprocess.padX) / preprocess.scale).clamp(0, preprocess.origWidth.toDouble());
    final double origY1 =
        ((box.top - preprocess.padY) / preprocess.scale).clamp(0, preprocess.origHeight.toDouble());
    final double origX2 =
        ((box.right - preprocess.padX) / preprocess.scale).clamp(0, preprocess.origWidth.toDouble());
    final double origY2 =
        ((box.bottom - preprocess.padY) / preprocess.scale).clamp(0, preprocess.origHeight.toDouble());

    final int classId = candidateClassIds[idx];
    results.add(Detection(
      classId: classId,
      className: classId < labels.length ? labels[classId] : 'class_$classId',
      confidence: candidateScores[idx],
      box: Rect.fromLTRB(origX1, origY1, origX2, origY2),
    ));
  }

  return results;
}
