import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/http/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/storage_helper.dart';

/// API para perfil de usuario
class ProfileApi {
  final ApiClient _client;

  ProfileApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Actualizar usuario: PUT /usuarios/:id
  Future<Map<String, dynamic>> updateUsuario({
    required String userId,
    Map<String, dynamic>? fields,
  }) async {
    final response = await _client.put('/usuarios/$userId', body: fields);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Update usuario failed: ${response.body}');
    }
  }

  /// Cambiar contraseña: PUT /usuarios/:id/cambiar-contrasena
  Future<void> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    final response = await _client.put(
      '/usuarios/$userId/cambiar-contrasena',
      body: {'nuevaContrasena': newPassword},
    );

    if (response.statusCode != 200) {
      throw Exception('Change password failed: ${response.body}');
    }
  }

  /// Subir avatar: POST /usuarios/:id/avatar (multipart)
  Future<Map<String, dynamic>> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    final token = await StorageHelper.getToken();
    final url = Uri.parse('${AppConfig.apiBaseUrl}/usuarios/$userId/avatar');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer ${token ?? ''}'
      ..files.add(await http.MultipartFile.fromPath('avatar', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Upload avatar failed: ${response.body}');
    }
  }

  /// Crear dueño: POST /duenio
  Future<Map<String, dynamic>> makeOwner({
    required int personaId,
    String? imagenCI,
    String? imagenFacial,
  }) async {
    final response = await _client.post(
      '/duenio',
      body: {
        'idPersonaD': personaId,
        'imagenCI': imagenCI ?? 'foto',
        'imagenFacial': imagenFacial ?? 'foto',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Make owner failed: ${response.body}');
    }
  }
}
