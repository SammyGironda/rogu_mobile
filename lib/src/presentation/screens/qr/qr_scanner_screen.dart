import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../data/models/qr_models.dart';
import '../../../data/repositories/qr_repository.dart';
import '../../state/providers.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav.dart';
import 'dart:convert';

class QRScannerScreen extends ConsumerStatefulWidget {
  static const String routeName = '/qr/scanner';

  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final _qrRepository = QrRepository();
  bool _scanning = true;
  String? _lastCode;
  DateTime? _lastScanTime;
  final List<_ScanResult> _history = [];
  Map<String, dynamic>? _lastResult;

  PaseAccesoResumen? pase;
  SedeAsignada? sede;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is Map) {
      final args = Map<String, dynamic>.from(rawArgs);
      pase = args['pase'] as PaseAccesoResumen?;
      sede = args['sede'] as SedeAsignada?;
    }
  }

  Future<void> _processScan(String qrCode) async {
    if (qrCode.trim().isEmpty) return;

    final now = DateTime.now();
    if (_lastCode == qrCode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inSeconds < 2) {
      return;
    }
    _lastCode = qrCode;
    _lastScanTime = now;

    final auth = ref.read(authProvider);
    final personaId = int.tryParse(auth.user?.personaId ?? '');

    setState(() => _scanning = false);

    try {
      // Extraer codigoQR real si el payload es JSON
      String codigoQrLimpio = qrCode;
      try {
        final decoded = jsonDecode(qrCode);
        if (decoded is Map && decoded['codigo'] != null) {
          codigoQrLimpio = decoded['codigo'].toString();
        }
      } catch (_) {
        // no es JSON, usamos el raw
      }

      final res = await _qrRepository.validateQr(
        qrCode: codigoQrLimpio,
        accion: 'entrada',
        idPersonaOpe: personaId,
      );

      final ok = res['valido'] == true;
      final msg = res['mensaje']?.toString() ?? (ok ? 'Acceso permitido' : 'Acceso denegado');
      final motivo = res['motivo']?.toString() ?? '';

      // Actualizar usos del pase con la respuesta en vivo
      if (pase != null && res['cupos'] is Map) {
        final cupos = Map<String, dynamic>.from(res['cupos']);
        final usados = cupos['usados'] is int
            ? cupos['usados'] as int
            : int.tryParse(cupos['usados']?.toString() ?? '');
        final maximo = cupos['total'] is int
            ? cupos['total'] as int
            : int.tryParse(cupos['total']?.toString() ?? '');
        setState(() {
          pase = pase!.copyWith(
            usados: usados ?? pase!.usados,
            maximo: maximo ?? pase!.maximo,
            estado: res['reserva']?['estado']?.toString() ?? pase!.estado,
          );
        });
      }

      setState(() {
        _lastResult = res;
        _history.insert(
          0,
          _ScanResult(
            code: qrCode,
            success: ok,
            message: '$msg${motivo.isNotEmpty ? ' ($motivo)' : ''}',
            timestamp: DateTime.now(),
          ),
        );
      });

      _showSnackBar(msg, isError: !ok);
    } catch (e) {
      _showSnackBar('Error al validar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _scanning = true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear pase'),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pase != null)
                _PaseInfoCard(pase: pase!, sedeNombre: sede?.nombre),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Visor de cámara', style: TextStyle(fontWeight: FontWeight.bold)),
                          Chip(
                            label: Text(_scanning ? 'Activo' : 'Procesando'),
                            backgroundColor:
                                _scanning ? Colors.green.shade100 : Colors.orange.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: MobileScanner(
                          controller: MobileScannerController(
                            facing: CameraFacing.back,
                            torchEnabled: false,
                          ),
                          onDetect: (capture) {
                            if (!_scanning) return;
                            final barcodes = capture.barcodes;
                            if (barcodes.isEmpty) return;
                            final raw = barcodes.first.rawValue ?? '';
                            if (raw.isEmpty) return;
                            _processScan(raw);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_lastResult != null) ...[
                _ResultCard(result: _lastResult!),
                const SizedBox(height: 12),
              ],
              if (_history.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._history.map(
                          (h) => ListTile(
                            dense: true,
                            leading: Icon(
                              h.success ? Icons.check_circle : Icons.error,
                              color: h.success ? Colors.green : Colors.red,
                            ),
                            title: Text(h.message),
                            subtitle: Text(h.timestamp.toLocal().toString()),
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

class _PaseInfoCard extends StatelessWidget {
  final PaseAccesoResumen pase;
  final String? sedeNombre;
  const _PaseInfoCard({required this.pase, this.sedeNombre});

  @override
  Widget build(BuildContext context) {
    final usos = '${pase.usados}/${pase.maximo}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pase.canchaNombre ?? 'Cancha',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (sedeNombre != null) Text('Sede: $sedeNombre'),
            if (pase.clienteCompleto.isNotEmpty) Text('Cliente: ${pase.clienteCompleto}'),
            if (pase.iniciaEn != null && pase.terminaEn != null)
              Text(
                'Horario: ${pase.iniciaEn} - ${pase.terminaEn}',
                style: const TextStyle(fontSize: 12),
              ),
            Text('Estado: ${pase.estado}'),
            Text('Usos: $usos'),
            if (pase.validoHasta != null)
              Text('Válido hasta: ${pase.validoHasta}'),
          ],
        ),
      ),
    );
  }
}

class _ScanResult {
  final bool success;
  final String message;
  final DateTime timestamp;
  final String code;

  _ScanResult({
    required this.success,
    required this.message,
    required this.timestamp,
    required this.code,
  });
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final reserva = result['reserva'] as Map<String, dynamic>? ?? {};
    final asistente = result['asistente'] as Map<String, dynamic>? ?? {};
    final cupos = result['cupos'] as Map<String, dynamic>? ?? {};

    final sedeFoto = reserva['sedeFoto']?.toString();
    final canchaFoto = reserva['canchaFoto']?.toString();
    final fotos = [sedeFoto, canchaFoto]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result['valido'] == true ? Icons.verified : Icons.error,
                  color: result['valido'] == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result['mensaje']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (fotos.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      fotos[i],
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 160,
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: fotos.length,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              reserva['cancha']?.toString() ?? 'Cancha',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (reserva['sede'] != null)
              Text(reserva['sede'].toString(), style: const TextStyle(color: Colors.grey)),
    if (reserva['horario'] != null)
      Text('Horario: ${reserva['horario']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.group, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Cupos usados ${cupos['usados'] ?? '-'} / ${cupos['total'] ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (asistente.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${asistente['nombre'] ?? 'Invitado'} (${asistente['tipo'] ?? ''})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
