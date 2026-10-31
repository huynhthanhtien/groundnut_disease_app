import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/disease_info.dart';
import '../models/history_entry.dart';
import '../services/history_store.dart';
import '../services/scan_analysis.dart';
import '../theme/app_colors.dart';
import '../utils/text_search.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

enum _Filter { all, diseased, severe, thisWeek }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Filter _filter = _Filter.all;
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<HistoryEntry> _apply(List<HistoryEntry> entries) {
    final String query = _search.text.trim();
    if (query.isEmpty) return _applyFilter(entries);
    return _applyFilter(entries).where((e) => matchesQuery(_searchText(e), query)).toList();
  }

  /// What the search box looks at: the note plus every disease name found.
  String _searchText(HistoryEntry e) => [
        e.note,
        for (final String c in {for (final d in e.detections) d.className}) displayNameFor(c),
      ].join(' ');

  List<HistoryEntry> _applyFilter(List<HistoryEntry> entries) {
    switch (_filter) {
      case _Filter.all:
        return entries;
      case _Filter.diseased:
        return entries.where((e) => e.analysis.isConfident).toList();
      case _Filter.severe:
        return entries.where((e) {
          final ScanAnalysis a = e.analysis;
          return a.isConfident && a.severity == Severity.severe;
        }).toList();
      case _Filter.thisWeek:
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        return entries.where((e) => e.savedAt.isAfter(cutoff)).toList();
    }
  }

  Future<void> _open(HistoryEntry entry) async {
    final Uint8List bytes;
    try {
      bytes = await File(entry.imagePath).readAsBytes();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không mở được ảnh đã lưu.')));
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          imageBytes: bytes,
          imageWidth: entry.imageWidth,
          imageHeight: entry.imageHeight,
          detections: entry.detections,
          savedEntry: entry,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khỏi lịch sử?'),
        content: const Text('Ảnh và kết quả này sẽ bị xóa khỏi máy.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xóa')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HistoryStore.instance,
      builder: (context, _) {
        final all = HistoryStore.instance.entries;
        final shown = _apply(all);

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lịch sử',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink)),
                      const SizedBox(height: 3),
                      Text('${all.length} lượt đã lưu · trên máy này',
                          style: TextStyle(fontSize: 14, color: AppColors.inkAt(0.55))),
                      if (all.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Tìm theo ghi chú hoặc tên bệnh',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Xóa tìm kiếm',
                                    icon: const Icon(Icons.close),
                                    onPressed: () => setState(_search.clear),
                                  ),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surfaceAlt,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(label: 'Tất cả', selected: _filter == _Filter.all, onTap: () => setState(() => _filter = _Filter.all)),
                            const SizedBox(width: 8),
                            _FilterChip(label: 'Có bệnh', selected: _filter == _Filter.diseased, onTap: () => setState(() => _filter = _Filter.diseased)),
                            const SizedBox(width: 8),
                            _FilterChip(label: 'Lan nặng', selected: _filter == _Filter.severe, onTap: () => setState(() => _filter = _Filter.severe)),
                            const SizedBox(width: 8),
                            _FilterChip(label: 'Tuần này', selected: _filter == _Filter.thisWeek, onTap: () => setState(() => _filter = _Filter.thisWeek)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              all.isEmpty
                                  ? 'Chưa có lượt quét nào được lưu.\nBấm "LƯU" trên màn kết quả để thêm vào đây.'
                                  : _search.text.trim().isNotEmpty
                                      ? 'Không tìm thấy mục nào cho "${_search.text.trim()}".'
                                      : 'Không có mục nào khớp bộ lọc.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.inkAt(0.5), fontSize: 15, height: 1.5),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          itemCount: shown.length + 1,
                          separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.inkAt(0.08)),
                          itemBuilder: (context, index) {
                            if (index == shown.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text('Vuốt sang trái để xóa một mục.',
                                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.inkAt(0.4))),
                              );
                            }
                            final entry = shown[index];
                            return Dismissible(
                              key: ValueKey(entry.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _confirmDelete(),
                              onDismissed: (_) => HistoryStore.instance.delete(entry.id),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: AppColors.severeBg,
                                child: const Icon(Icons.delete_outline, color: AppColors.severeText),
                              ),
                              child: _HistoryTile(entry: entry, onTap: () => _open(entry)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;

  const _HistoryTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ScanAnalysis a = entry.analysis;
    final String title = !a.hasDetection
        ? 'Không phát hiện bệnh'
        : a.isConfident
            ? displayNameFor(a.primary!.className)
            : 'Chưa chắc: ${displayNameFor(a.primary!.className)}';
    final SeverityStyle? chip = !a.hasDetection ? null : (a.isConfident ? styleFor(a.severity) : kUncertainStyle);
    final List<String> meta = [
      _formatTime(entry.savedAt),
      if (a.primary != null) '${(a.primary!.confidence * 100).toStringAsFixed(0)}%',
    ];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(entry.imagePath),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                cacheWidth: 180,
                errorBuilder: (context, error, stack) => Container(
                  width: 60,
                  height: 60,
                  color: AppColors.surfaceDim,
                  child: Icon(Icons.broken_image_outlined, color: AppColors.inkAt(0.4)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(meta.join(' · '), style: TextStyle(fontSize: 13.5, color: AppColors.inkAt(0.5))),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(entry.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, color: AppColors.inkAt(0.65))),
                  ],
                ],
              ),
            ),
            if (chip != null) StatusChip(chip),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
  if (diff.inDays < 1) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return '${t.day}/${t.month}/${t.year}';
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.ink : AppColors.inkAt(0.18)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
