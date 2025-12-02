import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../data/models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': email, 'contrasena': password}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userData = data['usuario'];

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);

        // Map backend user to local User model
        // Backend: {correo, usuario, idPersona, idUsuario, roles}
        final user = User(
          id: userData['idUsuario'].toString(),
          personaId: userData['idPersona']?.toString(),
          username: userData['usuario'],
          email: userData['correo'],
          // avatarUrl no disponible todavía
        );

        await prefs.setString(_userKey, jsonEncode(user.toMap()));

        return {'success': true, 'user': user, 'token': token};
      } else {
        final decoded = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : null;
        String message = 'Error al iniciar sesión';
        if (decoded != null) {
          final m = decoded['message'];
          if (m is String) {
            message = m;
          } else if (m is List) {
            message = m.join(' • ');
          }
        }
        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Registro de usuario CLIENTE, replicando el flujo de rogu-web:
  /// 1) POST /personas
  /// 2) POST /auth/register con idPersona devuelto
  Future<Map<String, dynamic>> register({
    required String nombres,
    required String paterno,
    required String materno,
    required String telefono,
    required String fechaNacimiento,
    required String genero,
    required String usuario,
    required String correo,
    required String contrasena,
    String? ci,
  }) async {
    try {
      // Paso 1: crear persona
      final personaUrl = Uri.parse('${AppConfig.apiBaseUrl}/personas');
      final personaRes = await http.post(
        personaUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombres': nombres.trim(),
          'paterno': paterno.trim(),
          'materno': materno.trim(),
          'telefono': telefono.trim(),
          'fechaNacimiento': fechaNacimiento,
          // Mapear genero a enum esperado por backend
          'genero': _mapGeneroEnum(genero),
          // Documento opcional: enviar CI como documentoNumero y tipo por defecto CC
          if (ci != null && ci.isNotEmpty) 'documentoNumero': ci.trim(),
          if (ci != null && ci.isNotEmpty) 'documentoTipo': 'CC',
        }),
      );

      if (personaRes.statusCode != 201 && personaRes.statusCode != 200) {
        final txt = personaRes.body;
        return {'success': false, 'message': 'Error al crear la persona: $txt'};
      }

      final personaData = jsonDecode(personaRes.body);
      final idPersona = personaData['id'] ?? personaData['idPersona'];
      if (idPersona == null) {
        return {
          'success': false,
          'message': 'La respuesta de persona no contiene idPersona',
        };
      }

      // Paso 2: registrar usuario (rol CLIENTE se asigna en el backend)
      final registerUrl = Uri.parse('${AppConfig.apiBaseUrl}/auth/register');
      final registerRes = await http.post(
        registerUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idPersona': idPersona,
          'usuario': usuario,
          'correo': correo,
          'contrasena': contrasena,
        }),
      );

      if (registerRes.statusCode != 201 && registerRes.statusCode != 200) {
        final txt = registerRes.body;
        return {
          'success': false,
          'message': 'Error al registrar usuario: $txt',
        };
      }

      final data = jsonDecode(registerRes.body);
      // El backend de register actualmente devuelve el usuario creado (sin token)
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Convierte valores cortos a enum backend
  String _mapGeneroEnum(String genero) {
    switch (genero.toUpperCase()) {
      case 'M':
      case 'MASCULINO':
        return 'MASCULINO';
      case 'F':
      case 'FEMENINO':
        return 'FEMENINO';
      case 'O':
      case 'OTRO':
        return 'OTRO';
      default:
        return 'OTRO';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return User.fromMap(jsonDecode(userStr));
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
