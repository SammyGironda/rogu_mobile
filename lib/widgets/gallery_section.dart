import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme.dart';
import 'gradient_button.dart';
import '../models/field.dart';
import '../models/venue.dart';
import '../services/fields_service.dart';
import '../screens/field_detail_screen.dart';

final _filterProvider = StateProvider<String>((_) => 'todo');

// Removed static GalleryItem dataset in favor of API-driven Field list

final _fieldsProvider = FutureProvider.autoDispose<List<Field>>((ref) async {
  // Basic fetch of all canchas; further filtering applied in widget
  return fieldsService.fetchAllFields();
});

class GallerySection extends ConsumerWidget {
  final String filterText;
  final String? venue;
  final String? location;
  final String? sport;
  final int? minPlayers;
  final int? maxPlayers;
  const GallerySection({
    super.key,
    this.filterText = '',
    this.venue,
    this.location,
    this.sport,
    this.minPlayers,
    this.maxPlayers,
  });

  // Status colors removed; cards no longer show 'Disponible/Ocupada/Reservado'

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_filterProvider);
    final fieldsAsync = ref.watch(_fieldsProvider);
    return fieldsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error cargando canchas: $e')),
      data: (baseFields) {
        // Map Field -> pseudo sport string
        List<Field> itemsBySport = baseFields.where((i) {
          final sportLower = (i.deporte ?? '').toLowerCase();
          switch (filter) {
            case 'todo':
              return true;
            case 'futbol':
              return sportLower.contains('fútbol') ||
                  sportLower.contains('futbol');
            case 'voley':
              return sportLower.contains('vóley') ||
                  sportLower.contains('voley');
            case 'basket':
              return sportLower.contains('básquet') ||
                  sportLower.contains('basket') ||
                  sportLower.contains('basquet');
            case 'multidisciplinas':
              // Consider multi-sport courts like futsal, pádel, etc. under multidisciplinas
              return !(sportLower.contains('fútbol') ||
                  sportLower.contains('futbol') ||
                  sportLower.contains('básquet') ||
                  sportLower.contains('basket') ||
                  sportLower.contains('basquet'));
            default:
              return true;
          }
        }).toList();

        final itemsSearch = itemsBySport.where((i) {
          if (filterText.isEmpty) return true;
          final q = filterText.toLowerCase();
          return i.nombre.toLowerCase().contains(q);
        }).toList();

        final items = itemsSearch.where((i) {
          // TODO: Apply venue/location filters when API provides those on Field list
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Galería de canchas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            // Tagline removed per request
            const SizedBox(height: 12),
            _Filters(),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => _openFieldDetail(context, item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: item.fotos.isNotEmpty
                                    ? Image.network(
                                        item.fotos.first,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) =>
                                            Container(
                                              color: AppColors.neutral800,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.white54,
                                                size: 40,
                                              ),
                                            ),
                                      )
                                    : Image.asset(
                                        'lib/assets/images/courts/imagen2.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) =>
                                            Container(
                                              color: AppColors.neutral800,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.white54,
                                                size: 40,
                                              ),
                                            ),
                                      ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(.05),
                                      Colors.black.withOpacity(.55),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                          child: Text(
                            item.nombre,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            item.deporte ?? 'Multidisciplinas',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: GradientButton(
                            onPressed: () => _openFieldDetail(context, item),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.visibility,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text('Ver detalles'),
                              ],
                            ),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0EA5E9), // sky-500
                                Color(0xFF6366F1), // indigo
                                Color(0xFFEC4899), // pink
                              ],
                            ),
                            borderRadius: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _openFieldDetail(BuildContext context, Field field) {
    final venue = Venue(
      id: 0,
      nombre: 'Sede',
      deportesDisponibles: const [],
      canchas: const [],
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FieldDetailScreen(field: field, venue: venue),
      ),
    );
  }
}

// Old demo detail removed

class _Filters extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(_filterProvider);
    // Sport filters per request
    final filters = ['todo', 'futbol', 'voley', 'basket', 'multidisciplinas'];
    return Wrap(
      spacing: 10,
      children: filters.map((f) {
        final bool active = f == current;
        return ChoiceChip(
          label: Text(f),
          selected: active,
          onSelected: (_) => ref.read(_filterProvider.notifier).state = f,
          selectedColor: AppColors.primary500,
        );
      }).toList(),
    );
  }
}
