import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/reports/providers/report_notifier.dart';
import 'package:mobile_samacite/core/widgets/modern_button.dart';
import 'package:mobile_samacite/features/reports/pages/create_report_page.dart';

/// Page intermédiaire pour la prise de photo avant le formulaire
class TakePhotoPage extends ConsumerStatefulWidget {
  const TakePhotoPage({super.key});

  @override
  ConsumerState<TakePhotoPage> createState() => _TakePhotoPageState();
}

class _TakePhotoPageState extends ConsumerState<TakePhotoPage> {
  @override
  void initState() {
    super.initState();
    
    // Écouter les changements d'état de l'analyse IA
    ref.listenManual(reportNotifierProvider, (previous, next) {
      // Si l'analyse vient de se terminer avec succès → aller au formulaire
      if (previous?.isAnalyzing == true && 
          next.isAnalyzing == false && 
          next.aiAnalysisResult != null) {
        // Attendre un peu pour que l'utilisateur voie le message de succès
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const CreateReportPage(),
              ),
            );
          }
        });
      }
      
      // Si l'analyse a échoué
      if (previous?.isAnalyzing == true && 
          next.isAnalyzing == false && 
          next.aiAnalysisError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${next.aiAnalysisError}'),
            backgroundColor: const Color(0xFFFFA000),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportNotifierProvider);
    final hasPhoto = reportState.selectedImages.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nouveau Signalement',
          style: TextStyle(
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icône principale
              Icon(
                hasPhoto ? Icons.auto_awesome : Icons.camera_alt,
                size: 120,
                color: hasPhoto ? const Color(0xFFFFA000) : const Color(0xFF007A3F),
              ),
              const SizedBox(height: 32),

              // Titre
              Text(
                hasPhoto 
                    ? '🤖 Analyse en cours...' 
                    : '📸 Prenez une photo',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007A3F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                hasPhoto
                    ? 'L\'intelligence artificielle analyse votre photo pour pré-remplir le formulaire'
                    : 'L\'IA analysera automatiquement votre photo et remplira le formulaire',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Indicateur de chargement si analyse en cours
              if (reportState.isAnalyzing) ...[
                const Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Analyse en cours...\nCela peut prendre quelques secondes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Aperçu de la photo si elle existe
              if (hasPhoto && !reportState.isAnalyzing)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(reportState.selectedImages.first.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 48),

              // Boutons
              if (!hasPhoto) ...[
                // Bouton Appareil photo
                ModernButton(
                  text: 'Appareil photo',
                  icon: Icons.camera_alt,
                  onPressed: () {
                    ref.read(reportNotifierProvider.notifier).takePicture();
                  },
                  height: 56,
                  primaryColor: const Color(0xFF007A3F),
                  secondaryColor: const Color(0xFF00A854),
                ),
                const SizedBox(height: 16),

                // Bouton Galerie
                OutlinedButton(
                  onPressed: () {
                    ref.read(reportNotifierProvider.notifier).selectImages();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: Color(0xFF007A3F), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.photo_library, color: Color(0xFF007A3F)),
                      SizedBox(width: 12),
                      Text(
                        'Galerie',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007A3F),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!reportState.isAnalyzing) ...[
                // Boutons pour changer la source de photo
                Row(
                  children: [
                    Expanded(
                      child: ModernButton(
                        text: 'Appareil photo',
                        icon: Icons.camera_alt,
                        onPressed: () {
                          ref.read(reportNotifierProvider.notifier).removeImage(0);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            ref.read(reportNotifierProvider.notifier).takePicture();
                          });
                        },
                        height: 56,
                        primaryColor: const Color(0xFF007A3F),
                        secondaryColor: const Color(0xFF00A854),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModernButton(
                        text: 'Galerie',
                        icon: Icons.photo_library,
                        onPressed: () {
                          ref.read(reportNotifierProvider.notifier).removeImage(0);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            ref.read(reportNotifierProvider.notifier).selectImages();
                          });
                        },
                        height: 56,
                        primaryColor: const Color(0xFFFFA000),
                        secondaryColor: const Color(0xFFFF8C00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Bouton Continuer sans changer
                ModernButton(
                  text: 'Continuer avec cette photo',
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const CreateReportPage(),
                      ),
                    );
                  },
                  height: 56,
                  primaryColor: Colors.grey[700],
                  secondaryColor: Colors.grey[600],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
