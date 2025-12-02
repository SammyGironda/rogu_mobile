import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

class ProfileService {
  Future<Map<String, dynamic>> fetchPersona(
    String personaId,
    String token,
  ) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/personas/$personaId');
    try {
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': res.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePersona({
    required String personaId,
    required String token,
    required Map<String, dynamic> fields,
  }) async {
    // Backend usa PATCH /personas/:id para actualización parcial
    final url = Uri.parse('${AppConfig.apiBaseUrl}/personas/$personaId');
    try {
      final res = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(fields),
      );
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {
        'success': false,
        'message': res.body.isNotEmpty ? res.body : 'Error ${res.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String userId,
    required String newPassword,
  }) async {
    // Backend: PUT /usuarios/:id/cambiar-contrasena  { nuevaContrasena }
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/usuarios/$userId/cambiar-contrasena',
    );
    try {
      final res = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'nuevaContrasena': newPassword}),
      );
      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {
        'success': false,
        'message': res.body.isNotEmpty ? res.body : 'Error ${res.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadAvatar({
    required String userId,
    required String token,
    required File file,
  }) async {
    // Endpoint supuesto para subida de avatar.
    final url = Uri.parse('${AppConfig.apiBaseUrl}/usuarios/$userId/avatar');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('avatar', file.path));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': response.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> makeOwner({
    required String personaId,
    required String token,
  }) async {
    // POST /duenio  body: { idPersonaD, imagenCI, imagenFacial }
    final url = Uri.parse('${AppConfig.apiBaseUrl}/duenio');
    try {
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idPersonaD': int.tryParse(personaId) ?? personaId,
          // Placeholders; UI deberá recolectar imágenes reales luego.
          'imagenCI': 'foto',
          'imagenFacial': 'foto',
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {
        'success': false,
        'message': res.body.isNotEmpty ? res.body : 'Error ${res.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUsuarioProfile({
    required String userId,
    required String token,
    required Map<String, dynamic> fields,
  }) async {
    // Backend usa PUT /usuarios/:id para correo / usuario
    final url = Uri.parse('${AppConfig.apiBaseUrl}/usuarios/$userId');
    try {
      final body = <String, dynamic>{};
      if (fields['correo'] != null) body['correo'] = fields['correo'];
      if (fields['usuario'] != null) body['usuario'] = fields['usuario'];
      if (body.isEmpty) {
        return {'success': false, 'message': 'Sin campos para actualizar'};
      }
      final res = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': res.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> changePasswordWithCurrent({
    required String token,
    required String userEmail,
    required String currentPassword,
    required String userId,
    required String newPassword,
  }) async {
    // Verificar contraseña actual intentando login
    final loginUrl = Uri.parse('${AppConfig.apiBaseUrl}/auth/login');
    try {
      final loginRes = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': userEmail, 'contrasena': currentPassword}),
      );
      if (loginRes.statusCode != 200) {
        return {'success': false, 'message': 'Contraseña actual incorrecta'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error validando contraseña actual: $e',
      };
    }

    // Si valida, cambiar contraseña
    return await changePassword(
      token: token,
      userId: userId,
      newPassword: newPassword,
    );
  }
}
