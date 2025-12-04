import 'dart:convert';
import '../../core/http/api_client.dart';

/// API para QR y validación de acceso
class QrApi {
  final ApiClient _client;

  QrApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Generar código QR para reserva: GET /reservas/:id/qr
  Future<Map<String, dynamic>> generateReservationQr(int idReserva) async {
    final response = await _client.get('/reservas/$idReserva/qr');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Generate QR failed: ${response.body}');
    }
  }

  /// Validar código QR: POST /pases-acceso/validar
  Future<Map<String, dynamic>> validateQr({
    required String qrCode,
    required String accion,
    int? idPersonaOpe,
  }) async {
    final response = await _client.post(
      '/pases-acceso/validar',
      body: {
        'codigoQR': qrCode,
        'accion': accion,
        if (idPersonaOpe != null) 'idControlador': idPersonaOpe,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Validate QR failed (code ${response.statusCode}): ${response.body}');
  }

  /// Obtener pases de acceso para una reserva: GET /pases-acceso/reserva/:id
  Future<List<dynamic>> getReservationPasses(int idReserva) async {
    final response = await _client.get('/pases-acceso/reserva/$idReserva');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Get reservation passes failed: ${response.body}');
    }
  }

  /// Obtener un pase de acceso por reserva (espera un solo pase)
  Future<Map<String, dynamic>> getPassByReserva(int idReserva) async {
    final response = await _client.get('/pases-acceso/reserva/$idReserva');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) return data.first;
      if (data is Map<String, dynamic>) return data;
      throw Exception('Pass not found for reserva $idReserva');
    } else {
      throw Exception('Get pass failed: ${response.body}');
    }
  }

  /// Asegurar que el operador trabaja en la sede
  Future<void> ensureTrabaja(int idPersonaOpe, int idSede) async {
    // Verificar si ya existe
    final uriGet = '/trabaja/$idPersonaOpe/$idSede';
    final resGet = await _client.get(uriGet);

    if (resGet.statusCode == 200) {
      return; // Ya existe la relación
    }

    // Crear nueva relación
    final body = {'idPersonaOpe': idPersonaOpe, 'idSede': idSede};
    final resPost = await _client.post('/trabaja', body: body);

    if (resPost.statusCode >= 200 && resPost.statusCode < 300) {
      return;
    }
    throw Exception('Error ${resPost.statusCode} al crear trabaja');
  }

  /// Crear registro de control
  Future<void> crearControla({
    required int idPersonaOpe,
    required int idReserva,
    required int idPaseAcceso,
    required String accion,
    required String resultado,
  }) async {
    final body = {
      'idPersonaOpe': idPersonaOpe,
      'idReserva': idReserva,
      'idPaseAcceso': idPaseAcceso,
      'accion': accion,
      'resultado': resultado,
    };

    final res = await _client.post('/controla', body: body);

    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Error ${res.statusCode} al crear controla');
  }

  /// Finalizar pase de acceso (actualizar usos)
  Future<void> finalizarPaseAccesoUsos({
    required int idPaseAcceso,
    required int vecesUsado,
    required String estado,
  }) async {
    final body = {'vecesUsado': vecesUsado, 'estado': estado};

    final res = await _client.patch('/pases-acceso/$idPaseAcceso', body: body);

    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Error ${res.statusCode} al actualizar pase');
  }

  /// Listar sedes asignadas al controlador logueado
  Future<List<dynamic>> getSedesAsignadas() async {
    final res = await _client.get('/trabaja/me/sedes');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data is List ? data : [];
    }
    throw Exception('Error ${res.statusCode} al obtener sedes');
  }

  /// Listar pases por sede para el controlador logueado
  Future<List<dynamic>> getPasesPorSede(int idSede) async {
    final res = await _client.get('/trabaja/me/sedes/$idSede/pases');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data is List ? data : [];
    }
    throw Exception('Error ${res.statusCode} al obtener pases de la sede');
  }
}
