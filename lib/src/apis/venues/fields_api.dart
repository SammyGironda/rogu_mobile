import 'dart:convert';
import '../../core/http/api_client.dart';

/// API para canchas/fields
class FieldsApi {
  final ApiClient _client;

  FieldsApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Listar todas las canchas: GET /cancha
  Future<List<dynamic>> getAllFields() async {
    final response = await _client.get('/cancha');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Get all fields failed: ${response.body}');
    }
  }

  /// Obtener cancha por ID: GET /cancha/:id
  Future<Map<String, dynamic>> getField(int idCancha) async {
    final response = await _client.get('/cancha/$idCancha');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Get field failed: ${response.body}');
    }
  }

  /// Crear cancha: POST /cancha
  Future<Map<String, dynamic>> createField(
    Map<String, dynamic> fieldData,
  ) async {
    final response = await _client.post('/cancha', body: fieldData);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Create field failed: ${response.body}');
    }
  }

  /// Actualizar cancha: PUT /cancha/:id
  Future<Map<String, dynamic>> updateField({
    required int idCancha,
    required Map<String, dynamic> fieldData,
  }) async {
    final response = await _client.put('/cancha/$idCancha', body: fieldData);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Update field failed: ${response.body}');
    }
  }

  /// Eliminar cancha: DELETE /cancha/:id
  Future<void> deleteField(int idCancha) async {
    final response = await _client.delete('/cancha/$idCancha');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Delete field failed: ${response.body}');
    }
  }

  /// Buscar disciplinas: GET /disciplina/search?q=query
  Future<List<dynamic>> searchDisciplines(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await _client.get(
      '/disciplina/search',
      queryParams: {'q': query},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      return [];
    }
  }
}
