import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/constants/api_constants.dart';

/// Modèle pour le résultat de l'analyse IA
class AIAnalysisResult {
  final String title;
  final String description;
  final int categoryId;
  final double confidence;

  AIAnalysisResult({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.confidence,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AIAnalysisResult(
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['category_id'] as int,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

/// Service d'analyse IA d'images avec Google Gemini via backend
class AIAnalysisService {
  final DioService _dioService;

  AIAnalysisService(this._dioService);

  /// Analyser une image et obtenir titre, description et catégorie
  /// 
  /// Envoie l'image au backend Laravel qui appelle Google Gemini Vision
  /// 
  /// [imagePath] : Chemin local de l'image à analyser
  /// 
  /// Retourne [AIAnalysisResult] avec les suggestions de l'IA
  /// 
  /// Throws [AIAnalysisException] en cas d'erreur
  Future<AIAnalysisResult> analyzeImage(String imagePath) async {
    try {
      // Vérifier que le fichier existe
      final file = File(imagePath);
      if (!await file.exists()) {
        throw AIAnalysisException('Le fichier image n\'existe pas');
      }

      // Préparer le FormData avec l'image
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      });

      // Appeler l'endpoint backend
      final response = await _dioService.dio.post(
        ApiConstants.aiAnalyzeImage,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          // Timeout plus long pour l'analyse IA
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Vérifier la réponse
      if (response.data['success'] != true) {
        throw AIAnalysisException(
          response.data['message'] ?? 'Erreur lors de l\'analyse',
        );
      }

      // Parser le résultat
      final data = response.data['data'] as Map<String, dynamic>;
      return AIAnalysisResult.fromJson(data);
      
    } on DioException catch (e) {
      // Gérer les erreurs réseau
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AIAnalysisException(
          'Délai d\'attente dépassé. Veuillez réessayer.',
        );
      }
      
      if (e.response?.statusCode == 422) {
        throw AIAnalysisException('Image invalide ou trop volumineuse');
      }
      
      if (e.response?.statusCode == 500) {
        throw AIAnalysisException(
          'Erreur du serveur lors de l\'analyse. Réessayez plus tard.',
        );
      }

      throw AIAnalysisException(
        e.response?.data['message'] ?? 'Erreur de connexion au serveur',
      );
      
    } catch (e) {
      throw AIAnalysisException(
        'Erreur inattendue: ${e.toString()}',
      );
    }
  }

  /// Analyser plusieurs images (pour future implémentation)
  /// 
  /// Actuellement, analyse seulement la première image
  /// TODO: Support multi-images si backend l'implémente
  Future<AIAnalysisResult> analyzeImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      throw AIAnalysisException('Aucune image à analyser');
    }
    
    // Pour l'instant, on analyse juste la première
    return analyzeImage(imagePaths.first);
  }
}

/// Exception personnalisée pour les erreurs d'analyse IA
class AIAnalysisException implements Exception {
  final String message;

  AIAnalysisException(this.message);

  @override
  String toString() => message;
}

/// Provider Riverpod pour le service d'analyse IA
final aiAnalysisServiceProvider = Provider<AIAnalysisService>((ref) {
  final dio = ref.watch(dioServiceProvider);
  return AIAnalysisService(dio);
});
