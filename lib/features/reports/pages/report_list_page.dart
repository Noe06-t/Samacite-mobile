import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/reports/providers/report_list_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/report_list_state.dart';
import 'package:mobile_samacite/features/reports/providers/report_filter_notifier.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/features/auth/providers/auth_providers.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_samacite/features/reports/pages/report_detail_page.dart';
import 'package:mobile_samacite/features/reports/widgets/filter_bottom_sheet.dart';

/// Provider pour le repository
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final dioService = ref.watch(dioServiceProvider);
  return ReportRepository(dioService);
});

/// Provider pour le notifier de la liste des signalements
final reportListProvider = StateNotifierProvider<ReportListNotifier, ReportListState>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return ReportListNotifier(repository, ref);
});

/// Page liste des signalements
/// 
/// Affiche la liste paginée avec infinite scroll
/// Design basé sur liste-signalements.xml et item-signalement.xml
class ReportListPage extends ConsumerStatefulWidget {
  const ReportListPage({super.key});

  @override
  ConsumerState<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends ConsumerState<ReportListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Charger les signalements au démarrage
    // ET à chaque fois qu'on revient sur la page (après création)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportListProvider.notifier).refresh();
    });

    // Infinite scroll
    _scrollController.addListener(_onScroll);
  }

  Future<void> _openFilterBottomSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );

    // Si des filtres ont été modifiés, recharger la liste
    if (result == true) {
      ref.read(reportListProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      // Charger plus quand à 90% du scroll
      ref.read(reportListProvider.notifier).loadMoreReports();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(reportListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportListProvider);

    // Afficher erreur dans SnackBar
    ref.listen<ReportListState>(reportListProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final filters = ref.watch(reportFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tous les signalements',
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
              colors: [Color(0xFF007A3F), Color(0xFF00A854)],
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
          // Bouton filtres avec badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _openFilterBottomSheet,
                tooltip: 'Filtrer',
              ),
              if (filters.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA000),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${filters.activeFiltersCount}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ReportListState state) {
    // Si erreur critique
    if (state.errorMessage != null && state.errorMessage!.isNotEmpty && state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(reportListProvider.notifier).refresh();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    // État initial de chargement
    if (state.isLoading && state.reports.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Liste vide
    if (state.reports.isEmpty) {
      return const Center(
        child: Text(
          'Aucun signalement pour le moment',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Liste avec données
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: state.reports.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator en bas
        if (index == state.reports.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final report = state.reports[index];
        return ReportItemWidget(
          report: report,
          onTap: () async {
            // Naviguer vers les détails et attendre le résultat
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailPage(reportId: report.id),
              ),
            );
            
            // Si un signalement a été supprimé, rafraîchir la liste
            if (result == true && mounted) {
              ref.read(reportListProvider.notifier).refresh();
            }
          },
        );
      },
    );
  }
}

/// Widget pour un item de signalement dans la liste
/// 
/// Design moderne avec photo, likes et commentaires
class ReportItemWidget extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onTap;

  const ReportItemWidget({
    super.key,
    required this.report,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image principale cliquable
              _buildImage(context),
              
              // Contenu
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A3F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Description courte
                    Text(
                      report.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    
                    // Ligne avec likes et commentaires
                    Row(
                      children: [
                        // Badge likes
                        _buildStatBadge(
                          Icons.favorite,
                          report.likesCount.toString(),
                          const Color(0xFFEA0707),
                        ),
                        const SizedBox(width: 16),
                        
                        // Badge commentaires  
                        _buildStatBadge(
                          Icons.comment,
                          '0', // TODO: Ajouter commentsCount au modèle
                          const Color(0xFF007A3F),
                        ),
                        
                        const Spacer(),
                        
                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(report.createdAt ?? ''),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildStatBadge(IconData icon, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            count,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (report.images.isNotEmpty) {
      final imageUrl = ImageUtils.getFullImageUrl(report.images.first);
      return GestureDetector(
        onTap: () => _showFullImage(context, imageUrl),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            memCacheHeight: 400,
            placeholder: (context, url) => Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) {
              return _buildPlaceholder();
            },
          ),
        ),
      );
    }
    
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 60,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
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
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Aujourd\'hui';
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
