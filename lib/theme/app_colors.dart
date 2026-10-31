import 'package:flutter/material.dart';

import '../services/scan_analysis.dart';

/// Palette lifted from the "Peanut Leaf Scanner" Android design (option 2a):
/// warm off-white surfaces, a muted sage green for primary actions/success,
/// and an amber tone for "medium severity" states. Original values were
/// specified in OKLCH; these are the closest sRGB approximations.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFAF9F6);
  static const Color surfaceAlt = Color(0xFFF1EFE8);
  static const Color surfaceDim = Color(0xFFEFECE4);
  static const Color ink = Color(0xFF1B1A17);

  static Color inkAt(double opacity) => ink.withValues(alpha: opacity);

  // Primary (sage green) — buttons, links, "mild/good" states.
  static const Color primary = Color(0xFF4C8B62);
  static const Color primaryDark = Color(0xFF3B6C4C);
  static const Color primaryLight = Color(0xFF63A472);
  static const Color primaryBright = Color(0xFF8FD9A0); // dark-mode accent

  // Amber (medium severity, notes/warnings).
  static const Color amberBg = Color(0xFFF3E6D3);
  static const Color amberText = Color(0xFF8A5A2E);
  static const Color noteBg = Color(0xFFF5EDDD);
  static const Color noteBorder = Color(0xFFE8D4B0);
  static const Color noteTitle = Color(0xFF6B4423);
  static const Color noteBody = Color(0xFF5C4632);

  // Rust/red-orange (high severity).
  static const Color rust = Color(0xFFD2792E);
  static const Color severeBg = Color(0xFFF6DCC9);
  static const Color severeText = Color(0xFF8A3E1F);

  // Dark viewfinder background.
  static const Color viewfinderBg = Color(0xFF0D0F0A);

  /// One color per model class name (labels.txt), used for the boxes drawn
  /// on the photo, the swatches in the detection list and the library icons
  /// so they can be matched at a glance.
  static const Map<String, Color> classColors = {
    'Black Fungus Pod': Color(0xFF3F3A36),
    'Early and Late leaf spot': Color(0xFFD9A23B),
    'Fungus leaf': Color(0xFF6E9BD9),
    'Rust-Leaf': rust,
    'black fungus-grondnut': Color(0xFFB06BC7),
    'brown Fungus Pod': Color(0xFF8C5A3C),
  };

  static Color forClass(String className) => classColors[className] ?? primaryLight;
}

class SeverityStyle {
  final String label;
  final Color background;
  final Color foreground;

  const SeverityStyle(this.label, this.background, this.foreground);
}

SeverityStyle styleFor(Severity s) {
  switch (s) {
    case Severity.severe:
      return const SeverityStyle('Nặng', AppColors.severeBg, AppColors.severeText);
    case Severity.moderate:
      return const SeverityStyle('Trung bình', AppColors.amberBg, AppColors.amberText);
    case Severity.mild:
      return SeverityStyle('Nhẹ', AppColors.primary.withValues(alpha: 0.14), AppColors.primaryDark);
  }
}

/// Style for a scan whose top detection is below [kConfidentThreshold].
final SeverityStyle kUncertainStyle = SeverityStyle('Chưa chắc', AppColors.inkAt(0.07), AppColors.inkAt(0.6));
