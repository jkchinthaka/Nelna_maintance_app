import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contract for authentication operations.
abstract class AuthRepository {
  /// Authenticate with email and password.
  Future<Either<Failure, AuthResult>> login(String email, String password);

  /// Register a new user account.
  Future<Either<Failure, AuthResult>> register(RegisterParams params);

  /// Invalidate the current session.
  Future<Either<Failure, void>> logout();

  /// Fetch the currently authenticated user profile.
  Future<Either<Failure, UserEntity>> getProfile();

  /// Change the current user's password.
  Future<Either<Failure, void>> changePassword(
    String currentPassword,
    String newPassword,
  );

  /// Exchange a refresh token for a fresh access token pair.
  Future<Either<Failure, AuthResult>> refreshToken();

  /// Check whether saved credentials exist and are potentially valid.
  Future<bool> isLoggedIn();
}
