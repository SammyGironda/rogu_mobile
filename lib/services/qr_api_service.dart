import 'dart:convert';
import 'package:http/http.dart' as http;

class QrApiService {
  final String baseUrl;
  final String? authToken;

  QrApiService({required this.baseUrl, this.authToken});

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<Map<String, dynamic>> getPasePorReserva(int idReserva) async {
    final uri = Uri.parse('$baseUrl/pases-acceso/reserva/$idReserva');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode} al obtener pase');
  }

  Future<void> ensureTrabaja(int idPersonaOpe, int idSede) async {
    final uriGet = Uri.parse('$baseUrl/trabaja/$idPersonaOpe/$idSede');
    final resGet = await http.get(uriGet, headers: _headers());
    if (resGet.statusCode == 200) {
      return; // ya existe
    }
    final uriPost = Uri.parse('$baseUrl/trabaja');
    final body = jsonEncode({
      'idPersonaOpe': idPersonaOpe,
      'idSede': idSede,
    });
    final resPost = await http.post(uriPost, headers: _headers(), body: body);
    if (resPost.statusCode >= 200 && resPost.statusCode < 300) {
      return;
    }
    throw Exception('Error ${resPost.statusCode} al crear trabaja');
  }

  Future<void> crearControla({
    required int idPersonaOpe,
    required int idReserva,
    required int idPaseAcceso,
    required String accion,
    required String resultado,
  }) async {
    final uri = Uri.parse('$baseUrl/controla');
    final body = jsonEncode({
      'idPersonaOpe': idPersonaOpe,
      'idReserva': idReserva,
      'idPaseAcceso': idPaseAcceso,
      'accion': accion,
      'resultado': resultado,
    });
    final res = await http.post(uri, headers: _headers(), body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Error ${res.statusCode} al crear controla');
  }

  Future<void> finalizarPaseAccesoUsos({
    required int idPaseAcceso,
    required int vecesUsado,
    required String estado,
  }) async {
    final uri = Uri.parse('$baseUrl/pases-acceso/$idPaseAcceso');
    final body = jsonEncode({
      'vecesUsado': vecesUsado,
      'estado': estado,
    });
    final res = await http.patch(uri, headers: _headers(), body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Error ${res.statusCode} al actualizar pase');
  }
}
