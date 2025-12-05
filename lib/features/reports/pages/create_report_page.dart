import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/reports/providers/report_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/category_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/report_state.dart';
import 'package:mobile_samacite/core/widgets/modern_button.dart';
import 'package:mobile_samacite/core/widgets/modern_text_field.dart';

class CreateReportPage extends ConsumerStatefulWidget {
  const CreateReportPage({super.key});

  @override
  ConsumerState<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends ConsumerState<CreateReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Capturer la localisation automatiquement au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportNotifierProvider.notifier).captureLocation();
      
      // Pré-remplir le formulaire avec les résultats de l'IA
      final reportState = ref.read(reportNotifierProvider);
      if (reportState.aiAnalysisResult != null) {
        final aiResult = reportState.aiAnalysisResult!;
        _titleController.text = aiResult.title;
        _descriptionController.text = aiResult.description;
        _selectedCategoryId = aiResult.categoryId;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleStateChange(ReportState? previous, ReportState next) {
    if (next.status == ReportStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signalement créé avec succès'),
          backgroundColor: Color(0xFF007A3F),
        ),
      );
      
      // Réinitialiser le formulaire
      _formKey.currentState?.reset();
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategoryId = null;
      });
      ref.read(reportNotifierProvider.notifier).reset();
      
      // CORRECTION 1 : Redirection vers HomePage après 1 seconde
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop(); // Retour à l'accueil
        }
      });
    } else if (next.status == ReportStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.errorMessage ?? 'Une erreur est survenue'),
          backgroundColor: const Color(0xFFEA0707),
        ),
      );
    }
  }

  void _submitForm() {
    final reportState = ref.read(reportNotifierProvider);
    
    // Validation : au moins 1 photo obligatoire
    if (reportState.selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 Veuillez ajouter au moins une photo'),
          backgroundColor: Color(0xFFEA0707),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une catégorie'),
            backgroundColor: Color(0xFFEA0707),
          ),
        );
        return;
      }

      ref.read(reportNotifierProvider.notifier).submitReport(
            title: _titleController.text,
            description: _descriptionController.text,
            categoryId: _selectedCategoryId!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'état pour afficher SnackBars
    ref.listen<ReportState>(reportNotifierProvider, _handleStateChange);
    
    final reportState = ref.watch(reportNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);

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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Aperçu de la photo
              _buildPhotoPreview(reportState),
              const SizedBox(height: 24),

              // Champ Titre
              ModernTextField(
                controller: _titleController,
                label: 'Titre',
                hint: 'Ex: Nid de poule sur la route',
                prefixIcon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
                enabled: reportState.status != ReportStatus.submitting,
              ),
              const SizedBox(height: 16),

              // Dropdown Catégorie
              categoriesAsync.when(
                data: (categories) => ModernDropdownField<int>(
                  value: _selectedCategoryId,
                  label: 'Catégorie',
                  prefixIcon: Icons.category,
                  items: categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: reportState.status != ReportStatus.submitting
                      ? (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        }
                      : null,
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner une catégorie';
                    }
                    return null;
                  },
                  enabled: reportState.status != ReportStatus.submitting,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(
                  'Erreur de chargement des catégories',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),

              // Champ Description
              ModernTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Pré-remplie par l\'IA - vous pouvez la modifier',
                prefixIcon: Icons.description,
                maxLines: 5,
                validator: null,
                enabled: reportState.status != ReportStatus.submitting,
              ),
              const SizedBox(height: 24),

              // Section Localisation
              _buildLocationSection(reportState),
              const SizedBox(height: 32),

              // Bouton Soumettre
              ModernButton(
                text: 'Créer le signalement',
                icon: Icons.check_circle,
                onPressed: reportState.status == ReportStatus.submitting
                    ? null
                    : _submitForm,
                isLoading: reportState.status == ReportStatus.submitting,
                height: 56,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(ReportState state) {
    if (state.selectedImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF007A3F), size: 20),
                SizedBox(width: 8),
                Text(
                  'Photo analysée par l\'IA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A3F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Aperçu de la photo
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(state.selectedImages.first.path),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(ReportState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Localisation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (state.isLoadingLocation)
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007A3F)),
                    ),
                  ),
                if (state.position != null)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF007A3F),
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (state.isLoadingLocation)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA000).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gps_fixed, color: Color(0xFFFFA000)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Capture automatique de votre position en cours...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            if (state.position != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A3F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF007A3F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Position capturée automatiquement',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${state.position!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            'Long: ${state.position!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (state.locationError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA0707).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Color(0xFFEA0707)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.locationError!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            if (state.locationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ModernOutlineButton(
                  text: 'Réessayer',
                  icon: Icons.refresh,
                  onPressed: state.status != ReportStatus.submitting &&
                          !state.isLoadingLocation
                      ? () {
                          ref
                              .read(reportNotifierProvider.notifier)
                              .captureLocation();
                        }
                      : null,
                  color: const Color(0xFF007A3F),
                  height: 48,
                ),
              ),

            if (state.position == null && 
                state.locationError == null && 
                !state.isLoadingLocation)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'La localisation sera capturée automatiquement',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
