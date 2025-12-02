import 'dart:io';
import '../../apis/profile/profile_api.dart';
import '../../apis/profile/personas_api.dart';
import '../../apis/auth/auth_api.dart';
import '../models/persona.dart';
import '../models/user.dart';
import '../models/profile_data.dart';
import '../../core/utils/storage_helper.dart';
import '../../core/config/app_config.dart';

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

  /// Obtener perfil completo y normalizado (usuario + persona + roles + avatar)
  Future<ProfileData> fetchProfile() async {
    final raw = await _profileApi.getProfile();
    final usuario = (raw['usuario'] ?? raw) as Map<String, dynamic>;
    final personaMap =
        raw['persona'] ?? usuario['persona'] ?? raw['cliente']?['persona'];
    final persona = personaMap != null
        ? Persona.fromMap(Map<String, dynamic>.from(personaMap))
        : null;

    final roles = _extractRoles(usuario);
    final String primaryRole = roles.isNotEmpty ? roles.first : 'CLIENTE';

    final avatarPath = _toNullableString(
      usuario['avatarPath'] ?? usuario['avatar_path'],
    );
    final avatarCandidate = _toNullableString(usuario['avatar']) ??
        avatarPath ??
        persona?.urlFoto;
    final avatarUrl = _resolveAvatarUrl(avatarCandidate);

    final bool correoVerificado = _toBool(
      usuario['correoVerificado'] ?? usuario['correo_verificado'],
    );
    final bool telefonoVerificado = persona?.telefonoVerificado ?? false;

    return ProfileData(
      persona: persona,
      roles: roles,
      primaryRole: primaryRole,
      avatarUrl: avatarUrl,
      avatarPath: avatarPath,
      correoVerificado: correoVerificado,
      telefonoVerificado: telefonoVerificado,
      personaId: persona?.idPersona,
    );
  }

  List<String> _extractRoles(Map<String, dynamic> usuario) {
    final rawRoles = usuario['roles'] ?? usuario['Roles'] ?? [];
    if (rawRoles is! List) return const ['CLIENTE'];
    final canonical = <String>{};
    for (final r in rawRoles) {
      final role = _canonicalizeRole(r?.toString() ?? '');
      if (role != null) canonical.add(role);
    }
    return canonical.isEmpty ? const ['CLIENTE'] : canonical.toList();
  }

  String? _canonicalizeRole(String role) {
    final normalized = role.trim().toUpperCase().replaceAll('Á', 'A').replaceAll('É', 'E')
      .replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
      .replaceAll('Ü', 'U').replaceAll('Ñ', 'N');
    switch (normalized) {
      case 'CLIENTE':
        return 'CLIENTE';
      case 'DUENIO':
      case 'DUENO':
      case 'OWNER':
      case 'PROPIETARIO':
        return 'DUENIO';
      case 'CONTROLADOR':
      case 'CONTROL':
        return 'CONTROLADOR';
      case 'ADMIN':
      case 'ADMINISTRADOR':
        return 'ADMIN';
      default:
        return null;
    }
  }

  String? _resolveAvatarUrl(String? candidate) {
    if (candidate == null || candidate.isEmpty) return null;
    final apiUri = Uri.parse(AppConfig.apiBaseUrl);
    final origin = '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';

    if (candidate.startsWith('http')) {
      final uri = Uri.tryParse(candidate);
      if (uri != null) {
        final bool isLocalHost =
            uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host.startsWith('10.0.2.2');

        // Corrige rutas que vienen como /avatars/.. para apuntar a /uploads/avatars
        if (uri.path.startsWith('/avatars')) {
          final fixed = uri.replace(
            host: apiUri.host,
            port: apiUri.port,
            scheme: apiUri.scheme,
            path: '/uploads${uri.path}',
          );
          return fixed.toString();
        }

        if (isLocalHost) {
          final normalized = uri.replace(
            host: apiUri.host,
            port: apiUri.port,
            scheme: apiUri.scheme,
          );
          return normalized.toString();
        }
        return uri.toString();
      }
      return candidate;
    }
    if (candidate.startsWith('/uploads')) return '$origin$candidate';
    if (candidate.startsWith('/avatars')) return '$origin/uploads$candidate';
    if (candidate.startsWith('/')) return '$origin$candidate';
    return '$origin/$candidate';
  }

  String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'si' || v == 'yes';
    }
    return false;
  }
}
