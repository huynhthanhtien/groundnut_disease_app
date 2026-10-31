import 'dart:ui';

double _iou(Rect a, Rect b) {
  final double interLeft = a.left > b.left ? a.left : b.left;
  final double interTop = a.top > b.top ? a.top : b.top;
  final double interRight = a.right < b.right ? a.right : b.right;
  final double interBottom = a.bottom < b.bottom ? a.bottom : b.bottom;

  final double interW = (interRight - interLeft).clamp(0, double.infinity);
  final double interH = (interBottom - interTop).clamp(0, double.infinity);
  final double interArea = interW * interH;

  final double areaA = a.width * a.height;
  final double areaB = b.width * b.height;

  return interArea / (areaA + areaB - interArea + 1e-9);
}

/// Class-aware greedy NMS. Mirrors the Python reference implementation used
/// to validate this algorithm against Ultralytics' own NMS (see
/// android_Computer-vision's scratch verification script): sort all
/// candidates by descending score, repeatedly keep the top candidate and
/// discard any *same-class* candidate whose IoU with it exceeds [iouThreshold].
List<int> nonMaxSuppression({
  required List<Rect> boxes,
  required List<double> scores,
  required List<int> classIds,
  double iouThreshold = 0.45,
}) {
  final List<int> order = List<int>.generate(boxes.length, (i) => i)
    ..sort((a, b) => scores[b].compareTo(scores[a]));

  final List<int> keep = [];
  final List<bool> suppressed = List<bool>.filled(boxes.length, false);

  for (int i = 0; i < order.length; i++) {
    final int idx = order[i];
    if (suppressed[idx]) continue;
    keep.add(idx);

    for (int j = i + 1; j < order.length; j++) {
      final int otherIdx = order[j];
      if (suppressed[otherIdx]) continue;
      if (classIds[otherIdx] != classIds[idx]) continue;
      if (_iou(boxes[idx], boxes[otherIdx]) > iouThreshold) {
        suppressed[otherIdx] = true;
      }
    }
  }

  return keep;
}
