import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../widgets/bottom_nav.dart';
import '../../widgets/app_drawer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reserva.dart';
import '../../../data/repositories/qr_repository.dart';
import '../../state/providers.dart';
import '../auth/login_screen.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  static const String routeName = '/qr';

  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  Reserva? currentReserva;
  int? idPaseAcceso;
  int? idPersonaOpe; // ID del operador/controlador
  int? idSede; // ID de la sede
  bool scanning = true;

  final TextEditingController _qrController = TextEditingController();
  final List<ScanResult> scanHistory = [];

  // Control de escaneos duplicados
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  final _qrRepository = QrRepository();

  @override
  void initState() {
    super.initState();
    // Auth guard: redirect to login if not authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (!auth.isAuthenticated) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        return;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Recibir argumentos de navegación
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is Map) {
      final args = Map<String, dynamic>.from(rawArgs);
      currentReserva ??= args['reserva'] as Reserva?;
      idPaseAcceso ??= args['idPaseAcceso'] as int?;
      idPersonaOpe ??= args['idPersonaOpe'] as int?;
      idSede ??= args['idSede'] as int?;
    }
  }

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  // Procesar el escaneo de un código QR
  void _processScan(String qrCode) {
    if (currentReserva == null || qrCode.trim().isEmpty) return;

    // Evitar escaneos duplicados en menos de 2 segundos
    final now = DateTime.now();
    if (_lastScannedCode == qrCode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inSeconds < 2) {
      return; // Ignorar escaneo duplicado
    }

    _lastScannedCode = qrCode;
    _lastScanTime = now;

    // Buscar el cliente por su código QR
    final idx = currentReserva!.clientes.indexWhere((c) => c.qrCode == qrCode);

    ScanResult result;

    if (idx == -1) {
      // QR no pertenece a esta reserva
      result = ScanResult(
        success: false,
        message: 'QR no pertenece a esta reserva',
        type: ScanType.error,
      );
      _showSnackBar('QR no pertenece a esta reserva', isError: true);
    } else {
      final cliente = currentReserva!.clientes[idx];

      if (cliente.escaneado) {
        // QR ya fue escaneado previamente
        result = ScanResult(
          success: false,
          message: 'QR ya registrado',
          type: ScanType.warning,
          cliente: cliente,
        );
        _showSnackBar(
          'QR ya registrado para ${cliente.nombre}',
          isError: false,
        );
      } else {
        // Registrar hora de escaneo
        final hora =
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}:'
            '${now.second.toString().padLeft(2, '0')}';

        // Actualizar cliente como escaneado
        final updated = List<Cliente>.from(currentReserva!.clientes);
        updated[idx] = cliente.copyWith(escaneado: true, horaEscaneo: hora);

        setState(() {
          currentReserva = currentReserva!.copyWith(clientes: updated);
        });

        result = ScanResult(
          success: true,
          message: 'Ingreso autorizado',
          type: ScanType.success,
          cliente: updated[idx],
        );
        _showSnackBar(
          '✓ Ingreso autorizado: ${cliente.nombre}',
          isError: false,
        );
      }
    }

    // Agregar al historial
    setState(() {
      scanHistory.insert(0, result);
      _qrController.clear();
    });
  }

  // Finalizar el proceso de escaneo
  Future<void> _finalizarIngreso() async {
    final total = currentReserva?.totalPersonas ?? 0;
    final scanned =
        currentReserva?.clientes.where((c) => c.escaneado).length ?? 0;

    if (total == 0 || scanned < total) {
      _showSnackBar(
        'Aún faltan personas por escanear ($scanned/$total)',
        isError: true,
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar ingreso'),
        content: Text('¿Confirmar ingreso de $total personas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Asegurar relación trabaja (operador-sede)
      if (idPersonaOpe != null && idSede != null) {
        await _qrRepository.ensureTrabaja(idPersonaOpe!, idSede!);
      }

      // 2. Actualizar pase de acceso
      if (idPaseAcceso != null) {
        await _qrRepository.finalizarPaseAccesoUsos(
          idPaseAcceso: idPaseAcceso!,
          vecesUsado: total,
          estado: 'USADO',
        );
      }

      // 3. Crear registro de control (auditoría)
      if (idPersonaOpe != null &&
          idPaseAcceso != null &&
          currentReserva != null) {
        await _qrRepository.crearControla(
          idPersonaOpe: idPersonaOpe!,
          idReserva: int.parse(currentReserva!.id),
          idPaseAcceso: idPaseAcceso!,
          accion: 'entrada',
          resultado: 'COMPLETADO_$total',
        );
      }

      if (mounted) Navigator.pop(context); // Cerrar loading
      _showSnackBar('✓ Ingreso completado y registrado');
      if (mounted) {
        // Regresar con la reserva actualizada
        Navigator.pop(context, currentReserva);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Cerrar loading
      _showSnackBar('Error al finalizar: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = currentReserva?.totalPersonas ?? 0;
    final scanned =
        currentReserva?.clientes.where((c) => c.escaneado).length ?? 0;
    final pending = total - scanned;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneo de QR'),
        leading: Builder(
          builder: (ctx) {
            final theme = Theme.of(context);
            final bool isDark = theme.brightness == Brightness.dark;
            final Color iconColor = isDark
                ? Colors.white
                : AppColors.neutral700;
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de la reserva
              if (currentReserva != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentReserva!.nombreReserva,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Cancha: ${currentReserva!.cancha}'),
                        Text('Fecha: ${currentReserva!.fecha}'),
                        Text('Hora: ${currentReserva!.hora}'),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Resumen de escaneos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Personas pendientes'),
                          Text(
                            '$pending de $total',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Escaneados'),
                          Text(
                            '$scanned',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Barra de progreso
              LinearProgressIndicator(
                value: total == 0 ? 0 : scanned / total,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),

              const SizedBox(height: 16),

              // Visor de cámara
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Visor de Cámara',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Chip(
                            label: Text(scanning ? 'Activo' : 'Detenido'),
                            backgroundColor: scanning
                                ? Colors.green.shade100
                                : Colors.grey.shade300,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Escáner QR
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: MobileScanner(
                          controller: MobileScannerController(
                            facing: CameraFacing.back,
                            torchEnabled: false,
                          ),
                          onDetect: (capture) {
                            if (!scanning) return;

                            final barcodes = capture.barcodes;
                            if (barcodes.isEmpty) return;

                            final raw = barcodes.first.rawValue ?? '';
                            if (raw.isEmpty) return;

                            _processScan(raw);
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Input manual
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _qrController,
                              enabled: scanning,
                              decoration: const InputDecoration(
                                hintText: 'Código QR manual...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed:
                                (!scanning || _qrController.text.trim().isEmpty)
                                ? null
                                : () => _processScan(_qrController.text),
                            child: const Text('Escanear'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Historial de escaneos
              if (scanHistory.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historial de Escaneos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...scanHistory.map((r) {
                          Color color;
                          IconData icon;
                          switch (r.type) {
                            case ScanType.success:
                              color = Colors.green.shade100;
                              icon = Icons.check_circle;
                              break;
                            case ScanType.warning:
                              color = Colors.orange.shade100;
                              icon = Icons.warning;
                              break;
                            case ScanType.error:
                              color = Colors.red.shade100;
                              icon = Icons.error;
                              break;
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.cliente != null
                                            ? r.cliente!.nombre
                                            : r.message,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (r.cliente != null)
                                        Text(
                                          r.message,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                if (r.cliente?.horaEscaneo != null)
                                  Text(
                                    r.cliente!.horaEscaneo!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
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

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => scanning = !scanning),
                      icon: Icon(scanning ? Icons.pause : Icons.play_arrow),
                      label: Text(scanning ? 'Detener' : 'Reanudar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _finalizarIngreso,
                      icon: const Icon(Icons.check),
                      label: const Text('Finalizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
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
