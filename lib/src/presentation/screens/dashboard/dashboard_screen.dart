import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/venues/application/venues_controller.dart';
import '../../../features/venues/presentation/venues_screen.dart';
import '../../state/providers.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/app_drawer.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends ConsumerWidget {
  static const String routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : AppColors.neutral700;
    final auth = ref.watch(authProvider);
    final venuesCtrl = ref.read(venuesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF06B6D4),
                    Color(0xFF8B5CF6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'lib/assets/rogu_logo.png',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROGU',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Reserva tu cancha favorita',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        leading: Builder(
          builder: (ctx) {
            return IconButton(
              icon: Icon(Icons.menu, color: iconColor),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
        actions: [_SessionAction(auth: auth)],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () => venuesCtrl.loadVenues(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Explora las sedes disponibles',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Selecciona una sede para ver sus canchas, horarios y reservar.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const VenuesPreviewSection(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _SessionAction extends StatelessWidget {
  const _SessionAction({required this.auth});

  final AuthState auth;

  @override
  Widget build(BuildContext context) {
    if (auth.isAuthenticated && auth.user != null) {
      final username = auth.user!.username;
      final String initials = username.isNotEmpty
          ? username.characters.first
          : '?';
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 16, child: Text(initials)),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  username,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: () => Navigator.pushNamed(context, LoginScreen.routeName),
        icon: const Icon(Icons.lock_open),
        label: const Text('Login'),
      ),
    );
  }
}
