import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';

/// Widget carousel auto-défilant pour la page d'accueil
/// 
/// Affiche des images de la ville de Dakar qui défilent automatiquement
class HomeCarousel extends StatefulWidget {
  const HomeCarousel({super.key});

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<CarouselItem> _items = [
    CarouselItem(
      image: 'assets/images/plage_ngor.png',
      title: 'Plage de Ngor',
      description: 'Un cadre de vie préservé',
    ),
    CarouselItem(
      image: 'assets/images/nid_De_poule.jpg',
      title: 'Routes & Chaussées',
      description: 'Signalez les nids-de-poule',
    ),
    CarouselItem(
      image: 'assets/images/fuite.jpg',
      title: 'Eau & Assainissement',
      description: 'Fuites et problèmes d\'eau',
    ),
    CarouselItem(
      image: 'assets/images/eclairage.jpg',
      title: 'Éclairage Public',
      description: 'Lampadaires et électricité',
    ),
    CarouselItem(
      image: 'assets/images/parcelle1.jpeg.jpg',
      title: 'Votre Quartier',
      description: 'Ensemble pour améliorer',
    ),
    CarouselItem(
      image: 'assets/images/parcelle22.jpeg.jpg',
      title: 'Participation Citoyenne',
      description: 'Chaque signalement compte',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _items.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carousel
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return _buildCarouselItem(_items[index]);
            },
          ),
        ),

        const SizedBox(height: 12),

        // Indicateurs de page
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (index) => _buildPageIndicator(index == _currentPage),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(CarouselItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond
            Image.asset(
              item.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: Colors.grey,
                  ),
                );
              },
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Texte
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Modèle pour un élément du carousel
class CarouselItem {
  final String image;
  final String title;
  final String description;

  CarouselItem({
    required this.image,
    required this.title,
    required this.description,
  });
}
