import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Small user preferences persisted as `<app documents>/settings.json`.
/// Falls back to in-memory defaults when storage isn't available.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  File? _file;

  bool _onboardingDone = false;
  String _extensionName = '';
  String _extensionPhone = '';

  /// Whether the photo-tips + disclaimer intro has been dismissed once.
  bool get onboardingDone => _onboardingDone;

  /// The user's local agricultural extension / plant-protection station.
  /// Entered by the user — the app ships no phone numbers of its own.
  String get extensionName => _extensionName;
  String get extensionPhone => _extensionPhone;

  Future<void> load() async {
    try {
      final Directory docs = await getApplicationDocumentsDirectory();
      _file = File(p.join(docs.path, 'settings.json'));
      if (await _file!.exists()) {
        final Map<String, dynamic> raw = jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
        _onboardingDone = raw['onboardingDone'] as bool? ?? false;
        _extensionName = raw['extensionName'] as String? ?? '';
        _extensionPhone = raw['extensionPhone'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('AppSettings: storage unavailable, using defaults ($e)');
      _file = null;
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    await _persist();
  }

  Future<void> setExtensionContact({required String name, required String phone}) async {
    _extensionName = name.trim();
    _extensionPhone = phone.trim();
    await _persist();
  }

  Future<void> _persist() async {
    notifyListeners();
    if (_file == null) return;
    await _file!.writeAsString(jsonEncode({
      'onboardingDone': _onboardingDone,
      'extensionName': _extensionName,
      'extensionPhone': _extensionPhone,
    }));
  }
}
