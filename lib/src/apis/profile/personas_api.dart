import 'dart:convert';
import '../../core/http/api_client.dart';

/// API para personas (crear, leer, actualizar)
class PersonasApi {
  final ApiClient _client;

  PersonasApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Crear persona: POST /personas
  Future<Map<String, dynamic>> createPersona({
    required String nombres,
    required String paterno,
    required String materno,
    required String telefono,
    required String fechaNacimiento,
    required String genero,
    String? documentoNumero,
    String? documentoTipo,
  }) async {
    final response = await _client.post(
      '/personas',
      body: {
        'nombres': nombres,
        'paterno': paterno,
        'materno': materno,
        'telefono': telefono,
        'fechaNacimiento': fechaNacimiento,
        'genero': genero,
        if (documentoNumero != null) 'documentoNumero': documentoNumero,
        if (documentoTipo != null) 'documentoTipo': documentoTipo,
      },
      skipAuth: true,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Create persona failed: ${response.body}');
    }
  }

  /// Obtener persona: GET /personas/:id
  Future<Map<String, dynamic>> getPersona(String personaId) async {
    final response = await _client.get('/personas/$personaId');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Get persona failed: ${response.body}');
    }
  }

  /// Actualizar persona: PATCH /personas/:id
  Future<Map<String, dynamic>> updatePersona({
    required String personaId,
    required Map<String, dynamic> fields,
  }) async {
    final response = await _client.patch('/personas/$personaId', body: fields);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Update persona failed: ${response.body}');
    }
  }
}
