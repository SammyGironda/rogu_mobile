import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/persona.dart';
import '../../../data/models/user.dart';
import '../../../data/models/profile_data.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../presentation/state/providers.dart';

class ProfileState {
	const ProfileState({
		required this.persona,
		required this.loading,
		required this.error,
		required this.roles,
		required this.primaryRole,
		required this.personaId,
		required this.avatarUrl,
		required this.correoVerificado,
		required this.telefonoVerificado,
	});

	factory ProfileState.initial() => const ProfileState(
			persona: null,
			loading: false,
			error: null,
			roles: const [],
			primaryRole: 'CLIENTE',
			personaId: null,
			avatarUrl: null,
			correoVerificado: false,
			telefonoVerificado: false,
		);

	final Persona? persona;
	final bool loading;
	final String? error;
	final List<String> roles;
	final String primaryRole;
	final String? personaId;
	final String? avatarUrl;
	final bool correoVerificado;
	final bool telefonoVerificado;

	ProfileState copyWith({
		Persona? persona,
		bool? loading,
		String? error,
		List<String>? roles,
		String? primaryRole,
		String? personaId,
		String? avatarUrl,
		bool? correoVerificado,
		bool? telefonoVerificado,
		bool clearError = false,
	}) {
		return ProfileState(
			persona: persona ?? this.persona,
			loading: loading ?? this.loading,
			error: clearError ? null : (error ?? this.error),
			roles: roles ?? this.roles,
			primaryRole: primaryRole ?? this.primaryRole,
			personaId: personaId ?? this.personaId,
			avatarUrl: avatarUrl ?? this.avatarUrl,
			correoVerificado: correoVerificado ?? this.correoVerificado,
			telefonoVerificado: telefonoVerificado ?? this.telefonoVerificado,
		);
	}
}

final profileControllerProvider =
	StateNotifierProvider.autoDispose<ProfileController, ProfileState>((ref) {
		final repo = ref.read(profileRepositoryProvider);
		return ProfileController(profileRepository: repo);
	});

class ProfileController extends StateNotifier<ProfileState> {
	ProfileController({required ProfileRepository profileRepository})
		: _profileRepository = profileRepository,
		  super(ProfileState.initial());

	final ProfileRepository _profileRepository;

	Future<void> loadProfile({required User user}) async {
		if (user.personaId == null) {
			state = state.copyWith(
				error: 'Usuario sin persona asociada',
				persona: null,
				roles: const [],
				primaryRole: 'CLIENTE',
				personaId: null,
				loading: false,
			);
			return;
		}

		state = state.copyWith(
			loading: true,
			error: null,
			personaId: user.personaId,
		);

		try {
			final ProfileData profile = await _profileRepository.fetchProfile();

			state = state.copyWith(
				persona: profile.persona,
				roles: profile.roles,
				primaryRole: profile.primaryRole,
				avatarUrl: profile.avatarUrl,
				correoVerificado: profile.correoVerificado,
				telefonoVerificado: profile.telefonoVerificado,
				loading: false,
				clearError: true,
			);
		} catch (e) {
			state = state.copyWith(
				loading: false,
				error: e.toString(),
			);
		}
	}
}
