import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/core/models/report_model_hive.dart';
import 'package:mobile_samacite/core/models/category_model_hive.dart';
import 'package:mobile_samacite/features/auth/pages/login_page.dart';
import 'package:mobile_samacite/features/notifications/pages/notification_list_page.dart';
import 'package:mobile_samacite/features/reports/pages/map_page.dart';
import 'package:mobile_samacite/features/splash/splash_screen.dart';

/// Point d'entrée principal de l'application
/// 
/// Notifications gérées via API Laravel uniquement (pas de Firebase)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // L'app démarre immédiatement : le premier frame Flutter s'affiche dès que
  // possible pour que l'écran natif Android disparaisse au plus vite. Hive
  // s'initialise ensuite en arrière-plan pendant que le SplashScreen Flutter
  // est déjà visible (les box sont de toute façon ouvertes à la demande).
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  await Hive.initFlutter();
  Hive.registerAdapter(ReportModelHiveAdapter());
  Hive.registerAdapter(CategoryModelHiveAdapter());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SamaCité',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textOnSecondary,
        ),
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/map': (context) => const MapPage(),
        '/notifications': (context) => const NotificationListPage(),
      },
      home: const SplashScreen(),
    );
  }
}
