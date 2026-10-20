import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/models/category_model.dart';
import 'package:mobile_samacite/features/reports/providers/report_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/category_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/report_state.dart';

// Palette inspirée de la maquette Stitch (voir lib/core/constants/app_colors.dart)
const Color _kPrimaryOrange = Color(0xFFFFA000);
const Color _kSecondaryGreen = Color(0xFF007A3F);
const Color _kPageBackground = Color(0xFFF8F9FA);
const Color _kLabelColor = Color(0xFF1A1A1A);
const Color _kInputBorder = Color(0x1F000000); // rgba(0,0,0,0.12)
const Color _kFocusHalo = Color(0x33FFA000); // rgba(255,160,0,0.20)
const Color _kDangerColor = Color(0xFFEA0707);

class CreateReportPage extends ConsumerStatefulWidget {
  const CreateReportPage({super.key});

  @override
  ConsumerState<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends ConsumerState<CreateReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();

    _titleFocusNode.addListener(() => setState(() {}));
    _descriptionFocusNode.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));

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
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _handleStateChange(ReportState? previous, ReportState next) {
    if (next.status == ReportStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signalement créé avec succès'),
          backgroundColor: _kSecondaryGreen,
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
          backgroundColor: _kDangerColor,
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
          content: Text('Veuillez ajouter au moins une photo'),
          backgroundColor: _kDangerColor,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une catégorie'),
            backgroundColor: _kDangerColor,
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

  /// Reprend une photo (caméra ou galerie) en réutilisant la logique
  /// existante du notifier (removeImage / takePicture / selectImages),
  /// identique à celle employée dans take_photo_page.dart.
  Future<void> _retakePhoto() async {
    final reportState = ref.read(reportNotifierProvider);
    if (reportState.status == ReportStatus.submitting) return;

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _kSecondaryGreen),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _kPrimaryOrange),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final notifier = ref.read(reportNotifierProvider.notifier);
    notifier.removeImage(0);
    notifier.clearAIAnalysis();
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategoryId = null;
    });

    if (source == 'camera') {
      await notifier.takePicture();
    } else {
      await notifier.selectImages();
    }

    if (!mounted) return;
    final newState = ref.read(reportNotifierProvider);
    if (newState.aiAnalysisResult != null) {
      setState(() {
        _titleController.text = newState.aiAnalysisResult!.title;
        _descriptionController.text = newState.aiAnalysisResult!.description;
        _selectedCategoryId = newState.aiAnalysisResult!.categoryId;
      });
    }
  }

  /// Relance l'analyse IA sur la photo actuelle et resynchronise les champs
  /// (réutilise ReportNotifier.analyzeImageWithAI déjà utilisée à l'init).
  Future<void> _regenerateAIDescription() async {
    final reportState = ref.read(reportNotifierProvider);
    if (reportState.selectedImages.isEmpty || reportState.isAnalyzing) return;

    await ref.read(reportNotifierProvider.notifier).analyzeImageWithAI();

    if (!mounted) return;
    final newState = ref.read(reportNotifierProvider);
    if (newState.aiAnalysisResult != null) {
      setState(() {
        _titleController.text = newState.aiAnalysisResult!.title;
        _descriptionController.text = newState.aiAnalysisResult!.description;
        _selectedCategoryId = newState.aiAnalysisResult!.categoryId;
      });
    }
  }

  CategoryModel? _findCategory(List<CategoryModel> categories, int? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  IconData _iconForCategory(String? iconName) {
    switch (iconName) {
      case 'construction':
        return Icons.construction;
      case 'water_drop':
        return Icons.water_drop;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'delete':
        return Icons.delete;
      case 'park':
        return Icons.park;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'état pour afficher SnackBars
    ref.listen<ReportState>(reportNotifierProvider, _handleStateChange);

    final reportState = ref.watch(reportNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final isSubmitting = reportState.status == ReportStatus.submitting;

    return Scaffold(
      backgroundColor: _kPageBackground,
      appBar: AppBar(
        backgroundColor: _kPageBackground,
        surfaceTintColor: _kPageBackground,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Nouveau Signalement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _kLabelColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kLabelColor),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Aperçu photo analysée par l'IA
                      categoriesAsync.when(
                        data: (categories) =>
                            _buildPhotoPreview(reportState, categories),
                        loading: () =>
                            _buildPhotoPreview(reportState, const []),
                        error: (_, __) =>
                            _buildPhotoPreview(reportState, const []),
                      ),
                      const SizedBox(height: 20),

                      // Titre
                      _buildTitleField(reportState),
                      const SizedBox(height: 20),

                      // Catégorie (chips)
                      categoriesAsync.when(
                        data: (categories) =>
                            _buildCategorySelector(categories, reportState),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(
                            color: _kSecondaryGreen,
                            backgroundColor: Color(0xFFE5E5E5),
                          ),
                        ),
                        error: (error, _) => Text(
                          'Erreur de chargement des catégories',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      _buildDescriptionField(reportState),
                      const SizedBox(height: 24),

                      // Localisation
                      _buildLocationSection(reportState),
                    ],
                  ),
                ),
              ),
            ),

            // Barre de soumission fixe en bas
            _buildSubmitBar(reportState, isSubmitting),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Photo
  // ---------------------------------------------------------------------

  Widget _buildPhotoPreview(ReportState state, List<CategoryModel> categories) {
    if (state.selectedImages.isEmpty) {
      return const SizedBox.shrink();
    }

    final aiResult = state.aiAnalysisResult;
    final detectedCategory = _findCategory(categories, aiResult?.categoryId);
    final confidencePercent =
        aiResult != null ? (aiResult.confidence * 100).round() : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image + overlay
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(state.selectedImages.first.path),
                  fit: BoxFit.cover,
                ),
                // Dégradé pour la lisibilité des badges
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                // Bandeau supérieur : badge IA + confiance
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 16, color: _kPrimaryOrange),
                            SizedBox(width: 6),
                            Text(
                              'Analysé par l\'IA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _kLabelColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (state.isAnalyzing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: _kPrimaryOrange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Analyse...',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (confidencePercent != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: _kSecondaryGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '$confidencePercent% confiance',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Bandeau inférieur : nom fichier + bouton Reprendre
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.photo_camera,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                state.selectedImages.first.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: state.status == ReportStatus.submitting
                              ? null
                              : _retakePhoto,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cameraswitch,
                                    size: 16, color: _kLabelColor),
                                SizedBox(width: 6),
                                Text(
                                  'Reprendre',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _kLabelColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bandeau détection auto (catégorie réellement détectée)
          if (aiResult != null)
            Container(
              width: double.infinity,
              color: _kSecondaryGreen.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.psychology,
                      size: 18, color: _kSecondaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondaryGreen),
                        children: [
                          const TextSpan(text: 'Détection auto : '),
                          TextSpan(
                            text: detectedCategory?.name ?? 'Catégorie suggérée',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Auto-rempli',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kLabelColor),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Titre
  // ---------------------------------------------------------------------

  Widget _buildTitleField(ReportState state) {
    final enabled = state.status != ReportStatus.submitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Titre du signalement',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kLabelColor),
            ),
            Text(
              'Obligatoire',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _stitchFieldContainer(
          focused: _titleFocusNode.hasFocus,
          child: TextFormField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            enabled: enabled,
            style: const TextStyle(fontSize: 15, color: _kLabelColor),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le titre est requis';
              }
              return null;
            },
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Ex: Gros nid-de-poule dangereux',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.warning_amber_rounded,
                  color: _kPrimaryOrange, size: 22),
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'Soyez concis pour faciliter l\'intervention rapide des équipes municipales.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Catégorie (chips)
  // ---------------------------------------------------------------------

  Widget _buildCategorySelector(
      List<CategoryModel> categories, ReportState state) {
    final enabled = state.status != ReportStatus.submitting;
    final selectedCount = _selectedCategoryId != null ? 1 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Catégorie municipale',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kLabelColor),
            ),
            Text(
              '$selectedCount sélectionnée',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kSecondaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategoryId == category.id;

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: enabled
                    ? () => setState(() => _selectedCategoryId = category.id)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? _kSecondaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _kSecondaryGreen : _kInputBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForCategory(category.icon),
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : _kLabelColor,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check, size: 16, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Description
  // ---------------------------------------------------------------------

  Widget _buildDescriptionField(ReportState state) {
    final enabled = state.status != ReportStatus.submitting;
    final hasAIResult = state.aiAnalysisResult != null;
    final canRegenerate =
        enabled && state.selectedImages.isNotEmpty && !state.isAnalyzing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Description des faits',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kLabelColor),
            ),
            InkWell(
              onTap: canRegenerate ? _regenerateAIDescription : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.isAnalyzing)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_kPrimaryOrange),
                      ),
                    )
                  else
                    Icon(
                      Icons.sync,
                      size: 14,
                      color: canRegenerate ? _kPrimaryOrange : Colors.grey,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    'Régénérer IA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: canRegenerate ? _kPrimaryOrange : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _stitchFieldContainer(
          focused: _descriptionFocusNode.hasFocus,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                enabled: enabled,
                maxLines: 4,
                minLines: 4,
                style: const TextStyle(fontSize: 14, color: _kLabelColor),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Décrivez l\'impact pour les usagers...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasAIResult)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EFEF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_fix_high,
                              size: 12, color: _kPrimaryOrange),
                          SizedBox(width: 4),
                          Text(
                            'Proposition auto-générée',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Text(
                    '${_descriptionController.text.length} car.',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Localisation (logique GPS inchangée)
  // ---------------------------------------------------------------------

  Widget _buildLocationSection(ReportState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localisation du signalement',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: _kLabelColor),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Visuel "carte" décoratif avec pin GPS
              Container(
                height: 120,
                width: double.infinity,
                color: _kSecondaryGreen.withOpacity(0.08),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.map_outlined,
                        size: 42, color: _kSecondaryGreen.withOpacity(0.25)),
                    if (state.position != null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: _kSecondaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Point GPS capturé',
                              style: TextStyle(fontSize: 10, color: _kLabelColor),
                            ),
                          ),
                        ],
                      )
                    else if (state.isLoadingLocation)
                      const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(_kPrimaryOrange),
                      )
                    else
                      Icon(Icons.location_off,
                          size: 28, color: Colors.grey[400]),
                  ],
                ),
              ),

              // Panneau d'information
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationStatusRow(state),
                    if (state.locationError != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: state.status != ReportStatus.submitting &&
                                  !state.isLoadingLocation
                              ? () => ref
                                  .read(reportNotifierProvider.notifier)
                                  .captureLocation()
                              : null,
                          icon: const Icon(Icons.refresh,
                              size: 18, color: _kSecondaryGreen),
                          label: const Text(
                            'Réessayer',
                            style: TextStyle(
                                color: _kSecondaryGreen,
                                fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kSecondaryGreen),
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (state.position == null &&
                        state.locationError == null &&
                        !state.isLoadingLocation)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStatusRow(ReportState state) {
    if (state.isLoadingLocation) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusIconBubble(
            icon: Icons.gps_fixed,
            color: _kPrimaryOrange,
            spinning: true,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAPTURE GPS EN COURS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryOrange,
                      letterSpacing: 0.4),
                ),
                SizedBox(height: 2),
                Text(
                  'Recherche de votre position...',
                  style: TextStyle(fontSize: 13, color: _kLabelColor),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.position != null) {
      final position = state.position!;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusIconBubble(icon: Icons.my_location, color: _kSecondaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'SIGNAL GPS ACTIF',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _kSecondaryGreen,
                          letterSpacing: 0.4),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.circle, size: 6, color: _kSecondaryGreen),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Lat: ${position.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kLabelColor),
                ),
                Text(
                  'Long: ${position.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kLabelColor),
                ),
                if (position.accuracy > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Précision ± ${position.accuracy.toStringAsFixed(0)}m',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (state.locationError != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusIconBubble(icon: Icons.error_outline, color: _kDangerColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SIGNAL GPS INDISPONIBLE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _kDangerColor,
                      letterSpacing: 0.4),
                ),
                const SizedBox(height: 2),
                Text(
                  state.locationError!,
                  style: const TextStyle(fontSize: 13, color: _kLabelColor),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusIconBubble(icon: Icons.location_searching, color: Colors.grey),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'En attente de localisation',
            style: TextStyle(fontSize: 13, color: _kLabelColor),
          ),
        ),
      ],
    );
  }

  Widget _statusIconBubble(
      {required IconData icon, required Color color, bool spinning = false}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: spinning
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )
          : Icon(icon, size: 18, color: color),
    );
  }

  // ---------------------------------------------------------------------
  // Soumission
  // ---------------------------------------------------------------------

  Widget _buildSubmitBar(ReportState state, bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: _kPageBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Material(
              color: isSubmitting ? _kPrimaryOrange.withOpacity(0.6) : _kPrimaryOrange,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isSubmitting ? null : _submitForm,
                child: Center(
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.black, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Créer le signalement',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Icon(Icons.verified_user_outlined,
                  size: 13, color: _kSecondaryGreen),
              SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Votre signalement sera transmis à l\'équipe municipale compétente',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  Widget _stitchFieldContainer({
    required bool focused,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? _kPrimaryOrange : _kInputBorder,
          width: focused ? 1.5 : 1.5,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: _kFocusHalo,
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      constraints: const BoxConstraints(minHeight: 52),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
