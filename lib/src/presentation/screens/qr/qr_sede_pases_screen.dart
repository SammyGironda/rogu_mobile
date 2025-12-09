import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/qr_models.dart';
import '../../../data/repositories/qr_repository.dart';
import '../../../core/theme/app_theme.dart';
import 'qr_scanner_screen.dart';

class QrSedePasesScreen extends ConsumerWidget {
  static const routeName = '/qr/sede';

  const QrSedePasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = QrRepository();
    final args = ModalRoute.of(context)?.settings.arguments;
    final sede = args is SedeAsignada ? args : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pases - ${sede?.nombre ?? 'Sede'}'),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: sede == null
            ? const Center(child: Text('Sede no encontrada'))
            : FutureBuilder<List<PaseAccesoResumen>>(
                future: repo.getPasesPorSede(sede.idSede),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final pases = snapshot.data ?? [];

                  // Filtrar solo pases que NO estén completados (usados < maximo)
                  final pasesActivos = pases
                      .where((p) => p.usados < p.maximo)
                      .toList();

                  if (pasesActivos.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.green.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sin pases pendientes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Todos los pases de acceso han sido utilizados',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: pasesActivos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pase = pasesActivos[index];
                      final usos = '${pase.usados}/${pase.maximo}';
                      final disponibles = pase.maximo - pase.usados;
                      final foto = pase.foto;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (foto != null && foto.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        foto,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image_not_supported),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                pase.canchaNombre ?? 'Cancha',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Chip(
                                              label: Text(
                                                '$disponibles disponible${disponibles != 1 ? 's' : ''}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              backgroundColor: Colors.green.shade100,
                                              side: BorderSide(
                                                color: Colors.green.shade300,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (pase.clienteCompleto.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  pase.clienteCompleto,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.group,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Usos: $usos',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Estado: ${pase.estado}',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      QRScannerScreen.routeName,
                                      arguments: {'pase': pase, 'sede': sede},
                                    );
                                  },
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Escanear QR'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
