import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apis/deprecated/reservations_service.dart';
import '../../../presentation/state/providers.dart';
import '../../../presentation/widgets/bottom_nav.dart';
import '../../../presentation/widgets/app_drawer.dart';
import '../../../presentation/screens/auth/login_screen.dart';
import '../../../presentation/widgets/gradient_button.dart';

final _historyProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final authState = ref.watch(authProvider);
    if (authState.user == null) return [];
    return reservationsService.getReservationsForUser(
      int.parse(authState.user!.id),
    );
  },
);

class BookingHistoryScreen extends ConsumerWidget {
  static const String routeName = '/booking_history';
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis Reservas')),
        drawer: const AppDrawer(),
        bottomNavigationBar: const BottomNavBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Inicia sesión para ver tus reservas'),
              const SizedBox(height: 16),
              GradientButton(
                onPressed: () =>
                    Navigator.pushNamed(context, LoginScreen.routeName),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_open, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Iniciar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final historyAsync = ref.watch(_historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas')),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reservas) {
          if (reservas.isEmpty) {
            return const Center(child: Text('No tienes reservas registradas'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final reserva = reservas[index];
              final cancha = reserva['cancha'] ?? {};
              final sede = cancha['sede'] ?? {};
              DateTime fecha;
              try {
                fecha = DateTime.parse(
                  reserva['fechaReserva'] ?? reserva['iniciaEn'],
                );
              } catch (_) {
                fecha = DateTime.now();
              }
              final horaInicio = reserva['horaInicio'] ?? '';
              final horaFin = reserva['horaFin'] ?? '';
              final estado = reserva['estado'] ?? 'PENDIENTE';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(estado),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(cancha['nombre'] ?? 'Cancha'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sede['nombre'] ?? 'Sede desconocida'),
                      Text(
                        '${fecha.day}/${fecha.month}/${fecha.year} • $horaInicio - $horaFin',
                      ),
                      Text(
                        'Estado: $estado',
                        style: TextStyle(
                          color: _getStatusColor(estado),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMADA':
      case 'APROBADA':
        return Colors.green;
      case 'PENDIENTE':
        return Colors.orange;
      case 'CANCELADA':
      case 'RECHAZADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
