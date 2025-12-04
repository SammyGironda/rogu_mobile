import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/qr_models.dart';
import '../../../data/repositories/qr_repository.dart';
import '../../../core/theme/app_theme.dart';

class AccessLogsScreen extends ConsumerWidget {
  static const routeName = '/qr/access-logs';

  const AccessLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sede = ModalRoute.of(context)?.settings.arguments as SedeAsignada?;

    if (sede == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registros de Acceso')),
        body: const Center(
          child: Text('Error: No se recibió información de la sede'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de Acceso'),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: QrRepository().getAccessLogsBySede(sede.idSede),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar registros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Sin registros de acceso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aún no hay escaneos registrados en ${sede.nombre ?? 'esta sede'}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Header info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary600,
                      AppColors.primary600.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sede.nombre ?? 'Sede ${sede.idSede}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${logs.length} registro${logs.length == 1 ? '' : 's'} de acceso',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Logs list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _AccessLogCard(log: log);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccessLogCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const _AccessLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final resultado = log['resultado']?.toString().toUpperCase() ?? '';
    final isSuccess = resultado == 'EXITOSO' || resultado == 'EXITOSA';
    final fecha = _parseFecha(log['fecha']);
    final controlador = log['controlador'] as Map<String, dynamic>?;
    final cliente = log['cliente'] as Map<String, dynamic>?;
    final cancha = log['cancha'] as Map<String, dynamic>?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status + Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSuccess ? Icons.check_circle : Icons.cancel,
                      color: isSuccess
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      resultado,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSuccess
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                if (fecha != null)
                  Text(
                    _formatFecha(fecha),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            // Details
            _DetailRow(
              icon: Icons.sports_soccer,
              label: 'Cancha',
              value: cancha?['nombre'] ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.person,
              label: 'Cliente',
              value: cliente != null
                  ? '${cliente['nombre'] ?? ''} ${cliente['apellido'] ?? ''}'
                        .trim()
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.badge,
              label: 'Controlador',
              value: controlador != null
                  ? '${controlador['nombre'] ?? ''} ${controlador['apellido'] ?? ''}'
                        .trim()
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.qr_code_2,
              label: 'Código QR',
              value: log['codigoQR']?.toString() ?? 'N/A',
              monospace: true,
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.touch_app,
              label: 'Acción',
              value: log['accion']?.toString().toUpperCase() ?? 'N/A',
            ),
            if (log['iniciaEn'] != null && log['terminaEn'] != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.schedule,
                label: 'Horario reserva',
                value:
                    '${_formatHora(log['iniciaEn'])} - ${_formatHora(log['terminaEn'])}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  DateTime? _parseFecha(dynamic fecha) {
    if (fecha == null) return null;
    try {
      return DateTime.parse(fecha.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatFecha(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day/$month ${hour}:$minute';
  }

  String _formatHora(dynamic hora) {
    if (hora == null) return '';
    try {
      final dt = DateTime.parse(hora.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return hora.toString();
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: 13,
                    fontFamily: monospace ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
