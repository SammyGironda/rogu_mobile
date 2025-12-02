import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/venues_controller.dart';
import 'widgets/venue_card.dart';
import '../../../presentation/widgets/app_drawer.dart';
import '../../../presentation/widgets/bottom_nav.dart';

class VenuesScreen extends ConsumerStatefulWidget {
  static const String routeName = '/venues';

  const VenuesScreen({super.key});

  @override
  ConsumerState<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends ConsumerState<VenuesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(venuesControllerProvider.notifier).loadVenues(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(venuesControllerProvider);
    final controller = ref.read(venuesControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sedes deportivas'),
        leading: Builder(
          builder: (ctx) {
            final Color iconColor = isDark
                ? Colors.white
                : AppColors.neutral700;
            return IconButton(
              icon: Icon(Icons.menu, color: iconColor),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: RefreshIndicator(
        onRefresh: () => controller.loadVenues(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Explora las sedes y sus canchas',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Consulta ubicacion, contacto y disponibilidad de canchas antes de reservar.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (state.error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
            if (state.loadingList && state.venues.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.venues.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No hay sedes disponibles.')),
              )
            else
              ...state.venues.map(
                (v) => VenueCard(
                  venue: v,
                  fields: state.fieldsByVenue[v.id] ?? const [],
                  expanded: state.expandedVenueId == v.id,
                  loadingFields: state.loadingFieldsFor == v.id,
                  onToggle: () => controller.toggleExpanded(v.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
