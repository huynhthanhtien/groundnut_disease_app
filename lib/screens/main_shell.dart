import 'package:flutter/material.dart';

import '../services/yolo_model_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'disease_library_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';

/// Top-level tabs. Tabs are kept alive in an [IndexedStack] so switching
/// between them never pushes routes; result/detail screens are pushed on
/// top of the shell and simply pop back to it.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab _tab = AppTab.scan;

  @override
  void initState() {
    super.initState();
    // Load the model in the background so the first scan doesn't stall.
    YoloModelService.instance.warmUp().catchError((Object e) {
      debugPrint('Model warm-up failed: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab.index,
        children: const [
          HomeScreen(),
          DiseaseLibraryScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        current: _tab,
        dark: _tab == AppTab.scan,
        onSelect: (tab) => setState(() => _tab = tab),
      ),
    );
  }
}
