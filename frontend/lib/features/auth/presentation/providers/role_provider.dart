import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/role_model.dart';

/// Fetches the list of roles available for registration.
///
/// Public callers see only self-register roles (Technician, Driver).
/// Authenticated admins see all roles.
final availableRolesProvider = FutureProvider<List<RoleListModel>>((ref) async {
  try {
    final response = await ApiClient().get(ApiConstants.roles);
    final data = response.data;

    if (data is Map<String, dynamic> && data['success'] == true) {
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => RoleListModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  } catch (e) {
    // Fallback to default roles if API fails
    return _defaultRoles;
  }

  return _defaultRoles;
});

/// Default roles when backend is unavailable
final List<RoleListModel> _defaultRoles = [
  RoleListModel(
    id: 1,
    name: 'super_admin',
    displayName: 'Super Admin',
  ),
  RoleListModel(
    id: 2,
    name: 'company_admin',
    displayName: 'Company Admin',
  ),
  RoleListModel(
    id: 3,
    name: 'maintenance_manager',
    displayName: 'Maintenance Manager',
  ),
  RoleListModel(
    id: 4,
    name: 'technician',
    displayName: 'Technician',
  ),
  RoleListModel(
    id: 5,
    name: 'store_manager',
    displayName: 'Store Manager',
  ),
  RoleListModel(
    id: 6,
    name: 'driver',
    displayName: 'Driver',
  ),
  RoleListModel(
    id: 7,
    name: 'finance_officer',
    displayName: 'Finance Officer',
  ),
];
