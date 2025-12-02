import 'dart:convert';
import '../../core/http/api_client.dart';

/// API para administración (aprobaciones de sedes/canchas)
class AdminApi {
  final ApiClient _client;

  AdminApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Listar sedes pendientes de aprobación: GET /sede/pendientes
  Future<List<dynamic>> getPendingVenues() async {
    final response = await _client.get('/sede/pendientes');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Get pending venues failed: ${response.body}');
    }
  }

  /// Aprobar sede: PUT /sede/:id/aprobar
  Future<void> approveVenue(int idSede) async {
    final response = await _client.put('/sede/$idSede/aprobar');

    if (response.statusCode != 200) {
      throw Exception('Approve venue failed: ${response.body}');
    }
  }

  /// Rechazar sede: PUT /sede/:id/rechazar
  Future<void> rejectVenue(int idSede, {String? motivo}) async {
    final response = await _client.put(
      '/sede/$idSede/rechazar',
      body: motivo != null ? {'motivo': motivo} : null,
    );

    if (response.statusCode != 200) {
      throw Exception('Reject venue failed: ${response.body}');
    }
  }

  /// Listar canchas pendientes: GET /cancha/pendientes
  Future<List<dynamic>> getPendingFields() async {
    final response = await _client.get('/cancha/pendientes');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Get pending fields failed: ${response.body}');
    }
  }

  /// Aprobar cancha: PUT /cancha/:id/aprobar
  Future<void> approveField(int idCancha) async {
    final response = await _client.put('/cancha/$idCancha/aprobar');

    if (response.statusCode != 200) {
      throw Exception('Approve field failed: ${response.body}');
    }
  }

  /// Rechazar cancha: PUT /cancha/:id/rechazar
  Future<void> rejectField(int idCancha, {String? motivo}) async {
    final response = await _client.put(
      '/cancha/$idCancha/rechazar',
      body: motivo != null ? {'motivo': motivo} : null,
    );

    if (response.statusCode != 200) {
      throw Exception('Reject field failed: ${response.body}');
    }
  }
}
