import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme.dart';
import '../screens/login_screen.dart';
import '../screens/new_reservation_screen.dart';
import '../screens/gestion_canchas_screen.dart';
import '../state/providers.dart';
import '../services/gestion_service.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : AppColors.neutral700;

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
          ListTile(
            leading: Icon(Icons.history, color: iconColor),
            title: const Text('Historial'),
            onTap: () => Navigator.pushNamed(context, '/booking_history'),
          ),
          ListTile(
            leading: Icon(Icons.event_available, color: iconColor),
            title: const Text('Gestión de canchas'),
            onTap: () async {
              final auth = ref.read(authProvider);
              if (!auth.isAuthenticated) {
                Navigator.pushNamed(context, LoginScreen.routeName);
                return;
              }
              final personaIdStr = auth.user?.personaId;
              final personaId = int.tryParse(personaIdStr ?? '');
              if (personaId == null) {
                // Sin persona asociada, enviar a creación de sede (pantalla nueva)
                Navigator.pushNamed(context, NewReservationScreen.routeName);
                return;
              }
              final result = await gestionService
                  .resolveGestionEntryForPersona(personaId);
              if (result['success'] != true) {
                // Acceso denegado o error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message']?.toString() ?? 'Acceso restringido')),
                );
                return;
              }
              final sede = result['sede'];
              if (sede == null) {
                // No tiene sede creada: ir a pantalla de nueva reserva/creación
                Navigator.pushNamed(context, NewReservationScreen.routeName);
              } else {
                // Tiene sede: abrir gestión de canchas con args de sede
                Navigator.pushNamed(
                  context,
                  GestionCanchasScreen.routeName,
                  arguments: {
                    'sede': sede,
                  },
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.qr_code, color: iconColor),
            title: const Text('Escanear QR'),
            onTap: () => Navigator.pushNamed(context, '/qr'),
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
            title: const Text('Configuración'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
