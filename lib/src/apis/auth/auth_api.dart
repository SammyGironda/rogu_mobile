import 'dart:convert';
import '../../core/http/api_client.dart';

/// API para autenticación (login, register, logout)
class AuthApi {
  final ApiClient _client;

  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Login: POST /auth/login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      body: {'correo': email, 'contrasena': password},
      skipAuth: true,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  /// Register: POST /auth/register
  Future<Map<String, dynamic>> register({
    required int idPersona,
    required String usuario,
    required String correo,
    required String contrasena,
  }) async {
    final response = await _client.post(
      '/auth/register',
      body: {
        'idPersona': idPersona,
        'usuario': usuario,
        'correo': correo,
        'contrasena': contrasena,
      },
      skipAuth: true,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Register failed: ${response.body}');
    }
  }

  /// Verificar token: GET /auth/verify
  Future<Map<String, dynamic>> verifyToken() async {
    final response = await _client.get('/auth/verify');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Token verification failed');
    }
  }
}
