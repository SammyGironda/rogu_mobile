import 'package:flutter/material.dart';
import '../models/field.dart';
import '../models/venue.dart';
import '../theme/theme.dart';
import 'select_slot_screen.dart';

class FieldDetailScreen extends StatelessWidget {
  final Field field;
  final Venue venue;
  const FieldDetailScreen({
    super.key,
    required this.field,
    required this.venue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(field.nombre)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImagesCarousel(
              images: field.fotos.isNotEmpty
                  ? field.fotos
                  : (venue.fotoPrincipal != null ? [venue.fotoPrincipal!] : []),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.nombre,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    venue.nombre,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (field.descripcion != null &&
                      field.descripcion!.isNotEmpty)
                    Text(field.descripcion!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  HoursBox(isDark: isDark),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Aquí se integrará el flujo de creación de reserva (horarios / checkout)
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SelectSlotScreen(field: field, venue: venue),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Realizar la reserva'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImagesCarousel extends StatefulWidget {
  final List<String> images;
  const ImagesCarousel({required this.images});
  @override
  State<ImagesCarousel> createState() => _ImagesCarouselState();
}

class _ImagesCarouselState extends State<ImagesCarousel> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 200,
        color: AppColors.primary100,
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: 48, color: AppColors.primary600),
      );
    }
    return Stack(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (_, i) {
              final img = widget.images[i];
              return Image.network(
                img,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primary100,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image, color: AppColors.primary600),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final active = i == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: active ? 20 : 8,
                decoration: BoxDecoration(
                  color: active ? AppColors.secondary500 : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class HoursBox extends StatelessWidget {
  final bool isDark;
  const HoursBox({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.neutral800 : AppColors.neutral100;
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horarios de Atención',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Lunes - Domingo: 08:00 - 22:00',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Nota: Ajustar con datos reales del backend si están disponibles.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}
