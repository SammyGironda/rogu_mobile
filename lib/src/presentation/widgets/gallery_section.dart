import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/venues/application/venues_controller.dart';
import '../../features/venues/presentation/venues_screen.dart';
import '../../data/models/venue.dart';
import '../../core/theme/app_theme.dart';
import 'gradient_button.dart';

final _sportFilterProvider = StateProvider<String>((_) => 'todo');

class GallerySection extends ConsumerStatefulWidget {
  const GallerySection({
    super.key,
    this.filterText = '',
    this.venue,
    this.location,
  });

  final String filterText;
  final String? venue;
  final String? location;

  @override
  ConsumerState<GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends ConsumerState<GallerySection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(venuesControllerProvider.notifier).loadVenues(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venuesState = ref.watch(venuesControllerProvider);
    final String sportFilter = ref.watch(_sportFilterProvider);

    final List<Venue> filtered = venuesState.venues.where((v) {
      if (widget.filterText.isNotEmpty) {
        final q = widget.filterText.toLowerCase();
        final match =
            v.nombre.toLowerCase().contains(q) ||
            (v.direccion ?? '').toLowerCase().contains(q) ||
            (v.ciudad ?? '').toLowerCase().contains(q);
        if (!match) return false;
      }
      if (widget.venue != null && widget.venue!.isNotEmpty) {
        if (!v.nombre.toLowerCase().contains(widget.venue!.toLowerCase())) {
          return false;
        }
      }
      if (widget.location != null && widget.location!.isNotEmpty) {
        final loc = widget.location!.toLowerCase();
        final matchLoc =
            (v.ciudad ?? '').toLowerCase().contains(loc) ||
            (v.direccion ?? '').toLowerCase().contains(loc);
        if (!matchLoc) return false;
      }
      final deportes = v.deportesDisponibles
          .map((d) => d.toLowerCase())
          .toList();
      switch (sportFilter) {
        case 'futbol':
          return deportes.any((d) => d.contains('futbol') || d.contains('fut'));
        case 'voley':
          return deportes.any(
            (d) => d.contains('voley') || d.contains('volley'),
          );
        case 'basket':
          return deportes.any(
            (d) => d.contains('basket') || d.contains('basquet'),
          );
        case 'multidisciplinas':
          return deportes.isEmpty;
        default:
          return true;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Galeria de sedes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, VenuesScreen.routeName),
              icon: const Icon(Icons.map),
              label: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SportFilters(),
        const SizedBox(height: 12),
        if (venuesState.loadingList && venuesState.venues.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No encontramos sedes con esos filtros.'),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final venue = filtered[index];
              final fieldsCount =
                  venuesState.fieldsByVenue[venue.id]?.length ??
                  venue.canchas.length;
              return _VenueTile(venue: venue, fieldsCount: fieldsCount);
            },
          ),
      ],
    );
  }
}

class _VenueTile extends StatelessWidget {
  const _VenueTile({required this.venue, required this.fieldsCount});

  final Venue venue;
  final int fieldsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, VenuesScreen.routeName),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: venue.fotoPrincipal != null
                        ? Image.network(
                            venue.fotoPrincipal!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackImage(),
                          )
                        : _fallbackImage(),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(.05),
                            Colors.black.withOpacity(.50),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            venue.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.sports_soccer,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                fieldsCount > 0 ? '$fieldsCount' : 'Ver',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.neutral500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      venue.direccion ??
                          venue.ciudad ??
                          'Ubicacion no disponible',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            if (venue.deportesDisponibles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: venue.deportesDisponibles
                      .take(2)
                      .map(
                        (d) => Chip(
                          label: Text(d, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.primary50,
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: GradientButton(
                onPressed: () =>
                    Navigator.pushNamed(context, VenuesScreen.routeName),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.visibility, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Ver detalle'),
                  ],
                ),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0EA5E9),
                    Color(0xFF6366F1),
                    Color(0xFFEC4899),
                  ],
                ),
                borderRadius: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: AppColors.neutral200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, color: AppColors.neutral500),
    );
  }
}

class _SportFilters extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(_sportFilterProvider);
    final filters = ['todo', 'futbol', 'voley', 'basket', 'multidisciplinas'];
    return Wrap(
      spacing: 10,
      children: filters.map((f) {
        final bool active = f == current;
        return ChoiceChip(
          label: Text(f),
          selected: active,
          onSelected: (_) => ref.read(_sportFilterProvider.notifier).state = f,
          selectedColor: AppColors.primary500,
        );
      }).toList(),
    );
  }
}
