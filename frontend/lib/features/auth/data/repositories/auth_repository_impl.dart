import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Concrete implementation of [AuthRepository].
///
/// Coordinates between the remote API and local secure storage,
/// mapping exceptions to domain [Failure]s.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  // ── Login ───────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, AuthResult>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _remoteDataSource.login(email, password);

      // Persist tokens & user locally.
      await _localDataSource.saveTokens(
        response.accessToken,
        response.refreshToken,
      );
      await _localDataSource.saveUserData(response.user);

      return Right(response.toAuthResult());
    } on ServerException catch (e) {
      return Left(
        e.statusCode == 401
            ? AuthFailure(message: e.message)
            : ServerFailure(message: e.message, errorCode: e.errorCode),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Register ────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, AuthResult>> register(RegisterParams params) async {
    try {
      final response = await _remoteDataSource.register(params.toJson());

      await _localDataSource.saveTokens(
        response.accessToken,
        response.refreshToken,
      );
      await _localDataSource.saveUserData(response.user);

      return Right(response.toAuthResult());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Best effort – clear locally even if the server call fails.
      try {
        await _remoteDataSource.logout();
      } on Exception {
        // Swallow remote errors; we still want to clear local state.
      }
      await _localDataSource.clearTokens();
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  // ── Profile ─────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    try {
      final user = await _remoteDataSource.getProfile();
      await _localDataSource.saveUserData(user);
      return Right(user);
    } on ServerException catch (e) {
      // Fall back to cached user if available.
      if (e.statusCode == 401) {
        return Left(AuthFailure(message: e.message));
      }
      final cached = await _localDataSource.getUserData();
      if (cached != null) return Right(cached);
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (_) {
      final cached = await _localDataSource.getUserData();
      if (cached != null) return Right(cached);
      return const Left(NetworkFailure());
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Change Password ─────────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _remoteDataSource.changePassword(currentPassword, newPassword);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Refresh Token ───────────────────────────────────────────────────
  @override
  Future<Either<Failure, AuthResult>> refreshToken() async {
    try {
      final storedRefresh = await _localDataSource.getRefreshToken();
      if (storedRefresh == null || storedRefresh.isEmpty) {
        return const Left(AuthFailure(message: 'No refresh token available'));
      }

      final tokens = await _remoteDataSource.refreshToken(storedRefresh);
      await _localDataSource.saveTokens(
        tokens['accessToken']!,
        tokens['refreshToken']!,
      );

      // Rebuild an AuthResult with the cached user.
      final cachedUser = await _localDataSource.getUserData();
      if (cachedUser == null) {
        return const Left(
          AuthFailure(message: 'Session expired. Please log in again.'),
        );
      }

      return Right(
        AuthResult(
          user: cachedUser,
          accessToken: tokens['accessToken']!,
          refreshToken: tokens['refreshToken']!,
        ),
      );
    } on ServerException catch (e) {
      await _localDataSource.clearTokens();
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Is Logged In ────────────────────────────────────────────────────
  @override
  Future<bool> isLoggedIn() => _localDataSource.isLoggedIn();
}
