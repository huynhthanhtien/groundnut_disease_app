import 'dart:ui';

class Detection {
  final int classId;
  final String className;
  final double confidence;

  /// Bounding box in the coordinate space of the original (un-letterboxed) image.
  final Rect box;

  const Detection({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.box,
  });

  Map<String, dynamic> toJson() => {
        'classId': classId,
        'className': className,
        'confidence': confidence,
        'box': [box.left, box.top, box.right, box.bottom],
      };

  factory Detection.fromJson(Map<String, dynamic> json) {
    final List<double> b = (json['box'] as List).map((v) => (v as num).toDouble()).toList();
    return Detection(
      classId: json['classId'] as int,
      className: json['className'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      box: Rect.fromLTRB(b[0], b[1], b[2], b[3]),
    );
  }

  @override
  String toString() =>
      'Detection(className: $className, confidence: ${confidence.toStringAsFixed(2)}, box: $box)';
}
