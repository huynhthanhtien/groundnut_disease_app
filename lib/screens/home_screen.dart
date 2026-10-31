import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/yolo_model_service.dart';
import '../theme/app_colors.dart';
import 'onboarding_screen.dart';
import 'result_screen.dart';

/// Photos are downscaled by the picker before analysis: the model only sees
/// 640x640 anyway, and decoding full 12–50 MP camera files was the slowest
/// step on mid-range phones.
const double _kMaxPickDimension = 1600;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: _kMaxPickDimension,
        maxHeight: _kMaxPickDimension,
        imageQuality: 90,
      );
    } catch (e) {
      debugPrint('pickImage failed: $e');
      _showError(source == ImageSource.camera
          ? 'Không mở được máy ảnh. Hãy kiểm tra quyền truy cập máy ảnh trong Cài đặt.'
          : 'Không mở được thư viện ảnh. Hãy kiểm tra quyền truy cập ảnh trong Cài đặt.');
      return;
    }
    if (picked == null) return;

    setState(() => _isProcessing = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();
      final InferenceResult result = await YoloModelService.instance.runInference(bytes);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageBytes: bytes,
            imageWidth: result.imageWidth,
            imageHeight: result.imageHeight,
            detections: result.detections,
          ),
        ),
      );
    } on UnreadableImageException {
      _showError('Không đọc được ảnh này. Hãy chọn ảnh JPG hoặc PNG khác.');
    } catch (e) {
      debugPrint('Inference failed: $e');
      _showError('Có lỗi khi phân tích ảnh. Hãy thử lại; nếu vẫn lỗi, khởi động lại ứng dụng.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.viewfinderBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Static viewfinder backdrop — no live camera preview plugin wired
          // up (image_picker just opens the system camera app); this frame
          // is a visual placeholder matching the design's mock viewfinder.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF14170F), Color(0xFF0D0F0A)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Quét bệnh',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                      ),
                      IconButton(
                        tooltip: 'Cách chụp ảnh',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                        ),
                        icon: Icon(Icons.help_outline, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const _ModelStatus(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(34, 20, 34, 24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        IgnorePointer(child: CustomPaint(painter: _DashedFramePainter())),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.eco_outlined, size: 84, color: Colors.white.withValues(alpha: 0.12)),
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'Chụp cận một lá hoặc quả bệnh,\nđủ sáng và rõ nét',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundAction(
                        icon: Icons.photo_library_outlined,
                        label: 'Thư viện',
                        onTap: _isProcessing ? null : () => _pickAndAnalyze(ImageSource.gallery),
                      ),
                      _ShutterButton(
                        busy: _isProcessing,
                        onTap: _isProcessing ? null : () => _pickAndAnalyze(ImageSource.camera),
                      ),
                      _RoundAction(
                        icon: Icons.lightbulb_outline,
                        label: 'Mẹo chụp',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryBright),
                    SizedBox(height: 16),
                    Text('Đang phân tích ảnh...', style: TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Đang tải mô hình..." pill while the model warms up; on failure, tapping
/// it retries (warmUp() forgets a failed load, so a second call starts over).
class _ModelStatus extends StatefulWidget {
  const _ModelStatus();

  @override
  State<_ModelStatus> createState() => _ModelStatusState();
}

class _ModelStatusState extends State<_ModelStatus> {
  late Future<void> _loading = YoloModelService.instance.warmUp();

  void _retry() => setState(() => _loading = YoloModelService.instance.warmUp());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
          return const SizedBox(height: 34);
        }
        final bool failed = snapshot.hasError;
        final Widget pill = Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!failed)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBright),
                )
              else
                const Icon(Icons.error_outline, size: 16, color: AppColors.rust),
              const SizedBox(width: 8),
              Text(
                failed ? 'Không tải được mô hình — chạm để thử lại' : 'Đang tải mô hình nhận diện...',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              if (failed) ...[
                const SizedBox(width: 6),
                const Icon(Icons.refresh, size: 16, color: Colors.white),
              ],
            ],
          ),
        );
        return failed ? Semantics(button: true, child: GestureDetector(onTap: _retry, child: pill)) : pill;
      },
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _RoundAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.4),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;

  const _ShutterButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Chụp ảnh',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.28), blurRadius: 0, spreadRadius: 4)],
              ),
              child: Center(
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: busy ? AppColors.inkAt(0.3) : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Chụp lá', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DashedFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.35);

    final Path dashed = Path();
    const double dashWidth = 8;
    const double dashGap = 6;
    final Path outline = Path()..addRRect(rrect);
    for (final metric in outline.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        dashed.addPath(metric.extractPath(distance, next.clamp(0, metric.length)), Offset.zero);
        distance = next + dashGap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
