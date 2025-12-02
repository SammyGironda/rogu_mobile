import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../state/providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/bookings/new_reservation_screen.dart';

/// Reusable BottomNavigationBar that maps fixed indices to named routes.
class BottomNavBar extends ConsumerWidget {
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
          final personaId = auth.user?.personaId;
          if (personaId == null) {
            Navigator.pushReplacementNamed(
              context,
              NewReservationScreen.routeName,
            );
            return;
          }

          // Verificar roles usando ProfileRepository
          try {
            final profileRepo = ref.read(profileRepositoryProvider);
            final roles = await profileRepo.checkUserRoles(personaId);
            final isOwner = roles['isOwner'] == true;
            final isAdmin = roles['isAdmin'] == true;

            if (!context.mounted) return;

            if (!(isOwner || isAdmin)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Acceso restringido a dueños o administradores',
                  ),
                ),
              );
              return;
            }

            // TODO: Verificar si tiene sede usando nueva API cuando esté disponible
            // Por ahora, redirigir a crear sede
            Navigator.pushReplacementNamed(
              context,
              NewReservationScreen.routeName,
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
