/// Constantes pour les endpoints API
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api';
  
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
  
  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
