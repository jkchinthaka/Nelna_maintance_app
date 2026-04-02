import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';
import '../widgets/auth_text_field.dart';

/// Responsive registration screen that mirrors the login experience.
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
              borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1100;

              final authPanel = _buildAuthPanel(context);
              final formCard = _buildFormCard(context, isLoading, theme);

              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: authPanel),
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: Center(child: formCard)),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    authPanel,
                    const SizedBox(height: 20),
                    formCard,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthPanel(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 560),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.24),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -20,
            child: _Orb(size: 180, color: Colors.white.withOpacity(0.12)),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: _Orb(size: 220, color: Colors.white.withOpacity(0.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: const Icon(
                        Icons.engineering_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Create team accounts and access roles',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.84),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.16)),
                      ),
                      child: const Text(
                        'Built for fleet, workshop, and store teams',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Bring new people into the system with the right permissions from day one.',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quick registration keeps onboarding simple for managers while preserving control over access and responsibilities.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.88),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _FeatureChip(
                        icon: Icons.verified_rounded, label: 'Permission-safe'),
                    _FeatureChip(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Fast onboarding'),
                    _FeatureChip(
                        icon: Icons.group_work_rounded, label: 'Team ready'),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    _StatPill(value: '1 min', label: 'Typical setup time'),
                    SizedBox(width: 12),
                    _StatPill(value: '6 roles', label: 'Permission choices'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.04);
  }

  Widget _buildFormCard(BuildContext context, bool isLoading, ThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(32),
          border:
              Border.all(color: theme.colorScheme.outline.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign up for ${AppConstants.appName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _RoleDropdown(
                  selectedRoleId: _selectedRoleId,
                  enabled: !isLoading,
                  onChanged: (id) => setState(() => _selectedRoleId = id),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        controller: _firstNameController,
                        focusNode: _firstNameFocus,
                        label: 'First name',
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
                        onFieldSubmitted: (_) => _lastNameFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        controller: _lastNameController,
                        focusNode: _lastNameFocus,
                        label: 'Last name',
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
                        onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  label: 'Email address',
                  hint: 'you@company.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    final re = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
                    if (!re.hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  label: 'Phone (optional)',
                  hint: '+94 77 123 4567',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
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
                        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])');
                    if (!re.hasMatch(v)) {
                      return 'Needs upper, lower, digit & special char';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  label: 'Confirm password',
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
                FilledButton(
                  onPressed: isLoading ? null : _onRegister,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 18),
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
                      onPressed: isLoading ? null : () => context.go('/login'),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '© ${DateTime.now().year} ${AppConstants.appName}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.04),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;

  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.02)],
        ),
      ),
    );
  }
}

// ── Role Dropdown ──────────────────────────────────────────────────────────

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
          borderRadius: BorderRadius.circular(18),
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
              borderRadius: BorderRadius.circular(18),
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
            labelText: 'Register as',
            prefixIcon: const Icon(Icons.badge_outlined, size: 22),
            filled: true,
            fillColor:
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 1.8),
            ),
          ),
          validator: (value) => value == null ? 'Please select a role' : null,
          items: roles
              .map((role) => DropdownMenuItem<int>(
                    value: role.id,
                    child: Text(
                      role.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
              .toList(),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          dropdownColor: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        );
      },
    );
  }
}
