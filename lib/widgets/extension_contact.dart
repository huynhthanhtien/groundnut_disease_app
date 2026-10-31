import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_settings.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// Calls the user's saved extension station, asking for the number first if
/// none has been entered yet. The app deliberately ships no phone numbers —
/// stations differ per commune/district and change over time.
Future<void> callExtensionStation(BuildContext context) async {
  final AppSettings settings = AppSettings.instance;
  if (settings.extensionPhone.isEmpty) {
    final bool saved = await editExtensionContact(context);
    if (!saved || !context.mounted) return;
  }
  final Uri uri = Uri(scheme: 'tel', path: settings.extensionPhone.replaceAll(RegExp(r'[^0-9+]'), ''));
  final bool ok = await launchUrl(uri).catchError((_) => false);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không mở được ứng dụng gọi điện. Số đã lưu: ${settings.extensionPhone}')),
    );
  }
}

/// Bottom sheet to enter/edit the station name + phone. Returns true if saved.
Future<bool> editExtensionContact(BuildContext context) async {
  final AppSettings settings = AppSettings.instance;
  final (String, String)? result = await showModalBottomSheet<(String, String)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => _ContactSheet(name: settings.extensionName, phone: settings.extensionPhone),
  );
  if (result == null) return false;
  await settings.setExtensionContact(name: result.$1, phone: result.$2);
  return true;
}

class _ContactSheet extends StatefulWidget {
  final String name;
  final String phone;

  const _ContactSheet({required this.name, required this.phone});

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.name);
  late final TextEditingController _phone = TextEditingController(text: widget.phone);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạm khuyến nông / BVTV của bạn',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(
            'Nhập số điện thoại của cán bộ khuyến nông xã, trạm khuyến nông hoặc trạm BVTV huyện. Số được lưu trên máy này.',
            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.inkAt(0.62)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Tên (vd. Trạm khuyến nông huyện)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: primaryButtonStyle(),
            onPressed: () {
              if (_phone.text.trim().isEmpty) return;
              Navigator.of(context).pop((_name.text, _phone.text));
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
