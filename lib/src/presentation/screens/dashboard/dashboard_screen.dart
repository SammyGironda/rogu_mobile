import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/gallery_section.dart';
import '../../widgets/footer_rogu.dart';
import '../../widgets/gradient_button.dart';
import '../auth/login_screen.dart';
import '../../state/providers.dart';
import '../bookings/new_reservation_screen.dart';
import '../management/gestion_canchas_screen.dart';
import '../../../apis/deprecated/gestion_service.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Navigation handled by BottomNavBar (shared widget)
  String _query = '';
  String? _venue;
  String? _location;
  // Removed sport dropdown from dashboard filters; sport chips exist in gallery

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : AppColors.neutral700;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
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
                    'ROGÜ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const Spacer(),
              // Mostrar login o perfil según estado de autenticación
              Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authProvider);
                  if (authState.isAuthenticated && authState.user != null) {
                    final username = authState.user!.username;
                    return InkWell(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.person, size: 18),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              username,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return GradientButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, LoginScreen.routeName),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_open, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Login'),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        leading: Builder(
          builder: (ctx) {
            return IconButton(
              icon: Icon(Icons.menu, color: iconColor),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code, color: iconColor),
            onPressed: () => Navigator.pushNamed(context, '/qr'),
          ),
          IconButton(
            icon: Icon(Icons.person, color: iconColor),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary500),
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
              onTap: () => Navigator.pushReplacementNamed(
                context,
                DashboardScreen.routeName,
              ),
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
                // Acceso controlado: autenticación + dueño/admin + sede
                final container = ProviderScope.containerOf(context);
                final auth = container.read(authProvider);
                if (!auth.isAuthenticated) {
                  Navigator.pushNamed(context, LoginScreen.routeName);
                  return;
                }
                final personaIdStr = auth.user?.personaId;
                final personaId = int.tryParse(personaIdStr ?? '');
                if (personaId == null) {
                  Navigator.pushNamed(context, NewReservationScreen.routeName);
                  return;
                }
                final result = await gestionService
                    .resolveGestionEntryForPersona(personaId);
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
                  Navigator.pushNamed(context, NewReservationScreen.routeName);
                } else {
                  Navigator.pushNamed(
                    context,
                    GestionCanchasScreen.routeName,
                    arguments: {'sede': sede},
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.settings, color: iconColor),
              title: const Text('Configuración'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed upper search bar per request
            const SizedBox(height: 16),
            const SizedBox(height: 20),
            // Barra de búsqueda + filtros
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Buscar por sede o deporte',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _query = v;
                });
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _venue,
                    decoration: const InputDecoration(labelText: 'Sede'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Sede Principal',
                        child: Text('Sede Principal'),
                      ),
                      DropdownMenuItem(
                        value: 'Sede Norte',
                        child: Text('Sede Norte'),
                      ),
                      DropdownMenuItem(
                        value: 'Sede Centro',
                        child: Text('Sede Centro'),
                      ),
                      DropdownMenuItem(
                        value: 'Sede Elite',
                        child: Text('Sede Elite'),
                      ),
                      DropdownMenuItem(
                        value: 'Sede Indoor',
                        child: Text('Sede Indoor'),
                      ),
                      DropdownMenuItem(
                        value: 'Sede Rooftop',
                        child: Text('Sede Rooftop'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _venue = v),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String>(
                    value: _location,
                    decoration: const InputDecoration(labelText: 'Ubicación'),
                    items: const [
                      DropdownMenuItem(value: 'Centro', child: Text('Centro')),
                      DropdownMenuItem(value: 'Norte', child: Text('Norte')),
                      DropdownMenuItem(value: 'Sur', child: Text('Sur')),
                    ],
                    onChanged: (v) => setState(() => _location = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Gallery Section
            GallerySection(
              filterText: _query,
              venue: _venue,
              location: _location,
            ),
            const SizedBox(height: 32),
            // Footer brand block
            const ROGUFooter(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
