import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/reports/providers/report_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/category_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/report_state.dart';

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
      setState(() => _selectedCategoryId = null);
      ref.read(reportNotifierProvider.notifier).reset();
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
        title: const Text('Nouveau Signalement'),
        backgroundColor: const Color(0xFF007A3F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section Photos
              _buildPhotoSection(reportState),
              const SizedBox(height: 24),

              // Champ Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Ex: Nid de poule sur la route',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
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
                data: (categories) => DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
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
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(
                  'Erreur de chargement des catégories',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),

              // Champ Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez le problème en détail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La description est requise';
                  }
                  return null;
                },
                enabled: reportState.status != ReportStatus.submitting,
              ),
              const SizedBox(height: 24),

              // Section Localisation
              _buildLocationSection(reportState),
              const SizedBox(height: 32),

              // Bouton Soumettre
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: reportState.status == ReportStatus.submitting
                      ? null
                      : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA000),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: reportState.status == ReportStatus.submitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('En cours...'),
                          ],
                        )
                      : const Text(
                          'Créer le signalement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ReportState state) {
    final imageCount = state.selectedImages.length;
    final canAddMore = imageCount < 5;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$imageCount/5 photos',
                  style: TextStyle(
                    color: imageCount >= 5 ? const Color(0xFFEA0707) : Colors.grey[600],
                    fontWeight: imageCount >= 5 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grille de photos sélectionnées
            if (imageCount > 0)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: imageCount,
                itemBuilder: (context, index) {
                  final image = state.selectedImages[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(image.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(reportNotifierProvider.notifier)
                                .removeImage(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEA0707),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            if (imageCount > 0) const SizedBox(height: 12),

            // Boutons Ajouter photos
            if (canAddMore)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.status != ReportStatus.submitting
                          ? () {
                              ref
                                  .read(reportNotifierProvider.notifier)
                                  .selectImages();
                            }
                          : null,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Ajouter des photos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF007A3F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.status != ReportStatus.submitting
                          ? () {
                              ref
                                  .read(reportNotifierProvider.notifier)
                                  .takePicture();
                            }
                          : null,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Prendre une photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF007A3F),
                      ),
                    ),
                  ),
                ],
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
            const Text(
              'Localisation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

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
                          Text(
                            'Latitude: ${state.position!.latitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Longitude: ${state.position!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 12),
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

            if (state.position != null || state.locationError != null)
              const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.status != ReportStatus.submitting &&
                        !state.isLoadingLocation
                    ? () {
                        ref
                            .read(reportNotifierProvider.notifier)
                            .captureLocation();
                      }
                    : null,
                icon: state.isLoadingLocation
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  state.isLoadingLocation
                      ? 'Localisation en cours...'
                      : 'Capturer ma position',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A3F),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'La localisation est optionnelle mais recommandée',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
