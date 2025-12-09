import 'dart:convert';
import '../../core/http/api_client.dart';

/// API para sedes/venues
class VenuesApi {
  final ApiClient _client;

  VenuesApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Listar sedes para página inicio: GET /sede/inicio
  Future<List<dynamic>> getVenuesInicio() async {
    final response = await _client.get('/sede/inicio');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Get venues inicio failed: ${response.body}');
    }
  }

  /// Obtener sede por ID: GET /sede/:id
  Future<Map<String, dynamic>> getVenue(int idSede) async {
    final response = await _client.get('/sede/$idSede');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['sede'] is Map<String, dynamic>) {
        return data['sede'] as Map<String, dynamic>;
      }
      if (data is Map<String, dynamic>) {
        return data;
      }
      print('Get venue unexpected payload: $data');
      throw Exception('Get venue failed: unexpected payload');
    } else {
      print('Get venue failed status=${response.statusCode} body=${response.body}');
      throw Exception('Get venue failed: ${response.body}');
    }
  }

  /// Obtener canchas de una sede: GET /sede/:id/canchas
  Future<List<dynamic>> getVenueFields(int idSede, {String? deporte}) async {
    final queryParams = deporte != null && deporte.isNotEmpty
        ? {'deporte': deporte}
        : null;

    final response = await _client.get(
      '/sede/$idSede/canchas',
      queryParams: queryParams,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Puede venir como {canchas: [...]} o directamente [...]
      if (data is Map && data['canchas'] is List) {
        return data['canchas'];
      } else if (data is List) {
        return data;
      }
      return [];
    } else {
      print(
        'Get venue fields failed status=${response.statusCode} body=${response.body}',
      );
      throw Exception('Get venue fields failed: ${response.body}');
    }
  }

  /// Crear sede: POST /sede
  Future<Map<String, dynamic>> createVenue(
    Map<String, dynamic> sedeData,
  ) async {
    final response = await _client.post('/sede', body: sedeData);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Create venue failed: ${response.body}');
    }
  }

  /// Actualizar sede: PUT /sede/:id
  Future<Map<String, dynamic>> updateVenue({
    required int idSede,
    required Map<String, dynamic> sedeData,
  }) async {
    final response = await _client.put('/sede/$idSede', body: sedeData);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Update venue failed: ${response.body}');
    }
  }

  /// Eliminar sede: DELETE /sede/:id
  Future<void> deleteVenue(int idSede) async {
    final response = await _client.delete('/sede/$idSede');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Delete venue failed: ${response.body}');
    }
  }

  /// Obtener sede por personaId: GET /sede (con query idPersonaD)
  Future<Map<String, dynamic>> getSedeByPersona(int personaId) async {
    final response = await _client.get(
      '/sede',
      queryParams: {'idPersonaD': personaId.toString()},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Puede devolver lista o objeto directo
      if (data is List && data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      } else if (data is Map) {
        final sedes = data['sedes'] as List? ?? [];
        if (sedes.isNotEmpty) {
          return sedes.first as Map<String, dynamic>;
        }
        return data as Map<String, dynamic>;
      }
      throw Exception('No venue found for persona $personaId');
    } else {
      throw Exception('Get sede by persona failed: ${response.body}');
    }
  }
}
