import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../theme/app_colors.dart';

/// Responsive enterprise scaffold with collapsible sidebar, app bar, and
/// user menu.
class AppScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final String title;

  const AppScaffold({super.key, required this.child, required this.title});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  bool _sidebarExpanded = true;

  // Menu items with role-based visibility tags
  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      path: '/dashboard',
      roles: null, // visible to all
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
        'technician',
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
        'technician',
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
    final isMobile = MediaQuery.of(context).size.width < 768;
    final currentPath = GoRouterState.of(context).matchedLocation;

    if (isMobile) {
      return Scaffold(
        appBar: _buildAppBar(context, isMobile: true),
        drawer: _buildDrawer(context, currentPath),
        body: widget.child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context, currentPath),
          Expanded(
            child: Column(
              children: [
                _buildDesktopAppBar(context),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile AppBar ───────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool isMobile,
  }) {
    return AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          icon: const Badge(
            label: Text('3'),
            child: Icon(Icons.notifications_outlined),
          ),
          onPressed: () {
            // TODO: show notifications
          },
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          icon: const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'profile', child: Text('Profile')),
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          onSelected: (value) {
            if (value == 'logout') {
              ref.read(authStateProvider.notifier).logout();
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Desktop AppBar ──────────────────────────────────────────────────
  Widget _buildDesktopAppBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  ref.watch(currentUserProvider)?.fullName ?? 'User',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authStateProvider.notifier).logout();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Desktop Sidebar ─────────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context, String currentPath) {
    final width = _sidebarExpanded ? 260.0 : 72.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarExpanded ? 16 : 8,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.engineering,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (_sidebarExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nelna',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _sidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _sidebarExpanded = !_sidebarExpanded),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _navItems.map((item) {
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

          // Footer
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _sidebarExpanded
                ? const Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── Mobile Drawer ───────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context, String currentPath) {
    return Drawer(
      child: Container(
        color: AppColors.primaryDark,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.engineering,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Nelna Maintenance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: _navItems.map((item) {
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
            ],
          ),
        ),
      ),
    );
  }
}

// ── Navigation Item Model ─────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final List<String>? roles; // null = visible to all

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    this.roles,
  });
}

// ── Sidebar Tile Widget ───────────────────────────────────────────────
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive ? Colors.white.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
            child: Row(
              mainAxisAlignment:
                  expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? Colors.white : Colors.white60,
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
                            isActive ? FontWeight.w600 : FontWeight.w400,
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
  }
}
