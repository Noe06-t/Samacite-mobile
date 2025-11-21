import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/features/auth/providers/auth_notifier.dart';
import 'package:mobile_samacite/features/auth/providers/auth_state.dart';
import 'package:mobile_samacite/features/auth/pages/login_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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
        title: const Text('SamaCité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: authState.maybeWhen(
        authenticated: (user, token) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue, ${user.name}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              if (user.phone != null) ...[
                const SizedBox(height: 4),
                Text(
                  user.phone!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.report_problem,
                    color: AppColors.primary,
                  ),
                  title: const Text('Mes signalements'),
                  subtitle: const Text('Voir tous vos signalements'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigation vers les signalements
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.add_circle,
                    color: AppColors.secondary,
                  ),
                  title: const Text('Nouveau signalement'),
                  subtitle: const Text('Créer un nouveau signalement'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigation vers création signalement
                  },
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
