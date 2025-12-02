import '../../apis/venues/fields_api.dart';
import '../models/field.dart';

/// Repository para canchas/fields
class FieldsRepository {
  final FieldsApi _fieldsApi;

  FieldsRepository({FieldsApi? fieldsApi})
    : _fieldsApi = fieldsApi ?? FieldsApi();

  /// Obtener todas las canchas
  Future<List<Field>> getAllFields() async {
    try {
      final data = await _fieldsApi.getAllFields();
      return data
          .map((e) => Field.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all fields: $e');
    }
  }

  /// Obtener cancha por ID
  Future<Field> getField(int idCancha) async {
    try {
      final data = await _fieldsApi.getField(idCancha);
      return Field.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get field: $e');
    }
  }

  /// Obtener canchas por sede
  Future<List<Field>> getFieldsByVenue(int venueId) async {
    try {
      final data = await _fieldsApi.getAllFields();
      final fields = data
          .map((e) => Field.fromJson(e as Map<String, dynamic>))
          .where((f) => f.sedeId == venueId)
          .toList();
      return fields;
    } catch (e) {
      throw Exception('Failed to get fields by venue: $e');
    }
  }

  /// Crear cancha
  Future<Field> createField(Map<String, dynamic> fieldData) async {
    try {
      final data = await _fieldsApi.createField(fieldData);
      return Field.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create field: $e');
    }
  }

  /// Actualizar cancha
  Future<Field> updateField({
    required int idCancha,
    required Map<String, dynamic> fieldData,
  }) async {
    try {
      final data = await _fieldsApi.updateField(
        idCancha: idCancha,
        fieldData: fieldData,
      );
      return Field.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update field: $e');
    }
  }

  /// Eliminar cancha
  Future<void> deleteField(int idCancha) async {
    try {
      await _fieldsApi.deleteField(idCancha);
    } catch (e) {
      throw Exception('Failed to delete field: $e');
    }
  }

  /// Buscar disciplinas
  Future<List<Map<String, dynamic>>> searchDisciplines(String query) async {
    try {
      final data = await _fieldsApi.searchDisciplines(query);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to search disciplines: $e');
    }
  }
}
