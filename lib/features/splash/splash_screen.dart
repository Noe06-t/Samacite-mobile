import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/auth/providers/auth_notifier.dart';
import 'package:mobile_samacite/features/auth/pages/login_page.dart';
import 'package:mobile_samacite/features/home/pages/main_navigation_page.dart';

/// Écran de splash qui affiche le logo SamaCité au démarrage
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _animDuration = Duration(milliseconds: 900);

  late final AnimationController _animationController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _titleOffset;
  late final Animation<double> _titleFade;
  late final Animation<double> _sloganFade;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: _animDuration,
    );

    // Logo : apparition avec un léger "pop" rebondi + rotation subtile
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _logoRotation = Tween<double>(begin: -0.12, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    // Titre : glisse légèrement vers le haut en apparaissant
    _titleOffset = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );

    // Slogan puis loader : apparition en fondu, en dernier
    _sloganFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );
    _loaderFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    _animationController.forward();

    _navigateAfterDelay();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterDelay() async {
    // Laisse l'animation du logo se jouer (moins d'1 seconde)
    await Future.delayed(_animDuration);

    for (var attempt = 0; attempt < 25; attempt++) {
      final authState = ref.read(authNotifierProvider);
      final isChecking = authState.maybeWhen(
        initial: () => true,
        loading: () => true,
        orElse: () => false,
      );
      if (!isChecking) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      final destination = authState.maybeWhen(
        authenticated: (_, __) => const MainNavigationPage(),
        orElse: () => null,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => destination ?? const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo SamaCité : pop rebondi + légère rotation
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: RotationTransition(
                  turns: _logoRotation,
                  child: Image.asset(
                    'assets/images/samacite_logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nom de l'application : glisse vers le haut en fondu
            FadeTransition(
              opacity: _titleFade,
              child: SlideTransition(
                position: _titleOffset,
                child: const Text(
                  'SamaCité',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A3F), // Couleur verte de la marque
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Slogan
            FadeTransition(
              opacity: _sloganFade,
              child: const Text(
                'Signaler. Suivre. Améliorer.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Indicateur de chargement
            FadeTransition(
              opacity: _loaderFade,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
