import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:groundnut_disease_app/utils/nms.dart';

void main() {
  test('suppresses a lower-score box of the same class with high IoU overlap', () {
    final boxes = [
      const Rect.fromLTRB(0, 0, 100, 100),
      const Rect.fromLTRB(5, 5, 105, 105), // heavily overlaps box 0
    ];
    final scores = [0.9, 0.8];
    final classIds = [0, 0];

    final keep = nonMaxSuppression(boxes: boxes, scores: scores, classIds: classIds);

    expect(keep, [0]);
  });

  test('keeps overlapping boxes of different classes', () {
    final boxes = [
      const Rect.fromLTRB(0, 0, 100, 100),
      const Rect.fromLTRB(5, 5, 105, 105),
    ];
    final scores = [0.9, 0.8];
    final classIds = [0, 1];

    final keep = nonMaxSuppression(boxes: boxes, scores: scores, classIds: classIds);

    expect(keep.toSet(), {0, 1});
  });

  test('keeps non-overlapping boxes of the same class', () {
    final boxes = [
      const Rect.fromLTRB(0, 0, 50, 50),
      const Rect.fromLTRB(200, 200, 250, 250),
    ];
    final scores = [0.6, 0.95];
    final classIds = [0, 0];

    final keep = nonMaxSuppression(boxes: boxes, scores: scores, classIds: classIds);

    expect(keep.toSet(), {0, 1});
  });
}
