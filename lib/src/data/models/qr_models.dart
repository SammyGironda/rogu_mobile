class SedeAsignada {
  final int idSede;
  final String? nombre;
  final DateTime? asignadoDesde;
  final DateTime? asignadoHasta;

  SedeAsignada({
    required this.idSede,
    this.nombre,
    this.asignadoDesde,
    this.asignadoHasta,
  });

  factory SedeAsignada.fromJson(Map<String, dynamic> json) {
    return SedeAsignada(
      idSede: json['idSede'] is int
          ? json['idSede']
          : int.tryParse(json['idSede']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString(),
      asignadoDesde: json['asignadoDesde'] != null
          ? DateTime.tryParse(json['asignadoDesde'].toString())
          : null,
      asignadoHasta: json['asignadoHasta'] != null
          ? DateTime.tryParse(json['asignadoHasta'].toString())
          : null,
    );
  }
}

class PaseAccesoResumen {
  final int idPaseAcceso;
  final int idReserva;
  final String estado;
  final DateTime? validoDesde;
  final DateTime? validoHasta;
  final int usados;
  final int maximo;
  final int? idCancha;
  final String? canchaNombre;
  final int? idSede;
  final String? sedeNombre;
  final String? clienteNombre;
  final String? clienteApellido;
  final DateTime? iniciaEn;
  final DateTime? terminaEn;
  final String? codigoQR;
  final String? foto;

  PaseAccesoResumen({
    required this.idPaseAcceso,
    required this.idReserva,
    required this.estado,
    required this.usados,
    required this.maximo,
    this.validoDesde,
    this.validoHasta,
    this.idCancha,
    this.canchaNombre,
    this.idSede,
    this.sedeNombre,
    this.clienteNombre,
    this.clienteApellido,
    this.iniciaEn,
    this.terminaEn,
    this.codigoQR,
    this.foto,
  });

  PaseAccesoResumen copyWith({
    int? usados,
    int? maximo,
    String? estado,
  }) {
    return PaseAccesoResumen(
      idPaseAcceso: idPaseAcceso,
      idReserva: idReserva,
      estado: estado ?? this.estado,
      validoDesde: validoDesde,
      validoHasta: validoHasta,
      usados: usados ?? this.usados,
      maximo: maximo ?? this.maximo,
      idCancha: idCancha,
      canchaNombre: canchaNombre,
      idSede: idSede,
      sedeNombre: sedeNombre,
      clienteNombre: clienteNombre,
      clienteApellido: clienteApellido,
      iniciaEn: iniciaEn,
      terminaEn: terminaEn,
      codigoQR: codigoQR,
      foto: foto,
    );
  }

  factory PaseAccesoResumen.fromJson(Map<String, dynamic> json) {
    final usos = json['usos'] as Map<String, dynamic>? ?? {};
    final cancha = json['cancha'] as Map<String, dynamic>? ?? {};
    final cliente = json['cliente'] as Map<String, dynamic>? ?? {};
    final horario = json['horario'] as Map<String, dynamic>? ?? {};

    return PaseAccesoResumen(
      idPaseAcceso: json['idPaseAcceso'] is int
          ? json['idPaseAcceso']
          : int.tryParse(json['idPaseAcceso']?.toString() ?? '0') ?? 0,
      idReserva: json['idReserva'] is int
          ? json['idReserva']
          : int.tryParse(json['idReserva']?.toString() ?? '0') ?? 0,
      estado: json['estado']?.toString() ?? '',
      validoDesde: json['validoDesde'] != null
          ? DateTime.tryParse(json['validoDesde'].toString())
          : null,
      validoHasta: json['validoHasta'] != null
          ? DateTime.tryParse(json['validoHasta'].toString())
          : null,
      usados: usos['usados'] is int
          ? usos['usados']
          : int.tryParse(usos['usados']?.toString() ?? '0') ?? 0,
      maximo: usos['maximo'] is int
          ? usos['maximo']
          : int.tryParse(usos['maximo']?.toString() ?? '0') ?? 0,
      idCancha: cancha['idCancha'] is int
          ? cancha['idCancha']
          : int.tryParse(cancha['idCancha']?.toString() ?? ''),
      canchaNombre: cancha['nombre']?.toString(),
      idSede: cancha['idSede'] is int
          ? cancha['idSede']
          : int.tryParse(cancha['idSede']?.toString() ?? ''),
      sedeNombre: cancha['sede']?.toString(),
      clienteNombre: cliente['nombre']?.toString(),
      clienteApellido: cliente['apellido']?.toString(),
      iniciaEn: horario['iniciaEn'] != null
          ? DateTime.tryParse(horario['iniciaEn'].toString())
          : null,
      terminaEn: horario['terminaEn'] != null
          ? DateTime.tryParse(horario['terminaEn'].toString())
          : null,
      codigoQR: json['codigoQR']?.toString(),
      foto: cancha['foto']?.toString(),
    );
  }

  String get clienteCompleto {
    if ((clienteNombre ?? '').isEmpty) return clienteApellido ?? '';
    if ((clienteApellido ?? '').isEmpty) return clienteNombre ?? '';
    return '$clienteNombre $clienteApellido';
  }
}
