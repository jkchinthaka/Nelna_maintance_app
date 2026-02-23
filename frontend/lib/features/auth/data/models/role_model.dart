import 'package:equatable/equatable.dart';

/// Lightweight role returned by GET /api/v1/roles.
class RoleModel extends Equatable {
  final int id;
  final String name;
  final String displayName;
  final String? description;
  final bool isSystem;

  const RoleModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.isSystem = false,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String?,
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, displayName, description, isSystem];
}
