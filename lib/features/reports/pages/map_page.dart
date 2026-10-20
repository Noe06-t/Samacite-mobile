import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/services/location_service.dart';
import 'package:mobile_samacite/features/reports/pages/report_detail_page.dart';
import 'package:mobile_samacite/features/reports/pages/report_list_page.dart';

/// Page affichant tous les signalements sur une carte OpenStreetMap
///
/// Fonctionnalités:
/// - Affiche tous les signalements sous forme de marqueurs
/// - Couleurs des marqueurs selon le statut (pending, in_progress, resolved)
/// - Filtres par statut (chips flottants avec compteurs réels)
/// - Clic sur marqueur → Aperçu flottant du signalement, puis navigation vers page détail
/// - Zoom/Pan sur la carte
/// - Centrage automatique sur un signalement spécifique si fourni
/// - Centrage sur la position GPS réelle de l'utilisateur
class MapPage extends ConsumerStatefulWidget {
  final VoidCallback? onRootBack;

  /// ID du signalement à centrer (optionnel)
  final int? focusedReportId;

  /// Latitude pour centrer la carte (optionnel)
  final double? centerLatitude;

  /// Longitude pour centrer la carte (optionnel)
  final double? centerLongitude;

  const MapPage({
    super.key,
    this.focusedReportId,
    this.centerLatitude,
    this.centerLongitude,
    this.onRootBack,
  });

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

/// Filtre de statut appliqué aux marqueurs affichés sur la carte
enum _StatusFilter { all, pending, inProgress, resolved }

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  bool _hasInitialCentered = false; // Flag pour éviter de recentrer plusieurs fois

  // Centre par défaut: Dakar, Sénégal
  static const LatLng _defaultCenter = LatLng(14.6937, -17.4441);
  static const double _defaultZoom = 12.0;

  /// Filtre de statut actuellement sélectionné pour la carte
  _StatusFilter _statusFilter = _StatusFilter.all;

  /// Signalement sélectionné affiché dans la carte flottante en bas
  ReportModel? _selectedReport;

  /// Dernière position GPS connue de l'utilisateur (utilisée pour calculer une vraie distance)
  Position? _userPosition;

  /// Indique si une récupération de position GPS est en cours
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    // Charger les signalements au montage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportListProvider.notifier).loadReports();

      // Centrer immédiatement si des coordonnées sont fournies (navigation depuis détail)
      if (widget.centerLatitude != null && widget.centerLongitude != null) {
        print('[MapPage] 🎯 Centrage immédiat sur coordonnées: (${widget.centerLatitude}, ${widget.centerLongitude})');
        _centerMapOnLocation(
          widget.centerLatitude!,
          widget.centerLongitude!,
          zoom: 15.0, // Zoom plus proche pour un signalement spécifique
        );
        _hasInitialCentered = true;
      }
    });
  }

  /// Centre la carte sur une position donnée
  void _centerMapOnLocation(double lat, double lng, {double zoom = 13.0}) {
    try {
      _mapController.move(LatLng(lat, lng), zoom);
      print('[MapPage] ✅ Carte centrée sur: ($lat, $lng) zoom: $zoom');
    } catch (e) {
      print('[MapPage] ❌ Erreur centrage carte: $e');
    }
  }

  /// Récupère la position GPS réelle de l'utilisateur et centre la carte dessus
  Future<void> _handleRecenterOnUserPosition() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _userPosition = position);
      _centerMapOnLocation(position.latitude, position.longitude, zoom: 15.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportListState = ref.watch(reportListProvider);

    // Centrer sur le premier signalement une fois les données chargées
    if (!_hasInitialCentered &&
        !reportListState.isLoading &&
        reportListState.reports.isNotEmpty &&
        widget.centerLatitude == null &&
        widget.centerLongitude == null) {

      // Utiliser addPostFrameCallback pour centrer après le build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasInitialCentered && reportListState.reports.isNotEmpty) {
          final firstReport = reportListState.reports.firstWhere(
            (r) => r.location != null,
            orElse: () => reportListState.reports.first,
          );

          if (firstReport.location != null && mounted) {
            print('[MapPage] 🎯 Centrage automatique sur premier signalement après chargement: '
                  '(${firstReport.location!.latitude}, ${firstReport.location!.longitude})');
            _centerMapOnLocation(
              firstReport.location!.latitude,
              firstReport.location!.longitude,
            );
            setState(() {
              _hasInitialCentered = true;
            });
          }
        }
      });
    }

    final allReports = reportListState.reports;
    final filteredReports = _applyStatusFilter(allReports);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Carte des signalements',
          style: TextStyle(
            color: Colors.white,
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              widget.onRootBack?.call();
            }
          },
        ),
      ),
      body: reportListState.isLoading && reportListState.reports.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : reportListState.errorMessage != null && reportListState.reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        reportListState.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(reportListProvider.notifier).loadReports();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _defaultCenter,
                        initialZoom: _defaultZoom,
                        minZoom: 5.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        // Tuiles OpenStreetMap via proxy (meilleure compatibilité émulateur)
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.samacite.mobile_samacite',
                          // Configuration pour améliorer la compatibilité
                          tileProvider: NetworkTileProvider(),
                        ),

                        // Marqueurs des signalements (filtrés par statut)
                        MarkerLayer(
                          markers: _buildMarkers(filteredReports),
                        ),
                      ],
                    ),

                    // Chips de filtre par statut (flottants, en haut)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: _buildStatusFilterChips(allReports),
                    ),

                    // Légende des couleurs (flottante, sous les chips)
                    Positioned(
                      top: 72,
                      right: 16,
                      child: _buildLegend(),
                    ),

                    // Bouton flottant "Ma position" (GPS réel)
                    Positioned(
                      right: 16,
                      bottom: _selectedReport != null ? 232 : 32,
                      child: _buildCircleButton(
                        icon: Icons.my_location_rounded,
                        isLoading: _isLocating,
                        onTap: _handleRecenterOnUserPosition,
                        tooltip: 'Centrer sur ma position',
                      ),
                    ),

                    // Carte flottante du signalement sélectionné OU compteur par défaut
                    if (_selectedReport != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: _buildSelectedReportCard(_selectedReport!),
                      )
                    else
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              '${filteredReports.where((r) => r.location != null).length} signalement(s)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  /// Applique le filtre de statut sélectionné à la liste de signalements
  List<ReportModel> _applyStatusFilter(List<ReportModel> reports) {
    switch (_statusFilter) {
      case _StatusFilter.all:
        return reports;
      case _StatusFilter.pending:
        return reports.where((r) => _normalizeStatus(r.status) == 'pending').toList();
      case _StatusFilter.inProgress:
        return reports.where((r) => _normalizeStatus(r.status) == 'in_progress').toList();
      case _StatusFilter.resolved:
        return reports.where((r) => _normalizeStatus(r.status) == 'resolved').toList();
    }
  }

  /// Normalise une chaîne de statut (français ou anglais) vers une clé stable
  String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
      case 'in_progress':
        return 'in_progress';
      case 'résolu':
      case 'resolved':
        return 'resolved';
      case 'en attente':
      case 'pending':
      default:
        return 'pending';
    }
  }

  /// Construit la rangée de chips de filtre par statut avec compteurs réels
  Widget _buildStatusFilterChips(List<ReportModel> allReports) {
    final pendingCount = allReports.where((r) => _normalizeStatus(r.status) == 'pending').length;
    final inProgressCount = allReports.where((r) => _normalizeStatus(r.status) == 'in_progress').length;
    final resolvedCount = allReports.where((r) => _normalizeStatus(r.status) == 'resolved').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Tous (${allReports.length})',
            isSelected: _statusFilter == _StatusFilter.all,
            dotColor: null,
            onTap: () => setState(() => _statusFilter = _StatusFilter.all),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'En attente ($pendingCount)',
            isSelected: _statusFilter == _StatusFilter.pending,
            dotColor: _statusAccentColor('pending'),
            onTap: () => setState(() => _statusFilter = _StatusFilter.pending),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'En cours ($inProgressCount)',
            isSelected: _statusFilter == _StatusFilter.inProgress,
            dotColor: _statusAccentColor('in_progress'),
            onTap: () => setState(() => _statusFilter = _StatusFilter.inProgress),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Résolu ($resolvedCount)',
            isSelected: _statusFilter == _StatusFilter.resolved,
            dotColor: _statusAccentColor('resolved'),
            onTap: () => setState(() => _statusFilter = _StatusFilter.resolved),
          ),
        ],
      ),
    );
  }

  /// Widget chip de filtre individuel (pill, flottant avec ombre)
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color? dotColor,
    required VoidCallback onTap,
  }) {
    const secondaryColor = Color(0xFF007A3F);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? secondaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
              )
            else if (dotColor != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton circulaire flottant (ex: centrage GPS)
  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
    String? tooltip,
  }) {
    final button = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Icon(icon, color: const Color(0xFFFFA000), size: 24),
    );

    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: button,
      ),
    );
  }

  /// Construit la liste des marqueurs depuis les signalements avec clustering
  List<Marker> _buildMarkers(List<ReportModel> reports) {
    print('[MapPage] 🗺️ Nombre total de signalements: ${reports.length}');

    final validReports = reports.where((report) {
      // Ne garder que les signalements avec location valide
      final hasLocation = report.location != null;

      if (!hasLocation) {
        print('[MapPage] ⚠️ Signalement ${report.id} SANS coordonnées GPS (location = null)');
      } else {
        print('[MapPage] ✅ Signalement ${report.id}: (${report.location!.latitude}, ${report.location!.longitude})');
      }

      return hasLocation;
    }).toList();

    print('[MapPage] 📍 Nombre de signalements avec coordonnées: ${validReports.length}');

    // Grouper les signalements par position (clustering)
    final Map<String, List<ReportModel>> clusters = {};

    for (final report in validReports) {
      final location = report.location!;
      // Créer une clé unique basée sur les coordonnées (arrondi à 6 décimales)
      final key = '${location.latitude.toStringAsFixed(6)}_${location.longitude.toStringAsFixed(6)}';

      if (!clusters.containsKey(key)) {
        clusters[key] = [];
      }
      clusters[key]!.add(report);
    }

    print('[MapPage] 🔢 Nombre de clusters créés: ${clusters.length}');

    // Créer un marker pour chaque cluster
    final markers = <Marker>[];

    for (final entry in clusters.entries) {
      final reportsInCluster = entry.value;
      final firstReport = reportsInCluster.first;
      final location = firstReport.location!;
      final count = reportsInCluster.length;

      // Déterminer la couleur dominante du cluster (status le plus fréquent)
      final statusCounts = <String, int>{};
      for (final report in reportsInCluster) {
        statusCounts[report.status] = (statusCounts[report.status] ?? 0) + 1;
      }
      final dominantStatus = statusCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final color = _statusAccentColor(dominantStatus);

      // Vérifier si le cluster contient le signalement focusé
      final isFocused = reportsInCluster.any((r) => r.id == widget.focusedReportId) ||
          (_selectedReport != null && reportsInCluster.any((r) => r.id == _selectedReport!.id));

      print('[MapPage] 🎨 Création cluster à (${location.latitude}, ${location.longitude}): '
            '$count signalement(s), couleur=$dominantStatus, focusé=$isFocused');

      markers.add(
        Marker(
          point: LatLng(location.latitude, location.longitude),
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () {
              if (count == 1) {
                // Un seul signalement : afficher l'aperçu flottant en bas
                setState(() => _selectedReport = firstReport);
                _centerMapOnLocation(location.latitude, location.longitude, zoom: 15.0);
              } else {
                // Plusieurs signalements : afficher une bottom sheet
                _showClusterBottomSheet(reportsInCluster);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Icône de localisation
                Icon(
                  Icons.location_on,
                  size: isFocused ? 50 : 40,
                  color: color,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // Badge avec le nombre (si plusieurs signalements)
                if (count > 1)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    print('[MapPage] 🎯 Total markers créés: ${markers.length}');
    return markers;
  }

  /// Affiche une bottom sheet avec la liste des signalements d'un cluster
  void _showClusterBottomSheet(List<ReportModel> reports) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${reports.length} signalements à cette position',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final color = _statusAccentColor(report.status);

                    return ListTile(
                      leading: Icon(
                        Icons.location_on,
                        color: color,
                      ),
                      title: Text(
                        report.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _statusLabel(report.status),
                        style: TextStyle(color: color, fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context); // Fermer la bottom sheet
                        setState(() => _selectedReport = report);
                        if (report.location != null) {
                          _centerMapOnLocation(
                            report.location!.latitude,
                            report.location!.longitude,
                            zoom: 15.0,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Retourne la couleur d'accent (pleine) selon le statut du signalement
  Color _statusAccentColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'in_progress':
        return const Color(0xFF0023D1);
      case 'resolved':
        return const Color(0xFF34C759);
      case 'pending':
      default:
        return const Color(0xFFFFA000);
    }
  }

  /// Retourne la couleur de fond claire associée au statut (pour les badges)
  Color _statusBackgroundColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'in_progress':
        return const Color(0xFFE8EDFF);
      case 'resolved':
        return const Color(0xFFEBF9EE);
      case 'pending':
      default:
        return const Color(0xFFFFF4E5);
    }
  }

  /// Retourne le libellé français du statut
  String _statusLabel(String status) {
    switch (_normalizeStatus(status)) {
      case 'in_progress':
        return 'En cours';
      case 'resolved':
        return 'Résolu';
      case 'pending':
      default:
        return 'En attente';
    }
  }

  /// Widget légende des couleurs (flottante, style carte blanche avec ombre douce)
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem('En attente', _statusAccentColor('pending')),
          const SizedBox(height: 6),
          _buildLegendItem('En cours', _statusAccentColor('in_progress')),
          const SizedBox(height: 6),
          _buildLegendItem('Résolu', _statusAccentColor('resolved')),
        ],
      ),
    );
  }

  /// Widget item de légende
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
      ],
    );
  }

  /// Formate une date ISO en temps relatif (ex: "il y a 2h"), identique au format
  /// utilisé dans le reste de l'application (voir NotificationTile)
  String _formatRelativeTime(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    }
  }

  /// Formate une distance en mètres de façon lisible
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Construit la carte flottante en bas affichant le signalement sélectionné
  Widget _buildSelectedReportCard(ReportModel report) {
    final accentColor = _statusAccentColor(report.status);
    final bgColor = _statusBackgroundColor(report.status);
    final address = report.location?.address;
    final relativeTime = _formatRelativeTime(report.createdAt);

    double? distanceInMeters;
    if (_userPosition != null && report.location != null) {
      distanceInMeters = _locationService.calculateDistance(
        _userPosition!.latitude,
        _userPosition!.longitude,
        report.location!.latitude,
        report.location!.longitude,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Petite poignée visuelle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniature
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: report.images.isNotEmpty
                      ? Image.network(
                          report.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: bgColor,
                            child: Icon(Icons.image_not_supported_outlined, color: accentColor),
                          ),
                        )
                      : Container(
                          color: bgColor,
                          child: Icon(Icons.location_on, color: accentColor),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(report.status).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (distanceInMeters != null) ...[
                          const Spacer(),
                          const Icon(Icons.near_me, size: 13, color: Color(0xFFFFA000)),
                          const SizedBox(width: 2),
                          Text(
                            _formatDistance(distanceInMeters),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFA000),
                            ),
                          ),
                        ],
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
                        color: Colors.black87,
                      ),
                    ),
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: Colors.black45),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
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
          const SizedBox(height: 12),
          // Bandeau likes + temps relatif
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined, size: 15, color: Color(0xFF007A3F)),
                const SizedBox(width: 6),
                Text(
                  '${report.likesCount} j\'aime${report.likesCount > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (relativeTime.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    'Signalé $relativeTime',
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Bouton d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToReportDetail(report.id),
                  icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.black87),
                  label: const Text(
                    'Voir les détails',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA000),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _selectedReport = null),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.close, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Navigation vers la page détail du signalement
  void _navigateToReportDetail(int reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailPage(reportId: reportId),
      ),
    );
  }
}
