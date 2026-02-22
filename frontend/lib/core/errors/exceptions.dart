class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  ServerException({required this.message, this.statusCode, this.errorCode});
}

class NetworkException implements Exception {
  final String message;
  NetworkException({this.message = 'No internet connection'});
}

class CacheException implements Exception {
  final String message;
  CacheException({this.message = 'Cache error'});
}

class AuthException implements Exception {
  final String message;
  AuthException({required this.message});
}
