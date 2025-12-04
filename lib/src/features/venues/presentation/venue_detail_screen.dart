import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/field.dart';
import '../../../data/models/venue.dart';
import '../application/venues_controller.dart';

class VenueDetailScreen extends ConsumerStatefulWidget {
  const VenueDetailScreen({super.key, required this.venueId});

  static const String routeName = '/venue_detail';

  final int venueId;

  @override
  ConsumerState<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDetail);
  }

  void _loadDetail() {
    if (_requested) return;
    _requested = true;
    ref.read(venuesControllerProvider.notifier).loadVenueDetail(widget.venueId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(venuesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sede deportiva')),
      body: Builder(
        builder: (context) {
          if (state.isLoadingDetail && state.venueDetail == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.venueDetail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700),
                ),
              ),
            );
          }
          final Venue? venue = state.venueDetail;
          if (venue == null) {
            return const Center(child: Text('No se pudo cargar la sede.'));
          }
          final List<Field> fields =
              state.fieldsByVenue[venue.id] ?? venue.canchas;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Headline(venue: venue, fieldsCount: fields.length),
              const SizedBox(height: 12),
              if (venue.deportesDisponibles.isNotEmpty)
                _CardSection(
                  title: 'Disciplinas',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: venue.deportesDisponibles
                        .map(
                          (d) => Chip(
                            label: Text(d),
                            backgroundColor: AppColors.primary50,
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (venue.descripcion != null && venue.descripcion!.isNotEmpty)
                _CardSection(
                  title: 'Descripcion',
                  child: Text(
                    venue.descripcion!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              _CardSection(
                title: 'Contacto',
                child: Builder(
                  builder: (context) {
                    final phone = venue.managerPhone ?? venue.telefono;
                    final email = venue.managerEmail ?? venue.email;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (venue.managerName != null &&
                            venue.managerName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Gestionado por ${venue.managerName}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        _InfoRow(
                          icon: Icons.place_outlined,
                          label: venue.getShortLocation(),
                        ),
                        if (phone != null && phone.isNotEmpty)
                          _InfoRow(
                            icon: Icons.call,
                            label: phone,
                            onTap: () => _launchUri('tel:$phone'),
                          ),
                        if (email != null && email.isNotEmpty)
                          _InfoRow(
                            icon: Icons.mail_outline,
                            label: email,
                            onTap: () => _launchUri('mailto:$email'),
                          ),
                      ],
                    );
                  },
                ),
              ),
              _CardSection(
                title: 'Ubicaci\u00f3n y mapa',
                child: _VenueMap(
                  lat: venue.lat,
                  lon: venue.lon,
                  address: venue.getShortLocation(),
                ),
              ),
              _CardSection(
                title: 'Canchas disponibles',
                child: fields.isEmpty
                    ? const Text('Sin canchas disponibles en esta sede.')
                    : Column(
                        children: fields
                            .map(
                              (f) => _FieldTile(
                                field: f,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/booking_form',
                                  arguments: {
                                    'venueId': widget.venueId,
                                    'fieldId': f.id,
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launchUri(String uri) async {
    final parsed = Uri.parse(uri);
    if (await canLaunchUrl(parsed)) {
      await launchUrl(parsed);
    }
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.venue, required this.fieldsCount});

  final Venue venue;
  final int fieldsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
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
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    venue.getShortLocation(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sports_soccer,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (venue.totalCanchas ?? fieldsCount) > 0
                                  ? '${venue.totalCanchas ?? fieldsCount} canchas'
                                  : 'Ver canchas',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.location_city, color: AppColors.neutral500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    venue.getShortLocation(),
                    maxLines: 2,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Icon(icon, size: 18, color: AppColors.neutral600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: onTap != null ? InkWell(onTap: onTap, child: content) : content,
    );
  }
}

class _VenueMap extends StatelessWidget {
  const _VenueMap({
    required this.lat,
    required this.lon,
    required this.address,
  });

  final double? lat;
  final double? lon;
  final String address;

  @override
  Widget build(BuildContext context) {
    if (lat == null || lon == null || lat!.isNaN || lon!.isNaN) {
      return Text(address, style: Theme.of(context).textTheme.bodyMedium);
    }
    final point = LatLng(lat!, lon!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary600,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.field, required this.onTap});

  final Field field;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary50,
                image: field.fotos.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(field.fotos.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: field.fotos.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin foto',
                        style: TextStyle(
                          color: AppColors.primary600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.nombre,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (field.deporte != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        field.deporte!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (field.descripcion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        field.descripcion!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  field.precio != null
                      ? '\$${field.precio!.toStringAsFixed(2)}'
                      : 'Consultar',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      field.iluminacion == true
                          ? Icons.light_mode
                          : Icons.light_mode_outlined,
                      size: 16,
                      color: AppColors.neutral500,
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.neutral500,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
