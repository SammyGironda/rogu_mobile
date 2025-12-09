import 'field.dart';
import '../../core/utils/image_helper.dart';

class Venue {
	final int id;
	final String nombre;
	final String? ciudad;
	final String? direccion;
	final String? fotoPrincipal;
	final String? descripcion;
	final String? propietario;
	final String? telefono;
	final String? email;
	final double? lat;
	final double? lon;
	final String? managerName;
	final String? managerPhone;
	final String? managerEmail;
	final int? totalCanchas;
	final List<String> deportesDisponibles;
	final List<Field> canchas;

	Venue({
		required this.id,
		required this.nombre,
		this.ciudad,
		this.direccion,
		this.fotoPrincipal,
		this.descripcion,
		this.propietario,
		this.telefono,
		this.email,
		this.lat,
		this.lon,
		this.managerName,
		this.managerPhone,
		this.managerEmail,
		this.totalCanchas,
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

		double? _parseDouble(dynamic value) {
			if (value == null) return null;
			final stringValue = value.toString();
			if (stringValue.isEmpty) return null;
			return double.tryParse(stringValue);
		}

		final direccionRaw =
				json['direccion'] ??
				json['address'] ??
				json['ubicacion'] ??
				json['direccionCompleta'] ??
				json['addressLine'];
		final ciudadRaw =
				json['ciudad'] ??
				json['city'] ??
				json['distrito'] ??
				json['district'];
		final duenoRaw = json['duenio'] ?? json['dueno'] ?? json['owner'];

		String? _buildManagerName(dynamic dueno) {
			if (dueno is Map) {
				final nombre = dueno['nombre']?.toString() ?? '';
				final apellido = dueno['apellido']?.toString() ?? '';
				final combined = '$nombre $apellido'.trim();
				return combined.isNotEmpty ? combined : null;
			}
			if (dueno is String && dueno.isNotEmpty) return dueno;
			return null;
		}

		String? _managerPhone(dynamic dueno) {
			if (dueno is Map) {
				return (dueno['telefono'] ??
						dueno['phone'] ??
						dueno['mobile'])
					?.toString();
			}
			return null;
		}

		String? _managerEmail(dynamic dueno) {
			if (dueno is Map) {
				return (dueno['correo'] ?? dueno['email'])?.toString();
			}
			return null;
		}

		String? _resolveFotoPrincipal() {
			final direct = json['fotoPrincipal']?.toString();
			if (direct != null && direct.isNotEmpty) {
				return resolveImageUrl(direct);
			}
			final fotos = json['fotos'] as List?;
			if (fotos != null && fotos.isNotEmpty) {
				final first = fotos.first;
				if (first is Map) {
					final url =
						first['urlFoto'] ??
						first['url'] ??
						first['foto'] ??
						first['path'];
					if (url != null && url.toString().isNotEmpty) {
						return resolveImageUrl(url.toString());
					}
				} else if (first is String && first.isNotEmpty) {
					return resolveImageUrl(first);
				}
			}
			return null;
		}

		return Venue(
			id: json['idSede'] ?? json['id'] ?? 0,
			nombre: json['nombre'] ?? 'Sede',
			ciudad: ciudadRaw?.toString(),
			direccion: direccionRaw?.toString(),
			fotoPrincipal: _resolveFotoPrincipal(),
			descripcion: json['descripcion']?.toString(),
			propietario: (json['dueno'] ?? json['propietario'] ?? json['owner'])
					?.toString(),
			telefono: (json['telefono'] ?? json['contacto'])?.toString(),
			email: json['email']?.toString(),
			lat: _parseDouble(json['latitud'] ?? json['latitude']),
			lon: _parseDouble(json['longitud'] ?? json['longitude']),
			managerName: _buildManagerName(duenoRaw),
			managerPhone: _managerPhone(duenoRaw) ?? (json['telefono']?.toString()),
			managerEmail: _managerEmail(duenoRaw) ?? json['email']?.toString(),
			totalCanchas: json['estadisticas']?['totalCanchas'] as int? ??
					json['totalCanchas'] as int? ??
					rawFields.length,
			deportesDisponibles: deportes,
			canchas: rawFields
					.map((e) => Field.fromJson(e as Map<String, dynamic>))
					.toList(),
		);
	}

	/// Retorna una ubicación corta priorizando dirección, luego ciudad y
	/// finalmente las coordenadas si están disponibles.
	String getShortLocation() {
		if (direccion != null && direccion!.isNotEmpty) return direccion!;
		if (ciudad != null && ciudad!.isNotEmpty) return ciudad!;
		if (lat != null && lon != null) {
			return 'Lat ${lat!.toStringAsFixed(4)}, Lon ${lon!.toStringAsFixed(4)}';
		}
		return 'Ubicación no disponible';
	}
}
