import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Persists auth tokens and cached user data on-device.
class AuthLocalDataSource {
  final FlutterSecureStorage _storage;

  AuthLocalDataSource(this._storage);

  // ── Token Management ────────────────────────────────────────────────

  /// Persist both tokens after a successful authentication.
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
      _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
    ]);
  }

  /// Read the stored access token.
  Future<String?> getAccessToken() async {
    return _storage.read(key: AppConstants.accessTokenKey);
  }

  /// Read the stored refresh token.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.refreshTokenKey);
  }

  /// Remove all stored tokens.
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.accessTokenKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
      _storage.delete(key: AppConstants.userDataKey),
    ]);
  }

  // ── User Data Cache ─────────────────────────────────────────────────

  /// Cache the authenticated user for offline / quick-start use.
  Future<void> saveUserData(UserModel user) async {
    final jsonString = jsonEncode(user.toJson());
    await _storage.write(key: AppConstants.userDataKey, value: jsonString);
  }

  /// Retrieve the cached user, or `null` if none exists.
  Future<UserModel?> getUserData() async {
    try {
      final jsonString = await _storage.read(key: AppConstants.userDataKey);
      if (jsonString == null || jsonString.isEmpty) return null;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } on Exception {
      // Corrupted data – clear it silently.
      await _storage.delete(key: AppConstants.userDataKey);
      return null;
    }
  }

  // ── Quick Checks ────────────────────────────────────────────────────

  /// Returns `true` when a non-empty access token exists.
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
