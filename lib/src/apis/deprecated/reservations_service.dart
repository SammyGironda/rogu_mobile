import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

class ReservationSlot {
  final String horaInicio; // HH:MM:SS
  final String horaFin; // HH:MM:SS
  final bool ocupado;
  ReservationSlot({
    required this.horaInicio,
    required this.horaFin,
    required this.ocupado,
  });
}

class ReservationsService {
  final String baseUrl;
  ReservationsService({String? baseUrl})
    : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<List<Map<String, dynamic>>> getReservationsForField(
    int idCancha,
    DateTime date,
  ) async {
    final fecha = date.toIso8601String().split('T').first; // YYYY-MM-DD
    final uri = Uri.parse('$baseUrl/reservas/cancha/$idCancha?fecha=$fecha');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} al obtener reservas');
    }
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getReservationsForUser(
    int idUsuario,
  ) async {
    final uri = Uri.parse('$baseUrl/reservas/usuario/$idUsuario');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} al obtener historial');
    }
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  List<ReservationSlot> buildSlots(
    List<Map<String, dynamic>> existing, {
    int inicioHora = 6,
    int finHora = 24,
  }) {
    final slots = <ReservationSlot>[];
    // Convert existing reservations to time ranges
    bool overlap(String start, String end, String slotStart, String slotEnd) {
      return (start.compareTo(slotEnd) < 0) && (end.compareTo(slotStart) > 0);
    }

    for (int h = inicioHora; h < finHora; h++) {
      final start = formatHour(h);
      final end = formatHour(h + 1);
      final ocupado = existing.any(
        (r) => overlap(
          r['horaInicio'] as String,
          r['horaFin'] as String,
          start,
          end,
        ),
      );
      slots.add(
        ReservationSlot(horaInicio: start, horaFin: end, ocupado: ocupado),
      );
    }
    return slots;
  }

  Future<Map<String, dynamic>> createReservation({
    required int idCliente,
    required int idCancha,
    required DateTime inicia,
    required DateTime termina,
    int cantidadPersonas = 2,
    bool requiereAprobacion = false,
    double montoBase = 0,
    double montoExtra = 0,
    String? token,
  }) async {
    final body = {
      'idCliente': idCliente,
      'idCancha': idCancha,
      'iniciaEn': inicia.toIso8601String(),
      'terminaEn': termina.toIso8601String(),
      'cantidadPersonas': cantidadPersonas,
      'requiereAprobacion': requiereAprobacion,
      'montoBase': montoBase,
      'montoExtra': montoExtra,
      'montoTotal': montoBase + montoExtra,
    };
    final uri = Uri.parse('$baseUrl/reservas');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final res = await http.post(uri, headers: headers, body: jsonEncode(body));
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        'Error al crear reserva (${res.statusCode}): ${res.body}',
      );
    }
    final data = jsonDecode(res.body);
    return data is Map<String, dynamic> ? data : {'raw': data};
  }

  String formatHour(int hour) => hour.toString().padLeft(2, '0') + ':00:00';
}

final reservationsService = ReservationsService();
