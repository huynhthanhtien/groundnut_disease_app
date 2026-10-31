import 'package:flutter/material.dart';

import '../data/disease_info.dart';
import '../services/app_settings.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/extension_contact.dart';

/// Full reference page for one disease: what to do now, how to recognise
/// it, reference active ingredients, prevention and when to call an expert.
/// Reached from a scan result ("Xem cách xử lý") or the disease library.
class DiseaseDetailScreen extends StatelessWidget {
  final DiseaseInfo info;

  const DiseaseDetailScreen({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(info.part.label, style: TextStyle(fontSize: 15, color: AppColors.inkAt(0.6)))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(info.displayName,
                style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink)),
            const SizedBox(height: 3),
            Text(info.scientificName, style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: AppColors.inkAt(0.5))),
            const SizedBox(height: 12),
            Text(info.summary, style: TextStyle(fontSize: 15.5, height: 1.55, color: AppColors.inkAt(0.78))),
            if (!kContentReviewed) ...[
              const SizedBox(height: 14),
              const NoteCard(
                title: 'Nội dung đang chờ chuyên gia duyệt',
                body: 'Thông tin dưới đây là bản tham khảo, chưa được cán bộ BVTV kiểm duyệt. Hãy xác nhận với cán bộ địa phương trước khi áp dụng.',
                icon: Icons.rate_review_outlined,
              ),
            ],
            if (info.warning != null) ...[
              const SizedBox(height: 14),
              NoteCard(title: 'Cảnh báo an toàn', body: info.warning!, icon: Icons.warning_amber_rounded, severe: true),
            ],
            const _Section('Cần làm ngay'),
            for (int i = 0; i < info.steps.length; i++) _StepCard(index: i + 1, step: info.steps[i]),
            const _Section('Nhận biết triệu chứng'),
            BulletList(info.symptoms),
            const _Section('Dễ nhầm với'),
            BulletList(info.confusedWith),
            const _Section('Điều kiện phát sinh'),
            BulletList(info.conditions),
            const _Section('Thuốc tham khảo (hoạt chất)'),
            BulletList(info.activeIngredients),
            const SizedBox(height: 4),
            Text(kPesticideNote, style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.inkAt(0.55))),
            const _Section('Phòng ngừa cho vụ sau'),
            BulletList(info.prevention),
            const _Section('Khi nào cần gọi chuyên gia'),
            BulletList(info.callExpertWhen),
            const SizedBox(height: 18),
            const NoteCard(title: 'Lưu ý', body: kDisclaimer),
            const SizedBox(height: 14),
            const _CallStationButton(),
            const SizedBox(height: 16),
            Text('Cập nhật nội dung: $kContentUpdated',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.inkAt(0.4))),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final AdviceStep step;

  const _StepCard({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(step.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(step.body, style: TextStyle(fontSize: 15, height: 1.55, color: AppColors.inkAt(0.72))),
        ],
      ),
    );
  }
}

class _CallStationButton extends StatelessWidget {
  const _CallStationButton();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final AppSettings s = AppSettings.instance;
        final bool hasNumber = s.extensionPhone.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => callExtensionStation(context),
              style: secondaryButtonStyle().copyWith(minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54))),
              icon: const Icon(Icons.call_outlined),
              label: Text(hasNumber
                  ? 'Gọi ${s.extensionName.isNotEmpty ? s.extensionName : s.extensionPhone}'
                  : 'Gọi trạm khuyến nông'),
            ),
            if (hasNumber)
              TextButton(
                onPressed: () => editExtensionContact(context),
                child: Text('Đổi số (${s.extensionPhone})'),
              ),
          ],
        );
      },
    );
  }
}
