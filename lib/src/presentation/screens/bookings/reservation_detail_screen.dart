import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../qr/qr_scanner_screen.dart';
import '../../../data/models/reserva.dart' as model;

class ReservationDetailScreen extends StatelessWidget {
  static const String routeName = '/reservas/detalle';

  const ReservationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    model.Reserva? reserva;
    if (rawArgs is Map) {
      final args = Map<String, dynamic>.from(rawArgs);
      reserva = args['reserva'] as model.Reserva?;
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Reserva'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.pushNamed(
              context,
              QRScannerScreen.routeName,
              arguments: {'reserva': reserva},
            ),
            tooltip: 'Escanear QR',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppColors.card,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.group, color: AppColors.primary500),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nombre de la Reserva', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                Text(reserva?.nombreReserva ?? '-', style: theme.textTheme.titleMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_today, color: AppColors.primary500),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fecha', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                              Text(reserva?.fecha ?? '-'),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.access_time, color: AppColors.secondary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hora', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                              Text('${reserva?.hora ?? '-'} hrs'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.place, color: AppColors.accentForeground),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Cancha', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                Text(reserva?.cancha ?? '-'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            label: Text(reserva?.estado ?? 'pendiente'),
                            backgroundColor: AppColors.warning,
                            labelStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.warningForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        QRScannerScreen.routeName,
                        arguments: {'reserva': reserva},
                      ),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Iniciar Escaneo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.card,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clientes Autorizados (${reserva?.totalPersonas ?? 0})'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          itemCount: reserva?.clientes.length ?? 0,
                          itemBuilder: (context, index) {
                            final c = reserva!.clientes[index];
                            final scanned = c.escaneado;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scanned ? AppColors.success.withOpacity(0.2) : AppColors.card,
                                border: Border.all(color: scanned ? AppColors.success : AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary500.withOpacity(0.1),
                                    child: Text(c.nombre.isNotEmpty ? c.nombre[0] : '?', style: const TextStyle(color: AppColors.foreground)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.nombre),
                                        Text('Doc: ${c.documento}', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (scanned)
                                    const Chip(
                                      label: Text('Escaneado'),
                                      backgroundColor: AppColors.success,
                                      labelStyle: TextStyle(color: AppColors.successForeground),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
