/// Constantes pour les endpoints API
class ApiConstants {
  // 🌐 API Backend locale (dev)
  static const String baseUrl = 'https://samacite.artist-dev.com/api';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  
  // Reports endpoints
  static const String reports = '/reports';
  
  // Categories endpoints
  static const String categories = '/categories';
  
  // Comments endpoints
  static const String comments = '/comments';
  
  // AI Analysis endpoints
  static const String aiAnalyzeImage = '/ai/analyze-image';
  
  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(minutes: 2); // 2 minutes pour l'analyse IA
}
