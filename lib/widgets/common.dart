import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small uppercase section heading ("CHẨN ĐOÁN", "TRIỆU CHỨNG", ...).
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: AppColors.inkAt(0.5)),
    );
  }
}

/// Amber callout used for disclaimers and safety warnings.
class NoteCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  /// Stronger red-orange styling for safety warnings (e.g. aflatoxin).
  final bool severe;

  const NoteCard({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.info_outline,
    this.severe = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = severe ? AppColors.severeBg : AppColors.noteBg;
    final Color border = severe ? AppColors.rust.withValues(alpha: 0.45) : AppColors.noteBorder;
    final Color titleColor = severe ? AppColors.severeText : AppColors.noteTitle;
    final Color bodyColor = severe ? AppColors.severeText : AppColors.noteBody;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: titleColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor)),
                const SizedBox(height: 6),
                Text(body, style: TextStyle(fontSize: 14, height: 1.55, color: bodyColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded pill showing a [SeverityStyle] label.
class StatusChip extends StatelessWidget {
  final SeverityStyle style;

  const StatusChip(this.style, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: style.background, borderRadius: BorderRadius.circular(14)),
      child: Text(style.label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: style.foreground)),
    );
  }
}

/// Bulleted list of plain strings.
class BulletList extends StatelessWidget {
  final List<String> items;

  const BulletList(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final String item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 10),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ),
                Expanded(child: Text(item, style: TextStyle(fontSize: 15, height: 1.55, color: AppColors.inkAt(0.78)))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Large rounded primary/secondary button used for bottom actions.
ButtonStyle primaryButtonStyle() => ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );

ButtonStyle secondaryButtonStyle() => OutlinedButton.styleFrom(
      minimumSize: const Size(56, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(color: AppColors.inkAt(0.18)),
      foregroundColor: AppColors.ink,
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
