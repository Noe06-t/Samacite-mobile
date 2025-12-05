import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/reports/providers/report_list_state.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/features/auth/providers/auth_providers.dart';
import 'package:mobile_samacite/features/reports/pages/report_list_page.dart';

/// Provider pour la liste des signalements de l'utilisateur connecté
final myReportsProvider = StateNotifierProvider<MyReportsNotifier, ReportListState>((ref) {
  final repository = ref.watch(reportRepositoryProvider); // défini dans report_list_page.dart
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return MyReportsNotifier(repository, secureStorage);
});

/// Notifier pour la gestion des signalements de l'utilisateur connecté
/// 
/// Identique à ReportListNotifier mais filtre par user_id
class MyReportsNotifier extends StateNotifier<ReportListState> {
  final ReportRepository _repository;
  final dynamic _secureStorage;

  static const int _perPage = 15;
  static const List<String> _defaultIncludes = ['user', 'category', 'images'];

  MyReportsNotifier(this._repository, this._secureStorage) 
      : super(ReportListState.initial());

  /// Récupère l'ID de l'utilisateur connecté
  Future<int?> _getUserId() async {
    final userIdStr = await _secureStorage.getUserId();
    if (userIdStr == null) return null;
    return int.tryParse(userIdStr);
  }

  /// Charge la première page des signalements de l'utilisateur
  Future<void> loadReports() async {
    if (state.isLoading) return;

    final userId = await _getUserId();
    if (userId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Utilisateur non connecté',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      print('[MyReportsNotifier] 📡 Chargement signalements user_id: $userId');
      
      final result = await _repository.getReports(
        page: 1,
        perPage: _perPage,
        userId: userId, // ← Filtre par utilisateur
        includeRelations: _defaultIncludes,
      );

      final reports = result['data'] as List;
      final meta = result['meta'] as Map<String, dynamic>;

      final currentPage = meta['current_page'] as int;
      final lastPage = meta['last_page'] as int;
      final hasMore = currentPage < lastPage;

      print('[MyReportsNotifier] ✅ ${reports.length} signalements chargés');

      state = state.copyWith(
        reports: reports.cast(),
        isLoading: false,
        hasMore: hasMore,
        currentPage: currentPage,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      print('[MyReportsNotifier] ❌ ERREUR: $e');
      print('[MyReportsNotifier] 📍 StackTrace: $stackTrace');
      
      String errorMessage = 'Erreur de connexion';
      
      if (e.toString().contains('DioException')) {
        errorMessage = 'Impossible de charger vos signalements.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Erreur de format des données reçues';
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    }
  }

  /// Charge la page suivante (pagination)
  Future<void> loadMoreReports() async {
    if (state.isLoading || !state.hasMore) return;

    final userId = await _getUserId();
    if (userId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;

      final result = await _repository.getReports(
        page: nextPage,
        perPage: _perPage,
        userId: userId,
        includeRelations: _defaultIncludes,
      );

      final newReports = result['data'] as List;
      final meta = result['meta'] as Map<String, dynamic>;

      final currentPage = meta['current_page'] as int;
      final lastPage = meta['last_page'] as int;
      final hasMore = currentPage < lastPage;

      state = state.copyWith(
        reports: [...state.reports, ...newReports.cast()],
        isLoading: false,
        hasMore: hasMore,
        currentPage: currentPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de charger plus de signalements',
      );
    }
  }

  /// Rafraîchit la liste (pull-to-refresh)
  Future<void> refresh() async {
    state = ReportListState.initial();
    await loadReports();
  }
}
