import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/bottom_nav.dart';
import '../../widgets/app_drawer.dart';
import '../../../core/theme/app_theme.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/models/reserva.dart' as model;
import '../../../../services/qr_api_service.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  static const String routeName = '/qr';
  const QRScannerScreen({super.key});
  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  model.Reserva? currentReserva;
  int? idPaseAcceso;
  int? idPersonaOpe; // TODO: supply from auth/profile state
  int? idSede; // TODO: supply from reservation/sede context
  bool scanning = true;
  final TextEditingController _qrController = TextEditingController();
  final List<model.ScanResult> scanHistory = [];
  final List<int> _scanNumbers = [];
  final List<String> _scanTimes = [];
  int _scanCounter = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is Map) {
      final args = Map<String, dynamic>.from(rawArgs);
      currentReserva ??= args['reserva'] as model.Reserva?;
      idPaseAcceso ??= (args['idPaseAcceso'] as int?);
      idPersonaOpe ??= (args['idPersonaOpe'] as int?);
      idSede ??= (args['idSede'] as int?);
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
        result = model.ScanResult(success: false, message: 'QR ya registrado', type: model.ScanType.warning, cliente: cliente);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR ya registrado')));
      } else {
        final now = DateTime.now();
        final hora = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        final updated = List<model.Cliente>.from(currentReserva!.clientes);
        updated[idx] = cliente.copyWith(escaneado: true, horaEscaneo: hora);
        setState(() {
          currentReserva = currentReserva!.copyWith(clientes: updated);
        });
        result = model.ScanResult(success: true, message: 'Ingreso autorizado', type: model.ScanType.success, cliente: updated[idx]);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingreso autorizado')));
      }
    }
    final now2 = DateTime.now();
    final hora2 = '${now2.hour.toString().padLeft(2, '0')}:${now2.minute.toString().padLeft(2, '0')}:${now2.second.toString().padLeft(2, '0')}';
    setState(() {
      scanHistory.insert(0, result);
      _scanCounter += 1;
      _scanNumbers.insert(0, _scanCounter);
      _scanTimes.insert(0, hora2);
      _qrController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneo de QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/reservas/pendientes');
            }
          },
        ),
        actions: [
          Builder(
            builder: (ctx) {
              final theme = Theme.of(context);
              final bool isDark = theme.brightness == Brightness.dark;
              final Color iconColor = isDark ? AppColors.foreground : AppColors.foreground;
              return IconButton(
                icon: Icon(Icons.menu, color: iconColor),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menú',
              );
            },
          ),
        ],
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
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: MobileScanner(
                          controller: MobileScannerController(
                            facing: CameraFacing.back,
                            torchEnabled: false,
                          ),
                          onDetect: (capture) {
                            final barcodes = capture.barcodes;
                            if (barcodes.isEmpty) return;
                            final raw = barcodes.first.rawValue ?? '';
                            if (raw.isEmpty) return;
                            _processScan(raw);
                          },
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
                        ...scanHistory.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value;
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
                                Expanded(child: Text('Escaneo ${_scanNumbers[i]}')),
                                Text(
                                  _scanTimes[i],
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
              // Clientes Pendientes section removed per requirements
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
                      onPressed: () async {
                        // Persist aggregated results only when pending reaches 0
                        final total = currentReserva?.totalPersonas ?? 0;
                        final scanned = currentReserva?.clientes.where((c) => c.escaneado).length ?? 0;
                        if (total == 0 || scanned < total) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Aún faltan personas por escanear')),
                          );
                          return;
                        }
                        try {
                          final api = QrApiService(baseUrl: 'http://localhost:3000/api');
                          if (idPersonaOpe != null && idSede != null) {
                            await api.ensureTrabaja(idPersonaOpe!, idSede!);
                          }
                          if (idPaseAcceso != null) {
                            await api.finalizarPaseAccesoUsos(
                              idPaseAcceso: idPaseAcceso!,
                              vecesUsado: total,
                              estado: 'USADO',
                            );
                          }
                          if (idPersonaOpe != null && idPaseAcceso != null && currentReserva != null) {
                            await api.crearControla(
                              idPersonaOpe: idPersonaOpe!,
                              idReserva: int.parse(currentReserva!.id),
                              idPaseAcceso: idPaseAcceso!,
                              accion: 'entrada',
                              resultado: 'COMPLETADO_$total',
                            );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ingreso completado y registrado')),
                          );
                          if (mounted) Navigator.pop(context, currentReserva);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al finalizar: $e')),
                          );
                        }
                      },
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
