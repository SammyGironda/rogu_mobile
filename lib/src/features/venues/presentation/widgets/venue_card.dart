import 'package:flutter/material.dart';

import '../../../../data/models/field.dart';
import '../../../../data/models/venue.dart';
import '../../../../core/theme/app_theme.dart';

class VenueCard extends StatelessWidget {
  const VenueCard({
    super.key,
    required this.venue,
    required this.fields,
    required this.expanded,
    required this.loadingFields,
    required this.onToggle,
  });

  final Venue venue;
  final List<Field> fields;
  final bool expanded;
  final bool loadingFields;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color overlay = Colors.black.withOpacity(0.45);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    image: venue.fotoPrincipal != null
                        ? DecorationImage(
                            image: NetworkImage(venue.fotoPrincipal!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: venue.fotoPrincipal == null
                        ? LinearGradient(
                            colors: [
                              AppColors.primary600,
                              AppColors.primary400,
                            ],
                          )
                        : null,
                  ),
                ),
                Positioned.fill(child: Container(color: overlay)),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue.nombre,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    venue.direccion ??
                                        (venue.ciudad ??
                                            'Ubicacion no disponible'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (venue.propietario != null &&
                                venue.propietario!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.business_center,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Dueno: ${venue.propietario}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${venue.canchas.isNotEmpty ? venue.canchas.length : fields.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'canchas',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _VenueDetails(
                venue: venue,
                fields: fields,
                loadingFields: loadingFields,
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueDetails extends StatelessWidget {
  const _VenueDetails({
    required this.venue,
    required this.fields,
    required this.loadingFields,
  });

  final Venue venue;
  final List<Field> fields;
  final bool loadingFields;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark ? AppColors.neutral900 : AppColors.neutral50,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (venue.descripcion != null && venue.descripcion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                venue.descripcion!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.place,
                label: venue.direccion ?? 'Direccion no disponible',
              ),
              if (venue.ciudad != null && venue.ciudad!.isNotEmpty)
                _InfoChip(icon: Icons.location_city, label: venue.ciudad!),
              if (venue.telefono != null && venue.telefono!.isNotEmpty)
                _InfoChip(icon: Icons.call, label: venue.telefono!),
              if (venue.email != null && venue.email!.isNotEmpty)
                _InfoChip(icon: Icons.mail, label: venue.email!),
            ],
          ),
          if (venue.deportesDisponibles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Disciplinas', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
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
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Canchas', style: theme.textTheme.titleSmall),
              if (loadingFields)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!loadingFields && fields.isEmpty)
            Text(
              'Sin canchas disponibles en esta sede.',
              style: theme.textTheme.bodySmall,
            )
          else
            Column(children: fields.map((f) => _FieldTile(field: f)).toList()),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/booking_form');
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Reservar en esta sede'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.field});

  final Field field;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
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
                ? const Icon(Icons.sports, color: AppColors.primary600)
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
              const SizedBox(height: 4),
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
                  const SizedBox(width: 6),
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.neutral600),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.neutral700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
