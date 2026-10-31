import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/disease_info.dart';
import '../models/detection.dart';
import '../models/history_entry.dart';
import '../services/history_store.dart';
import '../services/scan_analysis.dart';
import '../theme/app_colors.dart';
import '../widgets/bounding_box_overlay.dart';
import '../widgets/common.dart';
import 'disease_detail_screen.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;
  final List<Detection> detections;

  /// Set when opened from the history list — hides "LƯU" (it's already
  /// saved) and offers delete instead.
  final HistoryEntry? savedEntry;

  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.detections,
    this.savedEntry,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _photoKey = GlobalKey();
  late HistoryEntry? _saved = widget.savedEntry;
  late final ScanAnalysis _analysis = ScanAnalysis.of(widget.detections, widget.imageWidth, widget.imageHeight);
  int? _highlighted;
  bool _busy = false;

  Future<void> _save() async {
    final String? note = await _askNote();
    if (note == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final HistoryEntry entry = await HistoryStore.instance.save(
        imageBytes: widget.imageBytes,
        imageWidth: widget.imageWidth,
        imageHeight: widget.imageHeight,
        detections: widget.detections,
        note: note,
      );
      if (!mounted) return;
      setState(() => _saved = entry);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu vào lịch sử')));
    } catch (e) {
      debugPrint('Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không lưu được. Hãy kiểm tra bộ nhớ máy.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editNote() async {
    final HistoryEntry? entry = _saved;
    if (entry == null) return;
    final String? note = await _askNote(initial: entry.note, title: 'Ghi chú');
    if (note == null || !mounted) return;
    try {
      await HistoryStore.instance.updateNote(entry.id, note);
    } catch (e) {
      debugPrint('Note update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không lưu được ghi chú.')));
      }
    }
    if (mounted) setState(() => _saved = HistoryStore.instance.byId(entry.id) ?? entry);
  }

  /// Returns the note (possibly empty), or null if the user cancelled.
  Future<String?> _askNote({String initial = '', String title = 'Lưu kết quả'}) {
    final TextEditingController controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Ghi chú (không bắt buộc)',
            hintText: 'vd. Ruộng sau nhà, luống 3',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Lưu')),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final HistoryEntry? entry = _saved;
    if (entry == null) return;
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
    if (ok != true) return;
    await HistoryStore.instance.delete(entry.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final RenderRepaintBoundary boundary = _photoKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
      final Directory tmp = await getTemporaryDirectory();
      final File file = File(p.join(tmp.path, 'ket_qua_benh_lac_${DateTime.now().millisecondsSinceEpoch}.png'));
      await file.writeAsBytes(png!.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: _shareText()));
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không chia sẻ được kết quả.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _shareText() {
    final Detection? primary = _analysis.primary;
    final StringBuffer sb = StringBuffer('Kết quả quét bệnh cây lạc');
    final DateTime when = _saved?.savedAt ?? DateTime.now();
    sb.write(' (${when.day}/${when.month}/${when.year})');
    if (_saved != null && _saved!.note.isNotEmpty) sb.write(' — ${_saved!.note}');
    sb.writeln();
    if (primary == null) {
      sb.writeln('Không phát hiện dấu hiệu bệnh.');
    } else {
      sb.writeln('${_analysis.isConfident ? 'Gợi ý' : 'Có thể là (chưa chắc chắn)'}: '
          '${displayNameFor(primary.className)} — độ tin cậy ${(primary.confidence * 100).toStringAsFixed(0)}%');
      sb.writeln('Phát hiện ${_analysis.primaryRegions.length} vùng nghi bệnh.');
      for (final Detection d in _analysis.otherConfident) {
        sb.writeln('Cũng phát hiện: ${displayNameFor(d.className)} — ${(d.confidence * 100).toStringAsFixed(0)}%');
      }
    }
    sb.write('Kết quả từ ứng dụng nhận diện bằng hình ảnh, cần cán bộ kỹ thuật xác nhận.');
    return sb.toString();
  }

  void _openZoom() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ZoomScreen(
        imageBytes: widget.imageBytes,
        imageWidth: widget.imageWidth,
        imageHeight: widget.imageHeight,
        detections: widget.detections,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Detection? primary = _analysis.primary;
    final DiseaseInfo? info = primary == null ? null : diseaseInfoFor(primary.className);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Photo(
                    repaintKey: _photoKey,
                    imageBytes: widget.imageBytes,
                    imageWidth: widget.imageWidth,
                    imageHeight: widget.imageHeight,
                    detections: widget.detections,
                    highlighted: _highlighted,
                    onBack: () => Navigator.of(context).pop(),
                    onShare: _busy ? null : _share,
                    onZoom: _openZoom,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: primary == null
                        ? const _NoDetectionBody()
                        : _analysis.isConfident
                            ? _DiagnosisBody(analysis: _analysis, info: info)
                            : _UncertainBody(primary: primary),
                  ),
                  if (widget.detections.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _DetectionList(
                        detections: widget.detections,
                        highlighted: _highlighted,
                        onTap: (i) => setState(() => _highlighted = _highlighted == i ? null : i),
                      ),
                    ),
                  if (_saved != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 16),
                      child: Row(
                        children: [
                          Icon(Icons.sticky_note_2_outlined, size: 18, color: AppColors.inkAt(0.5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _saved!.note.isEmpty ? 'Chưa có ghi chú' : _saved!.note,
                              style: TextStyle(fontSize: 14.5, color: AppColors.inkAt(_saved!.note.isEmpty ? 0.45 : 0.7)),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _editNote,
                            child: Text(_saved!.note.isEmpty ? 'Thêm' : 'Sửa'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                children: [
                  if (widget.savedEntry != null)
                    OutlinedButton(
                      onPressed: _busy ? null : _delete,
                      style: secondaryButtonStyle(),
                      child: const Text('XÓA', style: TextStyle(fontSize: 12)),
                    )
                  else
                    OutlinedButton(
                      onPressed: _saved != null || _busy ? null : _save,
                      style: secondaryButtonStyle(),
                      child: Text(_saved != null ? 'ĐÃ LƯU' : 'LƯU', style: const TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: info != null
                        ? ElevatedButton(
                            style: primaryButtonStyle(),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DiseaseDetailScreen(info: info)),
                            ),
                            child: Text(_analysis.isConfident ? 'Xem cách xử lý' : 'Xem thông tin bệnh này'),
                          )
                        : ElevatedButton(
                            style: primaryButtonStyle(),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(widget.savedEntry != null ? 'Quay lại' : 'Chụp ảnh khác'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final GlobalKey repaintKey;
  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;
  final List<Detection> detections;
  final int? highlighted;
  final VoidCallback onBack;
  final VoidCallback? onShare;
  final VoidCallback onZoom;

  const _Photo({
    required this.repaintKey,
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.detections,
    required this.highlighted,
    required this.onBack,
    required this.onShare,
    required this.onZoom,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: onZoom,
            child: RepaintBoundary(
              key: repaintKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes, fit: BoxFit.cover, gaplessPlayback: true),
                  BoundingBoxOverlay(
                    detections: detections,
                    originalImageWidth: imageWidth,
                    originalImageHeight: imageHeight,
                    fit: BoxFit.cover,
                    highlighted: highlighted,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _CircleIcon(icon: Icons.arrow_back, tooltip: 'Quay lại', onTap: onBack),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _CircleIcon(icon: Icons.share_outlined, tooltip: 'Chia sẻ kết quả', onTap: onShare),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: _CircleIcon(icon: Icons.zoom_in, tooltip: 'Phóng to ảnh', onTap: onZoom),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _CircleIcon({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _DiagnosisBody extends StatelessWidget {
  final ScanAnalysis analysis;
  final DiseaseInfo? info;

  const _DiagnosisBody({required this.analysis, required this.info});

  @override
  Widget build(BuildContext context) {
    final Detection primary = analysis.primary!;
    final SeverityStyle sevStyle = styleFor(analysis.severity);
    final int regions = analysis.primaryRegions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SectionLabel('Chẩn đoán'),
            if (info != null) ...[
              const SizedBox(width: 8),
              Text('· ${info!.part.label}', style: TextStyle(fontSize: 12.5, color: AppColors.inkAt(0.5))),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          displayNameFor(primary.className),
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink),
        ),
        if (info != null) ...[
          const SizedBox(height: 3),
          Text(
            info!.scientificName,
            style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: AppColors.inkAt(0.5)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'ĐỘ TIN CẬY',
                value: '${(primary.confidence * 100).toStringAsFixed(0)}%',
                background: AppColors.surfaceAlt,
                valueColor: AppColors.ink,
                labelColor: AppColors.inkAt(0.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'MỨC LAN (ƯỚC TÍNH)',
                value: sevStyle.label,
                background: sevStyle.background,
                valueColor: sevStyle.foreground,
                labelColor: sevStyle.foreground.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Phát hiện $regions vùng nghi bệnh, chiếm khoảng ${analysis.coveragePct.toStringAsFixed(0)}% khung ảnh.',
          style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.inkAt(0.72)),
        ),
        const SizedBox(height: 4),
        Text(
          'Mức lan ước tính từ số vùng và diện tích khung phát hiện, không phải đo chính xác tỷ lệ lá bệnh. '
          'Hãy kiểm tra thêm nhiều cây trong ruộng.',
          style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.inkAt(0.5)),
        ),
        if (analysis.otherConfident.isNotEmpty) ...[
          const SizedBox(height: 14),
          _AlsoFound(detections: analysis.otherConfident),
        ],
        if (info != null) ...[
          const SizedBox(height: 14),
          Text(info!.summary, style: TextStyle(fontSize: 15, height: 1.55, color: AppColors.inkAt(0.78))),
          if (info!.warning != null) ...[
            const SizedBox(height: 14),
            NoteCard(title: 'Cảnh báo an toàn', body: info!.warning!, icon: Icons.warning_amber_rounded, severe: true),
          ],
        ],
      ],
    );
  }
}

/// Other diseases found on the same photo with enough confidence — a leaf can
/// carry rust and leaf spot at once, and the treatment differs.
class _AlsoFound extends StatelessWidget {
  final List<Detection> detections;

  const _AlsoFound({required this.detections});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cũng phát hiện trên ảnh',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text('Cây có thể bị nhiều bệnh cùng lúc — xem cách xử lý từng bệnh.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.inkAt(0.55))),
          const SizedBox(height: 4),
          for (final Detection d in detections)
            InkWell(
              onTap: diseaseInfoFor(d.className) == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DiseaseDetailScreen(info: diseaseInfoFor(d.className)!)),
                      ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: AppColors.forClass(d.className), borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(displayNameFor(d.className),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
                    ),
                    Text('${(d.confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    if (diseaseInfoFor(d.className) != null) Icon(Icons.chevron_right, color: AppColors.inkAt(0.4)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UncertainBody extends StatelessWidget {
  final Detection primary;

  const _UncertainBody({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SectionLabel('Kết quả'),
            const SizedBox(width: 8),
            StatusChip(kUncertainStyle),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Chưa chắc chắn',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink)),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 15, height: 1.55, color: AppColors.inkAt(0.75)),
            children: [
              const TextSpan(text: 'Ảnh có thể có dấu hiệu '),
              TextSpan(text: displayNameFor(primary.className), style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(
                  text: ', nhưng độ tin cậy chỉ ${(primary.confidence * 100).toStringAsFixed(0)}% — '
                      'chưa đủ để kết luận. Hãy chụp lại theo gợi ý dưới đây.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _TipsCard(),
      ],
    );
  }
}

class _NoDetectionBody extends StatelessWidget {
  const _NoDetectionBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Kết quả'),
        const SizedBox(height: 8),
        const Text('Không phát hiện bệnh',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink)),
        const SizedBox(height: 8),
        Text(
          'Không thấy dấu hiệu của các bệnh app nhận diện được. Lá có thể khỏe, hoặc ảnh chưa đủ rõ. '
          'App hiện chỉ nhận diện ${kDiseases.length} nhóm bệnh (xem mục "Bệnh hại") — nếu cây vẫn có biểu hiện lạ, hãy hỏi cán bộ kỹ thuật.',
          style: TextStyle(fontSize: 15, height: 1.55, color: AppColors.inkAt(0.75)),
        ),
        const SizedBox(height: 16),
        const _TipsCard(),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mẹo chụp lại', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 10),
          BulletList([for (final AdviceStep t in kPhotoTips.take(4)) '${t.title}: ${t.body}']),
        ],
      ),
    );
  }
}

class _DetectionList extends StatelessWidget {
  final List<Detection> detections;
  final int? highlighted;
  final ValueChanged<int> onTap;

  const _DetectionList({required this.detections, required this.highlighted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Các vùng phát hiện'),
        const SizedBox(height: 2),
        Text('Chạm vào một dòng để làm nổi vùng đó trên ảnh.', style: TextStyle(fontSize: 12.5, color: AppColors.inkAt(0.45))),
        const SizedBox(height: 4),
        for (int i = 0; i < detections.length; i++)
          InkWell(
            onTap: () => onTap(i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
              decoration: BoxDecoration(
                color: highlighted == i ? AppColors.forClass(detections[i].className).withValues(alpha: 0.1) : null,
                border: Border(top: BorderSide(color: AppColors.inkAt(0.09))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: AppColors.forClass(detections[i].className), borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(displayNameFor(detections[i].className),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  ),
                  Text('${(detections[i].confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color background;
  final Color valueColor;
  final Color labelColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.background,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: labelColor)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}

/// Full-screen pinch-zoom view of the photo with all boxes.
class _ZoomScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;
  final List<Detection> detections;

  const _ZoomScreen({
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: InteractiveViewer(
        maxScale: 6,
        child: Center(
          child: AspectRatio(
            aspectRatio: imageHeight == 0 ? 1 : imageWidth / imageHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(imageBytes, fit: BoxFit.fill),
                BoundingBoxOverlay(
                  detections: detections,
                  originalImageWidth: imageWidth,
                  originalImageHeight: imageHeight,
                  fit: BoxFit.fill,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
