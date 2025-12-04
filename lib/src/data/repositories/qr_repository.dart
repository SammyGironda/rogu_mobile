import '../../apis/qr/qr_api.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/storage_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

/// Repository para QR y validación de acceso
class QrRepository {
  final QrApi _qrApi;

  QrRepository({QrApi? qrApi}) : _qrApi = qrApi ?? QrApi();

  /// Generar código QR para una reserva
  Future<Map<String, dynamic>> generateReservationQr(int idReserva) async {
    try {
      return await _qrApi.generateReservationQr(idReserva);
    } catch (e) {
      throw Exception('Failed to generate QR: $e');
    }
  }

  /// Validar código QR
  Future<Map<String, dynamic>> validateQr({
    required String qrCode,
    required int idControlador,
  }) async {
    try {
      return await _qrApi.validateQr(
        qrCode: qrCode,
        idControlador: idControlador,
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
}
