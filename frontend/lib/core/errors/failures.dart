import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? errorCode;
  const Failure({required this.message, this.errorCode});
  @override
  List<Object?> get props => [message, errorCode];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.errorCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.errorCode,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error occurred', super.errorCode});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.errorCode});
}

class ValidationFailure extends Failure {
  final List<Map<String, dynamic>>? errors;
  const ValidationFailure({
    required super.message,
    this.errors,
    super.errorCode,
  });
  @override
  List<Object?> get props => [message, errorCode, errors];
}
