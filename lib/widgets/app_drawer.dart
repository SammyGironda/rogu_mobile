import 'package:flutter/material.dart';

import '../theme/theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : AppColors.neutral700;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary500),
            child: Text('ROGU', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
          ),
          ListTile(leading: Icon(Icons.dashboard, color: iconColor), title: const Text('Dashboard'), onTap: () => Navigator.pushReplacementNamed(context, '/dashboard')),
          ListTile(leading: Icon(Icons.history, color: iconColor), title: const Text('Historial'), onTap: () => Navigator.pushNamed(context, '/booking_history')),
          ListTile(leading: Icon(Icons.event_available, color: iconColor), title: const Text('Gestión de reservas'), onTap: () => Navigator.pushNamed(context, '/new-reservation')),
          ListTile(leading: Icon(Icons.qr_code, color: iconColor), title: const Text('Escanear QR'), onTap: () => Navigator.pushNamed(context, '/qr')),
          const Divider(),
          ListTile(leading: Icon(Icons.person, color: iconColor), title: const Text('Perfil'), onTap: () => Navigator.pushNamed(context, '/profile')),
          ListTile(leading: Icon(Icons.report, color: iconColor), title: const Text('Denunciar'), onTap: () => Navigator.pushNamed(context, '/denuncia')),
          const Divider(),
          ListTile(leading: Icon(Icons.settings, color: iconColor), title: const Text('Configuración'), onTap: () {}),
        ],
      ),
    );
  }
}
