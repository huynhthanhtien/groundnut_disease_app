import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/detection.dart';
import '../models/history_entry.dart';

/// Saved scans (only kept when the user explicitly taps "LƯU"). Photos are
/// copied into `<app documents>/history/` and the list itself is a small
/// JSON index next to them — a few hundred entries at most, so a database
/// isn't worth the dependency.
class HistoryStore extends ChangeNotifier {
  HistoryStore._();

  static final HistoryStore instance = HistoryStore._();

  final List<HistoryEntry> _entries = [];
  Directory? _dir;

  /// Tail of the pending index writes. Writes are chained so two quick
  /// saves/deletes never write the same `.tmp` file concurrently.
  Future<void> _writing = Future.value();

  /// Newest first.
  List<HistoryEntry> get entries => List.unmodifiable(_entries.reversed);

  File get _indexFile => File(p.join(_dir!.path, 'index.json'));

  /// Reads the saved index from disk. If storage is unavailable (e.g. in
  /// widget tests, where there is no path_provider plugin) the store keeps
  /// working in memory only.
  Future<void> load() async {
    try {
      final Directory docs = await getApplicationDocumentsDirectory();
      _dir = await Directory(p.join(docs.path, 'history')).create(recursive: true);
      if (await _indexFile.exists()) {
        final List<dynamic> raw = jsonDecode(await _indexFile.readAsString()) as List<dynamic>;
        _entries
          ..clear()
          ..addAll(raw
              .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
              .where((e) => File(e.imagePath).existsSync()));
      }
    } catch (e) {
      debugPrint('HistoryStore: storage unavailable, keeping history in memory ($e)');
      _dir = null;
    }
    notifyListeners();
  }

  Future<HistoryEntry> save({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    required List<Detection> detections,
    String note = '',
  }) async {
    final DateTime now = DateTime.now();
    final String id = now.microsecondsSinceEpoch.toString();
    final Directory dir = _dir ?? await Directory.systemTemp.createTemp('history');
    final String imagePath = p.join(dir.path, '$id.jpg');
    await File(imagePath).writeAsBytes(imageBytes, flush: true);

    final HistoryEntry entry = HistoryEntry(
      id: id,
      imagePath: imagePath,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      detections: detections,
      savedAt: now,
      note: note.trim(),
    );
    _entries.add(entry);
    await _persist();
    notifyListeners();
    return entry;
  }

  Future<void> delete(String id) async {
    final int idx = _entries.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final HistoryEntry removed = _entries.removeAt(idx);
    notifyListeners();
    try {
      await File(removed.imagePath).delete();
    } catch (_) {
      // Already gone — nothing to clean up.
    }
    await _persist();
  }

  Future<void> updateNote(String id, String note) async {
    final int idx = _entries.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    _entries[idx] = _entries[idx].copyWith(note: note.trim());
    notifyListeners();
    await _persist();
  }

  /// Looks an entry up by id — screens holding an old [HistoryEntry] use this
  /// to pick up edits such as a changed note.
  HistoryEntry? byId(String id) {
    for (final HistoryEntry e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> _persist() {
    if (_dir == null) return Future.value();
    final Future<void> write = _writing.then((_) async {
      // Snapshot at write time so a chained write always stores the latest list.
      final String json = jsonEncode(_entries.map((e) => e.toJson()).toList());
      final File tmp = File('${_indexFile.path}.tmp');
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(_indexFile.path);
    });
    // Keep the chain alive even if one write fails; the caller still sees the error.
    _writing = write.catchError((Object e) => debugPrint('HistoryStore: write failed ($e)'));
    return write;
  }
}
