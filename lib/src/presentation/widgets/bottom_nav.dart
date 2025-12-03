import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../state/providers.dart';
import '../../apis/deprecated/gestion_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/bookings/new_reservation_screen.dart';
import '../screens/management/gestion_canchas_screen.dart';

/// Reusable BottomNavigationBar that maps fixed indices to named routes.
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  static const List<String> _routeNames = [
    '/dashboard',
    '/booking_history',
    '/new-reservation',
    '/reservas/pendientes',
    '/profile',
  ];

  int _currentIndexFromRoute(String? routeName) {
    if (routeName == null) return 0;
    final idx = _routeNames.indexOf(routeName);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color selectedColor = AppColors.primary600;
    final Color unselectedColor = isDark
        ? Colors.white70
        : AppColors.neutral500;

    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final int currentIndex = _currentIndexFromRoute(currentRoute);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (idx) async {
        final String dest = _routeNames[idx];
        if (dest == '/new-reservation') {
          // Gating for Gestión section from bottom nav index 2
          final auth = ref.read(authProvider);
          if (!auth.isAuthenticated) {
            Navigator.pushNamed(context, LoginScreen.routeName);
            return;
          }
          final personaId = int.tryParse(auth.user?.personaId ?? '');
          if (personaId == null) {
            Navigator.pushReplacementNamed(
              context,
              NewReservationScreen.routeName,
            );
            return;
          }
          final result = await gestionService.resolveGestionEntryForPersona(
            personaId,
          );
          if (!context.mounted) return;
          if (result['success'] != true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message']?.toString() ?? 'Acceso restringido',
                ),
              ),
            );
            return;
          }
          final sede = result['sede'];
          if (sede == null) {
            Navigator.pushReplacementNamed(
              context,
              NewReservationScreen.routeName,
            );
          } else {
            if (GestionCanchasScreen.routeName != currentRoute) {
              Navigator.pushReplacementNamed(
                context,
                GestionCanchasScreen.routeName,
                arguments: {'sede': sede},
              );
            }
          }
          return;
        }
        if (dest != currentRoute) {
          Navigator.pushReplacementNamed(context, dest);
        }
      },
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_available),
          label: 'Gestionar',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
