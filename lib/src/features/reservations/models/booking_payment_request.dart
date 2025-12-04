/// Request payload for Libelula or direct payment endpoints.
class BookingPaymentRequest {
  const BookingPaymentRequest({
    required this.amount,
    required this.description,
    required this.reservationId,
    this.userId,
    this.currency,
    this.paymentMethod,
    this.cardToken,
    this.paymentMethodId,
    this.installments,
    this.emailCliente,
    this.debtIdentifier,
    this.debtLines,
    this.emiteFactura,
  });

  final double amount;
  final String description;
  final int reservationId;
  final int? userId;
  final String? currency;
  final String? paymentMethod; // e.g. "qr" or "tarjeta"
  final String? cardToken; // tokenTarjeta
  final String? paymentMethodId; // payment_method_id for providers like MP
  final int? installments;
  final String? emailCliente;
  final String? debtIdentifier;
  final List<BookingDebtLine>? debtLines;
  final bool? emiteFactura;
}

class BookingDebtLine {
  const BookingDebtLine({
    required this.concepto,
    required this.cantidad,
    required this.costoUnitario,
  });

  final String concepto;
  final int cantidad;
  final double costoUnitario;
}
