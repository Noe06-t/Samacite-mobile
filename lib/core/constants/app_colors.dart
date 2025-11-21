import 'package:flutter/material.dart';

/// Palette de couleurs selon les spécifications
class AppColors {
  // Couleurs primaires
  static const Color primary = Color(0xFFFFA000); // Bouton primaire (texte noir)
  static const Color secondary = Color(0xFF007A3F); // Cadres & sections (texte blanc)
  static const Color background = Color(0xFFFFFFFF); // Fond général
  static const Color danger = Color(0xFFEA0707); // Danger (texte blanc)
  
  // États des signalements
  static const Color statusInProgress = Color(0x420023D1); // En cours
  static const Color statusResolved = Color(0x3634C759); // Résolu
  static const Color statusPending = Color(0x70FFA000); // En attente
  
  // Textes
  static const Color textOnPrimary = Colors.black;
  static const Color textOnSecondary = Colors.white;
  static const Color textOnDanger = Colors.white;
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
}
