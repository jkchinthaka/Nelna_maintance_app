import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_scaffold.dart';

// ── Screen imports ────────────────────────────────────────────────────
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/vehicles/presentation/screens/vehicle_list_screen.dart';
import '../../features/vehicles/presentation/screens/vehicle_form_screen.dart';
import '../../features/vehicles/presentation/screens/vehicle_detail_screen.dart';
import '../../features/vehicles/domain/entities/vehicle_entity.dart';
import '../../features/machines/presentation/screens/machine_list_screen.dart';
import '../../features/machines/presentation/screens/machine_form_screen.dart';
import '../../features/machines/presentation/screens/machine_detail_screen.dart';
import '../../features/machines/presentation/screens/breakdown_form_screen.dart';
import '../../features/machines/domain/entities/machine_entity.dart';
import '../../features/services/presentation/screens/service_list_screen.dart';
import '../../features/services/presentation/screens/service_form_screen.dart';
import '../../features/services/presentation/screens/service_detail_screen.dart';
import '../../features/services/domain/entities/service_entity.dart';
import '../../features/inventory/presentation/screens/product_list_screen.dart';
import '../../features/inventory/presentation/screens/product_detail_screen.dart';
import '../../features/inventory/presentation/screens/purchase_order_screen.dart';
import '../../features/inventory/presentation/screens/purchase_order_form_screen.dart';
import '../../features/inventory/presentation/screens/stock_alerts_screen.dart';
import '../../features/stores/presentation/screens/asset_list_screen.dart';
import '../../features/stores/presentation/screens/asset_form_screen.dart';
import '../../features/stores/presentation/screens/asset_detail_screen.dart';
import '../../features/stores/presentation/screens/asset_transfer_screen.dart';
import '../../features/reports/presentation/screens/reports_home_screen.dart';
import '../../features/reports/presentation/screens/maintenance_report_screen.dart';
import '../../features/reports/presentation/screens/vehicle_report_screen.dart';
import '../../features/reports/presentation/screens/expense_report_screen.dart';

// ── Router Provider ───────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isAuthenticated = authState is AuthAuthenticated;

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !loggingIn) return '/login';
      if (isAuthenticated && loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      // ── Login (no shell) ────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Main Shell with sidebar + app bar ───────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(
            title: _titleForLocation(state.matchedLocation),
            child: child,
          );
        },
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // ── Vehicles ─────────────────────────────────────────────────
          GoRoute(
            path: '/vehicles',
            name: 'vehicles',
            builder: (context, state) => const VehicleListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'vehicle-create',
                builder: (context, state) {
                  final vehicle = state.extra as VehicleEntity?;
                  return VehicleFormScreen(vehicle: vehicle);
                },
              ),
              GoRoute(
                path: ':id',
                name: 'vehicle-detail',
                builder: (context, state) => VehicleDetailScreen(
                  vehicleId: int.parse(state.pathParameters['id'] ?? '0'),
                ),
              ),
            ],
          ),

          // ── Machines ─────────────────────────────────────────────────
          GoRoute(
            path: '/machines',
            name: 'machines',
            builder: (context, state) => const MachineListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'machine-create',
                builder: (context, state) {
                  final machine = state.extra as MachineEntity?;
                  return MachineFormScreen(existingMachine: machine);
                },
              ),
              GoRoute(
                path: ':id',
                name: 'machine-detail',
                builder: (context, state) => MachineDetailScreen(
                  machineId: int.parse(state.pathParameters['id'] ?? '0'),
                ),
                routes: [
                  GoRoute(
                    path: 'breakdown',
                    name: 'machine-breakdown',
                    builder: (context, state) {
                      final id = int.tryParse(
                        state.pathParameters['id'] ?? '',
                      );
                      return BreakdownFormScreen(machineId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Services ─────────────────────────────────────────────────
          GoRoute(
            path: '/services',
            name: 'services',
            builder: (context, state) => const ServiceListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'service-create',
                builder: (context, state) {
                  final request = state.extra as ServiceRequestEntity?;
                  return ServiceFormScreen(serviceRequest: request);
                },
              ),
              GoRoute(
                path: ':id',
                name: 'service-detail',
                builder: (context, state) => ServiceDetailScreen(
                  serviceId: int.parse(state.pathParameters['id'] ?? '0'),
                ),
              ),
            ],
          ),

          // ── Inventory ────────────────────────────────────────────────
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            builder: (context, state) => const ProductListScreen(),
            routes: [
              GoRoute(
                path: 'products/create',
                name: 'product-create',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Create Product'),
              ),
              GoRoute(
                path: 'products/:id',
                name: 'product-detail',
                builder: (context, state) => ProductDetailScreen(
                  productId: int.parse(state.pathParameters['id'] ?? '0'),
                ),
              ),
              GoRoute(
                path: 'purchase-orders',
                name: 'purchase-orders',
                builder: (context, state) => const PurchaseOrderScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'purchase-order-create',
                    builder: (context, state) =>
                        const PurchaseOrderFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'purchase-order-detail',
                    builder: (context, state) => PurchaseOrderFormScreen(
                      purchaseOrderId: int.tryParse(
                        state.pathParameters['id'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'stock-alerts',
                name: 'stock-alerts',
                builder: (context, state) => const StockAlertsScreen(),
              ),
            ],
          ),

          // ── Assets ───────────────────────────────────────────────────
          GoRoute(
            path: '/assets',
            name: 'assets',
            builder: (context, state) => const AssetListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'asset-create',
                builder: (context, state) => const AssetFormScreen(),
              ),
              GoRoute(
                path: 'transfer',
                name: 'asset-transfer',
                builder: (context, state) => const AssetTransferScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'asset-detail',
                builder: (context, state) => AssetDetailScreen(
                  assetId: int.parse(state.pathParameters['id'] ?? '0'),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'asset-edit',
                    builder: (context, state) => AssetFormScreen(
                      assetId: int.tryParse(
                        state.pathParameters['id'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Reports ──────────────────────────────────────────────────
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsHomeScreen(),
            routes: [
              GoRoute(
                path: 'maintenance',
                name: 'report-maintenance',
                builder: (context, state) => const MaintenanceReportScreen(),
              ),
              GoRoute(
                path: 'vehicle',
                name: 'report-vehicle',
                builder: (context, state) => const VehicleReportScreen(),
              ),
              GoRoute(
                path: 'expense',
                name: 'report-expense',
                builder: (context, state) => const ExpenseReportScreen(),
              ),
              GoRoute(
                path: 'inventory',
                name: 'report-inventory',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Inventory Report'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ── Helper: derive page title from location ───────────────────────────
String _titleForLocation(String location) {
  if (location.startsWith('/vehicles')) return 'Vehicles';
  if (location.startsWith('/machines')) return 'Machines';
  if (location.startsWith('/services')) return 'Services';
  if (location.startsWith('/inventory')) return 'Inventory';
  if (location.startsWith('/assets')) return 'Assets';
  if (location.startsWith('/reports')) return 'Reports';
  return 'Dashboard';
}

// ── Placeholder for screens not yet implemented ───────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
