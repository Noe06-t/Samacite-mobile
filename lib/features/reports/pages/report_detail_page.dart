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
/// Design basé sur detail-signalement.xml :
/// - ScrollView avec image principale (200dp)
/// - Titre, adresse, date/statut
/// - Description
/// - Map preview + bouton "Voir sur la carte"
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Détail du signalement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF007A3F),
                Color(0xFF00A854),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Bouton supprimer visible uniquement si l'utilisateur est le créateur
          if (_report != null && currentUserId != null && _report!.userId == currentUserId)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_rounded, size: 20),
              ),
              tooltip: 'Supprimer ce signalement',
              onPressed: () => _confirmDelete(context),
            ),
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
        child: CircularProgressIndicator(),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image principale (200dp height)
          _buildMainImage(context),

          // En-tête avec gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre avec icône
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007A3F), Color(0xFF00A854)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007A3F).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.report_problem_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Adresse si disponible
                            if (report.location?.address != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: Color(0xFFFFA000),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      report.location!.address!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Badges de métadonnées
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Badge date
                      if (report.createdAt != null)
                        _buildInfoBadge(
                          Icons.access_time_rounded,
                          _formatDate(report.createdAt!),
                          Colors.blue.shade400,
                        ),
                      // Badge statut
                      _buildStatusChip(),
                      // Badge catégorie si disponible
                      if (report.categoryId != null)
                        _buildInfoBadge(
                          Icons.category_rounded,
                          'Catégorie ${report.categoryId}',
                          Colors.purple.shade400,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Likes avec design moderne
                  _LikeButton(report: report),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Description avec style moderne
                _buildModernSection(
                  icon: Icons.description_rounded,
                  title: 'Description',
                  iconColor: const Color(0xFF007A3F),
                  child: Text(
                    report.description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section Localisation moderne
                _buildModernSection(
                  icon: Icons.map_rounded,
                  title: 'Localisation',
                  iconColor: const Color(0xFFFFA000),
                  child: Column(
                    children: [
                      // Map preview stylisé
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildMapPreview(),
                      ),
                      const SizedBox(height: 12),
                      
                      // Bouton moderne avec gradient
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA000), Color(0xFFFF8F00)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFA000).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
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
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.my_location_rounded, size: 22),
                            label: const Text(
                              'Voir sur la carte',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Section commentaires
          const Divider(height: 1, thickness: 1),
          CommentsSection(
            reportId: report.id,
            currentUserId: report.userId,
          ),
        ],
      ),
    );
  }

  Widget _buildMainImage(BuildContext context) {
    if (report.images.isNotEmpty) {
      final imageUrl = ImageUtils.getFullImageUrl(report.images.first);
      return GestureDetector(
        onTap: () => _showFullImageGallery(context, report.images, 0),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              memCacheHeight: 500,
              placeholder: (context, url) => Container(
                height: 250,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => _buildImagePlaceholder(),
            ),
            
            // Indicateur "Appuyez pour agrandir"
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Voir en grand',
                      style: const TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA000),
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
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 250,
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

  void _showFullImageGallery(BuildContext context, List<String> images, int initialIndex) {
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

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final statusInfo = _getStatusInfo();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo['color'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusInfo['label'] as String,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo() {
    switch (report.status) {
      case 'pending':
        return {
          'label': 'En cours',
          'color': const Color(0x420023D1), // #0023D142
        };
      case 'resolved':
        return {
          'label': 'Résolu',
          'color': const Color(0x3634C759), // #34C75936
        };
      case 'in_progress':
        return {
          'label': 'En attente',
          'color': const Color(0x70FFA000), // #FFA00070
        };
      default:
        return {
          'label': 'Inconnu',
          'color': Colors.grey,
        };
    }
  }

  Widget _buildMapPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Aperçu de la carte',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
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
          onPressed: () => Navigator.pop(context),
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

/// Widget bouton Like avec compteur
/// 
/// Gère l'affichage et l'interaction pour liker/unliker un signalement
class _LikeButton extends ConsumerStatefulWidget {
  final ReportModel report;

  const _LikeButton({required this.report});

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton> {
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
      
      final result = await likeRepository.toggleLike(widget.report.id, previousIsLiked);

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
            content: Text(_isLiked ? '❤️ Vous aimez ce signalement' : 'Like retiré'),
            duration: const Duration(seconds: 1),
            backgroundColor: _isLiked ? const Color(0xFFEA0707) : Colors.grey[700],
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
        if (!errorMessage.contains('409') && !errorMessage.contains('déjà aimé')) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isLiked ? const Color(0xFFEA0707) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône like
          GestureDetector(
            onTap: _isLoading ? null : _toggleLike,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? const Color(0xFFEA0707) : Colors.grey[600],
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Compteur likes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_likesCount j\'aime${_likesCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoading)
                  const Text(
                    'Chargement...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  )
                else
                  Text(
                    _isLiked ? 'Vous aimez ce signalement' : 'Appuyez pour aimer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          // Indicateur loading
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}

// Provider pour LikeRepository
final likeRepositoryProvider = Provider.family<LikeRepository, DioService>(
  (ref, dioService) => LikeRepository(dioService),
);
