import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../data/models/sede_create_request.dart';

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
  /// Crea una Sede con el payload detallado que requiere la API.
  /// Usa campos de ubicación (country, city, addressLine, etc.),
  /// documentos (NIT, LicenciaFuncionamiento) y otros metadatos.
  Future<Map<String, dynamic>> createSedeV2(SedeCreateRequest request) async {
    final token = await _getToken();
    if (token == null) {
      return {
        'success': false,
        'message':
            'No autenticado. Vuelve a iniciar sesión para actualizar permisos.',
      };
    }
    final uri = Uri.parse('$baseUrl/sede');
    try {
      final res = await http.post(
        uri,
        headers: _authHeaders(token),
        body: jsonEncode(request.toJson()),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': data};
      }
      if (res.statusCode == 401) {
        return {
          'success': false,
          'message':
              '401 Unauthorized. Si acabas de convertirte en dueño, cierra sesión y vuelve a iniciar para refrescar tu token.',
        };
      }
      return {
        'success': false,
        'message': res.body.isNotEmpty ? res.body : 'Error ${res.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

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
    if (token == null) {
      return {
        'success': false,
        'message':
            'No autenticado. Vuelve a iniciar sesión para actualizar permisos.',
      };
    }
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
      final res = await http.post(
        uri,
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': data};
      }
      if (res.statusCode == 401) {
        return {
          'success': false,
          'message':
              '401 Unauthorized. Si acabas de convertirte en dueño, cierra sesión y vuelve a iniciar para refrescar tu token.',
        };
      }
      return {
        'success': false,
        'message': res.body.isNotEmpty ? res.body : 'Error ${res.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSede(
    int idSede,
    Map<String, dynamic> fields,
  ) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    final uri = Uri.parse('$baseUrl/sede/$idSede');
    try {
      final res = await http.patch(
        uri,
        headers: _authHeaders(token),
        body: jsonEncode(fields),
      );
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': res.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Obtiene la Sede creada por una persona específica.
  /// Úsalo al entrar a Gestionar para mostrar la sede existente sin crear otra.
  /// Si el backend tiene un endpoint dedicado (ej. `/sede/mia`), cámbialo aquí.
  Future<Map<String, dynamic>> getSedeByPersona(int idPersonaD) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    // Intento 1: query por idPersonaD
    final uri = Uri.parse('$baseUrl/sede?idPersonaD=$idPersonaD');
    try {
      final res = await http.get(uri, headers: _authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Puede devolver objeto directo o lista; normalizar a el primero
        if (data is List && data.isNotEmpty) {
          return {'success': true, 'data': data.first};
        }
        if (data is Map<String, dynamic>) {
          // Si viene { sedes: [...] }
          final list = (data['sedes'] as List?) ?? [];
          if (list.isNotEmpty) {
            return {'success': true, 'data': list.first};
          }
          return {'success': true, 'data': data};
        }
        return {
          'success': false,
          'message': 'No se encontró sede para la persona',
        };
      }
      return {
        'success': false,
        'message': res.body.isNotEmpty ? res.body : 'Error ${res.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Valida si el usuario tiene rol permitido para Gestión.
  /// Acepta roles como 'DUENIO', 'ADMINISTRADOR'.
  bool isAuthorizedForGestion(List<String> roles) {
    final normalized = roles.map((r) => r.toUpperCase()).toSet();
    return normalized.contains('DUENIO') ||
        normalized.contains('DUEÑO') ||
        normalized.contains('ADMINISTRADOR') ||
        normalized.contains('ADMIN');
  }

  // ---------------------- USUARIOS / ROLES AUX ----------------------
  /// Devuelve el usuario por idPersona usando endpoint backend /usuarios/persona/:idPersona
  Future<Map<String, dynamic>> getUsuarioByPersona(int idPersona) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    final uri = Uri.parse('$baseUrl/usuarios/persona/$idPersona');
    try {
      final res = await http.get(uri, headers: _authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': res.body.isNotEmpty ? res.body : 'Error ${res.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Verifica si existe relación usuario-rol para (idUsuario, idRol) usando GET /usuario-rol/:idUsuario/:idRol
  Future<bool> hasUserRoleId(int idUsuario, int idRol) async {
    final token = await _getToken();
    if (token == null) return false;
    final uri = Uri.parse('$baseUrl/usuario-rol/$idUsuario/$idRol');
    try {
      final res = await http.get(uri, headers: _authHeaders(token));
      // 200 => existe; 404 => no existe (según convención NestJS estándar)
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Flujo de entrada a Gestionar: valida roles (ADMIN=1, DUENIO=3) y retorna la sede de la persona si existe
  Future<Map<String, dynamic>> resolveGestionEntryForPersona(
    int idPersonaD,
  ) async {
    final usuarioRes = await getUsuarioByPersona(idPersonaD);
    if (usuarioRes['success'] != true) {
      return {
        'success': false,
        'message': 'No se pudo obtener usuario para la persona',
      };
    }
    final usuario = usuarioRes['data'] as Map<String, dynamic>;
    final idUsuario = (usuario['id'] ?? usuario['idUsuario']);
    if (idUsuario == null) {
      return {'success': false, 'message': 'Usuario no tiene idUsuario válido'};
    }

    final int uid = int.tryParse(idUsuario.toString()) ?? -1;
    if (uid <= 0) return {'success': false, 'message': 'idUsuario inválido'};

    // Roles permitidos: 1 (ADMIN), 3 (DUENIO)
    final isAdmin = await hasUserRoleId(uid, 1);
    final isOwner = await hasUserRoleId(uid, 3);
    if (!(isAdmin || isOwner)) {
      return {
        'success': false,
        'message': 'Acceso restringido a Dueños o Administradores',
      };
    }

    // Buscar sede de la persona
    final sedeRes = await getSedeByPersona(idPersonaD);
    if (sedeRes['success'] == true) {
      return {
        'success': true,
        'isAdmin': isAdmin,
        'isOwner': isOwner,
        'sede': sedeRes['data'],
      };
    }
    // Sin sede: notificar permitido, pero sin sede
    return {
      'success': true,
      'isAdmin': isAdmin,
      'isOwner': isOwner,
      'sede': null,
    };
  }

  // ---------------------- CANCHAS ----------------------
  Future<Map<String, dynamic>> listCanchas(
    int idSede, {
    String? deporte,
  }) async {
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
      // El backend requiere string con longitud >= 3; enviamos 'true'/'false'.
      'iluminacion': iluminacion ? 'true' : 'false',
      'estado': 'ACTIVA',
      'aforoMax': aforoMax,
      'dimensiones': dimensiones,
      if (reglasUso.isNotEmpty) 'reglasUso': reglasUso,
      'horaApertura': _formatHora(horaApertura),
      'horaCierre': _formatHora(horaCierre),
      if (precio != null) 'precio': precio,
      if (disciplinas.isNotEmpty) 'disciplinas': disciplinas,
      if (fotos.isNotEmpty) 'fotos': fotos,
      // 'techada' no está soportado por el backend actual; no incluir.
    };
    try {
      final res = await http.post(
        uri,
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': res.body};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateCancha(
    int idCancha,
    Map<String, dynamic> fields,
  ) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    final uri = Uri.parse('$baseUrl/cancha/$idCancha');
    try {
      final res = await http.patch(
        uri,
        headers: _authHeaders(token),
        body: jsonEncode(fields),
      );
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
