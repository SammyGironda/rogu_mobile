import 'field.dart';

class Venue {
  final int id;
  final String nombre;
  final String? ciudad;
  final String? direccion;
  final String? fotoPrincipal;
  final List<String> deportesDisponibles;
  final List<Field> canchas;

  Venue({
    required this.id,
    required this.nombre,
    this.ciudad,
    this.direccion,
    this.fotoPrincipal,
    required this.deportesDisponibles,
    required this.canchas,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    final deportes =
        (json['estadisticas']?['deportesDisponibles'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final rawFields = json['canchas'] as List? ?? [];
    return Venue(
      id: json['idSede'] ?? json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sede',
      ciudad: json['ciudad']?.toString(),
      direccion: json['direccion']?.toString(),
      fotoPrincipal: json['fotoPrincipal']?.toString(),
      deportesDisponibles: deportes,
      canchas: rawFields
          .map((e) => Field.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
