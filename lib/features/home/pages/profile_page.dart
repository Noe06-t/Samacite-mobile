import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/features/auth/providers/auth_notifier.dart';
import 'package:mobile_samacite/features/auth/providers/auth_state.dart';
import 'package:mobile_samacite/features/auth/pages/login_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        unauthenticated: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
            (route) => false,
          );
        },
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppColors.secondary,
      ),
      body: authState.maybeWhen(
        authenticated: (user, token) => SingleChildScrollView(
          child: Column(
            children: [
              // Header avec avatar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${user.prenom[0]}${user.nom[0]}'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${user.prenom} ${user.nom}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? user.telephone,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textOnSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.telephone,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textOnSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Informations du profil
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: AppColors.secondary,
                        ),
                        title: const Text('Nom complet'),
                        subtitle: Text('${user.prenom} ${user.nom}'),
                      ),
                    ),
                    if (user.email != null)
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.email,
                            color: AppColors.secondary,
                          ),
                          title: const Text('Email'),
                          subtitle: Text(user.email!),
                        ),
                      ),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.phone,
                          color: AppColors.secondary,
                        ),
                        title: const Text('Téléphone'),
                        subtitle: Text(user.telephone),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Paramètres',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.edit,
                          color: AppColors.primary,
                        ),
                        title: const Text('Modifier le profil'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigation vers modification du profil
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.lock,
                          color: AppColors.primary,
                        ),
                        title: const Text('Changer le mot de passe'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigation vers changement de mot de passe
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.notifications,
                          color: AppColors.primary,
                        ),
                        title: const Text('Notifications'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigation vers paramètres notifications
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: AppColors.danger,
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: AppColors.textOnDanger,
                        ),
                        title: const Text(
                          'Déconnexion',
                          style: TextStyle(color: AppColors.textOnDanger),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.textOnDanger,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Déconnexion'),
                              content: const Text(
                                'Êtes-vous sûr de vouloir vous déconnecter ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ref
                                        .read(authNotifierProvider.notifier)
                                        .logout();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.danger,
                                  ),
                                  child: const Text('Déconnexion'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
        orElse: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
