import 'dart:async';
import '../../apis/bookings/reservations_api.dart';
import '../../apis/deprecated/gestion_service.dart';
import '../models/reserva.dart' as model;

class PendingReservationsRepository {
  final ReservationsApi _reservationsApi;

  PendingReservationsRepository({ReservationsApi? reservationsApi})
      : _reservationsApi = reservationsApi ?? ReservationsApi();

  /// Carga reservas pendientes de la sede indicada.
  /// Obtiene canchas de la sede y consulta reservas por fecha actual.
  Future<List<model.Reserva>> loadPendingBySede({required int idSede}) async {
    final today = DateTime.now();
    final yyyy = today.year.toString().padLeft(4, '0');
    final mm = today.month.toString().padLeft(2, '0');
    final dd = today.day.toString().padLeft(2, '0');
    final fecha = '$yyyy-$mm-$dd';

    final canchasResp = await gestionService.listCanchas(idSede);
    final canchas = (canchasResp['canchas'] as List?) ?? [];

    final List<model.Reserva> result = [];
    for (final cancha in canchas) {
      final idCancha = cancha['idCancha'] as int?;
      final nombreCancha = cancha['nombre']?.toString() ?? 'Cancha';
      if (idCancha == null) continue;
      final reservas = await _reservationsApi.getFieldReservations(
        idCancha: idCancha,
        fecha: fecha,
      );
      for (final r in reservas) {
        final estado = (r['estado']?.toString().toLowerCase()) ?? 'pendiente';
        if (estado != 'pendiente') continue;

        // Excluir completadas explícitas
        final completadaEn = r['completadaEn'];
        if (completadaEn != null) continue;

        // Excluir vencidas: si horaFin ya pasó respecto a ahora
        final fechaStr = (r['fecha']?.toString() ?? fecha);
        final horaFinStr = (r['horaFin']?.toString() ?? '');
        DateTime? fin;
        try {
          if (horaFinStr.isNotEmpty) {
            fin = DateTime.parse('$fechaStr ${horaFinStr}');
          }
        } catch (_) {}
        if (fin != null && DateTime.now().isAfter(fin)) {
          // ya caducó, no incluir
          continue;
        }

        final horaInicio = (r['horaInicio']?.toString() ?? '').substring(0, 5);
        result.add(
          model.Reserva(
            id: (r['idReserva']?.toString() ?? ''),
            nombreReserva: r['nombreReserva']?.toString() ?? '-',
            fecha: fechaStr,
            hora: horaInicio.isEmpty ? '-' : horaInicio,
            cancha: nombreCancha,
            sedeId: idSede,
            clientes: const [],
            estado: 'pendiente',
            totalPersonas: (r['cantidadPersonas'] as int?) ?? 0,
          ),
        );
      }
    }
    return result;
  }
}
