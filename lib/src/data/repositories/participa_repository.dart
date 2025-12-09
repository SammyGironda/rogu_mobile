import '../../apis/participa/participa_api.dart';

class ParticipaRepository {
  final ParticipaApi _api;

  ParticipaRepository({ParticipaApi? api}) : _api = api ?? ParticipaApi();

  Future<Map<String, dynamic>> getParticipantes(int idReserva) {
    return _api.getParticipantes(idReserva);
  }

  Future<Map<String, dynamic>> invitar({
    required int idReserva,
    String? correo,
    int? idCliente,
    String? nombres,
    String? paterno,
    String? materno,
  }) {
    return _api.invitar(
      idReserva: idReserva,
      correo: correo,
      idCliente: idCliente,
      nombres: nombres,
      paterno: paterno,
      materno: materno,
    );
  }
}
