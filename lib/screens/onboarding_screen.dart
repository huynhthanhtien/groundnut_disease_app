import 'package:flutter/material.dart';

import '../data/disease_info.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Photo tips + disclaimer. Shown full-screen on first launch (with
/// [onDone]), and as a regular pushed page from the scan/library screens
/// (with [onDone] null, which shows a back button instead).
class OnboardingScreen extends StatelessWidget {
  final VoidCallback? onDone;

  const OnboardingScreen({super.key, this.onDone});

  @override
  Widget build(BuildContext context) {
    final bool firstRun = onDone != null;
    return Scaffold(
      appBar: firstRun ? null : AppBar(title: const Text('Cách chụp ảnh', style: TextStyle(fontWeight: FontWeight.w700))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                children: [
                  if (firstRun) ...[
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.eco, color: AppColors.primary, size: 34),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nhận diện bệnh cây lạc',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink)),
                    const SizedBox(height: 8),
                    Text(
                      'Chụp ảnh lá hoặc quả lạc, app sẽ gợi ý bệnh có thể gặp và cách xử lý. App chạy hoàn toàn trên máy, không cần mạng.',
                      style: TextStyle(fontSize: 15.5, height: 1.55, color: AppColors.inkAt(0.68)),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('Để có kết quả tốt'),
                    const SizedBox(height: 12),
                  ],
                  for (int i = 0; i < kPhotoTips.length; i++) _TipTile(index: i + 1, step: kPhotoTips[i]),
                  const SizedBox(height: 8),
                  const NoteCard(title: 'Lưu ý', body: kDisclaimer),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ElevatedButton(
                style: primaryButtonStyle(),
                onPressed: onDone ?? () => Navigator.of(context).pop(),
                child: Text(firstRun ? 'Tôi đã hiểu, bắt đầu' : 'Đã hiểu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  final int index;
  final AdviceStep step;

  const _TipTile({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(step.body, style: TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.inkAt(0.68))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
