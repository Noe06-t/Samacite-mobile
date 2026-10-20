import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/constants/app_colors.dart';
import 'package:mobile_samacite/features/home/pages/home_page.dart';
import 'package:mobile_samacite/features/reports/pages/report_list_page.dart';
import 'package:mobile_samacite/features/reports/pages/map_page.dart';
import 'package:mobile_samacite/features/home/pages/profile_page.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _currentIndex = 0;
  StreamSubscription? _notificationSubscription;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      ReportListPage(
        onRootBack: () => setState(() => _currentIndex = 0),
      ),
      MapPage(
        onRootBack: () => setState(() => _currentIndex = 0),
      ),
      const ProfilePage(),
    ];
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Écouter les clics sur notifications pour navigation
  void _setupNotificationListener() {
    // Navigation depuis notifications désactivée (sans Firebase push)
    print('[MainNavigation] ℹ️ Navigation depuis notifications push désactivée');
  }

  /// Construire une icône de navigation avec animation
  Widget _buildNavIcon(IconData icon, int index, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary.withOpacity(0.6),
            selectedFontSize: 13,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home_outlined, 0),
                activeIcon: _buildNavIcon(Icons.home_rounded, 0, isActive: true),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.report_problem_outlined, 1),
                activeIcon: _buildNavIcon(Icons.report_problem_rounded, 1, isActive: true),
                label: 'Signalements',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.map_outlined, 2),
                activeIcon: _buildNavIcon(Icons.map_rounded, 2, isActive: true),
                label: 'Carte',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_outline_rounded, 3),
                activeIcon: _buildNavIcon(Icons.person_rounded, 3, isActive: true),
                label: 'Profil',
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
