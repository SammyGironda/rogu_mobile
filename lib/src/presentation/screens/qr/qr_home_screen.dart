import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/qr_models.dart';
import '../../../data/repositories/qr_repository.dart';
import '../../state/providers.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav.dart';
import 'qr_sede_pases_screen.dart';
import 'access_logs_screen.dart';

class QrHomeScreen extends ConsumerWidget {
  static const routeName = '/qr';

  const QrHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final repo = QrRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Sedes para escanear')),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(
        child: auth.isAuthenticated
            ? FutureBuilder<List<SedeAsignada>>(
                future: repo.getSedesAsignadas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final sedes = snapshot.data ?? [];
                  if (sedes.isEmpty) {
                    return const Center(
                      child: Text('No tienes sedes asignadas.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sedes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sede = sedes[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Text(
                                sede.nombre ?? 'Sede ${sede.idSede}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text('ID: ${sede.idSede}'),
                              trailing: const Icon(Icons.qr_code_scanner),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  QrSedePasesScreen.routeName,
                                  arguments: sede,
                                );
                              },
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AccessLogsScreen.routeName,
                                          arguments: sede,
                                        );
                                      },
                                      icon: const Icon(Icons.history, size: 18),
                                      label: const Text('Ver Registros'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              )
            : const Center(child: Text('Inicia sesión para escanear')),
      ),
    );
  }
}
