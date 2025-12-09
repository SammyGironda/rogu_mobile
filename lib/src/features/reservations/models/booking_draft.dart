/// Draft of the booking data that will be reused across confirm/payment steps.
class BookingDraft {
  const BookingDraft({
    this.reservationId,
    required this.fieldId,
    required this.fieldName,
    required this.fieldPhotos,
    required this.venueId,
    required this.venueName,
    required this.date,
    required this.slots,
    required this.players,
    required this.totalAmount,
    this.description,
    this.currency,
    this.hostMessage,
  });

  final int? reservationId;
  final int fieldId;
  final String fieldName;
  final List<String> fieldPhotos;
  final int venueId;
  final String venueName;
  final DateTime date;
  final List<BookingSlot> slots;
  final int players;
  final double totalAmount;
  final String? description;
  final String? currency;
  final String? hostMessage;
}

/// Selected time window for the reservation day.
class BookingSlot {
  const BookingSlot({
    required this.startTime,
    required this.endTime,
  });

  final String startTime; // HH:mm or HH:mm:ss
  final String endTime; // HH:mm or HH:mm:ss
}
