import '../../apis/venues/venues_api.dart';
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
      return data
          .map((e) => Field.fromJson(e as Map<String, dynamic>))
          .toList();
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
}
