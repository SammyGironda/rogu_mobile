import 'booking_status.dart';

/// Transaction state returned by /api/transacciones endpoints.
class BookingTransaction {
  const BookingTransaction({
    required this.id,
    required this.reservationId,
    required this.method,
    required this.status,
    required this.amount,
    this.currency,
    this.description,
    this.qrSimpleUrl,
    this.pasarelaUrl,
    this.ticketUrl,
    this.externalPaymentId,
    this.clientIp,
    this.createdAt,
    this.updatedAt,
  });

  final dynamic id;
  final int reservationId; // idReserva
  final String method; // metodo: "qr", "tarjeta"
  final BookingStatus status; // estado
  final double amount; // monto
  final String? currency; // moneda
  final String? description;
  final String? qrSimpleUrl;
  final String? pasarelaUrl;
  final String? ticketUrl;
  final String? externalPaymentId; // idPagoExterno
  final String? clientIp; // ipCliente
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
