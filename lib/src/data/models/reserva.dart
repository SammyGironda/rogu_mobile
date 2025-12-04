import 'package:flutter/material.dart';

class Cliente {
  final String id;
  final String nombre;
  final String documento;
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
}

class Reserva {
  final String id;
  final String nombreReserva;
  final String fecha; // ISO yyyy-MM-dd
  final String hora; // HH:mm
  final String cancha;
  final int? sedeId; // ID de la sede a la que pertenece la cancha
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
}

class ScanResult {
  final bool success;
  final String message;
  final Cliente? cliente;
  final ScanType type;

  const ScanResult({
    required this.success,
    required this.message,
    this.cliente,
    required this.type,
  });
}

enum ScanType { success, error, warning }
