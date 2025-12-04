import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_draft.dart';
import '../models/booking_transaction.dart';
import '../services/transactions_api.dart';
import '../../../data/repositories/qr_repository.dart';

class BookingSuccessState {
  const BookingSuccessState({
    this.draft,
    this.transaction,
    this.qrDataUrl,
    this.accessCode,
    this.isLoading = false,
    this.error,
  });

  final BookingDraft? draft;
  final BookingTransaction? transaction;
  final String? qrDataUrl; // Access QR (not payment QR)
  final String? accessCode;
  final bool isLoading;
  final String? error;

  BookingSuccessState copyWith({
    BookingDraft? draft,
    BookingTransaction? transaction,
    String? qrDataUrl,
    String? accessCode,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BookingSuccessState(
      draft: draft ?? this.draft,
      transaction: transaction ?? this.transaction,
      qrDataUrl: qrDataUrl ?? this.qrDataUrl,
      accessCode: accessCode ?? this.accessCode,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final bookingSuccessControllerProvider =
    StateNotifierProvider.autoDispose<
      BookingSuccessController,
      BookingSuccessState
    >((ref) {
      final txApi = TransactionsApi();
      final qrRepo = QrRepository();
      return BookingSuccessController(txApi, qrRepo);
    });

class BookingSuccessController extends StateNotifier<BookingSuccessState> {
  BookingSuccessController(this._transactionsApi, this._qrRepository)
    : super(const BookingSuccessState());

  final TransactionsApi _transactionsApi;
  final QrRepository _qrRepository;

  void hydrate({
    BookingDraft? draft,
    BookingTransaction? transaction,
    String? qrDataUrl,
    String? accessCode,
  }) {
    state = state.copyWith(
      draft: draft ?? state.draft,
      transaction: transaction ?? state.transaction,
      qrDataUrl: qrDataUrl ?? state.qrDataUrl,
      accessCode: accessCode ?? state.accessCode,
      clearError: true,
    );
  }

  Future<void> loadTransaction(dynamic transactionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tx = await _transactionsApi.getTransaction(transactionId);
      state = state.copyWith(transaction: tx, isLoading: false);
      await loadAccessQr(tx.reservationId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAccessQr(int idReserva) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pass = await _qrRepository.getPassByReserva(idReserva);
      final idPase = pass['idPaseAcceso'] ?? pass['id'] ?? pass['idPase'];
      final codigo =
          pass['codigoAcceso'] ??
          pass['codigo'] ??
          pass['codigo_pase'] ??
          pass['codigoPase'];
      if (idPase != null) {
        final dataUrl = await _qrRepository.getQrImageDataUrl(idPase);
        state = state.copyWith(
          qrDataUrl: dataUrl,
          accessCode: codigo?.toString(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          accessCode: codigo?.toString(),
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
