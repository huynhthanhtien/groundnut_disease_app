import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Square input resolution the exported model was trained/exported for.
/// Must stay in sync with `--imgsz` used in android_Computer-vision's
/// scripts/export.py.
const int kModelInputSize = 640;

/// Result of letterbox-resizing an arbitrary photo to the model's fixed
/// input size, plus the geometry needed to map detection boxes back to the
/// original image's coordinate space.
class PreprocessResult {
  /// Flat NCHW float32 tensor of shape [1, 3, kModelInputSize,
  /// kModelInputSize], values in [0, 1]. Kept flat (rather than nested
  /// Lists) so it can be handed to the interpreter as raw bytes — nested
  /// Lists of ~1.2M boxed doubles were the main source of scan latency.
  final Float32List inputTensor;
  final double scale;
  final double padX;
  final double padY;
  final int origWidth;
  final int origHeight;

  const PreprocessResult({
    required this.inputTensor,
    required this.scale,
    required this.padX,
    required this.padY,
    required this.origWidth,
    required this.origHeight,
  });
}

/// Letterbox-resizes [original] into a `kModelInputSize` x `kModelInputSize`
/// canvas (gray padding, matching Ultralytics' default letterbox pad color of
/// 114) and builds the NCHW float32 input tensor the exported TFLite model
/// expects (confirmed empirically: input shape [1,3,640,640], values [0,1] —
/// see android_Computer-vision's tensor-inspection notes).
///
/// [original] must already be upright (see `img.bakeOrientation`), otherwise
/// boxes won't line up with the photo as Flutter displays it.
PreprocessResult preprocessImage(img.Image original) {
  final int origWidth = original.width;
  final int origHeight = original.height;

  final double scale = (kModelInputSize / origWidth < kModelInputSize / origHeight)
      ? kModelInputSize / origWidth
      : kModelInputSize / origHeight;

  final int scaledW = (origWidth * scale).round();
  final int scaledH = (origHeight * scale).round();

  final img.Image resized = img.copyResize(
    original,
    width: scaledW,
    height: scaledH,
    interpolation: img.Interpolation.linear,
  );

  final double padX = (kModelInputSize - scaledW) / 2;
  final double padY = (kModelInputSize - scaledH) / 2;

  final img.Image canvas = img.Image(width: kModelInputSize, height: kModelInputSize);
  img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
  img.compositeImage(canvas, resized, dstX: padX.round(), dstY: padY.round());

  const int plane = kModelInputSize * kModelInputSize;
  final Float32List tensor = Float32List(3 * plane);
  for (int y = 0; y < kModelInputSize; y++) {
    for (int x = 0; x < kModelInputSize; x++) {
      final img.Pixel pixel = canvas.getPixel(x, y);
      final int i = y * kModelInputSize + x;
      tensor[i] = pixel.r / 255.0;
      tensor[plane + i] = pixel.g / 255.0;
      tensor[2 * plane + i] = pixel.b / 255.0;
    }
  }

  return PreprocessResult(
    inputTensor: tensor,
    scale: scale,
    padX: padX,
    padY: padY,
    origWidth: origWidth,
    origHeight: origHeight,
  );
}
