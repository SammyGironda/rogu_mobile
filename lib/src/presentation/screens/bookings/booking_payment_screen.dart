import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/reservations/application/booking_payment_controller.dart';
import '../../../features/reservations/models/booking_draft.dart';
import 'booking_qr_screen.dart';

enum _PaymentMethod { qr, card }

/// Step 3: payment method selection and trigger to create debt/transaction.
class BookingPaymentScreen extends ConsumerStatefulWidget {
  const BookingPaymentScreen({super.key});

  static const String routeName = '/booking_payment';

  @override
  ConsumerState<BookingPaymentScreen> createState() =>
      _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends ConsumerState<BookingPaymentScreen> {
  _PaymentMethod _selected = _PaymentMethod.qr;
  BookingDraft? _draft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final d = ModalRoute.of(context)!.settings.arguments as BookingDraft;
      _draft = d;
      ref.read(bookingPaymentControllerProvider.notifier).setDraft(d);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft =
        _draft ?? ModalRoute.of(context)!.settings.arguments as BookingDraft;
    final theme = Theme.of(context);
    final state = ref.watch(bookingPaymentControllerProvider);
    final controller = ref.read(bookingPaymentControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Método de pago')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CompactSummary(draft: draft),
              const SizedBox(height: 16),
              Text(
                'Selecciona un método',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _PaymentOptionCard(
                title: 'Pago con QR',
                subtitle: 'Libélula / Banca móvil',
                icon: Icons.qr_code,
                selected: _selected == _PaymentMethod.qr,
                onTap: () => setState(() => _selected = _PaymentMethod.qr),
              ),
              const SizedBox(height: 10),
              _PaymentOptionCard(
                title: 'Tarjeta (prep)',
                subtitle: 'Próximamente',
                icon: Icons.credit_card,
                selected: _selected == _PaymentMethod.card,
                onTap: () => setState(() => _selected = _PaymentMethod.card),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => _onContinue(controller, draft),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _selected == _PaymentMethod.qr
                            ? 'Continuar con QR'
                            : 'Continuar con tarjeta',
                      ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onContinue(
    BookingPaymentController controller,
    BookingDraft draft,
  ) async {
    try {
      final resp = await controller.payWithLibelulaDebt(draft: draft);
      final updatedDraft =
          ref.read(bookingPaymentControllerProvider).draft ?? draft;
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        BookingQrScreen.routeName,
        arguments: {'draft': updatedDraft, 'payment': resp},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al generar pago: $e')));
    }
  }
}

class _CompactSummary extends StatelessWidget {
  const _CompactSummary({required this.draft});
  final BookingDraft draft;

  @override
  Widget build(BuildContext context) {
    final slotsLabel = draft.slots
        .map(
          (s) =>
              '${s.startTime.substring(0, 5)} - ${s.endTime.substring(0, 5)}',
        )
        .join(', ');
    final dateStr =
        '${draft.date.year.toString().padLeft(4, '0')}-${draft.date.month.toString().padLeft(2, '0')}-${draft.date.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Text(
            draft.fieldName,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            draft.venueName,
            style: const TextStyle(
              color: AppColors.neutral600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _Row(label: 'Fecha', value: dateStr),
          _Row(label: 'Horarios', value: slotsLabel),
          _Row(label: 'Jugadores', value: '${draft.players}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral800,
                ),
              ),
              Text(
                'Bs ${draft.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary500 : AppColors.neutral200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary600 : AppColors.neutral600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? AppColors.primary700
                          : AppColors.neutral900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary600),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.neutral600,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
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
