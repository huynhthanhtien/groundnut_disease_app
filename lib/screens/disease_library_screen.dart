import 'package:flutter/material.dart';

import '../data/disease_info.dart';
import '../services/app_settings.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/extension_contact.dart';
import 'disease_detail_screen.dart';
import 'onboarding_screen.dart';

/// Browse every disease the model knows, without scanning first.
class DiseaseLibraryScreen extends StatelessWidget {
  const DiseaseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text('Bệnh hại cây lạc',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink)),
            const SizedBox(height: 3),
            Text('${kDiseases.length} nhóm bệnh app có thể nhận diện',
                style: TextStyle(fontSize: 14, color: AppColors.inkAt(0.55))),
            for (final PlantPart part in PlantPart.values) ...[
              const SizedBox(height: 22),
              SectionLabel('Trên ${part.label.toLowerCase()}'),
              const SizedBox(height: 4),
              for (final DiseaseInfo d in kDiseases.where((d) => d.part == part)) _DiseaseTile(info: d),
            ],
            const SizedBox(height: 26),
            const SectionLabel('Tiện ích'),
            const SizedBox(height: 4),
            _UtilityTile(
              icon: Icons.lightbulb_outline,
              title: 'Cách chụp ảnh để nhận diện tốt',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingScreen())),
            ),
            ListenableBuilder(
              listenable: AppSettings.instance,
              builder: (context, _) {
                final AppSettings s = AppSettings.instance;
                return _UtilityTile(
                  icon: Icons.call_outlined,
                  title: 'Trạm khuyến nông / BVTV',
                  subtitle: s.extensionPhone.isEmpty
                      ? 'Chưa có số — chạm để thêm'
                      : '${s.extensionName.isNotEmpty ? '${s.extensionName} · ' : ''}${s.extensionPhone}',
                  onTap: () => editExtensionContact(context),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DiseaseTile extends StatelessWidget {
  final DiseaseInfo info;

  const _DiseaseTile({required this.info});

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.forClass(info.label);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DiseaseDetailScreen(info: info))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.inkAt(0.08)))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                info.part == PlantPart.leaf ? Icons.eco_outlined : (info.part == PlantPart.pod ? Icons.grain : Icons.grass),
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(info.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.inkAt(0.6))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.inkAt(0.35)),
          ],
        ),
      ),
    );
  }
}

class _UtilityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _UtilityTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(fontSize: 13.5, color: AppColors.inkAt(0.55))),
      trailing: Icon(Icons.chevron_right, color: AppColors.inkAt(0.35)),
      onTap: onTap,
    );
  }
}
