import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/core/models/report_model_hive.dart';
import 'package:mobile_samacite/core/models/category_model_hive.dart';
import 'package:mobile_samacite/features/auth/pages/login_page.dart';
import 'package:mobile_samacite/features/notifications/pages/notification_list_page.dart';
import 'package:mobile_samacite/features/reports/pages/map_page.dart';

/// Point d'entrée principal de l'application
/// 
/// Notifications gérées via API Laravel uniquement (pas de Firebase)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation Hive pour le cache local
  await Hive.initFlutter();
  
  // Enregistrement des adapters Hive
  Hive.registerAdapter(ReportModelHiveAdapter());
  Hive.registerAdapter(CategoryModelHiveAdapter());
  
  // Les box seront ouvertes à la demande (lazy loading)

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
        '/map': (context) => const MapPage(),
        '/notifications': (context) => const NotificationListPage(),
      },
      home: const LoginPage(),
    );
  }
}
