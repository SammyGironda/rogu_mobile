import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import 'dart:typed_data';
import '../../../data/repositories/reservations_repository.dart';
import '../../../data/repositories/qr_repository.dart';
import '../../../data/repositories/participa_repository.dart';
import '../../state/providers.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav.dart';
import '../auth/login_screen.dart';
import 'invite_participants_screen.dart';

final _historyProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final authState = ref.watch(authProvider);
    if (authState.user == null) return [];
    final reservationsRepo = ReservationsRepository();
    final user = authState.user!;
    // Siempre consultamos por idUsuario (backend espera id de usuario, no persona/cliente)
    final idUsuario = int.tryParse(user.id) ?? int.tryParse(user.personaId ?? '');
    if (idUsuario == null) return [];
    return reservationsRepo.getUserReservations(idUsuario);
  },
);

enum _BookingTab { all, pending, active, completed, cancelled }

enum _BookingStatus { active, pending, completed, cancelled }

class BookingHistoryScreen extends ConsumerStatefulWidget {
  static const String routeName = '/booking_history';
  static const String initialTabArg =
      'initialTab'; // 'all' | 'pending' | 'active' | 'completed' | 'cancelled'
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  _BookingTab _activeTab = _BookingTab.all;
  String _search = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args[BookingHistoryScreen.initialTabArg] is String) {
      final tabStr = (args[BookingHistoryScreen.initialTabArg] as String)
          .toLowerCase();
      switch (tabStr) {
        case 'pending':
          _activeTab = _BookingTab.pending;
          break;
        case 'active':
        case 'confirmadas':
          _activeTab = _BookingTab.active;
          break;
        case 'completed':
        case 'completadas':
          _activeTab = _BookingTab.completed;
          break;
        case 'cancelled':
          _activeTab = _BookingTab.cancelled;
          break;
        default:
          _activeTab = _BookingTab.all;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent ?? true) {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      });
      return const SizedBox.shrink();
    }

    final historyAsync = ref.watch(_historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Reservas',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (reservas) {
            final bookings = reservas.map(_mapBooking).toList();
            // Ordenar por fecha de creación/pago (más reciente primero)
            bookings.sort((a, b) {
              if (a.createdAt == null && b.createdAt == null) return 0;
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });
            final filtered = bookings.where(_filterBooking).toList();

            return RefreshIndicator(
              onRefresh: () => ref.refresh(_historyProvider.future),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  final horizontalPadding = isWide
                      ? (constraints.maxWidth - 500) / 2
                      : 0.0;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      16 + horizontalPadding,
                      12,
                      16 + horizontalPadding,
                      24,
                    ),
                    children: [
                      _Tabs(
                        active: _activeTab,
                        onChange: (tab) => setState(() => _activeTab = tab),
                      ),
                      const SizedBox(height: 12),
                      _SearchBar(
                        value: _search,
                        onChanged: (v) => setState(() => _search = v),
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        _EmptyState(search: _search)
                      else
                        ...filtered.map((b) => _BookingCard(booking: b)),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  bool _filterBooking(BookingView b) {
    final term = _search.trim().toLowerCase();
    final matches =
        term.isEmpty ||
        b.fieldName.toLowerCase().contains(term) ||
        b.sedeName.toLowerCase().contains(term) ||
        b.code.toLowerCase().contains(term);
    if (!matches) return false;
    switch (_activeTab) {
      case _BookingTab.pending:
        return b.status == _BookingStatus.pending;
      case _BookingTab.active:
        return b.status == _BookingStatus.active;
      case _BookingTab.completed:
        return b.status == _BookingStatus.completed;
      case _BookingTab.cancelled:
        return b.status == _BookingStatus.cancelled;
      case _BookingTab.all:
        return true;
    }
  }

  BookingView _mapBooking(Map<String, dynamic> r) {
    final cancha = r['cancha'] as Map<String, dynamic>? ?? {};
    final sede = cancha['sede'] as Map<String, dynamic>? ?? {};
    final estadoRaw = (r['estado'] ?? '').toString().toUpperCase();

    // Verificar completadaEn de forma más robusta
    final completadaEnRaw = r['completadaEn'];
    bool tieneCompletadaEn = false;

    if (completadaEnRaw != null &&
        completadaEnRaw.toString().isNotEmpty &&
        completadaEnRaw.toString() != 'null') {
      try {
        DateTime.parse(completadaEnRaw.toString());
        tieneCompletadaEn = true;
        print('✅ TIENE completadaEn válido');
      } catch (_) {
        print('❌ completadaEn no es fecha válida');
      }
    } else {
      print('❌ completadaEn es null o vacío');
    }

    // Determinar estado basado en completadaEn (validado en controla) o estado "Completada"
    _BookingStatus status = _BookingStatus.active;

    if (estadoRaw.contains('CANCEL')) {
      status = _BookingStatus.cancelled;
      print('🔴 Status: CANCELLED');
    } else if (tieneCompletadaEn || estadoRaw.contains('COMPLETADA')) {
      status = _BookingStatus.completed;
      print('🟢 Status: COMPLETED ✅✅✅');
    } else if (estadoRaw.contains('PENDIENTE')) {
      status = _BookingStatus.pending;
      print('🟡 Status: PENDING');
    } else if (estadoRaw.contains('CONFIRMADA')) {
      status = _BookingStatus.active;
      print('🟢 Status: ACTIVE (confirmada)');
    } else {
      print('⚪ Status: DEFAULT (active)');
    }

    DateTime startDate;
    DateTime endDate;
    try {
      startDate = DateTime.parse(
        r['iniciaEn'] ?? r['horaInicio'] ?? r['fecha'],
      ).toLocal();
    } catch (_) {
      startDate = DateTime.now();
    }
    try {
      endDate = DateTime.parse(
        r['terminaEn'] ?? r['horaFin'] ?? r['fecha'],
      ).toLocal();
    } catch (_) {
      endDate = startDate.add(const Duration(hours: 1));
    }
    final horaInicio =
        '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}';
    final horaFin =
        '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
    final monto = (r['montoTotal'] ?? r['monto'] ?? 0).toDouble();
    final fotos = cancha['fotos'] as List? ?? [];
    String? foto;
    if (fotos.isNotEmpty) {
      final f0 = fotos.first;
      if (f0 is Map) {
        foto = resolveImageUrl(
          (f0['urlFoto'] ?? f0['url'] ?? f0['imageUrl'] ?? f0['path'] ?? '')
              .toString(),
        );
      } else {
        foto = resolveImageUrl(f0.toString());
      }
    }

    // Extraer fecha de creación con precisión
    DateTime? createdAt;
    try {
      createdAt =
          DateTime.parse(r['creadoEn'] ?? r['createdAt'] ?? '').toLocal();
    } catch (_) {
      createdAt = null;
    }

    return BookingView(
      id: r['idReserva'] ?? r['id'],
      fieldName: cancha['nombre']?.toString() ?? 'Cancha',
      sedeName: sede['nombre']?.toString() ?? 'Sede',
      date: startDate,
      startDate: startDate,
      endDate: endDate,
      timeSlot: '$horaInicio - $horaFin',
      participants: (r['cantidadPersonas'] ?? r['personas'] ?? 0).toString(),
      totalPaid: monto,
      status: status,
      code:
          'ROGU-${(r['idReserva'] ?? r['id'] ?? 0).toString().padLeft(6, '0')}',
      sport:
          cancha['disciplina']?.toString() ??
          cancha['deporte']?.toString() ??
          'DEPORTE',
      image: foto,
      createdAt: createdAt,
    );
  }
}

class BookingView {
  BookingView({
    required this.id,
    required this.fieldName,
    required this.sedeName,
    required this.date,
    required this.startDate,
    required this.endDate,
    required this.timeSlot,
    required this.participants,
    required this.totalPaid,
    required this.status,
    required this.code,
    required this.sport,
    this.image,
    this.createdAt,
  });

  final dynamic id;
  final String fieldName;
  final String sedeName;
  final DateTime date;
  final DateTime startDate;
  final DateTime endDate;
  final String timeSlot;
  final String participants;
  final double totalPaid;
  final _BookingStatus status;
  final String code;
  final String sport;
  final String? image;
  final DateTime? createdAt;
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.active, required this.onChange});
  final _BookingTab active;
  final ValueChanged<_BookingTab> onChange;

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      (_BookingTab.all, 'Todas'),
      (_BookingTab.pending, 'Pendientes'),
      (_BookingTab.active, 'Confirmadas'),
      (_BookingTab.completed, 'Completadas'),
      (_BookingTab.cancelled, 'Canceladas'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final selected = t.$1 == active;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(t.$2),
              selected: selected,
              onSelected: (_) => onChange(t.$1),
              selectedColor: AppColors.neutral900,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColors.neutral100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Buscar por cancha, sede o código...',
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final BookingView booking;

  Color _statusColor(_BookingStatus s) {
    switch (s) {
      case _BookingStatus.active:
        return Colors.green.shade600;
      case _BookingStatus.pending:
        return Colors.orange.shade600;
      case _BookingStatus.completed:
        return Colors.blue.shade600;
      case _BookingStatus.cancelled:
        return Colors.red.shade600;
    }
  }

  String _statusLabel(_BookingStatus s) {
    switch (s) {
      case _BookingStatus.active:
        return 'Confirmada';
      case _BookingStatus.pending:
        return 'Pendiente de pago';
      case _BookingStatus.completed:
        return 'Completada';
      case _BookingStatus.cancelled:
        return 'Cancelada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final dateStr =
        '${booking.startDate.day} de ${_monthName(booking.startDate.month)} de ${booking.startDate.year}';
    final timeStr =
        '${booking.startDate.hour.toString().padLeft(2, '0')}:${booking.startDate.minute.toString().padLeft(2, '0')} - ${booking.endDate.hour.toString().padLeft(2, '0')}:${booking.endDate.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(booking: booking),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto de cancha o icono
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: booking.image != null
                    ? Colors.transparent
                    : AppColors.neutral900,
                borderRadius: BorderRadius.circular(14),
                image: booking.image != null
                    ? DecorationImage(
                        image: NetworkImage(booking.image!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _statusLabel(booking.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      booking.sport.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.sedeName.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.neutral600,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.fieldName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.neutral500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: const TextStyle(
                            color: AppColors.neutral600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.neutral500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            color: AppColors.neutral600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.group,
                        size: 14,
                        color: AppColors.neutral500,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${booking.participants} pers.',
                          style: const TextStyle(
                            color: AppColors.neutral600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  if (booking.createdAt != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 14,
                          color: AppColors.neutral500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pagado: ${_formatCreatedAt(booking.createdAt!)}',
                            style: const TextStyle(
                              color: AppColors.neutral500,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total pagado',
                  style: TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Bs ${booking.totalPaid.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.neutral500,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return months[(m - 1).clamp(0, 11)];
  }

  String _formatCreatedAt(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString().substring(2);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.search});
  final String search;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy, size: 36, color: AppColors.neutral400),
          const SizedBox(height: 8),
          Text(
            search.isEmpty
                ? 'No tienes reservas registradas'
                : 'Sin resultados para tu búsqueda',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.neutral800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Explora canchas y reserva tu próximo partido.',
            style: TextStyle(color: AppColors.neutral600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.booking});
  final BookingView booking;

  Color _statusColor(_BookingStatus s) {
    switch (s) {
      case _BookingStatus.active:
        return Colors.green.shade600;
      case _BookingStatus.pending:
        return Colors.orange.shade600;
      case _BookingStatus.completed:
        return Colors.blue.shade600;
      case _BookingStatus.cancelled:
        return Colors.red.shade600;
    }
  }

  String _statusLabel(_BookingStatus s) {
    switch (s) {
      case _BookingStatus.active:
        return 'Confirmada';
      case _BookingStatus.pending:
        return 'Pendiente de pago';
      case _BookingStatus.completed:
        return 'Completada';
      case _BookingStatus.cancelled:
        return 'Cancelada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final dateStr =
        '${booking.startDate.day} de ${_monthName(booking.startDate.month)} de ${booking.startDate.year}';
    final timeStr =
        '${booking.startDate.hour.toString().padLeft(2, '0')}:${booking.startDate.minute.toString().padLeft(2, '0')} - ${booking.endDate.hour.toString().padLeft(2, '0')}:${booking.endDate.minute.toString().padLeft(2, '0')}';
    final isActive = booking.status == _BookingStatus.active;
    final isPending = booking.status == _BookingStatus.pending;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF111827)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(
                            _statusLabel(booking.status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: statusColor.withOpacity(0.18),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          side: BorderSide(color: statusColor.withOpacity(0.4)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      booking.sport.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.fieldName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.sedeName,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (isActive) _QRSection(booking: booking),

              const SizedBox(height: 16),
              // Details & Payment
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Detalles',
                      rows: [
                        _InfoRow(
                          icon: Icons.calendar_today,
                          label: 'Fecha',
                          value: dateStr,
                        ),
                        _InfoRow(
                          icon: Icons.access_time,
                          label: 'Horario',
                          value: timeStr,
                        ),
                        _InfoRow(
                          icon: Icons.group,
                          label: 'Participantes',
                          value: '${booking.participants} personas',
                        ),
                        if (booking.createdAt != null)
                          _InfoRow(
                            icon: Icons.receipt_long,
                            label: 'Reservado',
                            value: _formatCreatedAt(booking.createdAt!),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: 'Pago',
                      rows: [
                        _InfoRow(
                          icon: Icons.payments,
                          label: 'Monto total',
                          value: 'Bs ${booking.totalPaid.toStringAsFixed(2)}',
                          bold: true,
                        ),
                        const _InfoRow(
                          icon: Icons.credit_card,
                          label: 'Método',
                          value: 'Pagado con Tarjeta',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botones de accion
              if (isActive) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InviteParticipantsScreen(
                          idReserva: int.parse(booking.id.toString()),
                          cancha: booking.fieldName,
                          sede: booking.sedeName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.group_add),
                  label: const Text('Invitar personas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (isPending)
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Implementar flujo de pago en mvil'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Completar Pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              // Bot3d0n cancelar para pendientes y confirmadas
              if (isPending || isActive) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, booking),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar Reserva'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _ParticipantsCard(reservaId: int.parse(booking.id.toString())),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCreatedAt(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute:$second';
  }

  void _showCancelDialog(BuildContext context, BookingView booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '¿Cancelar reserva?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estás a punto de cancelar tu reserva para:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              booking.fieldName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              booking.sedeName,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(booking.timeSlot),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _cancelReservation(context, booking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelReservation(
    BuildContext context,
    BookingView booking,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final repo = ReservationsRepository();
      await repo.cancelReservation(int.parse(booking.id.toString()));

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading
      Navigator.of(context).pop(); // Close detail screen

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reserva cancelada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al cancelar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _monthName(int m) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return months[(m - 1).clamp(0, 11)];
  }
}

class _QRSection extends StatefulWidget {
  const _QRSection({required this.booking});
  final BookingView booking;

  @override
  State<_QRSection> createState() => _QRSectionState();
}

class _QRSectionState extends State<_QRSection> {
  late Future<_QrResult> _qrFuture;

  @override
  void initState() {
    super.initState();
    _qrFuture = _loadQr();
  }

  Future<_QrResult> _loadQr() async {
    final repo = QrRepository();
    final pass = await repo.getPassByReserva(
      int.parse(widget.booking.id.toString()),
    );
    final idPase = pass['idPaseAcceso'] ?? pass['id'] ?? pass['idPase'];
    if (idPase == null) {
      throw Exception('No se encontró idPaseAcceso en la respuesta');
    }
    final code = pass['codigoAcceso'] ?? pass['codigo'] ?? widget.booking.code;
    final bytes = await repo.getQrImageBytes(idPase);
    return _QrResult(code: code.toString(), bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_QrResult>(
      future: _qrFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          final errText = snapshot.error?.toString() ?? 'Error desconocido';
          debugPrint('QR load error: $errText');
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No se pudo cargar el código QR',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 6),
                Text(
                  errText,
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
              ],
            ),
          );
        }
        final data = snapshot.data!;
        final qrWidget = Image.memory(
          data.bytes,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neutral200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Código de acceso',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: qrWidget,
              ),
              const SizedBox(height: 12),
              Text(
                data.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.neutral900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QrResult {
  _QrResult({required this.code, required this.bytes});
  final String code;
  final Uint8List bytes;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.neutral600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({required this.reservaId});
  final int reservaId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ParticipaRepository().getParticipantes(reservaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'No se pudieron cargar los participantes',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final cupos = data['cupos'] as Map<String, dynamic>? ?? {};
        final participantes =
            (data['participantes'] as List? ?? []).cast<Map<String, dynamic>>();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Participantes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Usados ${cupos['ocupados'] ?? cupos['usados'] ?? participantes.length}/${cupos['total'] ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (participantes.isEmpty)
                  const Text('Aún no hay participantes registrados')
                else
                  ...participantes.map((p) {
                    final tipo = (p['tipoAsistente'] ?? '').toString();
                    final checkIn = p['checkInEn']?.toString();
                    final confirmado = p['confirmado'] == true;
                    final nombre = p['nombre']?.toString() ?? 'Invitado';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        confirmado || (checkIn != null && checkIn.isNotEmpty)
                            ? Icons.check_circle
                            : Icons.access_time,
                        color: confirmado || (checkIn != null && checkIn.isNotEmpty)
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(
                        nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        tipo,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: checkIn != null && checkIn.isNotEmpty
                          ? Text(
                              _fmtFecha(checkIn),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            )
                          : null,
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtFecha(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
