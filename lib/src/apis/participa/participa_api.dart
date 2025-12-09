import 'dart:convert';
import '../../core/http/api_client.dart';

class ParticipaApi {
  final ApiClient _client;

  ParticipaApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> getParticipantes(int idReserva) async {
    final resp = await _client.get('/participa/reserva/$idReserva');
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${resp.statusCode}: ${resp.body}');
  }

  Future<Map<String, dynamic>> invitar({
    required int idReserva,
    String? correo,
    int? idCliente,
    String? nombres,
    String? paterno,
    String? materno,
  }) async {
    final body = <String, dynamic>{
      'idReserva': idReserva,
      if (correo != null && correo.isNotEmpty) 'correo': correo,
      if (idCliente != null) 'idCliente': idCliente,
      if (nombres != null && nombres.isNotEmpty) 'nombres': nombres,
      if (paterno != null && paterno.isNotEmpty) 'paterno': paterno,
      if (materno != null && materno.isNotEmpty) 'materno': materno,
    };

    final resp = await _client.post('/participa', body: body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${resp.statusCode}: ${resp.body}');
  }
}
