import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/fuel_log_form.dart';

/// Detailed view for a single vehicle with tabbed sections:
/// Details · Documents · Fuel Logs · Service History · Drivers
class VehicleDetailScreen extends ConsumerStatefulWidget {
  final int vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    'Details',
    'Documents',
    'Fuel Logs',
    'Service',
    'Drivers',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(vehicleDetailProvider(widget.vehicleId));

    return Scaffold(
      body: vehicleAsync.when(
        loading: () =>
            const LoadingOverlay(isLoading: true, child: SizedBox.expand()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(vehicleDetailProvider(widget.vehicleId)),
        ),
        data: (vehicle) => _buildContent(vehicle),
      ),
    );
  }

  Widget _buildContent(VehicleEntity vehicle) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // ── Hero / Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(background: _buildHero(vehicle)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Vehicle',
                onPressed: () =>
                    context.push('/vehicles/create', extra: vehicle),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(value, vehicle),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'fuel_log',
                    child: ListTile(
                      leading: Icon(Icons.local_gas_station),
                      title: Text('Add Fuel Log'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'document',
                    child: ListTile(
                      leading: Icon(Icons.description_outlined),
                      title: Text('Add Document'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'driver',
                    child: ListTile(
                      leading: Icon(Icons.person_add_outlined),
                      title: Text('Assign Driver'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Tab Bar ───────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _detailsTab(vehicle),
          _documentsTab(vehicle),
          _fuelLogsTab(vehicle),
          _serviceHistoryTab(vehicle),
          _driversTab(vehicle),
        ],
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────

  Widget _buildHero(VehicleEntity vehicle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.registrationNo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vehicle.make} ${vehicle.model}${vehicle.year != null ? ' (${vehicle.year})' : ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: vehicle.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Details Tab ─────────────────────────────────────────────────────────

  Widget _detailsTab(VehicleEntity vehicle) {
    final fmt = NumberFormat('#,##0.00');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Cost Analytics Summary ────────────────────────────────────
        _costSummaryCard(vehicle),
        const SizedBox(height: 16),

        _sectionTitle('Vehicle Information'),
        _infoTile('Registration No', vehicle.registrationNo),
        _infoTile('Make & Model', '${vehicle.make} ${vehicle.model}'),
        if (vehicle.year != null) _infoTile('Year', vehicle.year.toString()),
        _infoTile('Vehicle Type', vehicle.vehicleType),
        _infoTile('Fuel Type', vehicle.fuelType),
        if (vehicle.color != null) _infoTile('Color', vehicle.color!),
        _infoTile('Mileage', '${fmt.format(vehicle.mileage)} km'),
        if (vehicle.engineNo != null) _infoTile('Engine No', vehicle.engineNo!),
        if (vehicle.chassisNo != null)
          _infoTile('Chassis No', vehicle.chassisNo!),
        if (vehicle.branchName != null)
          _infoTile('Branch', vehicle.branchName!),

        const SizedBox(height: 16),
        _sectionTitle('Dates & Expiry'),
        if (vehicle.purchaseDate != null)
          _infoTile(
            'Purchase Date',
            DateFormat('dd MMM yyyy').format(vehicle.purchaseDate!),
          ),
        if (vehicle.purchasePrice != null)
          _infoTile(
            'Purchase Price',
            'LKR ${fmt.format(vehicle.purchasePrice)}',
          ),
        if (vehicle.insuranceExpiry != null)
          _dateTile(
            'Insurance Expiry',
            vehicle.insuranceExpiry!,
            warn: vehicle.isInsuranceExpiring,
          ),
        if (vehicle.licenseExpiry != null)
          _dateTile(
            'License Expiry',
            vehicle.licenseExpiry!,
            warn: vehicle.isLicenseExpiring,
          ),
        if (vehicle.lastServiceDate != null)
          _infoTile(
            'Last Service',
            DateFormat('dd MMM yyyy').format(vehicle.lastServiceDate!),
          ),
        if (vehicle.nextServiceDate != null)
          _dateTile('Next Service', vehicle.nextServiceDate!),
        if (vehicle.notes != null && vehicle.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('Notes'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(vehicle.notes!),
            ),
          ),
        ],
      ],
    );
  }

  // ── Documents Tab ───────────────────────────────────────────────────────

  Widget _documentsTab(VehicleEntity vehicle) {
    final docs = vehicle.documents ?? [];
    if (docs.isEmpty) {
      return _emptyTab(Icons.description_outlined, 'No documents');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: doc.isExpired
                  ? AppColors.error.withOpacity(0.1)
                  : doc.isExpiringSoon
                  ? AppColors.warning.withOpacity(0.1)
                  : AppColors.success.withOpacity(0.1),
              child: Icon(
                Icons.description,
                color: doc.isExpired
                    ? AppColors.error
                    : doc.isExpiringSoon
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ),
            title: Text(doc.type.replaceAll('_', ' ')),
            subtitle: Text(
              '${doc.documentNo}\nExpiry: ${DateFormat('dd MMM yyyy').format(doc.expiryDate)}',
            ),
            isThreeLine: true,
            trailing: doc.isExpired
                ? const StatusBadge(status: 'EXPIRED')
                : doc.isExpiringSoon
                ? const StatusBadge(status: 'EXPIRING')
                : const StatusBadge(status: 'ACTIVE'),
          ),
        );
      },
    );
  }

  // ── Fuel Logs Tab ───────────────────────────────────────────────────────

  Widget _fuelLogsTab(VehicleEntity vehicle) {
    final logs = vehicle.fuelLogs ?? [];
    if (logs.isEmpty) {
      return _emptyTab(Icons.local_gas_station_outlined, 'No fuel logs');
    }

    final fmt = NumberFormat('#,##0.00');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.info.withOpacity(0.1),
              child: const Icon(Icons.local_gas_station, color: AppColors.info),
            ),
            title: Text(
              '${log.fuelType} — ${fmt.format(log.quantity)} L',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${DateFormat('dd MMM yyyy').format(log.date)}\n'
              'LKR ${fmt.format(log.totalCost)} @ ${fmt.format(log.unitPrice)}/L  •  ${fmt.format(log.mileage)} km',
            ),
            isThreeLine: true,
            trailing: log.station != null
                ? Text(log.station!, style: const TextStyle(fontSize: 12))
                : null,
          ),
        );
      },
    );
  }

  // ── Service History Tab ─────────────────────────────────────────────────

  Widget _serviceHistoryTab(VehicleEntity vehicle) {
    // Service history is loaded separately—kept simple for now.
    return _emptyTab(
      Icons.build_outlined,
      'Service history via Services module',
    );
  }

  // ── Drivers Tab ─────────────────────────────────────────────────────────

  Widget _driversTab(VehicleEntity vehicle) {
    final drivers = vehicle.drivers ?? [];
    if (drivers.isEmpty) {
      return _emptyTab(Icons.people_outline, 'No drivers assigned');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final d = drivers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: d.isActive
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.textSecondary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                color: d.isActive ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            title: Text(d.driverName ?? 'Driver #${d.driverId}'),
            subtitle: Text(
              'Assigned: ${DateFormat('dd MMM yyyy').format(d.assignedDate)}'
              '${d.releasedDate != null ? '\nReleased: ${DateFormat('dd MMM yyyy').format(d.releasedDate!)}' : ''}',
            ),
            isThreeLine: d.releasedDate != null,
            trailing: StatusBadge(status: d.isActive ? 'ACTIVE' : 'INACTIVE'),
          ),
        );
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _costSummaryCard(VehicleEntity vehicle) {
    final analytics = ref.watch(
      vehicleCostAnalyticsProvider(CostAnalyticsParams(vehicleId: vehicle.id)),
    );

    return analytics.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final fmt = NumberFormat('#,##0.00');
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cost Analytics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                Row(
                  children: [
                    _costChip(
                      'Fuel',
                      'LKR ${fmt.format(data.fuelCosts.totalCost)}',
                      AppColors.info,
                    ),
                    const SizedBox(width: 12),
                    _costChip(
                      'Service',
                      'LKR ${fmt.format(data.serviceCosts)}',
                      AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    _costChip(
                      'Total',
                      'LKR ${fmt.format(data.totalCost)}',
                      AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _costChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile(String label, DateTime date, {bool warn = false}) {
    final isExpired = date.isBefore(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (isExpired || warn)
                  Icon(
                    Icons.warning_amber_rounded,
                    color: isExpired ? AppColors.error : AppColors.warning,
                    size: 18,
                  ),
                if (isExpired || warn) const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isExpired
                        ? AppColors.error
                        : warn
                        ? AppColors.warning
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTab(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _handleAction(String action, VehicleEntity vehicle) {
    switch (action) {
      case 'fuel_log':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => FuelLogForm(
            vehicleId: vehicle.id,
            defaultFuelType: vehicle.fuelType,
            onSaved: () {
              ref.invalidate(vehicleDetailProvider(widget.vehicleId));
              Navigator.of(context).pop();
            },
          ),
        );
        break;
      case 'document':
        // TODO: implement document form bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document form coming soon')),
        );
        break;
      case 'driver':
        // TODO: implement driver assignment bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver assignment coming soon')),
        );
        break;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Persistent Tab Bar Delegate
// ═══════════════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}
