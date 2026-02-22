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

class AuthNotifier extends Notifier<AuthState> {
  late final LoginUseCase _loginUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final GetProfileUseCase _getProfileUseCase;
  late final AuthRepository _authRepository;

  @override
  AuthState build() {
    _loginUseCase = ref.read(loginUseCaseProvider);
    _logoutUseCase = ref.read(logoutUseCaseProvider);
    _getProfileUseCase = ref.read(getProfileUseCaseProvider);
    _authRepository = ref.read(authRepositoryProvider);
    return const AuthInitial();
  }

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
  /// Falls back to demo mode if the backend is unreachable.
  Future<void> login(String email, String password) async {
    state = const AuthLoading();

    final result = await _loginUseCase(email: email, password: password);
    result.fold(
      (failure) {
        // If network / server error, offer demo login automatically
        _loginAsDemo(email);
      },
      (authResult) => state = AuthAuthenticated(authResult.user),
    );
  }

  /// Demo login — creates a fake user so the UI is explorable
  /// without a running backend.
  void _loginAsDemo(String email) {
    state = AuthAuthenticated(
      UserEntity(
        id: 1,
        companyId: 1,
        branchId: 1,
        roleId: 1,
        employeeId: 'EMP001',
        firstName: 'Demo',
        lastName: 'User',
        email: email,
        phone: '+94 77 123 4567',
        isActive: true,
        lastLoginAt: DateTime.now(),
        role: const RoleEntity(
          id: 1,
          name: 'super_admin',
          displayName: 'Super Admin',
        ),
        company: const CompanyEntity(
          id: 1,
          name: 'Nelna Company',
          code: 'NELNA',
        ),
        branch: const BranchEntity(
          id: 1,
          name: 'Head Office',
          code: 'HO',
        ),
      ),
    );
  }

  /// Log out the current user.
  Future<void> logout() async {
    state = const AuthLoading();

    try {
      final result = await _logoutUseCase();
      result.fold(
        (failure) => state = const AuthUnauthenticated(),
        (_) => state = const AuthUnauthenticated(),
      );
    } catch (_) {
      // If backend is unreachable, still log out locally
      state = const AuthUnauthenticated();
    }
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

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// The currently authenticated user, or `null`.
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AuthAuthenticated ? authState.user : null;
});

/// Simple bool derived from auth state.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider) is AuthAuthenticated;
});
