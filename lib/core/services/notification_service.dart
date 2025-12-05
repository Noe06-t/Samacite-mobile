import 'dart:async';
import 'package:mobile_samacite/core/services/dio_service.dart';

/// Service de gestion des notifications simplifié (sans Firebase)
/// 
/// Fonctionnalités:
/// - Polling périodique du backend pour nouvelles notifications
/// - Stream pour notifier l'UI des changements
/// - Cache du nombre de notifications non lues
/// 
/// Les notifications sont récupérées uniquement via l'API Laravel
class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Stream pour notifier des nouvelles notifications
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  Stream<int> get unreadCountStream => _unreadCountController.stream;

  Timer? _pollingTimer;
  int _cachedUnreadCount = 0;
  DioService? _dioService;

  /// Obtenir le nombre de notifications non lues en cache
  int get unreadCount => _cachedUnreadCount;

  /// Initialiser le service avec le DioService
  void initialize(DioService dioService) {
    _dioService = dioService;
    print('[NotificationService] ✅ Service initialisé (mode API uniquement)');
  }

  /// Démarrer le polling des notifications
  /// 
  /// Vérifie les nouvelles notifications toutes les [intervalSeconds] secondes
  void startPolling({int intervalSeconds = 30}) {
    if (_dioService == null) {
      print('[NotificationService] ⚠️ DioService non initialisé');
      return;
    }

    // Arrêter le polling existant s'il y en a un
    stopPolling();

    print('[NotificationService] 🔄 Démarrage du polling (toutes les ${intervalSeconds}s)');

    // Première vérification immédiate
    _checkUnreadCount();

    // Puis vérifications périodiques
    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _checkUnreadCount(),
    );
  }

  /// Arrêter le polling des notifications
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('[NotificationService] ⏹️ Polling arrêté');
  }

  /// Vérifier le nombre de notifications non lues
  Future<void> _checkUnreadCount() async {
    if (_dioService == null) return;

    try {
      final response = await _dioService!.dio.get('/notifications/unread-count');
      
      if (response.data['success'] == true) {
        final newCount = response.data['data']['unread_count'] as int;
        
        // Si le nombre a changé, notifier les listeners
        if (newCount != _cachedUnreadCount) {
          final oldCount = _cachedUnreadCount;
          _cachedUnreadCount = newCount;
          _unreadCountController.add(newCount);
          
          print('[NotificationService] 🔔 Notifications non lues: $oldCount → $newCount');
        }
      }
    } catch (e) {
      print('[NotificationService] ⚠️ Erreur vérification notifications: $e');
    }
  }

  /// Forcer une vérification manuelle
  Future<void> refresh() async {
    await _checkUnreadCount();
  }

  /// Mettre à jour manuellement le compteur (après lecture)
  void updateUnreadCount(int newCount) {
    if (newCount != _cachedUnreadCount) {
      _cachedUnreadCount = newCount;
      _unreadCountController.add(newCount);
      print('[NotificationService] 🔄 Compteur mis à jour: $newCount');
    }
  }

  /// Décrémenter le compteur (après lecture d'une notification)
  void decrementUnreadCount() {
    if (_cachedUnreadCount > 0) {
      _cachedUnreadCount--;
      _unreadCountController.add(_cachedUnreadCount);
      print('[NotificationService] 📉 Compteur décrémenté: $_cachedUnreadCount');
    }
  }

  /// Réinitialiser le compteur à 0 (après "tout marquer comme lu")
  void resetUnreadCount() {
    _cachedUnreadCount = 0;
    _unreadCountController.add(0);
    print('[NotificationService] 🔄 Compteur réinitialisé');
  }

  /// Nettoyer les ressources
  void dispose() {
    stopPolling();
    _unreadCountController.close();
  }
}
