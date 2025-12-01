import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/venue.dart';
import '../models/field.dart';
import '../config/app_config.dart';

class FieldsService {
  final String baseUrl;
  FieldsService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<List<Venue>> fetchVenuesInicio() async {
    final uri = Uri.parse('$baseUrl/sede/inicio');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} al cargar sedes');
    }
    final data = jsonDecode(res.body);
    if (data is! List) return [];
    // Los objetos devueltos aquí no incluyen canchas; se almacenan vacías inicialmente.
    return data.map<Venue>((e) {
      final map = e as Map<String, dynamic>;
      return Venue(
        id: map['idSede'] ?? map['id'] ?? 0,
        nombre: map['nombre'] ?? 'Sede',
        ciudad: map['ciudad']?.toString(),
        direccion: map['direccion']?.toString(),
        fotoPrincipal: map['fotoPrincipal']?.toString(),
        deportesDisponibles:
            (map['estadisticas']?['deportesDisponibles'] as List?)
                ?.map((d) => d.toString())
                .toList() ??
            <String>[],
        canchas: const [],
      );
    }).toList();
  }

  Future<List<Field>> fetchVenueFields(int idSede, {String? deporte}) async {
    final qs = deporte != null && deporte.isNotEmpty
        ? '?deporte=${Uri.encodeQueryComponent(deporte)}'
        : '';
    final uri = Uri.parse('$baseUrl/sede/$idSede/canchas$qs');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} al obtener canchas');
    }
    final data = jsonDecode(res.body);
    final raw = (data is Map && data['canchas'] is List)
        ? data['canchas'] as List
        : (data is List ? data : []);
    return raw
        .map<Field>((e) => Field.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Field>> fetchAllFields() async {
    final uri = Uri.parse('$baseUrl/cancha');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} al obtener todas las canchas');
    }
    final data = jsonDecode(res.body);
    final raw = (data is List) ? data : [];
    return raw
        .map<Field>((e) => Field.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> searchDisciplines(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(
      '$baseUrl/disciplina/search?q=${Uri.encodeQueryComponent(query)}',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}

final fieldsService = FieldsService();
