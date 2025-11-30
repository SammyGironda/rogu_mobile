import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../models/venue.dart';
import '../models/field.dart';
import '../services/fields_service.dart';
import 'field_detail_screen.dart';

// Estado de sedes y cancha filtrada
final venuesProvider = StateNotifierProvider<VenuesNotifier, AsyncValue<List<Venue>>>((ref) => VenuesNotifier()..load());
final selectedDisciplineProvider = StateProvider<String?>((ref) => null);

class VenuesNotifier extends StateNotifier<AsyncValue<List<Venue>>> {
  VenuesNotifier() : super(const AsyncValue.loading());

  Future<void> load() async {
    try {
      final venues = await fieldsService.fetchVenuesInicio();
      state = AsyncValue.data(venues);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadFieldsForVenue(int idSede, {String? deporte}) async {
    final current = state.value ?? [];
    try {
      final fields = await fieldsService.fetchVenueFields(idSede, deporte: deporte);
      final updated = current.map((v) => v.id == idSede ? Venue(id: v.id, nombre: v.nombre, ciudad: v.ciudad, direccion: v.direccion, fotoPrincipal: v.fotoPrincipal, deportesDisponibles: v.deportesDisponibles, canchas: fields) : v).toList();
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class NewReservationScreen extends ConsumerWidget {
  static const routeName = '/new-reservation';
  const NewReservationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venuesProvider);
    final selectedDiscipline = ref.watch(selectedDisciplineProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Reserva'),
        leading: Builder(builder: (ctx) {
          final Color iconColor = isDark ? Colors.white : AppColors.neutral700;
          return IconButton(icon: Icon(Icons.menu, color: iconColor), onPressed: () => Scaffold.of(ctx).openDrawer());
        }),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary50, Colors.white, AppColors.secondary50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async => ref.read(venuesProvider.notifier).load(),
          child: venuesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error al cargar sedes: $e'),
              ),
            ),
            data: (venues) {
              // Construir listado plano de canchas con sede
              final canchas = <Map<String, dynamic>>[];
              for (final v in venues) {
                for (final c in v.canchas) {
                  if (selectedDiscipline != null && selectedDiscipline.isNotEmpty) {
                    if ((c.deporte ?? '').toLowerCase() != selectedDiscipline.toLowerCase()) continue;
                  }
                  canchas.add({'field': c, 'venue': v});
                }
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  Text('Filtrar Disciplinas', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _DisciplineFilterBar(venues: venues),
                  const SizedBox(height: 24),
                  if (canchas.isEmpty)
                    Card(
                      color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No hay canchas para la disciplina seleccionada'),
                      ),
                    )
                  else
                    ...canchas.map((item) {
                      final Field field = item['field'];
                      final Venue venue = item['venue'];
                      final img = field.fotos.isNotEmpty ? field.fotos.first : venue.fotoPrincipal;
                      return _FieldCard(field: field, venue: venue, image: img);
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DisciplineFilterBar extends ConsumerWidget {
  final List<Venue> venues;
  const _DisciplineFilterBar({required this.venues});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDisciplineProvider);
    // Unir disciplinas de todas las sedes
    final allDisc = <String>{};
    for (final v in venues) {
      for (final d in v.deportesDisponibles) {
        allDisc.add(d);
      }
    }
    final chips = allDisc.toList()..sort();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todas'),
          selected: selected == null || selected.isEmpty,
          onSelected: (_) => ref.read(selectedDisciplineProvider.notifier).state = null,
          selectedColor: AppColors.primary500,
          labelStyle: TextStyle(color: (selected == null || selected.isEmpty) ? Colors.white : null),
        ),
        for (final d in chips)
          ChoiceChip(
            label: Text(d),
            selected: selected == d,
            onSelected: (_) => ref.read(selectedDisciplineProvider.notifier).state = d,
            selectedColor: AppColors.secondary500,
            labelStyle: TextStyle(color: selected == d ? Colors.white : null),
          ),
      ],
    );
  }
}

class _FieldCard extends ConsumerWidget {
  final Field field;
  final Venue venue;
  final String? image;
  const _FieldCard({required this.field, required this.venue, this.image});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () async {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FieldDetailScreen(field: field, venue: venue),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: image != null && image!.isNotEmpty
                    ? Image.network(image!, width: 96, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field.nombre, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(venue.nombre, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.neutral600)),
                    if (field.deporte != null)
                      Text(field.deporte!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondary600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 96,
        height: 72,
        color: AppColors.primary100,
        alignment: Alignment.center,
        child: const Icon(Icons.image, color: AppColors.primary600),
      );
}
