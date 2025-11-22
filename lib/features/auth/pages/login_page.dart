import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/features/auth/providers/auth_notifier.dart';
import 'package:mobile_samacite/features/auth/pages/register_page.dart';
import 'package:mobile_samacite/features/home/pages/main_navigation_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    print('[LoginPage] \ud83d\udd11 Bouton de connexion press\u00e9');
    print('[LoginPage] \u2714\ufe0f Validation du formulaire...');
    
    if (!_formKey.currentState!.validate()) {
      print('[LoginPage] ❌ Validation du formulaire échouée');
      return;
    }

    final identifier = _emailController.text.trim();
    print('[LoginPage] ✅ Formulaire valide');
    print('[LoginPage] 🆔 Identifiant (email ou téléphone): $identifier');
    
    // Si c'est un téléphone, ajouter le préfixe +221
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isEmail = emailRegex.hasMatch(identifier);
    final finalIdentifier = isEmail ? identifier : '+221$identifier';
    
    print('[LoginPage] 🔄 Identifiant final: $finalIdentifier');
    print('[LoginPage] 🔐 Appel de authNotifier.login()...');
    
    ref.read(authNotifierProvider.notifier).login(
          email: finalIdentifier, // Email ou téléphone avec préfixe 221
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      print('[LoginPage] \ud83d\udd0a Changement d\'\u00e9tat d\u00e9tect\u00e9');
      print('[LoginPage] \ud83d\udcca \u00c9tat pr\u00e9c\u00e9dent: $previous');
      print('[LoginPage] \ud83d\udcca Nouvel \u00e9tat: $next');
      
      next.maybeWhen(
        authenticated: (user, token) {
          print('[LoginPage] \u2705 \u00c9tat: AUTHENTICATED');
          print('[LoginPage] \ud83d\udc64 User: ${user.prenom} ${user.nom}');
          print('[LoginPage] \ud83d\udd11 Token: ${token.substring(0, 20)}...');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bienvenue ${user.prenom} ${user.nom} !'),
              backgroundColor: Colors.green,
            ),
          );
          
          print('[LoginPage] 🧐 Navigation vers MainNavigationPage...');
          // Navigation vers MainNavigationPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainNavigationPage(),
            ),
          );
        },
        error: (message) {
          print('[LoginPage] \u274c \u00c9tat: ERROR');
          print('[LoginPage] \ud83d\udcc4 Message: $message');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.danger,
            ),
          );
        },
        loading: () {
          print('[LoginPage] \u23f3 \u00c9tat: LOADING');
        },
        orElse: () {
          print('[LoginPage] \ud83e\udd37 \u00c9tat: AUTRE');
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(48),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        size: 48,
                        color: AppColors.textOnSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Connexion',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Renseignez vos identifiants pour accéder à SamaCité',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Email ou Téléphone',
                      hintText: 'exemple@email.com ou 771234567',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email ou téléphone requis';
                      }
                      // Si c'est un numéro, valider le format
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        // C'est un téléphone, doit commencer par 7
                        final phoneRegex = RegExp(r'^7[0-9]{8}$');
                        if (!phoneRegex.hasMatch(value.trim())) {
                          return 'Format invalide (ex: 771234567)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mot de passe requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: AppColors.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: authState.maybeWhen(
                        loading: () => null,
                        orElse: () => _handleLogin,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authState.maybeWhen(
                        loading: () => const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        orElse: () => const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('ou'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Pas encore de compte ? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Inscription',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
