// Cross-checks the Dart decode+NMS implementation against a reference raw
// TFLite output captured from android_Computer-vision (Python, ai_edge_litert
// interpreter) and Ultralytics' own NMS result on the same image. See
// test/fixtures/raw_output.json (the model's raw [1,10,8400] output for
// data/test/images/5454106-THUMB_....jpg) and
// test/fixtures/expected_detections.json (Ultralytics' NMS'd result on the
// same tensor). If this test starts failing after changing
// yolo_postprocess.dart or nms.dart, compare against those fixtures before
// assuming the fixtures are stale.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:groundnut_disease_app/services/image_preprocessor.dart';
import 'package:groundnut_disease_app/services/yolo_postprocess.dart';

void main() {
  test('postprocess matches Ultralytics reference decode on a known tensor', () {
    final rawJson = jsonDecode(File('test/fixtures/raw_output.json').readAsStringSync());
    final expectedJson = jsonDecode(File('test/fixtures/expected_detections.json').readAsStringSync()) as List;

    // rawJson shape: [1, 10, 8400] as nested dynamic lists -> flatten batch
    // 0 row-major into the Float32List postprocess() expects.
    final List<dynamic> rows = (rawJson as List)[0] as List;
    final int numAnchors = (rows[0] as List).length;
    final Float32List rawOutput = Float32List.fromList([
      for (final row in rows)
        for (final v in row as List) (v as num).toDouble(),
    ]);

    const labels = [
      'Black Fungus Pod',
      'Early and Late leaf spot',
      'Fungus leaf',
      'Rust-Leaf',
      'black fungus-grondnut',
      'brown Fungus Pod',
    ];

    // The reference image is already 640x640 (Roboflow-exported dataset),
    // resized (not letterboxed) directly to the model input, so scale=1 and
    // padding=0 reproduce the exact same coordinate space as the Python fixture.
    final preprocess = PreprocessResult(
      inputTensor: Float32List(0),
      scale: 1.0,
      padX: 0,
      padY: 0,
      origWidth: 640,
      origHeight: 640,
    );

    final detections = postprocess(rawOutput: rawOutput, numAnchors: numAnchors, labels: labels, preprocess: preprocess);

    expect(detections.length, expectedJson.length);

    for (var i = 0; i < detections.length; i++) {
      final expected = expectedJson[i] as Map<String, dynamic>;
      expect(detections[i].classId, expected['class_id']);
      expect(detections[i].className, expected['class_name']);
      expect(detections[i].confidence, closeTo((expected['confidence'] as num).toDouble(), 1e-4));

      final xyxy = (expected['xyxy'] as List).map((v) => (v as num).toDouble()).toList();
      // Tolerance covers both float rounding and postprocess() clamping
      // slightly-out-of-bounds coords (e.g. a box edge at x=-0.0012*640) to 0.
      expect(detections[i].box.left, closeTo(xyxy[0] * 640, 1.0));
      expect(detections[i].box.top, closeTo(xyxy[1] * 640, 1.0));
      expect(detections[i].box.right, closeTo(xyxy[2] * 640, 1.0));
      expect(detections[i].box.bottom, closeTo(xyxy[3] * 640, 1.0));
    }
  });
}
