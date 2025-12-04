import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/qr_models.dart';
import '../../../data/repositories/qr_repository.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav.dart';
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
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
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
                  if (pases.isEmpty) {
                    return const Center(child: Text('No hay pases vigentes para esta sede.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: pases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final pase = pases[index];
                      final usos = '${pase.usados}/${pase.maximo}';
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pase.canchaNombre ?? 'Cancha',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (pase.clienteCompleto.isNotEmpty)
                                Text('Cliente: ${pase.clienteCompleto}'),
                              Text('Estado: ${pase.estado}'),
                              Text('Usos: $usos'),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        QRScannerScreen.routeName,
                                        arguments: {
                                          'pase': pase,
                                          'sede': sede,
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.qr_code_scanner),
                                    label: const Text('Escanear'),
                                  )
                                ],
                              )
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
