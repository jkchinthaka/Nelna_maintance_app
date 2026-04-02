import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../features/notifications/presentation/widgets/notification_panel.dart';
import '../theme/app_colors.dart';

/// Responsive enterprise shell with a modern sidebar, app bar, and user menu.
class AppScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final String title;

  const AppScaffold({super.key, required this.child, required this.title});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  bool _sidebarExpanded = true;

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      path: '/dashboard',
      roles: null,
    ),
    _NavItem(
      icon: Icons.directions_car_outlined,
      activeIcon: Icons.directions_car,
      label: 'Vehicles',
      path: '/vehicles',
      roles: ['super_admin', 'company_admin', 'maintenance_manager', 'driver'],
    ),
    _NavItem(
      icon: Icons.precision_manufacturing_outlined,
      activeIcon: Icons.precision_manufacturing,
      label: 'Machines',
      path: '/machines',
      roles: [
        'super_admin',
        'company_admin',
        'maintenance_manager',
        'technician'
      ],
    ),
    _NavItem(
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
      label: 'Services',
      path: '/services',
      roles: [
        'super_admin',
        'company_admin',
        'maintenance_manager',
        'technician'
      ],
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Inventory',
      path: '/inventory',
      roles: ['super_admin', 'company_admin', 'store_manager'],
    ),
    _NavItem(
      icon: Icons.category_outlined,
      activeIcon: Icons.category,
      label: 'Assets',
      path: '/assets',
      roles: ['super_admin', 'company_admin', 'maintenance_manager'],
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Reports',
      path: '/reports',
      roles: ['super_admin', 'company_admin', 'finance_officer'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final currentPath = GoRouterState.of(context).matchedLocation;
    final authState = ref.watch(authStateProvider);
    final userRole =
        authState is AuthAuthenticated ? authState.user.roleName : null;

    final visibleItems = _navItems.where((item) {
      if (item.roles == null) return true;
      return userRole != null && item.roles!.contains(userRole);
    }).toList();

    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: _buildMobileAppBar(context),
        drawer: _buildDrawer(context, currentPath, visibleItems),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: widget.child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(context, currentPath, visibleItems),
            Expanded(
              child: Column(
                children: [
                  _buildDesktopHeader(context),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      titleSpacing: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Text(
        widget.title,
        style:
            theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final unread = ref.watch(notificationProvider).unreadCount;
            return IconButton(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => NotificationPanel.show(context),
            );
          },
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          icon: const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'profile', child: Text('Profile')),
            PopupMenuItem(value: 'settings', child: Text('Settings')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          onSelected: (value) {
            if (value == 'logout') {
              ref.read(authStateProvider.notifier).logout();
            } else if (value == 'profile') {
              context.push('/profile');
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.88),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: theme.colorScheme.outline.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Maintenance operations at a glance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Consumer(
              builder: (context, ref, _) {
                final unread = ref.watch(notificationProvider).unreadCount;
                return IconButton.filledTonal(
                  onPressed: () => NotificationPanel.show(context),
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildDesktopUserMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopUserMenu(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final displayName = currentUser?.fullName ?? 'User';
    final role = currentUser?.roleName.replaceAll('_', ' ').toUpperCase() ??
        'TEAM MEMBER';

    return PopupMenuButton<String>(
      offset: const Offset(0, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  role,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.expand_more_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'profile', child: Text('Profile')),
        PopupMenuItem(value: 'settings', child: Text('Settings')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: Text('Logout')),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          ref.read(authStateProvider.notifier).logout();
        } else if (value == 'profile') {
          context.push('/profile');
        }
      },
    );
  }

  Widget _buildSidebar(
      BuildContext context, String currentPath, List<_NavItem> visibleItems) {
    final width = _sidebarExpanded ? 292.0 : 92.0;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryDark,
            AppColors.secondary,
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                _sidebarExpanded ? 18 : 12, 18, _sidebarExpanded ? 16 : 12, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.engineering_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (_sidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nelna',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Maintenance Suite',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _sidebarExpanded = !_sidebarExpanded),
                    icon: Icon(
                      _sidebarExpanded
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        setState(() => _sidebarExpanded = !_sidebarExpanded),
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.white.withOpacity(0.12), height: 1),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              children: visibleItems.map((item) {
                final isActive = currentPath.startsWith(item.path);
                return _SidebarTile(
                  item: item,
                  expanded: _sidebarExpanded,
                  isActive: isActive,
                  onTap: () => context.go(item.path),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _SidebarFooter(
              compact: !_sidebarExpanded,
              onLogout: () => ref.read(authStateProvider.notifier).logout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
      BuildContext context, String currentPath, List<_NavItem> visibleItems) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDark,
              AppColors.primaryDark,
              AppColors.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.engineering_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nelna',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Maintenance Suite',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child:
                    Divider(color: Colors.white.withOpacity(0.12), height: 1),
              ),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  children: visibleItems.map((item) {
                    final isActive = currentPath.startsWith(item.path);
                    return _SidebarTile(
                      item: item,
                      expanded: true,
                      isActive: isActive,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(item.path);
                      },
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _SidebarFooter(
                  compact: false,
                  onLogout: () {
                    Navigator.of(context).pop();
                    ref.read(authStateProvider.notifier).logout();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends ConsumerWidget {
  final bool compact;
  final VoidCallback onLogout;

  const _SidebarFooter({required this.compact, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);

    if (compact) {
      return IconButton.filledTonal(
        onPressed: onLogout,
        icon: const Icon(Icons.logout_rounded),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accent,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser?.fullName ?? 'User',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentUser?.roleName
                              .replaceAll('_', ' ')
                              .toUpperCase() ??
                          'ACTIVE SESSION',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.18)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final List<String>? roles;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    this.roles,
  });
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool expanded;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.expanded,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: isActive ? Colors.white.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.white.withOpacity(0.08),
                      ],
                    )
                  : null,
              border: Border.all(
                color: isActive
                    ? Colors.white.withOpacity(0.12)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? Colors.white : Colors.white70,
                  size: 22,
                ),
                if (expanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!expanded) {
      return Tooltip(message: item.label, child: tile);
    }
    return tile;
  }
}
