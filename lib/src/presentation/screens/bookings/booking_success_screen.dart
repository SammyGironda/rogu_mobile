import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import '../../../core/theme/app_theme.dart';
import '../../../features/reservations/application/booking_success_controller.dart';
import '../../../features/reservations/models/booking_draft.dart';
import '../../../features/reservations/models/booking_status.dart';
import '../dashboard/dashboard_screen.dart';
import 'booking_history_screen.dart';

/// Step 5: final confirmation with access QR and booking details.
class BookingSuccessScreen extends ConsumerStatefulWidget {
  const BookingSuccessScreen({super.key});

  static const String routeName = '/booking_success';

  @override
  ConsumerState<BookingSuccessScreen> createState() =>
      _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends ConsumerState<BookingSuccessScreen> {
  dynamic _transactionId;
  BookingDraft? _draft;
  BookingStatus? _status;
  bool _loadedQr = false;
  bool _triggeredLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _draft = args['draft'] as BookingDraft?;
      _transactionId = args['transactionId'];
      _status = args['status'] as BookingStatus?;
      final controller = ref.read(bookingSuccessControllerProvider.notifier);
      controller.hydrate(draft: _draft);
      if (_transactionId != null) {
        controller.loadTransaction(_transactionId);
      }
      final rid = _draft?.reservationId;
      if (rid != null) {
        controller.loadAccessQr(rid);
        _loadedQr = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_triggeredLoad) {
      _triggeredLoad = true;
      final state = ref.read(bookingSuccessControllerProvider);
      final rid = _draft?.reservationId ?? state.transaction?.reservationId;
      if (!_loadedQr && rid != null) {
        ref.read(bookingSuccessControllerProvider.notifier).loadAccessQr(rid);
        _loadedQr = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingSuccessControllerProvider);
    final tx = state.transaction;
    final draft = _draft ?? state.draft;
    final code =
        state.accessCode ??
        'ROGU-${(draft?.reservationId ?? _transactionId ?? 0).toString().padLeft(4, '0')}';
    final slotsLabel =
        draft?.slots
            .map(
              (s) =>
                  '${s.startTime.substring(0, 5)} - ${s.endTime.substring(0, 5)}',
            )
            .join(', ') ??
        '';
    final dateStr = draft != null
        ? '${draft.date.year.toString().padLeft(4, '0')}-${draft.date.month.toString().padLeft(2, '0')}-${draft.date.day.toString().padLeft(2, '0')}'
        : '';
    final qrUrl = state.qrDataUrl ?? tx?.ticketUrl ?? tx?.qrSimpleUrl;
    final paidAt = tx?.updatedAt ?? tx?.createdAt;
    final paidStr = paidAt != null
        ? '${paidAt.year.toString().padLeft(4, '0')}-${paidAt.month.toString().padLeft(2, '0')}-${paidAt.day.toString().padLeft(2, '0')} ${paidAt.hour.toString().padLeft(2, '0')}:${paidAt.minute.toString().padLeft(2, '0')}'
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Reserva confirmada')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pago confirmado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (_status ?? tx?.status ?? BookingStatus.aprobada)
                          .backendValue,
                      style: const TextStyle(color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (qrUrl != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: _buildQrWidget(qrUrl),
                  ),
                ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Detalles de la reserva',
                rows: [
                  _InfoRow(label: 'Código', value: code),
                  if (draft != null)
                    _InfoRow(label: 'Cancha', value: draft.fieldName),
                  if (draft != null)
                    _InfoRow(label: 'Sede', value: draft.venueName),
                  if (draft != null) _InfoRow(label: 'Fecha', value: dateStr),
                  if (slotsLabel.isNotEmpty)
                    _InfoRow(label: 'Horarios', value: slotsLabel),
                  if (draft != null)
                    _InfoRow(label: 'Participantes', value: '${draft.players}'),
                  if (paidStr != null)
                    _InfoRow(label: 'Fecha de pago', value: paidStr),
                  _InfoRow(
                    label: 'Total pagado',
                    value:
                        'Bs ${(tx?.amount ?? draft?.totalAmount ?? 0).toStringAsFixed(2)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Información importante',
                rows: const [
                  _InfoRow(
                    label: 'Presenta tu QR',
                    value:
                        'Muestra este código en la entrada para acceder a la cancha.',
                  ),
                  _InfoRow(
                    label: 'No compartas',
                    value:
                        'Evita compartir tu código con terceros no autorizados.',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  DashboardScreen.routeName,
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Volver al inicio'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  BookingHistoryScreen.routeName,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.neutral300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Ver mis reservas'),
              ),
              if (state.isLoading) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              fontWeight: FontWeight.w800,
              color: AppColors.neutral800,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.neutral900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildQrWidget(String qrUrl) {
  if (qrUrl.startsWith('data:image')) {
    final base64Part = qrUrl.split(',').last;
    try {
      final bytes = base64Decode(base64Part);
      return Image.memory(bytes, width: 220, height: 220, fit: BoxFit.contain);
    } catch (_) {
      // fallback to network try
    }
  }
  return Image.network(
    qrUrl,
    width: 220,
    height: 220,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => const Text('QR de acceso no disponible'),
  );
}
