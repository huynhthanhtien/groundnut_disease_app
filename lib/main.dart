import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_settings.dart';
import 'services/history_store.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([AppSettings.instance.load(), HistoryStore.instance.load()]);
  runApp(const GroundnutDiseaseApp());
}

class GroundnutDiseaseApp extends StatelessWidget {
  const GroundnutDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhận diện bệnh cây lạc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: ListenableBuilder(
        listenable: AppSettings.instance,
        builder: (context, _) => AppSettings.instance.onboardingDone
            ? const MainShell()
            : OnboardingScreen(onDone: AppSettings.instance.completeOnboarding),
      ),
    );
  }
}
