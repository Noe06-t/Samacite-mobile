import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/services/notification_service.dart';
import 'package:mobile_samacite/features/auth/providers/auth_notifier.dart';
import 'package:mobile_samacite/features/notifications/state/notification_notifier.dart';
import 'package:mobile_samacite/features/reports/pages/take_photo_page.dart';
import 'package:mobile_samacite/features/reports/pages/my_reports_page.dart';
import 'package:mobile_samacite/features/home/widgets/home_carousel.dart';
import 'package:mobile_samacite/core/utils/page_transitions.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    
    // Initialiser le token et charger les notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      authState.maybeWhen(
        authenticated: (user, token) {
          // Définir le token dans DioService
          final dioService = ref.read(dioServiceProvider);
          dioService.setToken(token);
          
          // Initialiser et démarrer le polling des notifications
          _notificationService.initialize(dioService);
          _notificationService.startPolling(intervalSeconds: 60); // ⏱️ Augmenté à 60s pour réduire la charge
          
          // Charger les notifications initiales
          ref.read(notificationNotifierProvider.notifier).loadNotifications();
          ref.read(notificationNotifierProvider.notifier).updateUnreadCount();
        },
        orElse: () {},
      );
    });
  }

  @override
  void dispose() {
    // Arrêter le polling quand on quitte la page
    _notificationService.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    // Debug : Afficher l'état actuel
    print('[HomePage] 📊 État auth: $authState');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SamaCité',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF007A3F), Color(0xFF00A854)],
            ),
          ),
        ),
        actions: [
          _buildNotificationButton(context, ref),
        ],
      ),
      body: authState.maybeWhen(
        authenticated: (user, token) {
          print('[HomePage] ✅ État authenticated détecté');
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      'Bienvenue ${user.prenom} ${user.nom} !',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Slogan
                  const Text(
                    'Signale, participe et améliore ta ville',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Carousel auto-défilant
                  const SizedBox(height: 8),
                  const HomeCarousel(),
                  
                  const SizedBox(height: 32),
                  const Text(
                    'Actions rapides',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    icon: Icons.add_circle_outline,
                    title: 'Nouveau signalement',
                    subtitle: 'Créer un signalement',
                    gradientColors: [Color(0xFFFFA000), Color(0xFFFF8F00)],
                    onTap: () {
                      Navigator.push(
                        context,
                        SlideUpPageRoute(
                          builder: (context) => const TakePhotoPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    context,
                    icon: Icons.list_alt,
                    title: 'Mes signalements',
                    subtitle: 'Voir tous vos signalements',
                    gradientColors: [Color(0xFF007A3F), Color(0xFF005A2F)],
                    onTap: () {
                      Navigator.push(
                        context,
                        ScalePageRoute(
                          builder: (context) => const MyReportsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () {
          print('[HomePage] ⏳ État orElse - affichage loading');
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  /// Widget pour les cartes d'action avec dégradé
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget pour le bouton de notifications avec badge
  Widget _buildNotificationButton(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications, color: Colors.white),
          
          // Badge avec compteur
          Consumer(
            builder: (context, ref, child) {
              final notificationNotifier = ref.watch(notificationNotifierProvider);
              final unreadCount = notificationNotifier.unreadCount;
              
              if (unreadCount == 0) return const SizedBox.shrink();
              
              return Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFA000),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      onPressed: () {
        Navigator.pushNamed(context, '/notifications');
      },
    );
  }
}
