import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_draft.dart';

class BookingConfirmState {
  const BookingConfirmState({
    this.draft,
    this.loading = false,
    this.error,
  });

  final BookingDraft? draft;
  final bool loading;
  final String? error;

  BookingConfirmState copyWith({
    BookingDraft? draft,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return BookingConfirmState(
      draft: draft ?? this.draft,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final bookingConfirmControllerProvider =
    StateNotifierProvider.autoDispose<BookingConfirmController, BookingConfirmState>((ref) {
  return BookingConfirmController();
});

class BookingConfirmController extends StateNotifier<BookingConfirmState> {
  BookingConfirmController() : super(const BookingConfirmState());

  void setDraft(BookingDraft draft) {
    state = state.copyWith(draft: draft, clearError: true);
  }
}
