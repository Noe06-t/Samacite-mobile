import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/models/comment_model.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/features/comments/repositories/comment_repository.dart';
import 'package:mobile_samacite/features/auth/providers/auth_providers.dart';
import 'package:mobile_samacite/features/auth/providers/auth_notifier.dart';

/// Section des commentaires pour la page de détail d'un signalement
/// 
/// Affiche:
/// - Liste des commentaires avec pagination
/// - Formulaire d'ajout de commentaire
/// - Possibilité de supprimer ses propres commentaires
class CommentsSection extends ConsumerStatefulWidget {
  final int reportId;
  final int? currentUserId; // ID de l'utilisateur connecté pour vérifier les droits

  const CommentsSection({
    super.key,
    required this.reportId,
    this.currentUserId,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  CommentRepository? _repository;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Utiliser l'instance DioService du provider qui contient le token
      final dioService = ref.read(dioServiceProvider);
      _repository = CommentRepository(dioService);
      _initialized = true;
      _loadComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _errorMessage = null;
      });
    }

    if (_repository == null) return;
    
    try {
      final result = await _repository!.getComments(
        widget.reportId,
        page: _currentPage,
      );

      setState(() {
        if (refresh) {
          _comments = result['data'] as List<CommentModel>;
        } else {
          _comments.addAll(result['data'] as List<CommentModel>);
        }
        _lastPage = result['last_page'] as int;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des commentaires';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadComments();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le commentaire ne peut pas être vide'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (content.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le commentaire ne peut pas dépasser 500 caractères'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_repository == null) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final newComment = await _repository!.createComment(
        widget.reportId,
        content,
      );

      // Récupérer les infos de l'utilisateur connecté depuis AuthNotifier
      final authState = ref.read(authNotifierProvider);
      CommentModel commentWithUser = newComment;
      
      // Ajouter les infos utilisateur au commentaire si elles manquent
      authState.maybeWhen(
        authenticated: (user, token) {
          if (newComment.user == null) {
            commentWithUser = newComment.copyWith(
              user: CommentUser(
                id: user.id,
                nom: user.nom,
                prenom: user.prenom,
                email: user.email,
                telephone: user.telephone,
              ),
            );
          }
        },
        orElse: () {},
      );

      setState(() {
        _comments.insert(0, commentWithUser); // Ajouter en premier
        _commentController.clear();
        _isSubmitting = false;
      });

      _commentFocus.unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commentaire ajouté avec succès'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le commentaire'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce commentaire ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (_repository == null) return;

    try {
      await _repository!.deleteComment(commentId);

      setState(() {
        _comments.removeWhere((c) => c.id == commentId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commentaire supprimé'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Commentaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // Formulaire d'ajout
        _buildCommentForm(),

        const Divider(height: 1),

        // Liste des commentaires
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          _buildErrorWidget()
        else if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Aucun commentaire pour le moment.\nSoyez le premier à commenter !',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          _buildCommentsList(),
      ],
    );
  }

  Widget _buildCommentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocus,
              maxLines: null,
              maxLength: 500,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                hintText: 'Ajouter un commentaire...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _isSubmitting ? null : _submitComment,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadComments(refresh: true),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length + (_currentPage < _lastPage ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == _comments.length) {
          // Bouton "Charger plus"
          return _isLoadingMore
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : TextButton(
                  onPressed: _loadMoreComments,
                  child: const Text('Charger plus de commentaires'),
                );
        }

        final comment = _comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    final bool canDelete = widget.currentUserId != null &&
        widget.currentUserId == comment.userId;
    
    // Récupérer le nom de l'utilisateur actuel pour afficher "Vous"
    final authState = ref.read(authNotifierProvider);
    String displayName = _getUserName(comment.user);
    
    authState.maybeWhen(
      authenticated: (user, token) {
        if (comment.userId == user.id) {
          displayName = 'Vous';
        }
      },
      orElse: () {},
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondary,
            child: Text(
              _getInitials(comment.user),
              style: const TextStyle(
                color: AppColors.textOnSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Contenu commentaire
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + date
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Texte commentaire
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Bouton supprimer
          if (canDelete)
            IconButton(
              onPressed: () => _deleteComment(comment.id),
              icon: const Icon(Icons.delete_outline),
              iconSize: 20,
              color: AppColors.danger,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  String _getInitials(CommentUser? user) {
    if (user == null) return '?';
    
    // Format minimal: {id, name, email}
    if (user.name != null && user.name!.isNotEmpty) {
      final parts = user.name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return user.name![0].toUpperCase();
    }
    
    // Format complet: {id, nom, prenom, email, telephone}
    final prenom = (user.prenom?.isNotEmpty ?? false) ? user.prenom![0] : '';
    final nom = (user.nom?.isNotEmpty ?? false) ? user.nom![0] : '';
    if (prenom.isEmpty && nom.isEmpty) return '?';
    return '$prenom$nom'.toUpperCase();
  }

  String _getUserName(CommentUser? user) {
    if (user == null) return 'Utilisateur inconnu';
    
    // Format minimal: {id, name, email}
    if (user.name != null && user.name!.isNotEmpty) {
      return user.name!;
    }
    
    // Format complet: {id, nom, prenom, email, telephone}
    final prenom = user.prenom ?? '';
    final nom = user.nom ?? '';
    if (prenom.isEmpty && nom.isEmpty) {
      return 'Utilisateur inconnu';
    }
    return '$prenom $nom'.trim();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inHours < 1) {
        return 'Il y a ${difference.inMinutes}min';
      } else if (difference.inDays < 1) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays}j';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
