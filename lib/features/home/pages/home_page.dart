import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/features/auth/providers/auth_notifier.dart';
import 'package:mobile_samacite/features/reports/pages/create_report_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SamaCité'),
        backgroundColor: AppColors.secondary,
      ),
      body: authState.maybeWhen(
        authenticated: (user, token) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, ${user.prenom} ${user.nom}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? user.telephone,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    title: const Text(
                      'Nouveau signalement',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Créer un signalement'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateReportPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(
                      Icons.list,
                      color: AppColors.secondary,
                      size: 32,
                    ),
                    title: const Text(
                      'Mes signalements',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Voir tous vos signalements'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigation vers les signalements
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(
                      Icons.map,
                      color: AppColors.secondary,
                      size: 32,
                    ),
                    title: const Text(
                      'Carte des signalements',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Explorer la carte'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigation vers la carte
                    },
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: AppColors.primary.withOpacity(0.1),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Signalements',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        color: AppColors.secondary.withOpacity(0.1),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Résolus',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        orElse: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
