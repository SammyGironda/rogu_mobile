import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav.dart';
import '../qr/qr_scanner_screen.dart';
import 'reservation_detail_screen.dart';
import '../../../data/models/reserva.dart' as model;
import '../../../data/repositories/pending_reservations_repository.dart';
import '../../state/providers.dart';

class PendingReservationsScreen extends ConsumerStatefulWidget {
  static const String routeName = '/reservas/pendientes';

  const PendingReservationsScreen({super.key});

  @override
  ConsumerState<PendingReservationsScreen> createState() => _PendingReservationsScreenState();
}

class _PendingReservationsScreenState extends ConsumerState<PendingReservationsScreen> {
  List<model.Reserva> _reservas = const [];
  int? _sedeId;
  String? _role;
  final _repo = PendingReservationsRepository();

  @override
  void initState() {
    super.initState();
    // Carga inicial vacía; se resolverá en didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Exigir sesión activa
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para ver reservas pendientes')),
        );
        Navigator.pushNamed(context, '/login');
      });
      return;
    }
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is Map) {
      final args = Map<String, dynamic>.from(rawArgs);
      _sedeId = args['idSede'] as int?;
      _role = args['role'] as String?;
      // Role guard: only ADMIN, DUENIO, CONTROLADOR allowed
      const allowed = {'ADMIN', 'DUENIO', 'CONTROLADOR'};
      if (_role == null || !allowed.contains(_role)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No autorizado: acceso solo para administradores, dueños y controladores')),
          );
          Navigator.pop(context);
        });
        return;
      }
      if (_sedeId != null) {
        // Cargar desde API por sede
        _loadFromApi(_sedeId!);
      }
    }
  }

  Future<void> _loadFromApi(int idSede) async {
    try {
      final data = await _repo.loadPendingBySede(idSede: idSede);
      if (!mounted) return;
      setState(() {
        _reservas = data;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando reservas: ${e.toString()}')),
      );
    }
  }

  void _openReservationDetail(model.Reserva reserva) {
    Navigator.pushNamed(
      context,
      ReservationDetailScreen.routeName,
      arguments: {
        'reserva': reserva,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas en sede'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.pushNamed(context, QRScannerScreen.routeName),
            tooltip: 'Escanear QR',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(
        child: _reservas.isEmpty
            ? Center(
                child: Card(
                  color: AppColors.card,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(height: 8),
                        Icon(Icons.calendar_today, size: 48, color: AppColors.mutedForeground),
                        SizedBox(height: 12),
                        Text('No hay reservas en esta sede'),
                        SizedBox(height: 6),
                        Text(
                          'Las reservas aparecerán aquí cuando estén disponibles para escanear su código QR.',
                          style: TextStyle(color: AppColors.mutedForeground),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: _reservas.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final r = _reservas[index];
                  Color estadoBg;
                  Color estadoFg;
                  switch (r.estado) {
                    case 'completada':
                      estadoBg = AppColors.success;
                      estadoFg = AppColors.successForeground;
                      break;
                    case 'en_proceso':
                      estadoBg = AppColors.primary500;
                      estadoFg = AppColors.primaryForeground;
                      break;
                    default:
                      estadoBg = AppColors.warning;
                      estadoFg = AppColors.warningForeground;
                  }

                  return Card(
                    color: AppColors.card,
                    child: InkWell(
                      onTap: () => _openReservationDetail(r),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.nombreReserva, style: theme.textTheme.titleLarge),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.group, size: 16, color: AppColors.mutedForeground),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${r.totalPersonas} personas autorizadas',
                                            style: const TextStyle(color: AppColors.mutedForeground),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(r.estado),
                                  backgroundColor: estadoBg,
                                  labelStyle: TextStyle(color: estadoFg),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Grid info
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary500.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.calendar_today, color: AppColors.primary500),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Fecha', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                        Text(r.fecha),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.access_time, color: AppColors.secondary),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Hora', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                        Text('${r.hora} hrs'),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.place, color: AppColors.accentForeground),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Cancha', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                        Text(r.cancha),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _openReservationDetail(r),
                                child: const Text('Ver Detalles'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
