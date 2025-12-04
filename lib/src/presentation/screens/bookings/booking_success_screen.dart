import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/reservations/application/booking_success_controller.dart';
import '../../../features/reservations/models/booking_draft.dart';
import '../../../features/reservations/models/booking_status.dart';
import '../dashboard/dashboard_screen.dart';
import 'booking_history_screen.dart';

/// Pantalla de éxito con QR de acceso y resumen completo.
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
        draft?.slots.isNotEmpty == true
            ? '${draft!.slots.first.startTime.substring(0, 5)} - ${draft.slots.last.endTime.substring(0, 5)}'
            : '';
    final dateStr = draft != null
        ? _formatDate(draft.date)
        : '';
    final dateTimeLabel = draft != null && slotsLabel.isNotEmpty
        ? '$dateStr $slotsLabel'
        : dateStr;
    final qrUrl = state.qrDataUrl ?? tx?.ticketUrl ?? tx?.qrSimpleUrl;
    final paidAt = tx?.updatedAt ?? tx?.createdAt;
    final paidStr = paidAt != null ? _formatDateTime(paidAt) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Reserva confirmada')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _heroSection(_status ?? tx?.status ?? BookingStatus.aprobada),
              const SizedBox(height: 16),
              _qrSection(
                qrUrl: qrUrl,
                code: code,
                onDownload: qrUrl != null ? () => _openUrl(qrUrl) : null,
                onShare: qrUrl != null ? () => _openUrl(qrUrl) : null,
              ),
              const SizedBox(height: 16),
              if (paidStr != null)
                _ValidityCard(validUntil: paidStr, people: draft?.players),
              const SizedBox(height: 12),
              _detailsCard(
                draft: draft,
                slotsLabel: slotsLabel,
                dateStr: dateStr,
                dateTimeLabel: dateTimeLabel,
                code: code,
                paidStr: paidStr,
                amount: tx?.amount ?? draft?.totalAmount ?? 0,
              ),
              const SizedBox(height: 12),
              _infoImportantCard(),
              const SizedBox(height: 24),
              _actionsFooter(context),
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
      // fall through to network
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

Widget _heroSection(BookingStatus status) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primary50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary200),
    ),
    child: Column(
      children: [
        const Icon(Icons.check_circle, size: 48, color: Colors.green),
        const SizedBox(height: 8),
        const Text(
          '¡Pago confirmado!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          status.backendValue,
          style: const TextStyle(color: AppColors.neutral600),
        ),
      ],
    ),
  );
}

Widget _qrSection({
  required String? qrUrl,
  required String code,
  VoidCallback? onDownload,
  VoidCallback? onShare,
}) {
  return Container(
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
        const Text(
          'Código de acceso',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Presenta este QR en la entrada',
          style: TextStyle(color: AppColors.neutral600),
        ),
        const SizedBox(height: 12),
        if (qrUrl != null)
          _buildQrWidget(qrUrl)
        else
          const Text('QR de acceso no disponible'),
        const SizedBox(height: 8),
        Text(
          code,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onDownload,
                child: const Text('Descargar QR'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onShare,
                child: const Text('Compartir'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ValidityCard extends StatelessWidget {
  const _ValidityCard({this.validUntil, this.people});
  final String? validUntil;
  final int? people;

  @override
  Widget build(BuildContext context) {
    if (validUntil == null && people == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE4B5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiempo de validez',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          if (validUntil != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Válido hasta: $validUntil'),
            ),
          if (people != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Válido para: $people personas'),
            ),
        ],
      ),
    );
  }
}

Widget _detailsCard({
  required BookingDraft? draft,
  required String slotsLabel,
  required String dateStr,
  required String dateTimeLabel,
  required String code,
  required String? paidStr,
  required double amount,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles de la reserva',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'Código', value: code),
        if (draft != null) _InfoRow(label: 'Cancha', value: draft.fieldName),
        if (draft != null) _InfoRow(label: 'Sede', value: draft.venueName),
        if (draft != null && slotsLabel.isNotEmpty) ...[
          _InfoRow(label: 'Fecha y hora', value: dateTimeLabel),
        ] else if (draft != null) ...[
          _InfoRow(label: 'Fecha', value: dateStr),
        ],
        if (slotsLabel.isNotEmpty && draft == null)
          _InfoRow(label: 'Horarios', value: slotsLabel),
        if (draft != null)
          _InfoRow(label: 'Participantes', value: '${draft.players}'),
        if (paidStr != null) _InfoRow(label: 'Fecha y hora de pago', value: paidStr),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8FBF1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total pagado',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral800,
                ),
              ),
              Text(
                'Bs ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _infoImportantCard() {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFDF0FF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEACBFF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Información importante',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        _InfoRow(
          label: 'Presenta tu QR',
          value: 'Muestra este código en la entrada para acceder a la cancha.',
        ),
        _InfoRow(
          label: 'No compartas',
          value: 'Evita compartir tu código con terceros no autorizados.',
        ),
      ],
    ),
  );
}

Widget _actionsFooter(BuildContext context) {
  return Column(
    children: [
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
        onPressed: () =>
            Navigator.pushNamed(context, BookingHistoryScreen.routeName),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.neutral300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text('Ver mis reservas'),
      ),
    ],
  );
}

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime date) {
  return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
