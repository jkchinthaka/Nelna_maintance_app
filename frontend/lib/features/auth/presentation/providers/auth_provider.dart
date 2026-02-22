import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

// ── Infrastructure Providers ──────────────────────────────────────────

final _secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(ref.read(_secureStorageProvider)),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (_) => AuthRemoteDataSource(ApiClient()),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    localDataSource: ref.read(authLocalDataSourceProvider),
  ),
);

// ── Use-case Providers ────────────────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.read(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.read(authRepositoryProvider)),
);

final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.read(authRepositoryProvider)),
);

// ── Auth State ────────────────────────────────────────────────────────

/// Represents the authentication lifecycle.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ── Auth State Notifier ───────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetProfileUseCase _getProfileUseCase;
  final AuthRepository _authRepository;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetProfileUseCase getProfileUseCase,
    required AuthRepository authRepository,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _getProfileUseCase = getProfileUseCase,
       _authRepository = authRepository,
       super(const AuthInitial());

  /// Check stored credentials and load the cached user (called on app start).
  Future<void> checkAuthStatus() async {
    state = const AuthLoading();
    final loggedIn = await _authRepository.isLoggedIn();

    if (!loggedIn) {
      state = const AuthUnauthenticated();
      return;
    }

    final result = await _getProfileUseCase();
    result.fold(
      (failure) => state = const AuthUnauthenticated(),
      (user) => state = AuthAuthenticated(user),
    );
  }

  /// Perform email + password login.
  Future<void> login(String email, String password) async {
    state = const AuthLoading();

    final result = await _loginUseCase(email: email, password: password);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (authResult) => state = AuthAuthenticated(authResult.user),
    );
  }

  /// Log out the current user.
  Future<void> logout() async {
    state = const AuthLoading();

    final result = await _logoutUseCase();
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const AuthUnauthenticated(),
    );
  }

  /// Refresh the user profile from the server.
  Future<void> refreshProfile() async {
    final result = await _getProfileUseCase();
    result.fold(
      (_) {}, // keep current state on failure
      (user) => state = AuthAuthenticated(user),
    );
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    logoutUseCase: ref.read(logoutUseCaseProvider),
    getProfileUseCase: ref.read(getProfileUseCaseProvider),
    authRepository: ref.read(authRepositoryProvider),
  );
});

/// The currently authenticated user, or `null`.
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AuthAuthenticated ? authState.user : null;
});

/// Simple bool derived from auth state.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider) is AuthAuthenticated;
});
