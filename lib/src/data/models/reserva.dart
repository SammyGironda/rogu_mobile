/// Modelo Cliente (persona que escanea su QR para ingresar)
class Cliente {
  final String id; // ID único del cliente
  final String nombre;
  final String documento; // Documento de identidad
  final String qrCode;
  final bool escaneado;
  final String? horaEscaneo;

  Cliente({
    required this.id,
    required this.nombre,
    required this.documento,
    required this.qrCode,
    this.escaneado = false,
    this.horaEscaneo,
  });

  Cliente copyWith({
    String? id,
    String? nombre,
    String? documento,
    String? qrCode,
    bool? escaneado,
    String? horaEscaneo,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      documento: documento ?? this.documento,
      qrCode: qrCode ?? this.qrCode,
      escaneado: escaneado ?? this.escaneado,
      horaEscaneo: horaEscaneo ?? this.horaEscaneo,
    );
  }

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      documento: json['documento'] ?? '',
      qrCode: json['qrCode'] ?? '',
      escaneado: json['escaneado'] ?? false,
      horaEscaneo: json['horaEscaneo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'documento': documento,
      'qrCode': qrCode,
      'escaneado': escaneado,
      'horaEscaneo': horaEscaneo,
    };
  }
}

/// Modelo Reserva para sistema de escaneo QR
class Reserva {
  final String id;
  final String nombreReserva; // Nombre descriptivo de la reserva
  final String fecha; // Formato ISO: yyyy-MM-dd
  final String hora; // Formato: HH:mm
  final String cancha; // Nombre de la cancha
  final int? sedeId; // ID de la sede (opcional)
  final List<Cliente> clientes;
  final String estado; // 'pendiente' | 'en_proceso' | 'completada'
  final int totalPersonas;

  const Reserva({
    required this.id,
    required this.nombreReserva,
    required this.fecha,
    required this.hora,
    required this.cancha,
    this.sedeId,
    required this.clientes,
    required this.estado,
    required this.totalPersonas,
  });

  Reserva copyWith({
    String? id,
    String? nombreReserva,
    String? fecha,
    String? hora,
    String? cancha,
    int? sedeId,
    List<Cliente>? clientes,
    String? estado,
    int? totalPersonas,
  }) {
    return Reserva(
      id: id ?? this.id,
      nombreReserva: nombreReserva ?? this.nombreReserva,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      cancha: cancha ?? this.cancha,
      sedeId: sedeId ?? this.sedeId,
      clientes: clientes ?? this.clientes,
      estado: estado ?? this.estado,
      totalPersonas: totalPersonas ?? this.totalPersonas,
    );
  }

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'].toString(),
      nombreReserva: json['nombreReserva'] ?? json['nombre'] ?? '',
      fecha: json['fecha'] ?? '',
      hora: json['hora'] ?? '',
      cancha: json['cancha'] ?? json['nombreCancha'] ?? '',
      sedeId: json['sedeId'] as int?,
      clientes:
          (json['clientes'] as List?)
              ?.map((c) => Cliente.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      estado: json['estado'] ?? 'pendiente',
      totalPersonas: json['totalPersonas'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreReserva': nombreReserva,
      'fecha': fecha,
      'hora': hora,
      'cancha': cancha,
      'sedeId': sedeId,
      'clientes': clientes.map((c) => c.toJson()).toList(),
      'estado': estado,
      'totalPersonas': totalPersonas,
    };
  }
}

/// Enum para tipo de escaneo
enum ScanType { success, warning, error }

/// Resultado del escaneo
class ScanResult {
  final bool success;
  final String message;
  final ScanType type;
  final Cliente? cliente;

  ScanResult({
    required this.success,
    required this.message,
    required this.type,
    this.cliente,
  });
}
