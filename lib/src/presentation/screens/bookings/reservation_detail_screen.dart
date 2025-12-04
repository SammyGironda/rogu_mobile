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
        title: const Text('Detalle de Reservas'),
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
                                const Text('Reservado por', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
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
                              const Text('Fecha de ingreso', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
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
                              const Text('Hora de ingreso', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
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
              // Sección de clientes autorizados removida según requerimiento
            ],
          ),
        ),
      ),
    );
  }
}
