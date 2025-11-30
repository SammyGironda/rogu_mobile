import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Reusable BottomNavigationBar that maps fixed indices to named routes.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const List<String> _routeNames = [
    '/dashboard',
    '/booking_history',
    '/new-reservation',
    '/qr',
    '/profile',
  ];

  int _currentIndexFromRoute(String? routeName) {
    if (routeName == null) return 0;
    final idx = _routeNames.indexOf(routeName);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color selectedColor = AppColors.primary600;
    final Color unselectedColor = isDark ? Colors.white70 : AppColors.neutral500;

    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final int currentIndex = _currentIndexFromRoute(currentRoute);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (idx) {
        final String dest = _routeNames[idx];
        if (dest != currentRoute) {
          // replace so we don't stack routes
          Navigator.pushReplacementNamed(context, dest);
        }
      },
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
        BottomNavigationBarItem(icon: Icon(Icons.event_available), label: 'Gestionar'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
