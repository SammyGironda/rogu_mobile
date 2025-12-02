import '../../apis/qr/qr_api.dart';

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
}
