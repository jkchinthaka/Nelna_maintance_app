import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';
import '../widgets/auth_text_field.dart';

/// Enterprise-grade registration screen matching the login screen style.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  static const int _defaultCompanyId = 1;
  int? _selectedRoleId;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Please select a role'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      return;
    }

    final params = RegisterParams(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      companyId: _defaultCompanyId,
      roleId: _selectedRoleId!,
    );

    await ref.read(authStateProvider.notifier).register(params);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);

    // Show error snackbar
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),

                  // ── Logo & Title ──────────────────────────────────
                  _LogoSection(),
                  const SizedBox(height: 32),

                  // ── Form Card ─────────────────────────────────────
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create Account',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign up for ${AppConstants.appName}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Role selector ────────────────────────
                            _RoleDropdown(
                              selectedRoleId: _selectedRoleId,
                              enabled: !isLoading,
                              onChanged: (id) =>
                                  setState(() => _selectedRoleId = id),
                            ),
                            const SizedBox(height: 16),

                            // ── First name ──────────────────────────
                            AuthTextField(
                              controller: _firstNameController,
                              focusNode: _firstNameFocus,
                              label: 'First Name',
                              hint: 'John',
                              prefixIcon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'First name is required';
                                }
                                if (v.trim().length < 2) {
                                  return 'At least 2 characters';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) =>
                                  _lastNameFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),

                            // ── Last name ───────────────────────────
                            AuthTextField(
                              controller: _lastNameController,
                              focusNode: _lastNameFocus,
                              label: 'Last Name',
                              hint: 'Doe',
                              prefixIcon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Last name is required';
                                }
                                if (v.trim().length < 2) {
                                  return 'At least 2 characters';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) =>
                                  _emailFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),

                            // ── Email ───────────────────────────────
                            AuthTextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              label: 'Email Address',
                              hint: 'you@company.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                final re = RegExp(
                                  r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                                );
                                if (!re.hasMatch(v.trim())) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) =>
                                  _phoneFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),

                            // ── Phone (optional) ────────────────────
                            AuthTextField(
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              label: 'Phone (optional)',
                              hint: '+94 77 123 4567',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              onFieldSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),

                            // ── Password ────────────────────────────
                            AuthTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              label: 'Password',
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (v.length < 8) {
                                  return 'At least 8 characters';
                                }
                                final re = RegExp(
                                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])',
                                );
                                if (!re.hasMatch(v)) {
                                  return 'Needs upper, lower, digit & special char';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) =>
                                  _confirmPasswordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),

                            // ── Confirm password ────────────────────
                            AuthTextField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              label: 'Confirm Password',
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _onRegister(),
                            ),
                            const SizedBox(height: 24),

                            // ── Register button ─────────────────────
                            FilledButton(
                              onPressed: isLoading ? null : _onRegister,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Already have an account? ──────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed:
                            isLoading ? null : () => context.go('/login'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Footer ────────────────────────────────────────
                  Text(
                    '© ${DateTime.now().year} ${AppConstants.appName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Logo Section ──────────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.build_circle_outlined,
            size: 38,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppConstants.appName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ── Role Dropdown ─────────────────────────────────────────────────────────

/// Fetches available roles from the API and renders a styled dropdown.
class _RoleDropdown extends ConsumerWidget {
  final int? selectedRoleId;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  const _RoleDropdown({
    required this.selectedRoleId,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(availableRolesProvider);
    final theme = Theme.of(context);

    return rolesAsync.when(
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.error),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load roles. Tap to retry.',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => ref.invalidate(availableRolesProvider),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
      data: (roles) {
        if (roles.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
            ),
            child: Text(
              'No roles available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return DropdownButtonFormField<int>(
          value: selectedRoleId,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            labelText: 'Register As',
            prefixIcon: const Icon(Icons.badge_outlined, size: 22),
            filled: true,
            fillColor:
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
          validator: (value) => value == null ? 'Please select a role' : null,
          items: roles.map((role) {
            return DropdownMenuItem<int>(
              value: role.id,
              child: Text(
                role.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return roles.map((role) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      _roleIcon(role.name),
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      role.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          dropdownColor: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        );
      },
    );
  }

  IconData _roleIcon(String roleName) {
    switch (roleName) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'company_admin':
        return Icons.business;
      case 'maintenance_manager':
        return Icons.engineering;
      case 'technician':
        return Icons.build;
      case 'store_manager':
        return Icons.inventory_2;
      case 'driver':
        return Icons.directions_car;
      case 'finance_officer':
        return Icons.account_balance;
      default:
        return Icons.person;
    }
  }
}
