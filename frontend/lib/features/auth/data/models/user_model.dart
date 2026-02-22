import '../../domain/entities/user_entity.dart';

/// Data-layer model for [RoleEntity].
class RoleModel extends RoleEntity {
  const RoleModel({
    required super.id,
    required super.name,
    required super.displayName,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      displayName:
          json['displayName'] as String? ?? json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'displayName': displayName,
  };
}

/// Data-layer model for [CompanyEntity].
class CompanyModel extends CompanyEntity {
  const CompanyModel({
    required super.id,
    required super.name,
    required super.code,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};
}

/// Data-layer model for [BranchEntity].
class BranchModel extends BranchEntity {
  const BranchModel({
    required super.id,
    required super.name,
    required super.code,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};
}

/// Data-layer model for [UserEntity].
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.companyId,
    super.branchId,
    required super.roleId,
    super.employeeId,
    required super.firstName,
    required super.lastName,
    required super.email,
    super.phone,
    super.avatar,
    super.isActive,
    super.lastLoginAt,
    required RoleModel super.role,
    CompanyModel? super.company,
    BranchModel? super.branch,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      companyId: json['companyId'] as int? ?? 0,
      branchId: json['branchId'] as int?,
      roleId: json['roleId'] as int? ?? 0,
      employeeId: json['employeeId'] as String?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'] as String)
          : null,
      role: json['role'] != null
          ? RoleModel.fromJson(json['role'] as Map<String, dynamic>)
          : const RoleModel(id: 0, name: 'unknown', displayName: 'Unknown'),
      company: json['company'] != null
          ? CompanyModel.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      branch: json['branch'] != null
          ? BranchModel.fromJson(json['branch'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyId': companyId,
    'branchId': branchId,
    'roleId': roleId,
    'employeeId': employeeId,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'avatar': avatar,
    'isActive': isActive,
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'role': (role as RoleModel).toJson(),
    if (company != null) 'company': (company! as CompanyModel).toJson(),
    if (branch != null) 'branch': (branch! as BranchModel).toJson(),
  };

  /// Create a copy with overrides.
  UserModel copyWith({
    int? id,
    int? companyId,
    int? branchId,
    int? roleId,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatar,
    bool? isActive,
    DateTime? lastLoginAt,
    RoleModel? role,
    CompanyModel? company,
    BranchModel? branch,
  }) {
    return UserModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      roleId: roleId ?? this.roleId,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role as RoleModel,
      company: company ?? this.company as CompanyModel?,
      branch: branch ?? this.branch as BranchModel?,
    );
  }
}
