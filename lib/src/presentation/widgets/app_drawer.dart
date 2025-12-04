import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../state/providers.dart';
import '../../features/venues/presentation/venues_screen.dart';


class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : AppColors.neutral700;
    final auth = ref.watch(authProvider);

    Future<List<String>> _loadRoles() async {
      if (!auth.isAuthenticated) return const ['CLIENTE'];
      try {
        final profileRepo = ref.read(profileRepositoryProvider);
        final profile = await profileRepo.fetchProfile();
        return profile.roles;
      } catch (_) {
        return const ['CLIENTE'];
      }
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary500),
            child: Text(
              'ROGU',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: iconColor),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          FutureBuilder<List<String>>(
            future: _loadRoles(),
            builder: (context, snapshot) {
              final roles = snapshot.data ?? const ['CLIENTE'];
              final isCliente = roles.contains('CLIENTE');
              final isControlador = roles.contains('CONTROLADOR');
              final isAdminOrOwner =
                  roles.contains('ADMIN') || roles.contains('DUENIO');

              return Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.location_city, color: iconColor),
                    title: const Text('Sedes'),
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      VenuesScreen.routeName,
                    ),
                  ),
                  if (isCliente)
                    ListTile(
                      leading: Icon(Icons.history, color: iconColor),
                      title: const Text('Historial'),
                      onTap: () =>
                          Navigator.pushNamed(context, '/booking_history'),
                    ),
                  if (isAdminOrOwner)
                    ListTile(
                      leading: Icon(Icons.event_available, color: iconColor),
                      title: const Text('Gestion de canchas'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Funcionalidad en desarrollo'),
                          ),
                        );
                      },
                    ),
                  if (isControlador)
                    ListTile(
                      leading: Icon(Icons.qr_code, color: iconColor),
                      title: const Text('Escanear QR'),
                      onTap: () => Navigator.pushNamed(context, '/qr'),
                    ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.person, color: iconColor),
            title: const Text('Perfil'),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          ListTile(
            leading: Icon(Icons.report, color: iconColor),
            title: const Text('Denunciar'),
            onTap: () => Navigator.pushNamed(context, '/denuncia'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.settings, color: iconColor),
            title: const Text('Configuracion'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
