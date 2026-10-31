import 'package:flutter/painting.dart';

/// Maps [rect] from image pixel space into the space of a [viewSize] widget
/// that paints a [imageSize] image with [fit] and centered alignment (the
/// `Image` widget's default). Handles cropping fits like [BoxFit.cover],
/// where scaling the axes independently would misplace boxes.
Rect mapImageRectToView(Rect rect, Size imageSize, Size viewSize, {BoxFit fit = BoxFit.cover}) {
  if (imageSize.isEmpty || viewSize.isEmpty) return Rect.zero;
  final FittedSizes sizes = applyBoxFit(fit, imageSize, viewSize);
  final Rect src = Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
  final Rect dst = Alignment.center.inscribe(sizes.destination, Offset.zero & viewSize);
  final double sx = dst.width / src.width;
  final double sy = dst.height / src.height;
  return Rect.fromLTRB(
    dst.left + (rect.left - src.left) * sx,
    dst.top + (rect.top - src.top) * sy,
    dst.left + (rect.right - src.left) * sx,
    dst.top + (rect.bottom - src.top) * sy,
  );
}
