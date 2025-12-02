class Field {
  final int id;
  final String nombre;
  final String? descripcion;
  final double? precio;
  final List<String> fotos;
  final String? deporte;
  final bool? iluminacion;

  Field({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.precio,
    required this.fotos,
    this.deporte,
    this.iluminacion,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    final fotosRaw = json['fotos'] as List? ?? [];
    return Field(
      id: json['idCancha'] ?? json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Cancha',
      descripcion: json['descripcion']?.toString(),
      precio: _toDouble(json['precio']),
      fotos: fotosRaw
          .map(
            (e) => (e is Map ? (e['urlFoto'] ?? e['url'] ?? '') : e.toString()),
          )
          .where((e) => e.toString().isNotEmpty)
          .cast<String>()
          .toList(),
      deporte: json['deporte']?.toString(),
      iluminacion: json['iluminacion'] is bool ? json['iluminacion'] : null,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      return parsed;
    }
    return null;
  }
}
