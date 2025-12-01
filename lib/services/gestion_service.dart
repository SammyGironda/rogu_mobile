import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Servicio para operaciones autenticadas de gestión de Sedes y Canchas.
/// Enfocado en CRUD básico requerido por la nueva pantalla "Gestionar".
class GestionService {
  final String baseUrl;
  GestionService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ---------------------- SEDE ----------------------
  Future<Map<String, dynamic>> createSede({
    required int idPersonaD,
    required String nombre,
    String descripcion = '',
    required String direccion,
    String? latitud,
    String? longitud,
    required String telefono,
    required String email,
    String politicas = '',
    String nit = '',
    String licenciaFuncionamiento = '',
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado. Vuelve a iniciar sesión para actualizar permisos.'};
    final uri = Uri.parse('$baseUrl/sede');
    final body = {
      'idPersonaD': idPersonaD,
      'nombre': nombre,
      if (descripcion.isNotEmpty) 'descripcion': descripcion,
      'direccion': direccion,
      if (latitud != null && latitud.isNotEmpty) 'latitud': latitud,
      if (longitud != null && longitud.isNotEmpty) 'longitud': longitud,
      'telefono': telefono,
      'email': email,
      if (politicas.isNotEmpty) 'politicas': politicas,
      // Quitar campos no aceptados por backend actual
      // if backend later expects 'NIT' or 'LicenciaFuncionamiento', adapt here
      // Estado inicial asumido; ajustar si backend requiere otro valor.
      'estado': 'ACTIVA',
    };
    try {
      final res = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': data};
      }
      if (res.statusCode == 401) {
        return {
          'success': false,
          'message': '401 Unauthorized. Si acabas de convertirte en dueño, cierra sesión y vuelve a iniciar para refrescar tu token.'
        };
      }
      return {
        'success': false,
        'message': res.body.isNotEmpty ? res.body : 'Error ${res.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSede(int idSede, Map<String, dynamic> fields) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    final uri = Uri.parse('$baseUrl/sede/$idSede');
    try {
      final res = await http.patch(uri, headers: _authHeaders(token), body: jsonEncode(fields));
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': res.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ---------------------- CANCHAS ----------------------
  Future<Map<String, dynamic>> listCanchas(int idSede, {String? deporte}) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    final qs = (deporte != null && deporte.isNotEmpty)
        ? '?deporte=${Uri.encodeQueryComponent(deporte)}'
        : '';
    final uri = Uri.parse('$baseUrl/sede/$idSede/canchas$qs');
    try {
      final res = await http.get(uri, headers: _authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Backend puede devolver { canchas: [] } o lista directa
        List raw;
        if (data is Map && data['canchas'] is List) {
          raw = data['canchas'];
        } else if (data is List) {
          raw = data;
        } else {
            raw = [];
        }
        return {'success': true, 'data': raw};
      }
      return {'success': false, 'message': res.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> createCancha({
    required int idSede,
    required String nombre,
    required String superficie,
    required bool cubierta,
    required bool iluminacion,
    required bool techada,
    required int aforoMax,
    required String dimensiones,
    String reglasUso = '',
    List<String> disciplinas = const [],
    List<String> fotos = const [],
    // Horarios básicos; si no se manejan aún se usan defaults
    String horaApertura = '08:00',
    String horaCierre = '22:00',
    double? precio,
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    final uri = Uri.parse('$baseUrl/cancha');
    final body = {
      'idSede': idSede,
      'nombre': nombre,
      'superficie': superficie,
      'cubierta': cubierta,
      'iluminacion': iluminacion ? 'SI' : 'NO', // backend esperaba string (según DTO lectura)
      'estado': 'ACTIVA',
      'aforoMax': aforoMax,
      'dimensiones': dimensiones,
      if (reglasUso.isNotEmpty) 'reglasUso': reglasUso,
      'horaApertura': _formatHora(horaApertura),
      'horaCierre': _formatHora(horaCierre),
      if (precio != null) 'precio': precio,
      if (disciplinas.isNotEmpty) 'disciplinas': disciplinas,
      if (fotos.isNotEmpty) 'fotos': fotos,
      // techada podría mapearse a otra propiedad si existe; placeholder
      'techada': techada,
    };
    try {
      final res = await http.post(uri, headers: _authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': res.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateCancha(int idCancha, Map<String, dynamic> fields) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    final uri = Uri.parse('$baseUrl/cancha/$idCancha');
    try {
      final res = await http.patch(uri, headers: _authHeaders(token), body: jsonEncode(fields));
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': res.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteCancha(int idCancha) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    final uri = Uri.parse('$baseUrl/cancha/$idCancha');
    try {
      final res = await http.delete(uri, headers: _authHeaders(token));
      if (res.statusCode == 200 || res.statusCode == 204) {
        return {'success': true};
      }
      return {'success': false, 'message': res.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Asegura formato HH:mm (descarta segundos si vienen)
  String _formatHora(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      return '$h:$m';
    }
    return raw; // se asume correcto o backend validar
  }
}

final gestionService = GestionService();
