import '../../apis/qr/qr_api.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/storage_helper.dart';
import '../models/qr_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

/// Repository para QR y validacion de acceso
class QrRepository {
  final QrApi _qrApi;

  QrRepository({QrApi? qrApi}) : _qrApi = qrApi ?? QrApi();

  /// Generar codigo QR para una reserva
  Future<Map<String, dynamic>> generateReservationQr(int idReserva) async {
    try {
      return await _qrApi.generateReservationQr(idReserva);
    } catch (e) {
      throw Exception('Failed to generate QR: $e');
    }
  }

  /// Validar codigo QR
  Future<Map<String, dynamic>> validateQr({
    required String qrCode,
    required String accion,
    int? idPersonaOpe,
  }) async {
    try {
      return await _qrApi.validateQr(
        qrCode: qrCode,
        accion: accion,
        idPersonaOpe: idPersonaOpe,
      );
    } catch (e) {
      throw Exception('Failed to validate QR: $e');
    }
  }

  /// Obtener pases de acceso para una reserva
  Future<List<Map<String, dynamic>>> getReservationPasses(int idReserva) async {
    try {
      final data = await _qrApi.getReservationPasses(idReserva);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get reservation passes: $e');
    }
  }

  /// Obtener un solo pase por reserva
  Future<Map<String, dynamic>> getPassByReserva(int idReserva) async {
    try {
      return await _qrApi.getPassByReserva(idReserva);
    } catch (e) {
      throw Exception('Failed to get pass by reserva: $e');
    }
  }

  /// Descargar la imagen del QR como bytes (similar a /pases-acceso/:id/qr en web)
  Future<Uint8List> getQrImageBytes(int idPaseAcceso) async {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    final url = '$base/api/pases-acceso/$idPaseAcceso/qr';
    final token = await StorageHelper.getToken();
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final resp = await http.get(Uri.parse(url), headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load QR image (${resp.statusCode})');
    }
    return resp.bodyBytes;
  }

  /// Devuelve DataURL para usar en Image.memory con base64 si se necesita
  Future<String> getQrImageDataUrl(int idPaseAcceso) async {
    final bytes = await getQrImageBytes(idPaseAcceso);
    final b64 = base64Encode(bytes);
    return 'data:image/png;base64,$b64';
  }

  /// Asegurar que el operador trabaja en la sede
  Future<void> ensureTrabaja(int idPersonaOpe, int idSede) async {
    try {
      return await _qrApi.ensureTrabaja(idPersonaOpe, idSede);
    } catch (e) {
      throw Exception('Failed to ensure trabaja: $e');
    }
  }

  /// Crear registro de control
  Future<void> crearControla({
    required int idPersonaOpe,
    required int idReserva,
    required int idPaseAcceso,
    required String accion,
    required String resultado,
  }) async {
    try {
      return await _qrApi.crearControla(
        idPersonaOpe: idPersonaOpe,
        idReserva: idReserva,
        idPaseAcceso: idPaseAcceso,
        accion: accion,
        resultado: resultado,
      );
    } catch (e) {
      throw Exception('Failed to create controla: $e');
    }
  }

  /// Finalizar pase de acceso (actualizar usos)
  Future<void> finalizarPaseAccesoUsos({
    required int idPaseAcceso,
    required int vecesUsado,
    required String estado,
  }) async {
    try {
      return await _qrApi.finalizarPaseAccesoUsos(
        idPaseAcceso: idPaseAcceso,
        vecesUsado: vecesUsado,
        estado: estado,
      );
    } catch (e) {
      throw Exception('Failed to finalize pase acceso: $e');
    }
  }

  Future<List<SedeAsignada>> getSedesAsignadas() async {
    try {
      final data = await _qrApi.getSedesAsignadas();
      return data
          .map((e) => SedeAsignada.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sedes: $e');
    }
  }

  Future<List<PaseAccesoResumen>> getPasesPorSede(int idSede) async {
    try {
      final data = await _qrApi.getPasesPorSede(idSede);
      return data
          .map((e) => PaseAccesoResumen.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pases por sede: $e');
    }
  }

  /// Obtener todos los registros de acceso (tabla controla) de una sede
  Future<List<Map<String, dynamic>>> getAccessLogsBySede(int idSede) async {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    final url = '$base/api/controla/sede/$idSede';
    final token = await StorageHelper.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final resp = await http.get(Uri.parse(url), headers: headers);

    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to load access logs (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body);
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
