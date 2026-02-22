import 'package:equatable/equatable.dart';

/// Core user entity in the domain layer.
class UserEntity extends Equatable {
  final int id;
  final int companyId;
  final int? branchId;
  final int roleId;
  final String? employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? avatar;
  final bool isActive;
  final DateTime? lastLoginAt;
  final RoleEntity role;
  final CompanyEntity? company;
  final BranchEntity? branch;

  const UserEntity({
    required this.id,
    required this.companyId,
    this.branchId,
    required this.roleId,
    this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.avatar,
    this.isActive = true,
    this.lastLoginAt,
    required this.role,
    this.company,
    this.branch,
  });

  /// Convenience getter for full display name.
  String get fullName => '$firstName $lastName';

  /// Role code name (e.g. `super_admin`).
  String get roleName => role.name;

  /// Human-readable role label (e.g. "Super Admin").
  String get roleDisplayName => role.displayName;

  @override
  List<Object?> get props => [id, email];
}

/// Role value-object.
class RoleEntity extends Equatable {
  final int id;
  final String name;
  final String displayName;

  const RoleEntity({
    required this.id,
    required this.name,
    required this.displayName,
  });

  @override
  List<Object?> get props => [id, name];
}

/// Company value-object.
class CompanyEntity extends Equatable {
  final int id;
  final String name;
  final String code;

  const CompanyEntity({
    required this.id,
    required this.name,
    required this.code,
  });

  @override
  List<Object?> get props => [id];
}

/// Branch value-object.
class BranchEntity extends Equatable {
  final int id;
  final String name;
  final String code;

  const BranchEntity({
    required this.id,
    required this.name,
    required this.code,
  });

  @override
  List<Object?> get props => [id];
}

/// Aggregate returned after login / register / refresh.
class AuthResult {
  final UserEntity user;
  final String accessToken;
  final String refreshToken;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

/// Parameters for the register use-case.
class RegisterParams {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final int companyId;
  final int roleId;
  final int? branchId;
  final String? employeeId;
  final String? phone;

  const RegisterParams({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.companyId,
    required this.roleId,
    this.branchId,
    this.employeeId,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'password': password,
    'companyId': companyId,
    'roleId': roleId,
    if (branchId != null) 'branchId': branchId,
    if (employeeId != null) 'employeeId': employeeId,
    if (phone != null) 'phone': phone,
  };
}
