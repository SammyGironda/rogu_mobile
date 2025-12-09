import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../state/providers.dart';
import '../screens/auth/login_screen.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  static const List<String> _routeNames = [
    '/dashboard',
    '/booking_history',
    '/new-reservation',
    '/qr',
    '/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color selectedColor = AppColors.primary600;
    final Color unselectedColor = isDark
        ? Colors.white70
        : AppColors.neutral500;
    final auth = ref.watch(authProvider);
    final profileRepo = ref.read(profileRepositoryProvider);

    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    return FutureBuilder<List<String>>(
      future: () async {
        if (!auth.isAuthenticated) return const ['CLIENTE'];
        try {
          final profile = await profileRepo.fetchProfile();
          return profile.roles;
        } catch (_) {
          return const ['CLIENTE'];
        }
      }(),
      builder: (context, snapshot) {
        final roles = snapshot.data ?? const ['CLIENTE'];
        final isCliente = roles.contains('CLIENTE');
        final isControlador = roles.contains('CONTROLADOR');
        final isAdminOrOwner =
            roles.contains('ADMIN') || roles.contains('DUENIO');

        // Build active routes and items based on roles
        final activeRoutes = <String>[];
        final items = <BottomNavigationBarItem>[];

        // Dashboard
        activeRoutes.add(_routeNames[0]);
        items.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
        );

        // Historial only for clientes
        if (isCliente) {
          activeRoutes.add(_routeNames[1]);
          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Historial',
            ),
          );
        }

        // Gestion solo admin/duenio
        if (isAdminOrOwner) {
          activeRoutes.add(_routeNames[2]);
          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.event_available),
              label: 'Gestionar',
            ),
          );
        }

        // QR solo controlador
        if (isControlador) {
          activeRoutes.add(_routeNames[3]);
          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.qr_code),
              label: 'QR',
            ),
          );
        }

        // Perfil
        activeRoutes.add(_routeNames[4]);
        items.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        );

        final effectiveIndex = activeRoutes.indexOf(currentRoute ?? '');
        final currentIndex = effectiveIndex >= 0 ? effectiveIndex : 0;

        return BottomNavigationBar(
          currentIndex: currentIndex,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          type: BottomNavigationBarType.fixed,
          items: items,
          onTap: (idx) async {
            final destRoute = activeRoutes[idx];
            if (destRoute == '/new-reservation') {
              final authState = ref.read(authProvider);
              if (!authState.isAuthenticated) {
                Navigator.pushNamed(context, LoginScreen.routeName);
                return;
              }
              final personaId = authState.user?.personaId;
              if (personaId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Usuario sin persona asociada'),
                  ),
                );
                return;
              }
              try {
                final rolesMap = await profileRepo.checkUserRoles(personaId);
                final isOwner = rolesMap['isOwner'] == true;
                final isAdmin = rolesMap['isAdmin'] == true;
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidad en desarrollo')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
              return;
            }

            if (destRoute != currentRoute) {
              Navigator.pushReplacementNamed(context, destRoute);
            }
          },
        );
      },
    );
  }
}
