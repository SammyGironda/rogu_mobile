import 'dart:io';
import '../../apis/profile/profile_api.dart';
import '../../apis/profile/personas_api.dart';
import '../../apis/auth/auth_api.dart';
import '../models/persona.dart';
import '../models/user.dart';
import '../../core/utils/storage_helper.dart';

/// Repository para perfil de usuario
class ProfileRepository {
  final ProfileApi _profileApi;
  final PersonasApi _personasApi;
  final AuthApi _authApi;

  ProfileRepository({
    ProfileApi? profileApi,
    PersonasApi? personasApi,
    AuthApi? authApi,
  }) : _profileApi = profileApi ?? ProfileApi(),
       _personasApi = personasApi ?? PersonasApi(),
       _authApi = authApi ?? AuthApi();

  /// Obtener datos de persona
  Future<Persona> getPersona(String personaId) async {
    try {
      final data = await _personasApi.getPersona(personaId);
      return Persona.fromMap(data);
    } catch (e) {
      throw Exception('Failed to get persona: $e');
    }
  }

  /// Actualizar datos de persona
  Future<Persona> updatePersona({
    required String personaId,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final data = await _personasApi.updatePersona(
        personaId: personaId,
        fields: fields,
      );
      return Persona.fromMap(data);
    } catch (e) {
      throw Exception('Failed to update persona: $e');
    }
  }

  /// Actualizar datos de usuario (correo, usuario)
  Future<User> updateUsuario({
    required String userId,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final data = await _profileApi.updateUsuario(
        userId: userId,
        fields: fields,
      );

      // Actualizar en storage
      final currentUser = await StorageHelper.getUser();
      if (currentUser != null) {
        final updatedUser = User.fromMap({...currentUser, ...data});
        await StorageHelper.saveUser(updatedUser.toMap());
        return updatedUser;
      }

      return User.fromMap(data);
    } catch (e) {
      throw Exception('Failed to update usuario: $e');
    }
  }

  /// Cambiar contraseña
  Future<void> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      await _profileApi.changePassword(
        userId: userId,
        newPassword: newPassword,
      );
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  /// Cambiar contraseña validando contraseña actual
  Future<void> changePasswordWithCurrent({
    required String userEmail,
    required String currentPassword,
    required String userId,
    required String newPassword,
  }) async {
    try {
      // Verificar contraseña actual intentando login
      await _authApi.login(email: userEmail, password: currentPassword);

      // Si valida, cambiar contraseña
      await changePassword(userId: userId, newPassword: newPassword);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  /// Subir avatar
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    try {
      final data = await _profileApi.uploadAvatar(userId: userId, file: file);

      // Retornar URL del avatar
      return data['avatarUrl'] ?? data['url'] ?? '';
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Convertir usuario en dueño
  Future<void> makeOwner({
    required String personaId,
    String? imagenCI,
    String? imagenFacial,
  }) async {
    try {
      await _profileApi.makeOwner(
        personaId: int.parse(personaId),
        imagenCI: imagenCI,
        imagenFacial: imagenFacial,
      );
    } catch (e) {
      throw Exception('Failed to make owner: $e');
    }
  }

  /// Verificar roles de usuario (isOwner, isAdmin)
  /// Retorna {'isOwner': bool, 'isAdmin': bool}
  Future<Map<String, bool>> checkUserRoles(String personaId) async {
    try {
      final personaIdInt = int.parse(personaId);

      // Obtener usuario por persona
      final usuario = await _profileApi.getUsuarioByPersona(personaIdInt);
      final userId = (usuario['id'] ?? usuario['idUsuario']) as int?;

      if (userId == null) {
        return {'isOwner': false, 'isAdmin': false};
      }

      // Verificar roles: 1=ADMIN, 3=DUENIO
      final isAdmin = await _profileApi.hasUserRole(userId, 1);
      final isOwner = await _profileApi.hasUserRole(userId, 3);

      return {'isOwner': isOwner, 'isAdmin': isAdmin};
    } catch (e) {
      return {'isOwner': false, 'isAdmin': false};
    }
  }
}
