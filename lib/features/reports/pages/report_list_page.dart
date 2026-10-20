import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/reports/providers/report_list_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/report_list_state.dart';
import 'package:mobile_samacite/features/reports/providers/report_filter_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/report_filter_state.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/features/auth/providers/auth_providers.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_samacite/features/reports/pages/report_detail_page.dart';
import 'package:mobile_samacite/features/reports/pages/take_photo_page.dart';
import 'package:mobile_samacite/features/reports/widgets/filter_bottom_sheet.dart';
import 'package:mobile_samacite/core/utils/status_utils.dart';

/// Couleur de fond générale de la page (maquette Stitch)
const Color _kPageBackground = Color(0xFFF8F9FA);
const Color _kPrimaryOrange = Color(0xFFFFA000);
const Color _kSecondaryGreen = Color(0xFF007A3F);

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
/// Design inspiré de la maquette Google Stitch "Signalements citoyens"
class ReportListPage extends ConsumerStatefulWidget {
  const ReportListPage({super.key, this.onRootBack});

  final VoidCallback? onRootBack;

  @override
  ConsumerState<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends ConsumerState<ReportListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    // Charger les signalements au démarrage
    // ET à chaque fois qu'on revient sur la page (après création)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportListProvider.notifier).refresh();
      _searchController.text = ref.read(reportFilterProvider).searchQuery;
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
    _searchController.dispose();
    _searchDebounce?.cancel();
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

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(reportFilterProvider.notifier).setSearchQuery(value);
      ref.read(reportListProvider.notifier).refresh();
    });
  }

  void _onStatusChipSelected(String? status) {
    final current = ref.read(reportFilterProvider).status;
    if (current == status) return;
    ref.read(reportFilterProvider.notifier).setStatus(status);
    ref.read(reportListProvider.notifier).refresh();
  }

  void _openReport(ReportModel report) async {
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
  }

  void _goToCreateReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TakePhotoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportListProvider);
    final filters = ref.watch(reportFilterProvider);

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

    return Scaffold(
      backgroundColor: _kPageBackground,
      appBar: AppBar(
        backgroundColor: _kPageBackground,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kSecondaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20, color: _kSecondaryGreen),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              widget.onRootBack?.call();
            }
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DAKAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kSecondaryGreen,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Signalements',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilterRow(filters),
          const SizedBox(height: 10),
          _buildStatusChips(filters),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildBody(state, filters.status),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildReportFab(),
    );
  }

  Widget _buildSearchAndFilterRow(ReportFilterState filters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Rechercher un quartier, une voirie...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openFilterBottomSheet,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.tune, size: 22, color: Colors.black87),
                  ),
                ),
              ),
              if (filters.hasActiveFilters)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: _kPrimaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips(ReportFilterState filters) {
    final chips = <_StatusChipData>[
      const _StatusChipData(label: 'Tous', status: null, dotColor: null),
      const _StatusChipData(label: 'En attente', status: 'En attente', dotColor: _kPrimaryOrange),
      const _StatusChipData(label: 'En cours', status: 'En cours', dotColor: Color(0xFF0023D1)),
      const _StatusChipData(label: 'Résolus', status: 'Résolu', dotColor: Color(0xFF34C759)),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isActive = filters.status == chip.status;
          return GestureDetector(
            onTap: () => _onStatusChipSelected(chip.status),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? _kSecondaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isActive ? null : Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.check, size: 15, color: Colors.white),
                    )
                  else if (chip.dotColor != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: chip.dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  Text(
                    chip.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_kPrimaryOrange, Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _kPrimaryOrange.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _goToCreateReport,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_location_alt, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Signaler',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ReportListState state, String? statusFilter) {
    // Filtrage du statut côté client (voir normalizeStatus : le backend a des
    // valeurs de statut incohérentes selon les signalements).
    final reports = statusFilter == null
        ? state.reports
        : state.reports
            .where((r) => normalizeStatus(r.status) == normalizeStatus(statusFilter))
            .toList();

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

    // Liste vide (après filtrage par statut)
    if (reports.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              statusFilter == null
                  ? 'Aucun signalement pour le moment'
                  : 'Aucun signalement avec ce statut pour le moment',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    // Liste avec données
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: reports.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator en bas
        if (index == reports.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final report = reports[index];
        return ReportItemWidget(
          report: report,
          onTap: () => _openReport(report),
        );
      },
    );
  }
}

class _StatusChipData {
  final String label;
  final String? status;
  final Color? dotColor;

  const _StatusChipData({required this.label, required this.status, required this.dotColor});
}

/// Widget pour un item de signalement dans la liste
///
/// Design inspiré de la maquette Stitch : miniature carrée, badge de statut,
/// temps relatif, adresse, description tronquée et stats (likes/commentaires).
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
    final address = report.location?.address;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThumbnail(context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildStatusBadge(report.status),
                              const Spacer(),
                              Text(
                                _formatRelativeDate(report.createdAt),
                                style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (address != null && address.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: _kPrimaryOrange),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  report.description,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${report.likesCount}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(width: 18),
                    Icon(Icons.mode_comment_outlined, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${report.commentsCount}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    late final Color background;
    late final Color foreground;
    late final String label;

    switch (normalizeStatus(status)) {
      case 'in_progress':
        background = const Color(0xFFE8EDFF);
        foreground = const Color(0xFF0023D1);
        label = 'En cours';
        break;
      case 'resolved':
        background = const Color(0xFFEBF9EE);
        foreground = const Color(0xFF34C759);
        label = 'Résolu';
        break;
      case 'pending':
      default:
        background = const Color(0xFFFFF4E5);
        foreground = _kPrimaryOrange;
        label = 'En attente';
        break;
    }

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: foreground,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (report.images.isNotEmpty) {
      final imageUrl = ImageUtils.getFullImageUrl(report.images.first);
      return GestureDetector(
        onTap: () => _showFullImage(context, imageUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            memCacheWidth: 160,
            placeholder: (context, url) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => _buildPlaceholder(),
          ),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: 28,
        color: Colors.grey[500],
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

  String _formatRelativeDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
