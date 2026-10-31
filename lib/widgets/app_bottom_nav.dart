import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppTab { scan, library, history }

/// Bottom nav for the app shell (see MainShell). Pushed detail screens
/// (result, disease detail) sit on top of the shell and use a back button
/// instead, so the navigation stack never grows by tab-hopping.
class AppBottomNav extends StatelessWidget {
  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  /// The scan tab is a full-bleed dark camera UI, so the bar goes dark too.
  final bool dark;

  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? AppColors.viewfinderBg : AppColors.surfaceAlt,
        border: Border(top: BorderSide(color: dark ? Colors.white.withValues(alpha: 0.08) : AppColors.inkAt(0.08))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.camera_alt_outlined,
                label: 'Quét',
                selected: current == AppTab.scan,
                dark: dark,
                onTap: () => onSelect(AppTab.scan),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                label: 'Bệnh hại',
                selected: current == AppTab.library,
                dark: dark,
                onTap: () => onSelect(AppTab.library),
              ),
              _NavItem(
                icon: Icons.history,
                label: 'Lịch sử',
                selected: current == AppTab.history,
                dark: dark,
                onTap: () => onSelect(AppTab.history),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? (dark ? AppColors.primaryBright : AppColors.primary)
        : (dark ? Colors.white.withValues(alpha: 0.6) : AppColors.inkAt(0.55));
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 12.5, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
