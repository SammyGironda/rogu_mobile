import 'dart:convert';
import '../../core/http/api_client.dart';

/// API para reservas
class ReservationsApi {
  final ApiClient _client;

  ReservationsApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Obtener reservas de una cancha: GET /reservas/cancha/:id?fecha=YYYY-MM-DD
  Future<List<dynamic>> getFieldReservations({
    required int idCancha,
    required String fecha,
  }) async {
    final response = await _client.get(
      '/reservas/cancha/$idCancha',
      queryParams: {'fecha': fecha},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Get field reservations failed: ${response.body}');
    }
  }

  /// Obtener reservas de un usuario: GET /reservas/usuario/:id
  Future<List<dynamic>> getUserReservations(int idUsuario) async {
    final response = await _client.get('/reservas/usuario/$idUsuario');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Get user reservations failed: ${response.body}');
    }
  }

  /// Crear reserva: POST /reservas
  Future<Map<String, dynamic>> createReservation({
    required int idCliente,
    required int idCancha,
    required String iniciaEn,
    required String terminaEn,
    int cantidadPersonas = 2,
    bool requiereAprobacion = false,
    double montoBase = 0,
    double montoExtra = 0,
  }) async {
    final montoTotal = montoBase + montoExtra;

    final response = await _client.post(
      '/reservas',
      body: {
        'idCliente': idCliente,
        'idCancha': idCancha,
        'iniciaEn': iniciaEn,
        'terminaEn': terminaEn,
        'cantidadPersonas': cantidadPersonas,
        'requiereAprobacion': requiereAprobacion,
        'montoBase': montoBase,
        'montoExtra': montoExtra,
        'montoTotal': montoTotal,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : {'raw': data};
    } else {
      throw Exception('Create reservation failed: ${response.body}');
    }
  }

  /// Cancelar reserva: DELETE /reservas/:id
  Future<void> cancelReservation(int idReserva) async {
    final response = await _client.delete('/reservas/$idReserva');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Cancel reservation failed: ${response.body}');
    }
  }

  /// Obtener detalles de una reserva: GET /reservas/:id
  Future<Map<String, dynamic>> getReservation(int idReserva) async {
    final response = await _client.get('/reservas/$idReserva');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Get reservation failed: ${response.body}');
    }
  }
}
