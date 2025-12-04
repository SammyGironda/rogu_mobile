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

      setState(() {
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
