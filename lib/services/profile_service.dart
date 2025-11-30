import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ProfileService {
  Future<Map<String, dynamic>> fetchPersona(String personaId, String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/personas/$personaId');
    try {
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
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
    final url = Uri.parse('${AppConfig.apiBaseUrl}/personas/$personaId');
    try {
      final res = await http.put(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }, body: jsonEncode(fields));
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': res.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    // Endpoint supuesto; ajustar si difiere en backend real.
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/change-password');
    try {
      final res = await http.post(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }, body: jsonEncode({
        'actual': currentPassword,
        'nueva': newPassword,
      }));
      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': res.body};
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
}
