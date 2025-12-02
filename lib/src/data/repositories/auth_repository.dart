import '../../apis/auth/auth_api.dart';
import '../../apis/profile/personas_api.dart';
import '../models/user.dart';
import '../../core/utils/storage_helper.dart';

/// Repository para autenticación y registro
class AuthRepository {
  final AuthApi _authApi;
  final PersonasApi _personasApi;

  AuthRepository({AuthApi? authApi, PersonasApi? personasApi})
    : _authApi = authApi ?? AuthApi(),
      _personasApi = personasApi ?? PersonasApi();

  /// Login completo: autenticar + guardar token y usuario
  Future<User> login({required String email, required String password}) async {
    try {
      final response = await _authApi.login(email: email, password: password);

      final token = response['token'] as String;
      final userData = response['usuario'] as Map<String, dynamic>;

      // Guardar token
      await StorageHelper.saveToken(token);

      // Mapear y guardar usuario
      final user = User.fromMap(userData);
      await StorageHelper.saveUser(user.toMap());

      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Registro completo: crear persona + crear usuario
  Future<void> register({
    required String nombres,
    required String paterno,
    required String materno,
    required String telefono,
    required String fechaNacimiento,
    required String genero,
    required String usuario,
    required String correo,
    required String contrasena,
    String? ci,
  }) async {
    try {
      // Paso 1: crear persona
      final personaResponse = await _personasApi.createPersona(
        nombres: nombres.trim(),
        paterno: paterno.trim(),
        materno: materno.trim(),
        telefono: telefono.trim(),
        fechaNacimiento: fechaNacimiento,
        genero: _mapGeneroEnum(genero),
        documentoNumero: ci?.trim(),
        documentoTipo: ci != null && ci.isNotEmpty ? 'CC' : null,
      );

      final idPersona = personaResponse['id'] ?? personaResponse['idPersona'];
      if (idPersona == null) {
        throw Exception('No se obtuvo idPersona al crear persona');
      }

      // Paso 2: registrar usuario
      await _authApi.register(
        idPersona: idPersona is int
            ? idPersona
            : int.parse(idPersona.toString()),
        usuario: usuario,
        correo: correo,
        contrasena: contrasena,
      );
    } catch (e) {
      throw Exception('Register failed: $e');
    }
  }

  /// Logout: limpiar storage
  Future<void> logout() async {
    await StorageHelper.clearAll();
  }

  /// Obtener usuario guardado en storage
  Future<User?> getCurrentUser() async {
    final userData = await StorageHelper.getUser();
    if (userData != null) {
      return User.fromMap(userData);
    }
    return null;
  }

  /// Verificar si hay sesión activa
  Future<bool> isAuthenticated() async {
    final token = await StorageHelper.getToken();
    return token != null && token.isNotEmpty;
  }

  String _mapGeneroEnum(String genero) {
    switch (genero.toUpperCase()) {
      case 'M':
      case 'MASCULINO':
        return 'MASCULINO';
      case 'F':
      case 'FEMENINO':
        return 'FEMENINO';
      case 'O':
      case 'OTRO':
        return 'OTRO';
      default:
        return 'OTRO';
    }
  }
}
