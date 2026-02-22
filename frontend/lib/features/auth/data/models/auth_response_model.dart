import '../../domain/entities/user_entity.dart';
import 'user_model.dart';

/// Model that wraps the API response for auth endpoints
/// (login, register, refresh).
class AuthResponseModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  /// Parse the `data` block from the authentication API response.
  ///
  /// Expected JSON shape:
  /// ```json
  /// {
  ///   "user": { ... },
  ///   "accessToken": "...",
  ///   "refreshToken": "..."
  /// }
  /// ```
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }

  /// Convert to the domain-layer [AuthResult].
  AuthResult toAuthResult() {
    return AuthResult(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
