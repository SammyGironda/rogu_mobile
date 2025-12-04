import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/state/providers.dart';
import '../models/booking_draft.dart';
import '../models/booking_payment_request.dart';
import '../models/booking_payment_response.dart';
import '../models/booking_status.dart';
import '../services/libelula_payment_api.dart';
import '../../../data/repositories/reservations_repository.dart';

class BookingPaymentState {
  const BookingPaymentState({
    this.draft,
    this.request,
    this.response,
    this.status = BookingStatus.pendiente,
    this.isSubmitting = false,
    this.error,
  });

  final BookingDraft? draft;
  final BookingPaymentRequest? request;
  final BookingPaymentResponse? response;
  final BookingStatus status;
  final bool isSubmitting;
  final String? error;

  BookingPaymentState copyWith({
    BookingDraft? draft,
    BookingPaymentRequest? request,
    BookingPaymentResponse? response,
    BookingStatus? status,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return BookingPaymentState(
      draft: draft ?? this.draft,
      request: request ?? this.request,
      response: response ?? this.response,
      status: status ?? this.status,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final bookingPaymentControllerProvider =
    StateNotifierProvider.autoDispose<
      BookingPaymentController,
      BookingPaymentState
    >((ref) {
      final api = LibelulaPaymentApi();
      final reservationsRepo = ReservationsRepository();
      return BookingPaymentController(ref, api, reservationsRepo);
    });

class BookingPaymentController extends StateNotifier<BookingPaymentState> {
  BookingPaymentController(this._ref, this._api, this._reservationsRepository)
    : super(const BookingPaymentState());

  final Ref _ref;
  final LibelulaPaymentApi _api;
  final ReservationsRepository _reservationsRepository;

  void setDraft(BookingDraft draft) {
    state = state.copyWith(draft: draft, clearError: true);
  }

  void setRequest(BookingPaymentRequest request) {
    state = state.copyWith(request: request, clearError: true);
  }

  void resetResponse() {
    state = state.copyWith(response: null, clearError: true);
  }

  Future<BookingPaymentResponse> payWithLibelulaDebt({
    required BookingDraft draft,
    String? description,
  }) async {
    final auth = _ref.read(authProvider);
    final userId = int.tryParse(auth.user?.personaId ?? auth.user?.id ?? '');
    final email = auth.user?.email;
    if (email == null || !email.contains('@')) {
      throw Exception(
        'No se pudo obtener un email válido del usuario para el pago.',
      );
    }

    final concept =
        description ??
        'Reserva ${draft.fieldName} ${draft.venueName} ${draft.date.toIso8601String().split('T').first}';
    final debtIdentifier =
        'ROGU-${draft.reservationId ?? draft.fieldId}-${DateTime.now().millisecondsSinceEpoch}';

    final reservationId = await _ensureReservationId(
      draft: draft,
      userId: userId,
    );

    final updatedDraft = BookingDraft(
      reservationId: reservationId,
      fieldId: draft.fieldId,
      fieldName: draft.fieldName,
      fieldPhotos: draft.fieldPhotos,
      venueId: draft.venueId,
      venueName: draft.venueName,
      date: draft.date,
      slots: draft.slots,
      players: draft.players,
      totalAmount: draft.totalAmount,
      description: draft.description,
      currency: draft.currency,
      hostMessage: draft.hostMessage,
    );

    final request = BookingPaymentRequest(
      amount: updatedDraft.totalAmount,
      description: concept,
      reservationId: updatedDraft.reservationId ?? 0,
      userId: userId,
      currency: updatedDraft.currency ?? 'BOB',
      paymentMethod: 'qr',
      emailCliente: email,
      debtIdentifier: debtIdentifier,
      debtLines: [
        BookingDebtLine(
          concepto: concept,
          cantidad: 1,
          costoUnitario: updatedDraft.totalAmount,
        ),
      ],
      emiteFactura: false,
    );
    state = state.copyWith(
      draft: updatedDraft,
      request: request,
      isSubmitting: true,
      clearError: true,
    );
    try {
      final response = await _api.createDebt(request);
      state = state.copyWith(
        response: response,
        isSubmitting: false,
        status: BookingStatus.fromBackend(response.status),
      );
      return response;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
        status: BookingStatus.pendiente,
      );
      rethrow;
    }
  }

  Future<int?> _ensureReservationId({
    required BookingDraft draft,
    int? userId,
  }) async {
    if (draft.reservationId != null) return draft.reservationId;
    final idCliente = userId;
    if (idCliente == null) {
      throw Exception('No se pudo obtener el idUsuario para crear la reserva.');
    }

    final slots = List.of(draft.slots)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (slots.isEmpty) {
      throw Exception('No hay horarios seleccionados.');
    }
    DateTime _compose(DateTime date, String hhmm) {
      final parts = hhmm.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return DateTime(date.year, date.month, date.day, h, m);
    }

    final start = _compose(draft.date, slots.first.startTime);
    final end = _compose(draft.date, slots.last.endTime);

    final resp = await _reservationsRepository.createReservation(
      idCliente: idCliente,
      idCancha: draft.fieldId,
      inicia: start,
      termina: end,
      cantidadPersonas: draft.players,
      requiereAprobacion: false,
      montoBase: draft.totalAmount,
      montoExtra: 0,
    );
    final reservaNode = resp['reserva'] is Map<String, dynamic>
        ? resp['reserva'] as Map<String, dynamic>
        : null;
    final rawId =
        resp['idReserva'] ??
        reservaNode?['idReserva'] ??
        resp['id'] ??
        resp['reservaId'] ??
        reservaNode?['id'] ??
        reservaNode?['reservaId'];
    if (rawId == null) {
      throw Exception('No se obtuvo idReserva del backend.');
    }
    return int.tryParse(rawId.toString()) ?? rawId as int?;
  }
}
