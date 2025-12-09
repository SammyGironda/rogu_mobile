import '../../apis/venues/venues_api.dart';
import '../../apis/venues/fields_api.dart';
import '../models/venue.dart';
import '../models/field.dart';

/// Repository para sedes/venues
class VenuesRepository {
  final VenuesApi _venuesApi;

  VenuesRepository({VenuesApi? venuesApi})
    : _venuesApi = venuesApi ?? VenuesApi();

  /// Obtener sedes para página inicio
  Future<List<Venue>> getVenuesInicio() async {
    try {
      final data = await _venuesApi.getVenuesInicio();
      return data
          .map((e) => Venue.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get venues inicio: $e');
    }
  }

  /// Obtener sede por ID
  Future<Venue> getVenue(int idSede) async {
    try {
      final data = await _venuesApi.getVenue(idSede);
      return Venue.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get venue: $e');
    }
  }

  /// Obtener canchas de una sede
  Future<List<Field>> getVenueFields(int idSede, {String? deporte}) async {
    try {
      final data = await _venuesApi.getVenueFields(idSede, deporte: deporte);
      List<Field> fields = data
          .map((e) => Field.fromJson(e as Map<String, dynamic>))
          .toList();

      // Completar aforo/capacidad y fotos usando detalle de cancha cuando falte
      final needsDetail = fields.where((f) {
        final missingCapacity = (f.maxPlayers ?? f.aforoMaximo) == null;
        final missingPhotos = f.fotos.isEmpty;
        return missingCapacity || missingPhotos;
      }).toList();

      if (needsDetail.isNotEmpty) {
        final fieldsApi = FieldsApi();
        for (final f in needsDetail) {
          try {
            final detail = await fieldsApi.getField(f.id);
            final detailField = Field.fromJson(detail);
            final merged = _mergeFieldData(f, detailField);
            final idx = fields.indexWhere((x) => x.id == f.id);
            if (idx != -1) {
              fields[idx] = merged;
            }
          } catch (_) {
            // Ignorar si falla el detalle y continuar con los datos actuales
          }
        }
      }

      return fields;
    } catch (e) {
      throw Exception('Failed to get venue fields: $e');
    }
  }

  /// Crear sede
  Future<Venue> createVenue(Map<String, dynamic> sedeData) async {
    try {
      final data = await _venuesApi.createVenue(sedeData);
      return Venue.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create venue: $e');
    }
  }

  /// Actualizar sede
  Future<Venue> updateVenue({
    required int idSede,
    required Map<String, dynamic> sedeData,
  }) async {
    try {
      final data = await _venuesApi.updateVenue(
        idSede: idSede,
        sedeData: sedeData,
      );
      return Venue.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update venue: $e');
    }
  }

  /// Eliminar sede
  Future<void> deleteVenue(int idSede) async {
    try {
      await _venuesApi.deleteVenue(idSede);
    } catch (e) {
      throw Exception('Failed to delete venue: $e');
    }
  }

  /// Obtener sede por personaId
  Future<Map<String, dynamic>> getVenueByPersona(int personaId) async {
    try {
      final data = await _venuesApi.getSedeByPersona(personaId);
      return data;
    } catch (e) {
      throw Exception('Failed to get venue by persona: $e');
    }
  }

  Field _mergeFieldData(Field base, Field detail) {
    return Field(
      id: base.id != 0 ? base.id : detail.id,
      sedeId: base.sedeId != 0 ? base.sedeId : detail.sedeId,
      nombre: base.nombre.isNotEmpty ? base.nombre : detail.nombre,
      descripcion: base.descripcion ?? detail.descripcion,
      superficie: base.superficie ?? detail.superficie,
      cubierta: base.cubierta ?? detail.cubierta,
      iluminacion: base.iluminacion ?? detail.iluminacion,
      techada: base.techada ?? detail.techada,
      aforoMaximo: detail.aforoMaximo ?? base.aforoMaximo,
      dimensiones: base.dimensiones ?? detail.dimensiones,
      reglasUso: base.reglasUso ?? detail.reglasUso,
      precio: base.precio ?? detail.precio,
      horaApertura: base.horaApertura ?? detail.horaApertura,
      horaCierre: base.horaCierre ?? detail.horaCierre,
      maxPlayers: detail.maxPlayers ?? base.maxPlayers,
      fotos: base.fotos.isNotEmpty ? base.fotos : detail.fotos,
      disciplinas: (base.disciplinas != null && base.disciplinas!.isNotEmpty)
          ? base.disciplinas
          : detail.disciplinas,
      deporte: base.deporte ?? detail.deporte,
    );
  }
}
