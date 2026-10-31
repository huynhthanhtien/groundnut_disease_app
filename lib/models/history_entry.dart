import 'detection.dart';
import '../services/scan_analysis.dart';

class HistoryEntry {
  final String id;

  /// Absolute path of the saved photo inside the app's documents directory.
  final String imagePath;
  final int imageWidth;
  final int imageHeight;
  final List<Detection> detections;
  final DateTime savedAt;

  /// Optional free-text note, e.g. which field/plot the photo was taken in.
  final String note;

  HistoryEntry({
    required this.id,
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.detections,
    required this.savedAt,
    this.note = '',
  });

  HistoryEntry copyWith({String? note}) => HistoryEntry(
        id: id,
        imagePath: imagePath,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        detections: detections,
        savedAt: savedAt,
        note: note ?? this.note,
      );

  /// Computed once — the history list filters and redraws often.
  late final ScanAnalysis analysis = ScanAnalysis.of(detections, imageWidth, imageHeight);

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'detections': detections.map((d) => d.toJson()).toList(),
        'savedAt': savedAt.toIso8601String(),
        'note': note,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        imageWidth: json['imageWidth'] as int,
        imageHeight: json['imageHeight'] as int,
        detections: (json['detections'] as List)
            .map((d) => Detection.fromJson(d as Map<String, dynamic>))
            .toList(),
        savedAt: DateTime.parse(json['savedAt'] as String),
        note: (json['note'] as String?) ?? '',
      );
}
