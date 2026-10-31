import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:groundnut_disease_app/models/detection.dart';
import 'package:groundnut_disease_app/models/history_entry.dart';
import 'package:groundnut_disease_app/services/scan_analysis.dart';

Detection _det(String name, double conf, Rect box) =>
    Detection(classId: 0, className: name, confidence: conf, box: box);

void main() {
  test('union coverage counts overlapping boxes once', () {
    final pct = unionCoveragePct(
      const [Rect.fromLTRB(0, 0, 50, 100), Rect.fromLTRB(0, 0, 50, 100)],
      100,
      100,
    );
    expect(pct, closeTo(50, 0.5));
  });

  test('empty scan has no primary and is not confident', () {
    final a = ScanAnalysis.of(const [], 100, 100);
    expect(a.hasDetection, isFalse);
    expect(a.isConfident, isFalse);
  });

  test('primary is highest-confidence detection; regions are same-class only', () {
    final a = ScanAnalysis.of([
      _det('Rust-Leaf', 0.4, const Rect.fromLTRB(0, 0, 10, 10)),
      _det('Early and Late leaf spot', 0.8, const Rect.fromLTRB(0, 0, 10, 10)),
      _det('Early and Late leaf spot', 0.6, const Rect.fromLTRB(50, 50, 60, 60)),
    ], 100, 100);
    expect(a.primary!.className, 'Early and Late leaf spot');
    expect(a.primaryRegions.length, 2);
    expect(a.isConfident, isTrue);
    expect(a.coveragePct, closeTo(2, 0.5));
    expect(a.severity, Severity.mild);
  });

  test('low top confidence is flagged as uncertain', () {
    final a = ScanAnalysis.of([_det('Rust-Leaf', 0.3, const Rect.fromLTRB(0, 0, 10, 10))], 100, 100);
    expect(a.hasDetection, isTrue);
    expect(a.isConfident, isFalse);
  });

  test('severity grows with region count and coverage, not confidence', () {
    expect(severityFor(regionCount: 1, coveragePct: 5), Severity.mild);
    expect(severityFor(regionCount: 3, coveragePct: 5), Severity.moderate);
    expect(severityFor(regionCount: 1, coveragePct: 20), Severity.moderate);
    expect(severityFor(regionCount: 6, coveragePct: 5), Severity.severe);
    expect(severityFor(regionCount: 1, coveragePct: 45), Severity.severe);
  });

  test('history entry survives a JSON round trip', () {
    final entry = HistoryEntry(
      id: '1',
      imagePath: '/tmp/1.jpg',
      imageWidth: 640,
      imageHeight: 480,
      detections: [_det('Rust-Leaf', 0.9, const Rect.fromLTRB(1, 2, 3, 4))],
      savedAt: DateTime(2026, 10, 28, 9, 30),
      note: 'Ruộng sau nhà',
    );
    final back = HistoryEntry.fromJson(entry.toJson());
    expect(back.id, '1');
    expect(back.note, 'Ruộng sau nhà');
    expect(back.savedAt, entry.savedAt);
    expect(back.detections.single.box, const Rect.fromLTRB(1, 2, 3, 4));
    expect(back.detections.single.className, 'Rust-Leaf');
  });

  test('other confident classes are listed once each, strongest first', () {
    final a = ScanAnalysis.of([
      _det('Early and Late leaf spot', 0.9, const Rect.fromLTRB(0, 0, 10, 10)),
      _det('Rust-Leaf', 0.55, const Rect.fromLTRB(20, 20, 30, 30)),
      _det('Rust-Leaf', 0.7, const Rect.fromLTRB(40, 40, 50, 50)),
      _det('Fungus leaf', 0.3, const Rect.fromLTRB(60, 60, 70, 70)),
    ], 100, 100);
    expect(a.otherConfident.map((d) => d.className), ['Rust-Leaf']);
    expect(a.otherConfident.single.confidence, 0.7);
  });

  test('uncertain scan has no other confident classes', () {
    final a = ScanAnalysis.of([
      _det('Rust-Leaf', 0.45, const Rect.fromLTRB(0, 0, 10, 10)),
      _det('Fungus leaf', 0.4, const Rect.fromLTRB(20, 20, 30, 30)),
    ], 100, 100);
    expect(a.otherConfident, isEmpty);
  });

  test('copyWith changes only the note', () {
    final entry = HistoryEntry(
      id: '1',
      imagePath: '/tmp/1.jpg',
      imageWidth: 10,
      imageHeight: 10,
      detections: const [],
      savedAt: DateTime(2026, 10, 28),
      note: 'cũ',
    );
    final edited = entry.copyWith(note: 'mới');
    expect(edited.note, 'mới');
    expect(edited.id, entry.id);
    expect(edited.savedAt, entry.savedAt);
  });
}
