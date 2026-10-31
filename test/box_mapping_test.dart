import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groundnut_disease_app/utils/box_mapping.dart';

void main() {
  test('cover: wide photo in a tall view is cropped horizontally, not stretched', () {
    // 2000x1000 photo into a 300x300 view: scale 0.3, scaled width 600, so
    // 150px is cropped off each side.
    const imageSize = Size(2000, 1000);
    const viewSize = Size(300, 300);
    final r = mapImageRectToView(const Rect.fromLTRB(1000, 0, 1500, 500), imageSize, viewSize);
    expect(r.left, closeTo(150, 1e-6)); // 1000*0.3 - 150
    expect(r.top, closeTo(0, 1e-6));
    expect(r.right, closeTo(300, 1e-6)); // 1500*0.3 - 150
    expect(r.bottom, closeTo(150, 1e-6));
    // Box stays square like the source region (independent-axis scaling
    // would have produced a 75x150 rectangle).
    expect(r.width, closeTo(r.height, 1e-6));
  });

  test('contain: letterboxes with offset', () {
    const imageSize = Size(1000, 500);
    const viewSize = Size(200, 200);
    final r = mapImageRectToView(const Rect.fromLTRB(0, 0, 1000, 500), imageSize, viewSize, fit: BoxFit.contain);
    expect(r, const Rect.fromLTRB(0, 50, 200, 150));
  });

  test('fill: matches simple per-axis scaling', () {
    final r = mapImageRectToView(
      const Rect.fromLTRB(10, 20, 30, 40),
      const Size(100, 100),
      const Size(200, 50),
      fit: BoxFit.fill,
    );
    expect(r, const Rect.fromLTRB(20, 10, 60, 20));
  });
}
