import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_samacite/features/reports/providers/report_filter_state.dart';

void main() {
  group('ReportFilterState', () {
    test('initial() devrait créer un état sans filtres actifs', () {
      // Given
      final state = ReportFilterState.initial();

      // Then
      expect(state.status, isNull);
      expect(state.categoryId, isNull);
      expect(state.startDate, isNull);
      expect(state.endDate, isNull);
      expect(state.searchQuery, '');
    });

    test('copyWith() devrait mettre à jour uniquement le champ spécifié', () {
      // Given
      final state = ReportFilterState.initial();

      // When
      final newState = state.copyWith(status: 'pending');

      // Then
      expect(newState.status, 'pending');
      expect(newState.categoryId, isNull);
      expect(newState.startDate, isNull);
      expect(newState.endDate, isNull);
      expect(newState.searchQuery, '');
    });

    test('copyWith() avec null devrait réinitialiser le champ', () {
      // Given
      final state = ReportFilterState.initial().copyWith(
        status: 'pending',
        categoryId: 1,
      );

      // When
      final newState = state.copyWith(
        status: null,
        categoryId: null,
      );

      // Then
      expect(newState.status, isNull);
      expect(newState.categoryId, isNull);
    });
  });

  group('ReportFilterStateX - hasActiveFilters', () {
    test('devrait retourner false quand aucun filtre actif', () {
      // Given
      final state = ReportFilterState.initial();

      // Then
      expect(state.hasActiveFilters, isFalse);
    });

    test('devrait retourner true quand statut est défini', () {
      // Given
      final state = ReportFilterState.initial().copyWith(status: 'pending');

      // Then
      expect(state.hasActiveFilters, isTrue);
    });

    test('devrait retourner true quand categoryId est défini', () {
      // Given
      final state = ReportFilterState.initial().copyWith(categoryId: 1);

      // Then
      expect(state.hasActiveFilters, isTrue);
    });

    test('devrait retourner true quand startDate est défini', () {
      // Given
      final state = ReportFilterState.initial().copyWith(
        startDate: DateTime(2025, 1, 1),
      );

      // Then
      expect(state.hasActiveFilters, isTrue);
    });

    test('devrait retourner true quand endDate est défini', () {
      // Given
      final state = ReportFilterState.initial().copyWith(
        endDate: DateTime(2025, 12, 31),
      );

      // Then
      expect(state.hasActiveFilters, isTrue);
    });

    test('devrait retourner true quand searchQuery est non vide', () {
      // Given
      final state = ReportFilterState.initial().copyWith(searchQuery: 'test');

      // Then
      expect(state.hasActiveFilters, isTrue);
    });

    test('devrait retourner true quand plusieurs filtres sont actifs', () {
      // Given
      final state = ReportFilterState.initial().copyWith(
        status: 'pending',
        categoryId: 1,
        searchQuery: 'test',
      );

      // Then
      expect(state.hasActiveFilters, isTrue);
    });
  });

  group('ReportFilterStateX - activeFiltersCount', () {
    test('devrait retourner 0 quand aucun filtre actif', () {
      // Given
      final state = ReportFilterState.initial();

      // Then
      expect(state.activeFiltersCount, 0);
    });

    test('devrait retourner 1 quand un seul filtre actif', () {
      // Given
      final state = ReportFilterState.initial().copyWith(status: 'pending');

      // Then
      expect(state.activeFiltersCount, 1);
    });

    test('devrait retourner 2 quand statut et catégorie sont actifs', () {
      // Given
      final state = ReportFilterState.initial().copyWith(
        status: 'resolved',
        categoryId: 2,
      );

      // Then
      expect(state.activeFiltersCount, 2);
    });

    test('devrait compter startDate et endDate comme 1 filtre de plage', () {
      // Given
      final state = ReportFilterState.initial().copyWith(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
      );

      // Then
      expect(state.activeFiltersCount, 1);
    });

    test('devrait retourner 4 quand tous les filtres sont actifs', () {
      // Given
      final state = ReportFilterState.initial().copyWith(
        status: 'in_progress',
        categoryId: 3,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
        searchQuery: 'test',
      );

      // Then
      expect(state.activeFiltersCount, 4);
    });
  });

  group('ReportFilterStateX - toQueryParameters', () {
    test('devrait retourner un Map vide quand aucun filtre actif', () {
      // Given
      final state = ReportFilterState.initial();

      // When
      final params = state.toQueryParameters();

      // Then
      expect(params, isEmpty);
    });

    test('devrait inclure filter[status] quand statut défini', () {
      // Given
      final state = ReportFilterState.initial().copyWith(status: 'pending');

      // When
      final params = state.toQueryParameters();

      // Then
      expect(params, containsPair('filter[status]', 'pending'));
    });

    test('devrait inclure filter[category_id] quand categoryId défini', () {
      // Given
      final state = ReportFilterState.initial().copyWith(categoryId: 5);

      // When
      final params = state.toQueryParameters();

      // Then
      expect(params, containsPair('filter[category_id]', '5'));
    });

    test('devrait inclure filter[start_date] au format ISO (date uniquement)', () {
      // Given
      final date = DateTime(2025, 6, 15);
      final state = ReportFilterState.initial().copyWith(startDate: date);

      // When
      final params = state.toQueryParameters();

      // Then
      expect(params, containsPair('filter[start_date]', '2025-06-15'));
    });

    test('devrait inclure filter[end_date] au format ISO (date uniquement)', () {
      // Given
      final date = DateTime(2025, 12, 31);
      final state = ReportFilterState.initial().copyWith(endDate: date);

      // When
      final params = state.toQueryParameters();

      // Then
      expect(params, containsPair('filter[end_date]', '2025-12-31'));
    });

    test('devrait inclure search quand searchQuery non vide', () {
      // Given
      final state = ReportFilterState.initial().copyWith(searchQuery: 'route cassée');

      // When
      final params = state.toQueryParameters();

      // Then
      expect(params, containsPair('search', 'route cassée'));
    });

    test('devrait inclure tous les paramètres quand tous les filtres sont actifs', () {
      // Given
      final state = ReportFilterState.initial().copyWith(
        status: 'resolved',
        categoryId: 7,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 3, 31),
        searchQuery: 'éclairage',
      );

      // When
      final params = state.toQueryParameters();

      // Then
      expect(params, {
        'filter[status]': 'resolved',
        'filter[category_id]': '7',
        'filter[start_date]': '2025-01-01',
        'filter[end_date]': '2025-03-31',
        'search': 'éclairage',
      });
    });

    test('ne devrait PAS inclure les filtres null ou vides', () {
      // Given
      final state = ReportFilterState.initial().copyWith(
        status: 'pending',
        searchQuery: '', // Vide, ne doit pas être inclus
      );

      // When
      final params = state.toQueryParameters();

      // Then
      expect(params, {'filter[status]': 'pending'});
      expect(params.containsKey('filter[category_id]'), isFalse);
      expect(params.containsKey('search'), isFalse);
    });
  });
}
