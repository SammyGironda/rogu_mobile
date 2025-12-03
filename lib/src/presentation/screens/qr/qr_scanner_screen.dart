/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/bottom_nav.dart';
import '../../widgets/app_drawer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reserva.dart' as model;

class QRScannerScreen extends ConsumerStatefulWidget {
  static const String routeName = '/qr';

  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  late List<Booking> bookings;
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    // Cargar reservas (mock) para evitar pantalla vacía
    bookings = [
      Booking(
        id: 'R-2001',
        representative: 'Equipo Águilas',
        courtName: 'Cancha Principal',
        date: '2025-12-05',
        time: '18:00',
        status: 'aprobada',
        participants: [
          Participant(id: 'P1', name: 'Carlos'),
          Participant(id: 'P2', name: 'Ana'),
        ],
      ),
      Booking(
        id: 'R-2002',
        representative: 'Club Titanes',
        courtName: 'Cancha 2',
        date: '2025-12-06',
        time: '19:30',
        status: 'pendiente',
        participants: [
          Participant(id: 'P3', name: 'Luis'),
          Participant(id: 'P4', name: 'María'),
        ],
      ),
    ];
  }

  void _toggleExpanded(String bookingId) {
    setState(() {
      _expanded[bookingId] = !(_expanded[bookingId] ?? false);
    });
  }

  Future<void> _showScanDialog(BuildContext context, Booking booking) async {
    bool scanned = false;
    late model.Reserva? currentReserva;
    bool scanning = true;
    final TextEditingController _qrController = TextEditingController();
    final List<model.ScanResult> scanHistory = [];
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
                                ),
    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map<String, dynamic>;
      currentReserva ??= args['reserva'] as model.Reserva?;
    }

    void _processScan(String qrCode) {
      if (currentReserva == null || qrCode.trim().isEmpty) return;

      final idx = currentReserva!.clientes.indexWhere((c) => c.qrCode == qrCode);
      model.ScanResult result;
      if (idx == -1) {
        result = model.ScanResult(success: false, message: 'QR no pertenece a esta reserva', type: model.ScanType.error);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR no pertenece a esta reserva')));
      } else {
        final cliente = currentReserva!.clientes[idx];
        if (cliente.escaneado) {
          result = model.ScanResult(success: false, message: '${cliente.nombre} ya fue registrado', type: model.ScanType.warning, cliente: cliente);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${cliente.nombre} ya fue registrado')));
        } else {
          final now = DateTime.now();
          final hora = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
          final updated = List<model.Cliente>.from(currentReserva!.clientes);
          updated[idx] = cliente.copyWith(escaneado: true, horaEscaneo: hora);
          setState(() {
            currentReserva = currentReserva!.copyWith(clientes: updated);
          });
          result = model.ScanResult(success: true, message: '✓ ${cliente.nombre} - Ingreso autorizado', type: model.ScanType.success, cliente: updated[idx]);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingreso autorizado: ${cliente.nombre}')));
        }
      }
      setState(() {
        scanHistory.insert(0, result);
        _qrController.clear();
      });
    }
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Si existe alguna reserva, usa la primera para demo; sino muestra diálogo básico
                            title: const Text('Escaneo de QR'),
                              ? bookings.first
                              : Booking(
                                  id: 'R-DEMO',
                                  representative: 'Demo',
                                  courtName: 'Cancha',
                                  date: '2025-12-05',
                                  time: '18:00',
                                  status: 'pendiente',
                                  participants: [],
                                );
                          _showScanDialog(context, demo);
                        },
                        child: const Text('Iniciar Escaneo'),
                      ),
                    ],
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Counters card
                                  Card(
                                    color: AppColors.card,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary500,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.group, color: AppColors.primaryForeground),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Personas pendientes', style: TextStyle(color: AppColors.mutedForeground)),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        ((currentReserva?.totalPersonas ?? 0) - (currentReserva?.clientes.where((c) => c.escaneado).length ?? 0)).toString(),
                                                        style: const TextStyle(fontSize: 24),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text('de ${currentReserva?.totalPersonas ?? 0}', style: const TextStyle(color: AppColors.mutedForeground)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('Escaneados', style: TextStyle(color: AppColors.mutedForeground)),
                                              Text(
                                                '${currentReserva?.clientes.where((c) => c.escaneado).length ?? 0}',
                                                style: const TextStyle(fontSize: 24, color: AppColors.secondary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Progress bar
                                  Container(
                                    width: double.infinity,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.muted,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: (currentReserva == null || (currentReserva!.totalPersonas == 0))
                                            ? 0
                                            : (currentReserva!.clientes.where((c) => c.escaneado).length / currentReserva!.totalPersonas),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [AppColors.primary500, AppColors.secondary]),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Camera viewer (simulated)
                                  Card(
                                    color: AppColors.card,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Visor de Cámara'),
                                              Chip(
                                                label: Text(scanning ? 'Activo' : 'Detenido'),
                                                backgroundColor: scanning ? AppColors.success : AppColors.muted,
                                                labelStyle: TextStyle(color: scanning ? AppColors.successForeground : AppColors.foreground),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            height: 200,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(colors: [Color(0xFF0B0B0E), Color(0xFF121217)]),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.camera_alt, size: 40, color: Color(0xFF6B7280)),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: _qrController,
                                                  enabled: scanning,
                                                  decoration: const InputDecoration(
                                                    hintText: 'Ingresa el código QR manualmente...',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: (!scanning || _qrController.text.trim().isEmpty)
                                                    ? null
                                                    : () => _processScan(_qrController.text),
                                                child: const Text('Escanear'),
                                              ),
                                            ],
                                          ),
                                          if (currentReserva?.clientes.isNotEmpty ?? false)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6.0),
                                              child: Text(
                                                'Ejemplo: ${currentReserva!.clientes.first.qrCode}',
                                                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Scan history
                                  if (scanHistory.isNotEmpty)
                                    Card(
                                      color: AppColors.card,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Historial de Escaneos'),
                                            const SizedBox(height: 8),
                                            ...scanHistory.map((r) {
                                              Color bg;
                                              Color border;
                                              switch (r.type) {
                                                case model.ScanType.success:
                                                  bg = const Color(0xFF062615);
                                                  border = const Color(0xFF1C6B3C);
                                                  break;
                                                case model.ScanType.warning:
                                                  bg = const Color(0xFF3A2A00);
                                                  border = const Color(0xFF8A5E00);
                                                  break;
                                                case model.ScanType.error:
                                                  bg = const Color(0xFF2C0A0A);
                                                  border = const Color(0xFF7A2020);
                                                  break;
                                              }
                                              return Container(
                                                margin: const EdgeInsets.symmetric(vertical: 4),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: bg,
                                                  border: Border.all(color: border),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(child: Text(r.message)),
                                                    if (r.cliente?.horaEscaneo != null)
                                                      Text(
                                                        r.cliente!.horaEscaneo!,
                                                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  // Pending clients quick simulate
                                  Card(
                                    color: AppColors.card,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Clientes Pendientes (Click para simular)'),
                                          const SizedBox(height: 8),
                                          ...((currentReserva?.clientes ?? const <model.Cliente>[])
                                              .where((c) => !c.escaneado)
                                              .map((c) => InkWell(
                                                    onTap: scanning ? () => _processScan(c.qrCode) : null,
                                                    child: Container(
                                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(color: AppColors.border),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 40,
                                                            height: 40,
                                                            decoration: BoxDecoration(
                                                              color: AppColors.muted,
                                                              borderRadius: BorderRadius.circular(20),
                                                            ),
                                                            child: const Icon(Icons.qr_code, color: AppColors.mutedForeground),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(c.nombre),
                                                                Text('QR: ${c.qrCode}', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ))
                                              .toList()),
                                          if ((currentReserva?.clientes.where((c) => !c.escaneado).length ?? 0) == 0)
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 24),
                                              child: Center(
                                                child: Text('¡Todos los clientes han sido escaneados!'),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Action buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => setState(() => scanning = !scanning),
                                          child: Text(scanning ? 'Detener Escaneo' : 'Reanudar Escaneo'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(context, currentReserva),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.secondaryForeground),
                                          child: const Text('Finalizar Ingreso'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            child: const Text('Calificar'),
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/bottom_nav.dart';
import '../../widgets/app_drawer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reserva.dart' as model;

class QRScannerScreen extends ConsumerStatefulWidget {
  static const String routeName = '/qr';
  const QRScannerScreen({super.key});
  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  model.Reserva? currentReserva;
  bool scanning = true;
  final TextEditingController _qrController = TextEditingController();
  final List<model.ScanResult> scanHistory = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is Map) {
      final args = Map<String, dynamic>.from(rawArgs);
      currentReserva ??= args['reserva'] as model.Reserva?;
    }
  }

  void _processScan(String qrCode) {
    if (currentReserva == null || qrCode.trim().isEmpty) return;

    final idx = currentReserva!.clientes.indexWhere((c) => c.qrCode == qrCode);
    model.ScanResult result;
    if (idx == -1) {
      result = model.ScanResult(success: false, message: 'QR no pertenece a esta reserva', type: model.ScanType.error);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR no pertenece a esta reserva')));
    } else {
      final cliente = currentReserva!.clientes[idx];
      if (cliente.escaneado) {
        result = model.ScanResult(success: false, message: '${cliente.nombre} ya fue registrado', type: model.ScanType.warning, cliente: cliente);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${cliente.nombre} ya fue registrado')));
      } else {
        final now = DateTime.now();
        final hora = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        final updated = List<model.Cliente>.from(currentReserva!.clientes);
        updated[idx] = cliente.copyWith(escaneado: true, horaEscaneo: hora);
        setState(() {
          currentReserva = currentReserva!.copyWith(clientes: updated);
        });
        result = model.ScanResult(success: true, message: '✓ ${cliente.nombre} - Ingreso autorizado', type: model.ScanType.success, cliente: updated[idx]);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingreso autorizado: ${cliente.nombre}')));
      }
    }
    setState(() {
      scanHistory.insert(0, result);
      _qrController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneo de QR'),
        leading: Builder(
          builder: (ctx) {
            final theme = Theme.of(context);
            final bool isDark = theme.brightness == Brightness.dark;
            final Color iconColor = isDark ? AppColors.foreground : AppColors.foreground;
            return IconButton(
              icon: Icon(Icons.menu, color: iconColor),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppColors.card,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.primary500,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.group, color: AppColors.primaryForeground),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Personas pendientes', style: TextStyle(color: AppColors.mutedForeground)),
                              Row(
                                children: [
                                  Text(
                                    ((currentReserva?.totalPersonas ?? 0) - (currentReserva?.clientes.where((c) => c.escaneado).length ?? 0)).toString(),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('de ${currentReserva?.totalPersonas ?? 0}', style: const TextStyle(color: AppColors.mutedForeground)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Escaneados', style: TextStyle(color: AppColors.mutedForeground)),
                          Text(
                            '${currentReserva?.clientes.where((c) => c.escaneado).length ?? 0}',
                            style: const TextStyle(fontSize: 24, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (currentReserva == null || (currentReserva!.totalPersonas == 0))
                        ? 0
                        : (currentReserva!.clientes.where((c) => c.escaneado).length / currentReserva!.totalPersonas),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary500, AppColors.secondary]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.card,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Visor de Cámara'),
                          Chip(
                            label: Text(scanning ? 'Activo' : 'Detenido'),
                            backgroundColor: scanning ? AppColors.success : AppColors.muted,
                            labelStyle: TextStyle(color: scanning ? AppColors.successForeground : AppColors.foreground),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0B0B0E), Color(0xFF121217)]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Icon(Icons.camera_alt, size: 40, color: Color(0xFF6B7280)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _qrController,
                              enabled: scanning,
                              decoration: const InputDecoration(
                                hintText: 'Ingresa el código QR manualmente...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: (!scanning || _qrController.text.trim().isEmpty)
                                ? null
                                : () => _processScan(_qrController.text),
                            child: const Text('Escanear'),
                          ),
                        ],
                      ),
                      if (currentReserva?.clientes.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            'Ejemplo: ${currentReserva!.clientes.first.qrCode}',
                            style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (scanHistory.isNotEmpty)
                Card(
                  color: AppColors.card,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Historial de Escaneos'),
                        const SizedBox(height: 8),
                        ...scanHistory.map((r) {
                          Color bg;
                          Color border;
                          switch (r.type) {
                            case model.ScanType.success:
                              bg = const Color(0xFF062615);
                              border = const Color(0xFF1C6B3C);
                              break;
                            case model.ScanType.warning:
                              bg = const Color(0xFF3A2A00);
                              border = const Color(0xFF8A5E00);
                              break;
                            case model.ScanType.error:
                              bg = const Color(0xFF2C0A0A);
                              border = const Color(0xFF7A2020);
                              break;
                          }
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bg,
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(r.message)),
                                if (r.cliente?.horaEscaneo != null)
                                  Text(
                                    r.cliente!.horaEscaneo!,
                                    style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.card,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Clientes Pendientes (Click para simular)'),
                      const SizedBox(height: 8),
                      ...((currentReserva?.clientes ?? const <model.Cliente>[])
                          .where((c) => !c.escaneado)
                          .map((c) => InkWell(
                                onTap: scanning ? () => _processScan(c.qrCode) : null,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.muted,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(Icons.qr_code, color: AppColors.mutedForeground),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c.nombre),
                                            Text('QR: ${c.qrCode}', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList()),
                      if ((currentReserva?.clientes.where((c) => !c.escaneado).length ?? 0) == 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('¡Todos los clientes han sido escaneados!'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => scanning = !scanning),
                      child: Text(scanning ? 'Detener Escaneo' : 'Reanudar Escaneo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, currentReserva),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.secondaryForeground),
                      child: const Text('Finalizar Ingreso'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
