import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/services/notification_service.dart';
import 'package:mobile_samacite/core/utils/image_utils.dart';
import 'package:mobile_samacite/features/auth/providers/auth_notifier.dart';
import 'package:mobile_samacite/features/notifications/state/notification_notifier.dart';
import 'package:mobile_samacite/features/reports/pages/take_photo_page.dart';
import 'package:mobile_samacite/features/reports/pages/my_reports_page.dart';
import 'package:mobile_samacite/features/reports/pages/report_detail_page.dart';
import 'package:mobile_samacite/features/reports/pages/report_list_page.dart';
import 'package:mobile_samacite/features/reports/pages/map_page.dart';
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

          // Charger les derniers signalements pour la section "Signalements récents"
          ref.read(reportListProvider.notifier).loadReports();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context),
      body: authState.maybeWhen(
        authenticated: (user, token) {
          return RefreshIndicator(
            color: AppColors.secondary,
            onRefresh: () async {
              await ref.read(reportListProvider.notifier).refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bannière de salutation (dégradé vert)
                  _buildGreetingBanner(user.prenom, user.nom),

                  const SizedBox(height: 20),

                  // Carousel d'images existant
                  const HomeCarousel(),

                  const SizedBox(height: 24),

                  // Grandes cartes d'action
                  _buildActionCard(
                    context,
                    icon: Icons.photo_camera_rounded,
                    title: 'Nouveau signalement',
                    subtitle: 'Prendre une photo & géolocaliser',
                    gradientColors: const [Color(0xFFFFA000), Color(0xFFFF8F00)],
                    trailingIcon: Icons.add,
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
                    icon: Icons.folder_shared_rounded,
                    title: 'Mes signalements',
                    subtitle: 'Suivez vos déclarations',
                    gradientColors: const [Color(0xFF007A3F), Color(0xFF00A854)],
                    trailingIcon: Icons.arrow_forward_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        ScalePageRoute(
                          builder: (context) => const MyReportsPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Section signalements récents (vraies données)
                  const Text(
                    'Signalements récents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentReportsSection(),

                  const SizedBox(height: 20),

                  // Carte "Explorer la carte interactive"
                  _buildMapShortcutCard(context),
                ],
              ),
            ),
          );
        },
        orElse: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  /// AppBar restylée proche de la maquette : fond blanc, logo, titre "Accueil"
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black.withOpacity(0.05),
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/samacite_logo.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_city, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DAKAR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'Accueil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildNotificationButton(context, ref),
        const SizedBox(width: 4),
        authState.maybeWhen(
          authenticated: (user, token) => _buildProfileAvatar(context, user.prenom, user.nom, user.photoUrl),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildProfileAvatar(BuildContext context, String prenom, String nom, String? photoUrl) {
    final initials = '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        Navigator.pushNamed(context, '/profile');
      },
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.secondary,
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? CachedNetworkImageProvider(ImageUtils.getFullImageUrl(photoUrl))
            : null,
        child: (photoUrl == null || photoUrl.isEmpty)
            ? Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  /// Bannière de salutation avec dégradé vert
  Widget _buildGreetingBanner(String prenom, String nom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF007A3F), Color(0xFF00A854)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue $prenom $nom !',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Signale, participe et améliore ta ville',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
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
    required IconData trailingIcon,
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    trailingIcon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section "Signalements récents" alimentée par de vraies données
  Widget _buildRecentReportsSection() {
    final reportListState = ref.watch(reportListProvider);

    if (reportListState.isLoading && reportListState.reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (reportListState.reports.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Aucun signalement pour le moment',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final recentReports = reportListState.reports.take(3).toList();

    return Column(
      children: recentReports
          .map((report) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRecentReportCard(report),
              ))
          .toList(),
    );
  }

  Widget _buildRecentReportCard(ReportModel report) {
    final statusStyle = _statusStyle(report.status);
    final address = report.location?.address;
    final imageUrl = report.images.isNotEmpty ? ImageUtils.getFullImageUrl(report.images.first) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              ScalePageRoute(
                builder: (context) => ReportDetailPage(reportId: report.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey.shade200),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_outlined, color: Colors.grey),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusStyle.backgroundColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusStyle.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusStyle.textColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _relativeTime(report.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (address != null && address.isNotEmpty) ...[
                            const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ] else
                            const Spacer(),
                          const SizedBox(width: 4),
                          const Icon(Icons.thumb_up, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${report.likesCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Carte de raccourci vers la carte interactive
  Widget _buildMapShortcutCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              FadePageRoute(
                builder: (context) => const MapPage(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.map_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explorer la carte interactive',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Visualisez les interventions en direct',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Ouvrir',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
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
          const Icon(Icons.notifications_outlined, color: Colors.black87),

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
                    color: AppColors.danger,
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

  /// Retourne le style (couleur texte / fond) pour un statut donné
  _StatusStyle _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
      case 'in_progress':
        return const _StatusStyle(
          label: 'EN COURS',
          textColor: Color(0xFF0023D1),
          backgroundColor: Color(0xFFE8EDFF),
        );
      case 'résolu':
      case 'resolved':
        return const _StatusStyle(
          label: 'RÉSOLU',
          textColor: Color(0xFF34C759),
          backgroundColor: Color(0xFFEBF9EE),
        );
      case 'en attente':
      case 'pending':
      default:
        return const _StatusStyle(
          label: 'EN ATTENTE',
          textColor: Color(0xFFFFA000),
          backgroundColor: Color(0xFFFFF4E5),
        );
    }
  }

  /// Calcule un temps relatif lisible à partir d'une date ISO
  String _relativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes} min';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return '';
    }
  }
}

/// Style visuel associé à un statut de signalement
class _StatusStyle {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _StatusStyle({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });
}
