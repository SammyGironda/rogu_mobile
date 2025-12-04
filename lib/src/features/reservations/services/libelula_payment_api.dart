import 'dart:convert';

import '../../../core/http/api_client.dart';
import '../models/booking_payment_request.dart';
import '../models/booking_payment_response.dart';

/// Wrapper for Libelula and direct payment endpoints.
class LibelulaPaymentApi {
  LibelulaPaymentApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  ApiClient get client => _client;

  /// POST /api/libelula/crear-deuda
  Future<BookingPaymentResponse> createDebt(
    BookingPaymentRequest request,
  ) async {
    final response = await _client.post(
      '/libelula/crear-deuda',
      body: {
        'idReserva': request.reservationId,
        'email_cliente': request.emailCliente,
        'identificador_deuda': request.debtIdentifier,
        'descripcion': request.description,
        'moneda': request.currency ?? 'BOB',
        'emite_factura': request.emiteFactura ?? false,
        'lineas_detalle_deuda': request.debtLines
            ?.map(
              (e) => {
                'concepto': e.concepto,
                'cantidad': e.cantidad,
                'costo_unitario': e.costoUnitario,
              },
            )
            .toList(),
      },
    );

    _ensureOk(response.statusCode, response.body);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return BookingPaymentResponse(
      transactionId: data['transaccionId'] ?? data['id'],
      status: data['estado']?.toString(),
      qrSimpleUrl: data['qrSimpleUrl']?.toString(),
      pasarelaUrl: data['pasarelaUrl']?.toString(),
      ticketUrl: data['ticketUrl']?.toString(),
      expiresAt: _parseDate(data['vencimiento']),
      externalPaymentId: data['idPagoExterno']?.toString(),
    );
  }

  /// POST /api/pagos/qr with medioPago="qr"
  Future<BookingPaymentResponse> payWithQr(
    BookingPaymentRequest request,
  ) async {
    final response = await _client.post(
      '/pagos/qr',
      body: {
        'monto': request.amount,
        'descripcion': request.description,
        'idReserva': request.reservationId,
        'idUsuario': request.userId,
        'medioPago': request.paymentMethod ?? 'qr',
        'moneda': request.currency ?? 'BOB',
      },
    );

    _ensureOk(response.statusCode, response.body);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return BookingPaymentResponse(
      transactionId: data['transaccionId'] ?? data['id'],
      status: data['estado']?.toString(),
      qrSimpleUrl: (data['qrSimpleUrl'] ?? data['qrImageUrl'])?.toString(),
      pasarelaUrl: data['pasarelaUrl']?.toString(),
      ticketUrl: data['ticketUrl']?.toString(),
      expiresAt: _parseDate(data['vencimiento']),
      externalPaymentId: data['idPagoExterno']?.toString(),
    );
  }

  /// POST /api/pagos/tarjeta with MercadoPago token data.
  Future<BookingPaymentResponse> payWithCard(
    BookingPaymentRequest request,
  ) async {
    final response = await _client.post(
      '/pagos/tarjeta',
      body: {
        'monto': request.amount,
        'descripcion': request.description,
        'idReserva': request.reservationId,
        'idUsuario': request.userId,
        'tokenTarjeta': request.cardToken,
        'payment_method_id': request.paymentMethodId,
        'installments': request.installments,
        'moneda': request.currency ?? 'BOB',
      },
    );

    _ensureOk(response.statusCode, response.body);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return BookingPaymentResponse(
      transactionId: data['transaccionId'] ?? data['id'],
      status: data['estado']?.toString(),
      qrSimpleUrl: data['qrSimpleUrl']?.toString(),
      pasarelaUrl: data['pasarelaUrl']?.toString(),
      ticketUrl: data['ticketUrl']?.toString(),
      expiresAt: _parseDate(data['vencimiento']),
      externalPaymentId: data['idPagoExterno']?.toString(),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  void _ensureOk(int statusCode, String body) {
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Pago Libélula error ($statusCode): $body');
    }
  }
}
