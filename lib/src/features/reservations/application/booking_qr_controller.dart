import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_payment_response.dart';
import '../models/booking_status.dart';
import '../models/booking_transaction.dart';
import '../services/socket_payment_service.dart';
import '../services/transactions_api.dart';

class BookingQrState {
  const BookingQrState({
    this.transaction,
    this.paymentResponse,
    this.latestStatus,
    this.isListeningSocket = false,
    this.isPolling = false,
    this.error,
  });

  final BookingTransaction? transaction;
  final BookingPaymentResponse? paymentResponse;
  final BookingStatus? latestStatus;
  final bool isListeningSocket;
  final bool isPolling;
  final String? error;

  BookingQrState copyWith({
    BookingTransaction? transaction,
    BookingPaymentResponse? paymentResponse,
    BookingStatus? latestStatus,
    bool? isListeningSocket,
    bool? isPolling,
    String? error,
    bool clearError = false,
  }) {
    return BookingQrState(
      transaction: transaction ?? this.transaction,
      paymentResponse: paymentResponse ?? this.paymentResponse,
      latestStatus: latestStatus ?? this.latestStatus,
      isListeningSocket: isListeningSocket ?? this.isListeningSocket,
      isPolling: isPolling ?? this.isPolling,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final bookingQrControllerProvider =
    StateNotifierProvider.autoDispose<BookingQrController, BookingQrState>((ref) {
  final socketService = SocketPaymentService();
  final txApi = TransactionsApi();
  return BookingQrController(socketService, txApi);
});

class BookingQrController extends StateNotifier<BookingQrState> {
  BookingQrController(this._socketService, this._transactionsApi)
      : super(const BookingQrState());

  final SocketPaymentService _socketService;
  final TransactionsApi _transactionsApi;
  Timer? _pollingTimer;

  void setTransaction(BookingTransaction transaction) {
    state = state.copyWith(transaction: transaction, clearError: true);
  }

  void setPaymentResponse(BookingPaymentResponse response) {
    state = state.copyWith(paymentResponse: response, clearError: true);
  }

  void setStatus(BookingStatus status) {
    state = state.copyWith(latestStatus: status, clearError: true);
  }

  Future<void> startMonitoring({
    required dynamic transactionId,
    required void Function(PaymentCompletedEvent event) onCompleted,
    Duration pollInterval = const Duration(seconds: 4),
  }) async {
    state = state.copyWith(isListeningSocket: true, clearError: true);
    await _socketService.connect();
    _socketService.subscribeToTransaction(transactionId);
    _socketService.listenPaymentCompleted((event) {
      _stopPolling();
      onCompleted(event);
    });

    _startPolling(transactionId, onCompleted, pollInterval);
  }

  void _startPolling(
    dynamic transactionId,
    void Function(PaymentCompletedEvent event) onCompleted,
    Duration pollInterval,
  ) {
    state = state.copyWith(isPolling: true);
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(pollInterval, (_) async {
      try {
        final status =
            await _transactionsApi.getTransactionStatus(transactionId);
        setStatus(status);
        if (status == BookingStatus.aprobada) {
          _stopPolling();
          onCompleted(
            PaymentCompletedEvent(
              transactionId: transactionId,
              status: status,
              reservationId: state.transaction?.reservationId ?? 0,
              externalPaymentId: state.transaction?.externalPaymentId,
              amount: state.transaction?.amount,
            ),
          );
        }
      } catch (e) {
        state = state.copyWith(error: e.toString());
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    state = state.copyWith(isPolling: false);
  }

  @override
  void dispose() {
    _stopPolling();
    _socketService.dispose();
    super.dispose();
  }
}
