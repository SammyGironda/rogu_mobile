import '../../core/utils/image_helper.dart';

class Field {
  final int id;
  final int sedeId;
  final String nombre;
  final String? descripcion;
  final String? superficie;
  final bool? cubierta;
  final bool? iluminacion;
  final bool? techada;
	final int? aforoMaximo;
	final String? dimensiones;
	final String? reglasUso;
	final double? precio;
	final String? horaApertura;
	final String? horaCierre;
	final int? maxPlayers;
  final List<String> fotos;
  final List<String>? disciplinas;
  final String? deporte;

  Field({
    required this.id,
    required this.sedeId,
    required this.nombre,
    this.descripcion,
    this.superficie,
    this.cubierta,
    this.iluminacion,
    this.techada,
    this.aforoMaximo,
    this.dimensiones,
    this.reglasUso,
    this.precio,
		this.horaApertura,
		this.horaCierre,
		this.maxPlayers,
    required this.fotos,
    this.disciplinas,
    this.deporte,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
		final fotosRaw =
				json['fotos'] ??
				json['imagenes'] ??
				json['images'] ??
				json['photos'] ??
				[];
		final fotoPrincipal = json['fotoPrincipal']?.toString();
    final disciplinasRaw = json['disciplinas'] as List? ?? [];
    final capacity = _toInt(
      json['capacity'] ??
          json['capacidad'] ??
          json['capacidadPersonas'] ??
          json['capacidad_personas'] ??
          json['capacidadMaxima'] ??
          json['maximoPersonas'] ??
          json['maximoJugadores'] ??
          json['limiteJugadores'] ??
          json['aforo_max'] ??
          json['capacidadJugadores'] ??
          json['jugadores'] ??
          json['people'],
    );
    return Field(
      id: json['idCancha'] ?? json['id'] ?? 0,
      sedeId: json['idSede'] ?? json['sedeId'] ?? 0,
      nombre: json['nombre'] ?? 'Cancha',
      descripcion: json['descripcion']?.toString(),
      superficie: json['superficie']?.toString(),
      cubierta: _toBool(json['cubierta']),
      iluminacion: _toBool(json['iluminacion']),
      techada: _toBool(json['techada']),
      dimensiones: json['dimensiones']?.toString(),
      reglasUso: json['reglasUso']?.toString(),
      precio: _toDouble(json['precio']),
			horaApertura: json['horaApertura']?.toString(),
			horaCierre: json['horaCierre']?.toString(),
			maxPlayers: _toInt(
            json['maxPlayers'] ??
            json['capacidad'] ??
            json['capacidadPersonas'] ??
            json['capacidad_personas'] ??
            json['capacidadMaxima'] ??
            json['maximoPersonas'] ??
            json['maximoJugadores'] ??
            json['limiteJugadores'] ??
            json['aforo'] ??
            json['maxJugadores'] ??
            json['aforoMax'] ??
            json['aforoMaximo'] ??
            capacity,
          ),
      fotos: [
        ...fotosRaw
          .map(
            (e) => (e is Map
                ? (e['urlFoto'] ??
										e['url'] ??
										e['foto'] ??
										e['path'] ??
										e['imagen'])
								: e.toString()),
					)
					.where((e) => e.toString().isNotEmpty)
					.map((e) => resolveImageUrl(e.toString()))
          .toList(),
				if ((fotoPrincipal ?? '').isNotEmpty)
					resolveImageUrl(fotoPrincipal!),
			],
      aforoMaximo: _toInt(
        json['aforoMax'] ??
            json['aforo_max'] ??
            json['aforoMaximo'] ??
            json['capacidadMaxima'] ??
            capacity,
      ),
      disciplinas: disciplinasRaw.map((e) => e.toString()).toList(),
      deporte: json['deporte']?.toString(),
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

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      return parsed;
    }
    return null;
  }

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is String) {
      final lower = v.toLowerCase();
      if (lower == 'true' || lower == 'si' || lower == '1') return true;
      if (lower == 'false' || lower == 'no' || lower == '0') return false;
    }
    return null;
  }
}
