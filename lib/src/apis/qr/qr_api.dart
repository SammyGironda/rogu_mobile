import 'dart:convert';
import '../../core/http/api_client.dart';

/// API para QR y validación de acceso
class QrApi {
  final ApiClient _client;

  QrApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Generar código QR para reserva: GET /reservas/:id/qr
  Future<Map<String, dynamic>> generateReservationQr(int idReserva) async {
    final response = await _client.get('/reservas/$idReserva/qr');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Generate QR failed: ${response.body}');
    }
  }

  /// Validar código QR: POST /pases-acceso/validar
  Future<Map<String, dynamic>> validateQr({
    required String qrCode,
    required int idControlador,
  }) async {
    final response = await _client.post(
      '/pases-acceso/validar',
      body: {'codigo': qrCode, 'idControlador': idControlador},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Validate QR failed: ${response.body}');
    }
  }

  /// Obtener pases de acceso para una reserva: GET /pases-acceso/reserva/:id
  Future<List<dynamic>> getReservationPasses(int idReserva) async {
    final response = await _client.get('/pases-acceso/reserva/$idReserva');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Get reservation passes failed: ${response.body}');
    }
  }

  /// Obtener un pase de acceso por reserva (espera un solo pase)
  Future<Map<String, dynamic>> getPassByReserva(int idReserva) async {
    final response = await _client.get('/pases-acceso/reserva/$idReserva');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) return data.first;
      if (data is Map<String, dynamic>) return data;
      throw Exception('Pass not found for reserva $idReserva');
    } else {
      throw Exception('Get pass failed: ${response.body}');
    }
  }
}
