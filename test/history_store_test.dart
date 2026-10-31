import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:groundnut_disease_app/models/detection.dart';
import 'package:groundnut_disease_app/services/history_store.dart';

void main() {
  // No path_provider plugin here, so the store runs in memory (photos go to
  // a system temp dir) — enough to check the list bookkeeping.
  final HistoryStore store = HistoryStore.instance;

  test('save, edit note, delete', () async {
    final entry = await store.save(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      imageWidth: 10,
      imageHeight: 10,
      detections: const [
        Detection(classId: 3, className: 'Rust-Leaf', confidence: 0.8, box: Rect.fromLTRB(0, 0, 5, 5)),
      ],
      note: '  luống 3  ',
    );
    expect(entry.note, 'luống 3');
    expect(store.entries.first.id, entry.id);

    await store.updateNote(entry.id, ' luống 4 ');
    expect(store.byId(entry.id)!.note, 'luống 4');
    expect(store.byId(entry.id)!.detections.single.className, 'Rust-Leaf');

    await store.delete(entry.id);
    expect(store.byId(entry.id), isNull);
  });

  test('updating an unknown id is a no-op', () async {
    final int before = store.entries.length;
    await store.updateNote('missing', 'x');
    expect(store.entries.length, before);
  });
}
