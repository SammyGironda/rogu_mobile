import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/bottom_nav.dart';
import '../../widgets/app_drawer.dart';
import '../../../core/theme/app_theme.dart';
import '../../state/providers.dart';
import '../auth/login_screen.dart';

// TODO: Reemplazar con modelos reales de la base de datos
class Participant {
  String id;
  String name;
  int? rating;

  Participant({required this.id, required this.name, this.rating});
}

class Booking {
  String id;
  String representative;
  String courtName;
  String date;
  String time;
  String status;
  List<Participant> participants;

  Booking({
    required this.id,
    required this.representative,
    required this.courtName,
    required this.date,
    required this.time,
    required this.status,
    required this.participants,
  });
}

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
    // Auth guard: redirect to login if not authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (!auth.isAuthenticated) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        return;
      }
    });
    // TODO: Cargar reservas desde la base de datos
    bookings = [];
  }

  void _toggleExpanded(String bookingId) {
    setState(() {
      _expanded[bookingId] = !(_expanded[bookingId] ?? false);
    });
  }

  Future<void> _showScanDialog(BuildContext context, Booking booking) async {
    bool scanned = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                scanned ? 'Detalles de la Reserva' : 'Escanear Código QR',
              ),
              content: SizedBox(
                width: 300,
                child: scanned
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${booking.id}'),
                          const SizedBox(height: 8),
                          Text('Cancha: ${booking.courtName}'),
                          Text('Fecha: ${booking.date}'),
                          Text('Hora: ${booking.time}'),
                          const SizedBox(height: 8),
                          Row(children: [Chip(label: Text(booking.status))]),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code, size: 72),
                          const SizedBox(height: 12),
                          const Text(
                            'Presiona iniciar para simular el escaneo.',
                          ),
                        ],
                      ),
              ),
              actions: scanned
                  ? [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cerrar'),
                      ),
                      TextButton(
                        onPressed: () {
                          setStateDialog(() {
                            scanned = false;
                          });
                        },
                        child: const Text('Volver a escanear'),
                      ),
                      if (booking.status == 'aprobada')
                        ElevatedButton(
                          onPressed: () {
                            // Simulate validation
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Entrada validada correctamente'),
                              ),
                            );
                          },
                          child: const Text('Validar'),
                        ),
                    ]
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // simulate scanning
                          setStateDialog(() {
                            // show a small loading state while simulating
                          });
                          await Future.delayed(
                            const Duration(milliseconds: 800),
                          );
                          setStateDialog(() {
                            scanned = true;
                          });
                        },
                        child: const Text('Iniciar Escaneo'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRatingDialog(
    BuildContext context,
    Booking booking,
    Participant participant,
  ) async {
    int rating = participant.rating ?? 0;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Calificar ${participant.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Cómo calificarías su participación?'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        icon: Icon(
                          starIndex <= rating ? Icons.star : Icons.star_border,
                          color: starIndex <= rating
                              ? Colors.amber
                              : Colors.grey,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            rating = starIndex;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      participant.rating = rating;
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Calificación de $rating estrellas guardada para ${participant.name}',
                        ),
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isExpanded = _expanded[booking.id] ?? false;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.representative,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          Text(
                            booking.courtName,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          Text(
                            booking.date,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          Text(
                            booking.time,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          Chip(label: Text(booking.status)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showScanDialog(context, booking),
                      child: const Text('Escanear'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _toggleExpanded(booking.id),
                      child: Row(
                        children: [
                          Text(isExpanded ? 'Ocultar' : 'Detalles'),
                          const SizedBox(width: 6),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expanded participants
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                // Use app primary dark-blue for expanded background
                color: AppColors.primary700,
                border: const Border(top: BorderSide(color: Colors.black26)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participantes (${booking.participants.length})',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  ...booking.participants.map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary600,
                            child: Text(
                              p.name.isNotEmpty ? p.name[0] : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (p.rating != null)
                                  Row(
                                    children: List.generate(
                                      p.rating!,
                                      (i) => const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _showRatingDialog(context, booking, p),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors
                                  .primary500, // app primary for contrast
                            ),
                            child: const Text('Calificar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Bienvenido controlador',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: bookings.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay reservas disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Las reservas aprobadas aparecerán aquí',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16, top: 4),
                      children: bookings.map(_buildBookingCard).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
