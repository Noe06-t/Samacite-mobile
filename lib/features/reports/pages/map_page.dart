import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/features/reports/pages/report_detail_page.dart';
import 'package:mobile_samacite/features/reports/pages/report_list_page.dart';

/// Page affichant tous les signalements sur une carte OpenStreetMap
/// 
/// Fonctionnalités:
/// - Affiche tous les signalements sous forme de marqueurs
/// - Couleurs des marqueurs selon le statut (pending, in_progress, resolved)
/// - Clic sur marqueur → Navigation vers page détail
/// - Zoom/Pan sur la carte
/// - Centrage automatique sur un signalement spécifique si fourni
class MapPage extends ConsumerStatefulWidget {
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
  });

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  bool _hasInitialCentered = false; // Flag pour éviter de recentrer plusieurs fois

  // Centre par défaut: Dakar, Sénégal
  static const LatLng _defaultCenter = LatLng(14.6937, -17.4441);
  static const double _defaultZoom = 12.0;

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
          onPressed: () => Navigator.pop(context),
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
                        
                        // Marqueurs des signalements
                        MarkerLayer(
                          markers: _buildMarkers(reportListState.reports),
                        ),
                      ],
                    ),
                    
                    // Légende des couleurs (en haut à droite)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildLegend(),
                    ),
                    
                    // Compteur signalements (en bas)
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
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${reportListState.reports.length} signalement(s)',
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
      final color = _getColorForStatus(dominantStatus);
      
      // Vérifier si le cluster contient le signalement focusé
      final isFocused = reportsInCluster.any((r) => r.id == widget.focusedReportId);
      
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
                // Un seul signalement : ouvrir directement
                _navigateToReportDetail(firstReport.id);
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
                    final color = _getColorForStatus(report.status);
                    
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
                        report.status,
                        style: TextStyle(color: color),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context); // Fermer la bottom sheet
                        _navigateToReportDetail(report.id);
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

  /// Retourne la couleur selon le statut du signalement
  Color _getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
      case 'in_progress':
        return const Color(0xFF0023D1).withOpacity(0.26); // #0023D142
      case 'résolu':
      case 'resolved':
        return const Color(0xFF34C759).withOpacity(0.21); // #34C75936
      case 'en attente':
      case 'pending':
      default:
        return const Color(0xFFFFA000).withOpacity(0.44); // #FFA00070
    }
  }

  /// Widget légende des couleurs
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Légende',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem('En attente', _getColorForStatus('pending')),
          const SizedBox(height: 4),
          _buildLegendItem('En cours', _getColorForStatus('in_progress')),
          const SizedBox(height: 4),
          _buildLegendItem('Résolu', _getColorForStatus('resolved')),
        ],
      ),
    );
  }

  /// Widget item de légende
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
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
