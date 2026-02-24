import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/role_model.dart';

/// Fetches the list of roles available for registration.
///
/// Public callers see only self-register roles (Technician, Driver).
/// Authenticated admins see all roles.
final availableRolesProvider = FutureProvider<List<RoleListModel>>((ref) async {
  final response = await ApiClient().get(ApiConstants.roles);
  final data = response.data;

  if (data is Map<String, dynamic> && data['success'] == true) {
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => RoleListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  return [];
});
