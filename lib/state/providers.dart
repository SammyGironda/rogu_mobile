import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../src/data/models/user.dart';
import '../src/data/repositories/auth_repository.dart';
import '../src/data/repositories/profile_repository.dart';
import '../src/core/utils/storage_helper.dart';

// Auth State
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final user = await _authRepository.getCurrentUser();
    final isAuth = await _authRepository.isAuthenticated();

    if (user != null && isAuth) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        error: null,
      );
    } else {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        user: null,
        error: null,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = state.copyWith(isAuthenticated: false, user: null, error: null);
  }

  // Método helper para obtener token
  Future<String?> getToken() async {
    return await StorageHelper.getToken();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

// Profile repository provider
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);
