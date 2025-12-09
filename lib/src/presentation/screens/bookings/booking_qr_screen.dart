import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/reservations/application/booking_qr_controller.dart';
import '../../../features/reservations/models/booking_draft.dart';
import '../../../features/reservations/models/booking_payment_response.dart';
import 'booking_success_screen.dart';

/// Step 4: shows payment QR, countdown, polling and socket listener.
class BookingQrScreen extends ConsumerStatefulWidget {
  const BookingQrScreen({super.key});

  static const String routeName = '/booking_qr';

  @override
  ConsumerState<BookingQrScreen> createState() => _BookingQrScreenState();
}

class _BookingQrScreenState extends ConsumerState<BookingQrScreen> {
  BookingDraft? _draft;
  BookingPaymentResponse? _payment;
  Timer? _countdownTimer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _draft = args['draft'] as BookingDraft?;
      _payment = args['payment'] as BookingPaymentResponse?;
      if (_payment != null) {
        ref
            .read(bookingQrControllerProvider.notifier)
            .setPaymentResponse(_payment!);
      }
      _startCountdown();
      _startSocketAndPolling();
    });
  }

  void _startCountdown() {
    if (_payment?.expiresAt == null) return;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = _payment!.expiresAt!.difference(DateTime.now());
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
      if (diff.isNegative) {
        _countdownTimer?.cancel();
      }
    });
  }

  Future<void> _startSocketAndPolling() async {
    if (_payment == null) return;
    final txId = _payment!.transactionId;
    if (txId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transacción no encontrada')),
        );
      }
      return;
    }
    final controller = ref.read(bookingQrControllerProvider.notifier);
    await controller.startMonitoring(
      transactionId: txId,
      onCompleted: (event) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          BookingSuccessScreen.routeName,
          arguments: {
            'draft': _draft,
            'transactionId': event.transactionId,
            'status': event.status,
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingQrControllerProvider);
    final qrUrl = _payment?.qrSimpleUrl ?? _payment?.pasarelaUrl;
    return Scaffold(
      appBar: AppBar(title: const Text('Pago QR')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
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
                  child: qrUrl != null
                      ? Image.network(
                          qrUrl,
                          width: 220,
                          height: 220,
                          errorBuilder: (_, __, ___) => const Text('QR no disponible'),
                        )
                      : const Text('QR no disponible'),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Escanea el código QR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_remaining != null)
                Center(
                  child: Text(
                    'Vence en ${_formatDuration(_remaining!)}',
                    style: const TextStyle(color: AppColors.neutral600),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: qrUrl == null ? null : () => _downloadQr(qrUrl),
                      child: const Text('Descargar QR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar pago'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.latestStatus != null)
                Center(
                  child: Text(
                    'Estado: ${state.latestStatus!.name.toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadQr(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace del QR')),
      );
    }
  }
}

String _formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inHours.toString().padLeft(2, '0')}:$m:$s';
}
