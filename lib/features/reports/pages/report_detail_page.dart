import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/utils/image_utils.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/features/reports/pages/report_list_page.dart';
import 'package:mobile_samacite/features/reports/pages/map_page.dart';
import 'package:mobile_samacite/features/reports/repositories/like_repository.dart';
import 'package:mobile_samacite/features/comments/widgets/comments_section.dart';
import 'package:mobile_samacite/features/auth/providers/auth_notifier.dart';

/// Page de détail d'un signalement
///
/// Restylée façon maquette Google Stitch "Détails Signalement" :
/// - Fond de page clair #F8F9FA
/// - Image héro zoomable
/// - Badges catégorie / statut (pill)
/// - Bouton like pleine largeur orange
/// - Carte description, carte localisation, carte commentaires
///   (fond blanc, radius 16, ombre douce)
///
/// Toute la logique métier existante est conservée (like/unlike,
/// commentaires, suppression, navigation carte, visionneuse photo).
/// Les éléments fictifs de la maquette (numéro de dossier, priorité,
/// suivi d'avancement, workflow municipal à étapes, rôle "Délégué
/// Quartier", partage) ont été volontairement omis car ils n'existent
/// pas côté backend.
class ReportDetailPage extends ConsumerStatefulWidget {
  final int reportId;

  const ReportDetailPage({
    super.key,
    required this.reportId,
  });

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  ReportModel? _report;
  bool _isLoading = true;
  String? _errorMessage;

  static const Color _pageBackground = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadReportDetails();
  }

  Future<void> _loadReportDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repository = ref.read(reportRepositoryProvider);
      final report = await repository.getReportById(
        widget.reportId,
        includeRelations: ['user', 'category', 'images', 'location'],
      );

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      // Message user-friendly pour 404
      String errorMessage = 'Erreur lors du chargement';
      if (e.toString().contains('404') ||
          e.toString().contains('non trouvé') ||
          e.toString().contains('not found')) {
        errorMessage = 'Ce signalement n\'existe plus ou a été supprimé';
      } else {
        errorMessage = 'Erreur lors du chargement du signalement';
      }

      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer l'utilisateur connecté pour vérifier s'il est le créateur
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.maybeWhen(
      authenticated: (user, _) => user.id,
      orElse: () => null,
    );

    final bool canDelete = _report != null &&
        currentUserId != null &&
        _report!.userId == currentUserId;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        surfaceTintColor: _pageBackground,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Détails Signalement',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: Colors.black87,
            ),
          ),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        actions: [
          // Bouton supprimer visible uniquement si l'utilisateur est le créateur
          if (canDelete)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA0707).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Color(0xFFEA0707),
                ),
              ),
              tooltip: 'Supprimer ce signalement',
              onPressed: () => _confirmDelete(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Affiche une boîte de dialogue de confirmation avant suppression
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirmer la suppression'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer ce signalement ? '
            'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEA0707),
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted && context.mounted) {
      await _deleteReport(context);
    }
  }

  /// Supprime le signalement et retourne à la liste
  Future<void> _deleteReport(BuildContext context) async {
    if (_report == null) return;

    // Capturer le navigator et messenger avant les opérations async
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Afficher un loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final repository = ref.read(reportRepositoryProvider);
      await repository.delete(_report!.id);

      if (mounted && context.mounted) {
        // Fermer le loading d'abord
        navigator.pop();

        // Retourner à l'écran précédent IMMÉDIATEMENT
        // pour éviter que la page ne tente de recharger le signalement supprimé
        navigator.pop(true); // true indique qu'une suppression a eu lieu

        // Afficher un message de succès APRÈS avoir quitté la page
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Signalement supprimé avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        // Fermer le loading
        navigator.pop();

        // Afficher l'erreur
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: const Color(0xFFEA0707),
          ),
        );
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFA000),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.report_off, size: 80, color: Color(0xFFEA0707)),
              const SizedBox(height: 24),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF007A3F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA000),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadReportDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF007A3F),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_report == null) {
      return const Center(
        child: Text('Signalement non trouvé'),
      );
    }

    return ReportDetailContent(report: _report!);
  }
}

/// Contenu de la page de détail (widget stateless pour les tests)
class ReportDetailContent extends StatelessWidget {
  final ReportModel report;

  const ReportDetailContent({
    super.key,
    required this.report,
  });

  static const Color _pageBackground = Color(0xFFF8F9FA);
  static const Color _primaryOrange = Color(0xFFFFA000);
  static const Color _secondaryGreen = Color(0xFF007A3F);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBackground,
      child: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image héro (zoomable)
              _buildMainImage(context),
              const SizedBox(height: 16),

              // Badges catégorie + statut
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (report.category?.name != null)
                    _buildCategoryBadge(report.category!.name),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),

              // Titre
              Text(
                report.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Auteur + date
              _buildMetaRow(),
              const SizedBox(height: 20),

              // Bouton like pleine largeur
              _LikeButton(report: report),
              const SizedBox(height: 20),

              // Description ("Constat & Impact")
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 20,
                          color: _secondaryGreen,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Constat & Impact',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      report.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Localisation
              if (report.location?.address != null)
                _buildCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LOCALISATION',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  report.location!.address!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _primaryOrange.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 20,
                              color: _primaryOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _goToMap(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryOrange,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.my_location_rounded,
                              size: 20),
                          label: const Text(
                            'Voir sur la carte générale',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primaryOrange.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          size: 20,
                          color: _primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _goToMap(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryOrange,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.my_location_rounded,
                              size: 20),
                          label: const Text(
                            'Voir sur la carte',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Commentaires (widget existant, conteneur restylé)
              _buildCard(
                padding: EdgeInsets.zero,
                child: CommentsSection(
                  reportId: report.id,
                  currentUserId: report.userId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToMap(BuildContext context) {
    if (report.location != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(
            focusedReportId: report.id,
            centerLatitude: report.location!.latitude,
            centerLongitude: report.location!.longitude,
          ),
        ),
      );
    } else {
      Navigator.pushNamed(context, '/map');
    }
  }

  /// Carte blanche standard : radius 16, ombre douce
  Widget _buildCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _buildMetaRow() {
    final authorName = _getAuthorName();
    final createdLabel =
        report.createdAt != null ? _formatDate(report.createdAt!) : null;
    final bool hasUpdate = report.updatedAt != null &&
        report.createdAt != null &&
        report.updatedAt != report.createdAt;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        const Icon(Icons.schedule_rounded, size: 16, color: _primaryOrange),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            children: [
              if (authorName != null) ...[
                const TextSpan(text: 'Signalé par '),
                TextSpan(
                  text: authorName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ] else
                const TextSpan(text: 'Signalement'),
              if (createdLabel != null) TextSpan(text: ' le $createdLabel'),
            ],
          ),
        ),
        if (hasUpdate) ...[
          Text('•', style: TextStyle(color: Colors.grey.shade400)),
          Text(
            'Mis à jour ${_formatRelative(report.updatedAt!)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _secondaryGreen,
            ),
          ),
        ],
      ],
    );
  }

  String? _getAuthorName() {
    final user = report.user;
    if (user == null) return null;
    final prenom = user.prenom.isNotEmpty ? user.prenom[0] : '';
    final nom = user.nom;
    if (prenom.isEmpty && nom.isEmpty) return null;
    return '$prenom. $nom'.trim();
  }

  Widget _buildCategoryBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _secondaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer_rounded,
              size: 14, color: _secondaryGreen),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _secondaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final statusInfo = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: statusInfo['bg'] as Color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusInfo['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusInfo['label'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusInfo['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo() {
    // Le backend renvoie les statuts en français
    final status = report.status.toLowerCase().trim();

    if (status == 'en attente' || status == 'pending') {
      return {
        'label': 'En attente',
        'color': const Color(0xFFFFA000),
        'bg': const Color(0xFFFFF4E5),
      };
    } else if (status == 'en cours' || status == 'in_progress') {
      return {
        'label': 'En cours',
        'color': const Color(0xFF0023D1),
        'bg': const Color(0xFFE8EDFF),
      };
    } else if (status == 'résolu' ||
        status == 'resolu' ||
        status == 'resolved') {
      return {
        'label': 'Résolu',
        'color': const Color(0xFF34C759),
        'bg': const Color(0xFFEBF9EE),
      };
    }

    // Fallback
    return {
      'label': report.status,
      'color': Colors.grey.shade700,
      'bg': Colors.grey.shade200,
    };
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatRelative(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'à l\'instant';
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
      return 'il y a ${diff.inDays} j';
    } catch (e) {
      return '';
    }
  }

  Widget _buildMainImage(BuildContext context) {
    final BorderRadius imageRadius = BorderRadius.circular(16);

    if (report.images.isNotEmpty) {
      final imageUrl = ImageUtils.getFullImageUrl(report.images.first);
      return ClipRRect(
        borderRadius: imageRadius,
        child: GestureDetector(
          onTap: () => _showFullImageGallery(context, report.images, 0),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                memCacheHeight: 500,
                placeholder: (context, url) => Container(
                  height: 230,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => _buildImagePlaceholder(),
              ),

              // Indicateur "Agrandir la photo"
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Agrandir la photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Badge nombre d'images si plusieurs
              if (report.images.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primaryOrange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library,
                          color: Colors.black,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${report.images.length}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: imageRadius,
      child: _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade300, Colors.grey.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 80,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune image disponible',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImageGallery(
      BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _ImageGalleryViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Visionneuse d'images plein écran avec PageView
class _ImageGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageGalleryViewer({
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<_ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<_ImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final imageUrl = ImageUtils.getFullImageUrl(widget.images[index]);
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 60,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bouton like pleine largeur avec compteur réel
///
/// Gère l'affichage et l'interaction pour liker/unliker un signalement
/// ("J'appuie ce signalement" dans la maquette).
class _LikeButton extends ConsumerStatefulWidget {
  final ReportModel report;

  const _LikeButton({required this.report});

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton> {
  static const Color _primaryOrange = Color(0xFFFFA000);
  static const Color _secondaryGreen = Color(0xFF007A3F);

  late bool _isLiked;
  late int _likesCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.report.isLiked;
    _likesCount = widget.report.likesCount;
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // État optimiste : mise à jour immédiate de l'UI
    final previousIsLiked = _isLiked;
    final previousLikesCount = _likesCount;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    try {
      final dioService = ref.read(dioServiceProvider);
      final likeRepository = ref.read(likeRepositoryProvider(dioService));

      final result = await likeRepository.toggleLike(
          widget.report.id, previousIsLiked);

      // Mise à jour avec les valeurs réelles du serveur
      if (mounted) {
        setState(() {
          _isLiked = result['is_liked'] as bool;
          _likesCount = result['likes_count'] as int;
          _isLoading = false;
        });

        // Feedback visuel
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLiked
                ? '❤️ Vous aimez ce signalement'
                : 'Like retiré'),
            duration: const Duration(seconds: 1),
            backgroundColor:
                _isLiked ? const Color(0xFFEA0707) : Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      // Rollback en cas d'erreur
      if (mounted) {
        setState(() {
          _isLiked = previousIsLiked;
          _likesCount = previousLikesCount;
          _isLoading = false;
        });

        final errorMessage = e.toString();
        // Ne pas afficher d'erreur si c'est un conflit 409 (déjà géré par optimistic update)
        if (!errorMessage.contains('409') &&
            !errorMessage.contains('déjà aimé')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        _isLiked ? _secondaryGreen : _primaryOrange;
    final Color foregroundColor = _isLiked ? Colors.white : Colors.black;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _toggleLike,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  _isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_off_alt_rounded,
                  size: 22,
                  color: foregroundColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "J'appuie ce signalement",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: foregroundColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: foregroundColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_likesCount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
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
}

// Provider pour LikeRepository
final likeRepositoryProvider = Provider.family<LikeRepository, DioService>(
  (ref, dioService) => LikeRepository(dioService),
);
