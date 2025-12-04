import '../../apis/bookings/reservations_api.dart';

/// Repository para reservas
class ReservationsRepository {
  final ReservationsApi _reservationsApi;

  ReservationsRepository({ReservationsApi? reservationsApi})
    : _reservationsApi = reservationsApi ?? ReservationsApi();

  /// Obtener reservas de una cancha para una fecha
  Future<List<Map<String, dynamic>>> getFieldReservations({
    required int idCancha,
    required DateTime fecha,
  }) async {
    try {
      final fechaStr = fecha.toIso8601String().split('T').first; // YYYY-MM-DD
      final data = await _reservationsApi.getFieldReservations(
        idCancha: idCancha,
        fecha: fechaStr,
      );
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get field reservations: $e');
    }
  }

  /// Obtener reservas de un usuario
  Future<List<Map<String, dynamic>>> getUserReservations(int idUsuario) async {
    try {
      final data = await _reservationsApi.getUserReservations(idUsuario);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get user reservations: $e');
    }
  }

  /// Crear reserva
  Future<Map<String, dynamic>> createReservation({
    required int idCliente,
    required int idCancha,
    required DateTime inicia,
    required DateTime termina,
    int cantidadPersonas = 2,
    bool requiereAprobacion = false,
    double montoBase = 0,
    double montoExtra = 0,
  }) async {
    try {
      final data = await _reservationsApi.createReservation(
        idCliente: idCliente,
        idCancha: idCancha,
        iniciaEn: inicia.toIso8601String(),
        terminaEn: termina.toIso8601String(),
        cantidadPersonas: cantidadPersonas,
        requiereAprobacion: requiereAprobacion,
        montoBase: montoBase,
        montoExtra: montoExtra,
      );
      return data;
    } catch (e) {
      throw Exception('Failed to create reservation: $e');
    }
  }

  /// Cancelar reserva
  Future<void> cancelReservation(int idReserva) async {
    try {
      await _reservationsApi.cancelReservation(idReserva);
    } catch (e) {
      throw Exception('Failed to cancel reservation: $e');
    }
  }

  /// Obtener detalles de una reserva
  Future<Map<String, dynamic>> getReservation(int idReserva) async {
    try {
      final data = await _reservationsApi.getReservation(idReserva);
      return data;
    } catch (e) {
      throw Exception('Failed to get reservation: $e');
    }
  }

  /// Construir slots de tiempo disponibles/ocupados
	List<ReservationSlot> buildSlots(
		List<Map<String, dynamic>> existing, {
		int inicioHora = 6,
		int finHora = 22,
		int intervaloMinutos = 60,
	}) {
		final slots = <ReservationSlot>[];
		if (finHora <= inicioHora) return slots;

		bool overlap(String start, String end, String slotStart, String slotEnd) {
			return (start.compareTo(slotEnd) < 0) && (end.compareTo(slotStart) > 0);
		}

		DateTime current =
			DateTime(0, 1, 1, inicioHora, 0);
		final DateTime endBoundary =
			DateTime(0, 1, 1, finHora, 0);

		while (current.isBefore(endBoundary)) {
			final next = current.add(Duration(minutes: intervaloMinutos));
			if (next.isAfter(endBoundary)) break;
			final start = _formatTime(current);
			final end = _formatTime(next);
			final ocupado = existing.any(
				(r) => overlap(
					(r['horaInicio'] ?? r['iniciaEn'] ?? '').toString(),
					(r['horaFin'] ?? r['terminaEn'] ?? '').toString(),
					start,
					end,
				),
			);
			slots.add(
				ReservationSlot(horaInicio: start, horaFin: end, ocupado: ocupado),
			);
			current = next;
		}
		slots.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
		return slots;
	}

	String _formatTime(DateTime dt) {
		final h = dt.hour.toString().padLeft(2, '0');
		final m = dt.minute.toString().padLeft(2, '0');
		return '$h:$m:00';
	}
}

/// Modelo para slots de reserva
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
