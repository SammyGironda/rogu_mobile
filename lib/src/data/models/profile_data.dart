import 'persona.dart';

class ProfileData {
	const ProfileData({
		required this.persona,
		required this.roles,
		required this.primaryRole,
		required this.avatarUrl,
		required this.avatarPath,
		required this.correoVerificado,
		required this.telefonoVerificado,
		required this.personaId,
	});

	final Persona? persona;
	final List<String> roles;
	final String primaryRole;
	final String? avatarUrl;
	final String? avatarPath;
	final bool correoVerificado;
	final bool telefonoVerificado;
	final String? personaId;
}
