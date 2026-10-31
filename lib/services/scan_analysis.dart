import 'dart:ui';

import '../models/detection.dart';

/// Below this, the top detection is shown as "chưa chắc chắn" (asks the user
/// to retake) instead of as a diagnosis. The decode threshold
/// (kConfidenceThreshold = 0.25) stays lower so weak boxes are still listed.
const double kConfidentThreshold = 0.5;

enum Severity { mild, moderate, severe }

/// Summary numbers derived from one scan's detections. Everything here is a
/// heuristic over bounding boxes — the model does not segment lesions, so
/// "coverage" is the share of the *photo* covered by disease boxes, not the
/// share of the leaf that is actually diseased.
class ScanAnalysis {
  final Detection? primary;

  /// Detections with the same class as [primary].
  final List<Detection> primaryRegions;

  /// Union area of [primaryRegions] boxes as a percentage of the photo, 0–100.
  final double coveragePct;

  /// Other classes that also reached [kConfidentThreshold], strongest
  /// detection of each, highest confidence first — e.g. rust found on the
  /// same leaf as leaf spot. Empty when [primary] itself isn't confident.
  final List<Detection> otherConfident;

  const ScanAnalysis._(this.primary, this.primaryRegions, this.coveragePct, this.otherConfident);

  factory ScanAnalysis.of(List<Detection> detections, int imageWidth, int imageHeight) {
    if (detections.isEmpty) return const ScanAnalysis._(null, [], 0, []);
    final Detection primary = detections.reduce((a, b) => a.confidence >= b.confidence ? a : b);
    final List<Detection> same = detections.where((d) => d.className == primary.className).toList();
    final double coverage = unionCoveragePct(same.map((d) => d.box).toList(), imageWidth, imageHeight);

    final Map<String, Detection> bestOther = {};
    for (final Detection d in detections) {
      if (d.className == primary.className || d.confidence < kConfidentThreshold) continue;
      final Detection? prev = bestOther[d.className];
      if (prev == null || d.confidence > prev.confidence) bestOther[d.className] = d;
    }
    final List<Detection> others = bestOther.values.toList()..sort((a, b) => b.confidence.compareTo(a.confidence));
    return ScanAnalysis._(primary, same, coverage, others);
  }

  bool get hasDetection => primary != null;

  bool get isConfident => primary != null && primary!.confidence >= kConfidentThreshold;

  /// Only meaningful when [isConfident].
  Severity get severity => severityFor(regionCount: primaryRegions.length, coveragePct: coveragePct);
}

/// Rough spread estimate from how many regions were found and how much of
/// the photo they cover. Thresholds are a starting point to be tuned against
/// field-scored samples.
Severity severityFor({required int regionCount, required double coveragePct}) {
  if (regionCount >= 6 || coveragePct >= 40) return Severity.severe;
  if (regionCount >= 3 || coveragePct >= 15) return Severity.moderate;
  return Severity.mild;
}

/// Area of the union of [boxes] as a percentage of a [width] x [height]
/// image. Overlapping boxes are counted once (sampled on a grid, which is
/// plenty accurate for a displayed whole-number percentage).
double unionCoveragePct(List<Rect> boxes, int width, int height, {int grid = 100}) {
  if (boxes.isEmpty || width <= 0 || height <= 0) return 0;
  int covered = 0;
  for (int gy = 0; gy < grid; gy++) {
    final double y = (gy + 0.5) * height / grid;
    for (int gx = 0; gx < grid; gx++) {
      final double x = (gx + 0.5) * width / grid;
      for (final Rect b in boxes) {
        if (x >= b.left && x < b.right && y >= b.top && y < b.bottom) {
          covered++;
          break;
        }
      }
    }
  }
  return covered * 100 / (grid * grid);
}
