import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/features/auth/providers/auth_notifier.dart';
import 'package:mobile_samacite/core/models/user_model.dart';
import 'package:mobile_samacite/features/home/providers/user_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Page de modification du profil utilisateur
/// 
/// Permet de modifier :
/// - Nom
/// - Prénom
/// - Email (optionnel)
/// - Téléphone
/// 
/// Note : L'upload de photo sera ajouté dans une version future
class EditProfilePage extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _emailController;
  late final TextEditingController _telephoneController;

  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  File? _selectedImage;
  String? _uploadedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user.nom);
    _prenomController = TextEditingController(text: widget.user.prenom);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _telephoneController = TextEditingController(text: widget.user.telephone);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  /// Sélectionner et uploader une photo de profil
  Future<void> _handlePhotoUpload() async {
    print('[EditProfilePage] 📸 Début upload photo');
    
    try {
      // 1. Sélectionner l'image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        print('[EditProfilePage] ❌ Aucune image sélectionnée');
        return;
      }

      print('[EditProfilePage] ✅ Image sélectionnée: ${image.path}');
      setState(() {
        _isUploadingPhoto = true;
        _selectedImage = File(image.path);
      });

      // 2. Compresser l'image
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      print('[EditProfilePage] 🔄 Compression de l\'image...');
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 70,
        minWidth: 512,
        minHeight: 512,
      );

      if (compressedFile == null) {
        throw Exception('Échec de la compression');
      }

      print('[EditProfilePage] ✅ Image compressée: ${compressedFile.path}');

      // 3. Upload vers le backend
      final userRepository = ref.read(userRepositoryProvider);
      print('[EditProfilePage] 📤 Upload vers le backend...');
      final photoUrl = await userRepository.uploadProfilePhoto(compressedFile.path);
      print('[EditProfilePage] ✅ Photo uploadée: $photoUrl');

      setState(() {
        _uploadedPhotoUrl = photoUrl;
        _isUploadingPhoto = false;
      });

      if (!mounted) return;

      // 4. Mettre à jour l'état auth avec la nouvelle photo
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final authState = ref.read(authNotifierProvider);
      
      authState.whenOrNull(
        authenticated: (currentUser, token) {
          final updatedUser = currentUser.copyWith(photoUrl: photoUrl);
          authNotifier.updateUser(updatedUser);
          print('[EditProfilePage] ✅ État auth mis à jour avec la photo');
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Photo de profil mise à jour'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('[EditProfilePage] ❌ Erreur upload photo: $e');
      setState(() => _isUploadingPhoto = false);
      
      if (!mounted) return;

      String errorMessage = 'Erreur lors de l\'upload';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Validation du formulaire et soumission
  Future<void> _handleSubmit() async {
    print('[EditProfilePage] 🔵 _handleSubmit appelé');
    
    if (!_formKey.currentState!.validate()) {
      print('[EditProfilePage] ❌ Validation formulaire échouée');
      return;
    }

    print('[EditProfilePage] ✅ Validation formulaire OK');
    setState(() => _isLoading = true);

    try {
      // Préparer les données à envoyer
      final data = <String, dynamic>{
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'telephone': _telephoneController.text.trim(),
      };

      // Ajouter email seulement s'il est rempli
      if (_emailController.text.trim().isNotEmpty) {
        data['email'] = _emailController.text.trim();
      }

      print('[EditProfilePage] 📤 Données à envoyer: $data');

      // Appel API backend PUT /api/user/profile
      final userRepository = ref.read(userRepositoryProvider);
      print('[EditProfilePage] 🔄 Appel userRepository.updateProfile...');
      await userRepository.updateProfile(data);
      print('[EditProfilePage] ✅ updateProfile réussi');

      if (!mounted) return;

      // Mettre à jour l'état auth avec le nouvel utilisateur
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final authState = ref.read(authNotifierProvider);
      
      authState.whenOrNull(
        authenticated: (currentUser, token) {
          // Créer un nouveau UserModel avec les données mises à jour
          final updatedUser = currentUser.copyWith(
            nom: _nomController.text.trim(),
            prenom: _prenomController.text.trim(),
            telephone: _telephoneController.text.trim(),
            email: _emailController.text.trim().isNotEmpty 
                ? _emailController.text.trim() 
                : currentUser.email,
          );
          
          // Mettre à jour l'état auth
          authNotifier.updateUser(updatedUser);
          print('[EditProfilePage] 🔄 État auth mis à jour');
        },
      );

      // Afficher succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Retour à la page profil
      print('[EditProfilePage] 🔙 Navigation retour');
      Navigator.pop(context);
    } catch (e) {
      print('[EditProfilePage] ❌ ERREUR: $e');
      if (!mounted) return;

      String errorMessage = 'Une erreur est survenue';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      print('[EditProfilePage] 📢 Affichage SnackBar erreur: $errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('[EditProfilePage] 🏁 _handleSubmit terminé');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modifier le profil',
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
              colors: [Color(0xFFFFA000), Color(0xFFFF8F00)],
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
            child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar avec upload photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary,
                        backgroundImage: _selectedImage != null 
                            ? FileImage(_selectedImage!)
                            : (() {
                                String? photoUrl = widget.user.photoUrl;
                                if (photoUrl != null && photoUrl.isNotEmpty) {
                                  if (photoUrl.startsWith('/')) {
                                    photoUrl = 'http://192.168.1.17:8000$photoUrl';
                                  }
                                  return NetworkImage(photoUrl);
                                }
                                return null;
                              })(),
                        child: _selectedImage == null && 
                               (widget.user.photoUrl == null || widget.user.photoUrl!.isEmpty)
                            ? Text(
                                '${widget.user.prenom[0]}${widget.user.nom[0]}'.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnPrimary,
                                ),
                              )
                            : null,
                    ),
                    if (_isUploadingPhoto)
                      Positioned.fill(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.black54,
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.secondary,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: AppColors.textOnSecondary,
                          ),
                          onPressed: _isUploadingPhoto ? null : _handlePhotoUpload,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Champ Nom
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Champ Prénom
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le prénom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Champ Email (optionnel)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Email invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Champ Téléphone
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  hintText: '+221XXXXXXXXX',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le téléphone est requis';
                  }
                  // Validation basique téléphone sénégalais
                  if (!value.startsWith('+221') && !value.startsWith('221')) {
                    return 'Format : +221XXXXXXXXX';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Bouton Enregistrer
              ElevatedButton(
                onPressed: _isLoading ? null : () {
                  print('[EditProfilePage] 🖱️ Bouton Enregistrer cliqué');
                  _handleSubmit();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textOnPrimary,
                          ),
                        ),
                      )
                    : const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Bouton Annuler
              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
