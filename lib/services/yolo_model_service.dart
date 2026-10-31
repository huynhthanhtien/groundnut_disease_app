import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection.dart';
import 'image_preprocessor.dart';
import 'yolo_postprocess.dart';

// FP32 export: LiteRT-Torch's quantized ("w8a32") export path produces ops
// the on-device tflite_flutter runtime rejects at invoke() time ("Bad state:
// failed precondition") — see android_Computer-vision's scripts/export.py.
// The unquantized FP32 export runs fine.
const String _modelAsset = 'assets/models/best_fp32.tflite';
const String _labelsAsset = 'assets/models/labels.txt';

class InferenceResult {
  final List<Detection> detections;

  /// Dimensions of the photo after EXIF orientation has been applied — the
  /// space [Detection.box] is expressed in.
  final int imageWidth;
  final int imageHeight;

  const InferenceResult({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });
}

/// Thrown when the picked file isn't a decodable image.
class UnreadableImageException implements Exception {
  const UnreadableImageException();
}

/// Loads the exported groundnut-disease TFLite model once and runs
/// single-image inference on demand. The model has no built-in NMS (see
/// android_Computer-vision's scripts/export.py), so decoding + NMS happens
/// in [postprocess].
///
/// Decode, preprocessing, `invoke()` and postprocessing all run on a
/// background isolate (sharing the native interpreter by address) so the UI
/// keeps animating while a scan is in progress.
class YoloModelService {
  YoloModelService._();

  static final YoloModelService instance = YoloModelService._();

  Interpreter? _interpreter;
  List<String>? _labels;
  Future<void>? _loading;

  bool get isLoaded => _interpreter != null && _labels != null;

  /// Loads the model ahead of the first scan. Safe to call repeatedly.
  Future<void> warmUp() => _loading ??= _load().catchError((Object e) {
        _loading = null;
        throw e;
      });

  Future<void> _load() async {
    final Interpreter interpreter = await Interpreter.fromAsset(_modelAsset);
    // Tensors must be allocated before any tensor shape/data can be queried
    // (e.g. getOutputTensor below) — the native TFLite API throws "failed
    // precondition" if you query before allocating.
    interpreter.allocateTensors();
    _interpreter = interpreter;

    final String labelsText = await rootBundle.loadString(_labelsAsset);
    _labels = labelsText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<InferenceResult> runInference(Uint8List imageBytes) async {
    await warmUp();

    final Interpreter interpreter = _interpreter!;
    final List<int> outputShape = interpreter.getOutputTensor(0).shape;
    final _Job job = _Job(
      interpreterAddress: interpreter.address,
      labels: _labels!,
      imageBytes: imageBytes,
      // Expected [1, 4 + numClasses, numAnchors], e.g. [1, 10, 8400].
      channels: outputShape[1],
      numAnchors: outputShape[2],
    );
    return _inferInBackground(job);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _loading = null;
  }
}

class _Job {
  final int interpreterAddress;
  final List<String> labels;
  final Uint8List imageBytes;
  final int channels;
  final int numAnchors;

  const _Job({
    required this.interpreterAddress,
    required this.labels,
    required this.imageBytes,
    required this.channels,
    required this.numAnchors,
  });
}

// Top-level so the isolate closure captures only [job], never the service.
Future<InferenceResult> _inferInBackground(_Job job) => Isolate.run(() => _infer(job));

InferenceResult _infer(_Job job) {
  final img.Image? decoded = img.decodeImage(job.imageBytes);
  if (decoded == null) throw const UnreadableImageException();
  // Camera JPEGs are often stored sideways with an EXIF rotation tag; Flutter
  // honours the tag when displaying, so the model must see the same upright
  // pixels or boxes land in the wrong place.
  final img.Image upright = img.bakeOrientation(decoded);

  final PreprocessResult preprocess = preprocessImage(upright);

  final Interpreter interpreter = Interpreter.fromAddress(job.interpreterAddress, allocated: true);
  final Float32List output = Float32List(job.channels * job.numAnchors);
  interpreter.run(preprocess.inputTensor.buffer.asUint8List(), output.buffer);

  final List<Detection> detections = postprocess(
    rawOutput: output,
    numAnchors: job.numAnchors,
    labels: job.labels,
    preprocess: preprocess,
  );

  return InferenceResult(
    detections: detections,
    imageWidth: upright.width,
    imageHeight: upright.height,
  );
}
