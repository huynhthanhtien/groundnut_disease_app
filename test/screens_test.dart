import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:groundnut_disease_app/models/detection.dart';
import 'package:groundnut_disease_app/screens/history_screen.dart';
import 'package:groundnut_disease_app/screens/result_screen.dart';
import 'package:groundnut_disease_app/services/history_store.dart';

final Uint8List _png = img.encodePng(img.Image(width: 100, height: 100));

Detection _det(String name, double conf, Rect box) =>
    Detection(classId: 0, className: name, confidence: conf, box: box);

void main() {
  testWidgets('result lists a second confident disease', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ResultScreen(
        imageBytes: _png,
        imageWidth: 100,
        imageHeight: 100,
        detections: [
          _det('Early and Late leaf spot', 0.9, const Rect.fromLTRB(0, 0, 20, 20)),
          _det('Rust-Leaf', 0.7, const Rect.fromLTRB(50, 50, 70, 70)),
        ],
      ),
    ));

    expect(find.text('Cũng phát hiện trên ảnh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved result note can be edited', (tester) async {
    final entry = await tester.runAsync(() => HistoryStore.instance.save(
          imageBytes: _png,
          imageWidth: 100,
          imageHeight: 100,
          detections: [_det('Rust-Leaf', 0.8, const Rect.fromLTRB(0, 0, 20, 20))],
        ));
    await tester.pumpWidget(MaterialApp(
      home: ResultScreen(
        imageBytes: _png,
        imageWidth: 100,
        imageHeight: 100,
        detections: entry!.detections,
        savedEntry: entry,
      ),
    ));

    // The note row sits below the diagnosis; scroll it into view.
    await tester.scrollUntilVisible(find.text('Chưa có ghi chú'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ruộng sau nhà');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Ruộng sau nhà'), findsOneWidget);
    expect(HistoryStore.instance.byId(entry.id)!.note, 'Ruộng sau nhà');
    await tester.runAsync(() => HistoryStore.instance.delete(entry.id));
  });

  testWidgets('history search ignores diacritics and matches disease names', (tester) async {
    final store = HistoryStore.instance;
    final a = await tester.runAsync(() => store.save(
          imageBytes: _png,
          imageWidth: 100,
          imageHeight: 100,
          detections: [_det('Rust-Leaf', 0.8, const Rect.fromLTRB(0, 0, 20, 20))],
          note: 'Ruộng sau nhà',
        ));
    final b = await tester.runAsync(() => store.save(
          imageBytes: _png,
          imageWidth: 100,
          imageHeight: 100,
          detections: const [],
          note: 'Bãi bồi',
        ));

    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
    expect(find.text('Ruộng sau nhà'), findsOneWidget);
    expect(find.text('Bãi bồi'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ruong');
    await tester.pump();
    expect(find.text('Ruộng sau nhà'), findsOneWidget);
    expect(find.text('Bãi bồi'), findsNothing);

    await tester.enterText(find.byType(TextField), 'gi sat');
    await tester.pump();
    expect(find.text('Ruộng sau nhà'), findsOneWidget);
    expect(find.text('Bãi bồi'), findsNothing);

    await tester.enterText(find.byType(TextField), 'khong co');
    await tester.pump();
    expect(find.textContaining('Không tìm thấy'), findsOneWidget);

    await tester.runAsync(() async {
      await store.delete(a!.id);
      await store.delete(b!.id);
    });
  });
}
