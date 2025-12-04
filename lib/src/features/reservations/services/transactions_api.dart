import 'dart:convert';

import '../../../core/http/api_client.dart';
import '../models/booking_status.dart';
import '../models/booking_transaction.dart';

/// Wrapper for /api/transacciones endpoints.
class TransactionsApi {
  TransactionsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  ApiClient get client => _client;

  /// POST /api/transacciones
  Future<BookingTransaction> createManualTransaction({
    required int reservationId,
    required double amount,
    required String method,
    required BookingStatus initialStatus,
    int? userId,
    String? externalPaymentId,
  }) async {
    final response = await _client.post(
      '/transacciones',
      body: {
        'idReserva': reservationId,
        'monto': amount,
        'metodo': method,
        'estadoInicial': initialStatus.backendValue,
        if (userId != null) 'idUsuario': userId,
        if (externalPaymentId != null) 'idPagoExterno': externalPaymentId,
      },
    );
    _ensureOk(response.statusCode, response.body);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _mapTransaction(data);
  }

  /// GET /api/transacciones?estado=PENDIENTE
  Future<List<BookingTransaction>> getTransactions({String? estado}) async {
    final response = await _client.get(
      '/transacciones',
      queryParams: estado != null ? {'estado': estado} : null,
    );
    _ensureOk(response.statusCode, response.body);

    final data = jsonDecode(response.body);
    final list = (data is Map && data['transacciones'] is List)
        ? data['transacciones'] as List
        : (data as List? ?? []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(_mapTransaction)
        .toList();
  }

  /// GET /api/transacciones/:id
  Future<BookingTransaction> getTransaction(dynamic id) async {
    final response = await _client.get('/transacciones/$id');
    _ensureOk(response.statusCode, response.body);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _mapTransaction(data);
  }

  /// GET /api/transacciones/:id/estado
  Future<BookingStatus> getTransactionStatus(dynamic id) async {
    final response = await _client.get('/transacciones/$id/estado');
    _ensureOk(response.statusCode, response.body);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return BookingStatus.fromBackend(data['estado']?.toString());
  }

  BookingTransaction _mapTransaction(Map<String, dynamic> json) {
    return BookingTransaction(
      id: json['id'] ?? json['transaccionId'],
      reservationId: json['idReserva'] is String
          ? int.tryParse(json['idReserva']) ?? 0
          : (json['idReserva'] ?? 0),
      method: json['metodo']?.toString() ?? 'qr',
      status: BookingStatus.fromBackend(json['estado']?.toString()),
      amount: (json['monto'] is num)
          ? (json['monto'] as num).toDouble()
          : double.tryParse('${json['monto']}') ?? 0,
      currency: json['moneda']?.toString(),
      description: json['descripcion']?.toString(),
      qrSimpleUrl: json['qrSimpleUrl']?.toString(),
      pasarelaUrl: json['pasarelaUrl']?.toString(),
      ticketUrl: json['ticketUrl']?.toString(),
      externalPaymentId: json['idPagoExterno']?.toString(),
      clientIp: json['ipCliente']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  void _ensureOk(int statusCode, String body) {
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Transacciones API error ($statusCode): $body');
    }
  }
}
