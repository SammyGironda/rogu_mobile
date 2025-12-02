import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/field.dart';
import '../../../data/models/venue.dart';
import '../../../data/repositories/reservations_repository.dart';
import '../../state/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_helper.dart';
import '../auth/login_screen.dart';

final _dateProvider = StateProvider.autoDispose<DateTime>(
  (ref) => DateTime.now(),
);
final _selectedSlotsProvider = StateProvider.autoDispose<List<ReservationSlot>>(
  (ref) => [],
);

final _reservationsProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, int>((ref, idCancha) async {
      final date = ref.watch(_dateProvider);
      final reservationsRepo = ReservationsRepository();
      return await reservationsRepo.getFieldReservations(
        idCancha: idCancha,
        fecha: date,
      );
    });

class SelectSlotScreen extends ConsumerWidget {
  final Field field;
  final Venue venue;

  const SelectSlotScreen({super.key, required this.field, required this.venue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(_dateProvider);
    final existingAsync = ref.watch(_reservationsProvider(field.id));
    final selectedSlots = ref.watch(_selectedSlotsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Horarios - ${field.nombre}')),
      body: Column(
        children: [
          Expanded(
            child: existingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (reservas) {
                final reservationsRepo = ReservationsRepository();
                final slots = reservationsRepo.buildSlots(reservas);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DatePicker(date: date, idCancha: field.id),
                    const SizedBox(height: 16),
                    Text(
                      'Selecciona los horarios',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Puedes seleccionar múltiples horas consecutivas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: slots.map((s) {
                        final disabled = s.ocupado;
                        final isSelected = selectedSlots.contains(s);
                        return ElevatedButton(
                          onPressed: disabled
                              ? null
                              : () {
                                  _toggleSlot(ref, s);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: disabled
                                ? AppColors.neutral300
                                : (isSelected
                                      ? AppColors.primary700
                                      : AppColors.primary500),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            side: isSelected
                                ? const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${s.horaInicio.substring(0, 5)} - ${s.horaFin.substring(0, 5)}',
                              ),
                              disabled
                                  ? const Text(
                                      'Ocupado',
                                      style: TextStyle(fontSize: 11),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
          if (selectedSlots.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${selectedSlots.length} horas seleccionadas'),
                        Text(
                          'Total: \$${_calculateTotal(selectedSlots.length)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _confirm(context, ref, authState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('CONFIRMAR RESERVA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleSlot(WidgetRef ref, ReservationSlot slot) {
    final current = ref.read(_selectedSlotsProvider);
    if (current.contains(slot)) {
      ref.read(_selectedSlotsProvider.notifier).state = current
          .where((x) => x != slot)
          .toList();
    } else {
      ref.read(_selectedSlotsProvider.notifier).state = [...current, slot];
    }
  }

  double _calculateTotal(int hours) {
    final price = field.precio ?? 0;
    return price * hours;
  }

  void _confirm(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) async {
    if (!authState.isAuthenticated || authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para reservar')),
      );
      Navigator.pushNamed(context, LoginScreen.routeName);
      return;
    }

    final selected = ref.read(_selectedSlotsProvider);
    // Sort slots by time
    selected.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));

    // Check continuity
    for (int i = 0; i < selected.length - 1; i++) {
      if (selected[i].horaFin != selected[i + 1].horaInicio) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona horarios consecutivos'),
          ),
        );
        return;
      }
    }

    final startSlot = selected.first;
    final endSlot = selected.last;

    final date = ref.read(_dateProvider);
    final start = _buildDateTime(date, startSlot.horaInicio);
    final end = _buildDateTime(date, endSlot.horaFin);

    try {
      final token = await StorageHelper.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final reservationsRepo = ReservationsRepository();
      final resp = await reservationsRepo.createReservation(
        idCliente: int.parse(authState.user!.id),
        idCancha: field.id,
        inicia: start,
        termina: end,
        cantidadPersonas: 10,
        requiereAprobacion: false,
        montoBase: _calculateTotal(selected.length),
        montoExtra: 0,
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Reserva creada'),
            content: Text(
              'Tu reserva ha sido confirmada.\nID: ${resp['reserva']?['idReserva'] ?? 'N/A'}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close screen
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  DateTime _buildDateTime(DateTime date, String hhmmss) {
    final parts = hhmmss.split(':');
    final h = int.parse(parts[0]);
    return DateTime(date.year, date.month, date.day, h, 0);
  }
}

class _DatePicker extends ConsumerWidget {
  final DateTime date;
  final int idCancha;
  const _DatePicker({required this.date, required this.idCancha});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Fecha: ${date.toIso8601String().split('T').first}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now(),
              lastDate: DateTime(DateTime.now().year + 1),
            );
            if (picked != null) {
              ref.read(_dateProvider.notifier).state = picked;
              // Clear selection when date changes
              ref.read(_selectedSlotsProvider.notifier).state = [];
            }
          },
          child: const Text('Cambiar'),
        ),
      ],
    );
  }
}
