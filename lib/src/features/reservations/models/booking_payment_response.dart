/// Standardized response after creating a payment or debt.
class BookingPaymentResponse {
  const BookingPaymentResponse({
    required this.transactionId,
    this.status,
    this.qrSimpleUrl,
    this.pasarelaUrl,
    this.ticketUrl,
    this.expiresAt,
    this.externalPaymentId,
  });

  final dynamic transactionId; // transaccionId
  final String? status; // estado
  final String? qrSimpleUrl;
  final String? pasarelaUrl;
  final String? ticketUrl;
  final DateTime? expiresAt; // vencimiento
  final String? externalPaymentId; // idPagoExterno
}
