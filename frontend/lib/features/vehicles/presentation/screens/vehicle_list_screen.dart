import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/vehicle_card.dart';

/// Main vehicle listing screen with search, filter chips, pull‑to‑refresh,
/// loading skeletons, and responsive grid/list layout.
class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedType;

  static const _statusOptions = [
    'ACTIVE',
    'IN_SERVICE',
    'INACTIVE',
    'BREAKDOWN',
  ];

  static const _typeOptions = [
    'Car',
    'Van',
    'Truck',
    'Bus',
    'Motorcycle',
    'Heavy Vehicle',
  ];

  VehicleListParams get _params => VehicleListParams(
    search: _searchController.text.isNotEmpty ? _searchController.text : null,
    status: _selectedStatus,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) => setState(() {});

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleListProvider(_params));
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Column(
        children: [
          // ── Search + Filters ──────────────────────────────────────────
          _buildSearchBar(),
          _buildFilterChips(),

          // ── Vehicle List / Grid ───────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(vehicleListProvider(_params));
              },
              child: vehiclesAsync.when(
                loading: () => _buildLoadingSkeleton(isWide),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(vehicleListProvider(_params)),
                ),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return _buildEmptyState();
                  }
                  return isWide ? _buildGrid(vehicles) : _buildList(vehicles);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search vehicles by registration, make or model…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ── Filter Chips ────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    final hasActiveFilter = _selectedStatus != null || _selectedType != null;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Status chips
          ..._statusOptions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s.replaceAll('_', ' ')),
                selected: _selectedStatus == s,
                selectedColor: AppColors.primaryLight.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? s : null;
                  });
                },
              ),
            ),
          ),

          // Type chips
          ..._typeOptions.map(
            (t) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(t),
                selected: _selectedType == t,
                selectedColor: AppColors.secondary.withOpacity(0.2),
                checkmarkColor: AppColors.secondary,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? t : null;
                  });
                },
              ),
            ),
          ),

          if (hasActiveFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                onPressed: _clearFilters,
              ),
            ),
        ],
      ),
    );
  }

  // ── List Layout ─────────────────────────────────────────────────────────

  Widget _buildList(List<VehicleEntity> vehicles) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VehicleCard(
            vehicle: vehicles[index],
            onTap: () => context.push('/vehicles/${vehicles[index].id}'),
          ),
        );
      },
    );
  }

  // ── Grid Layout (desktop) ───────────────────────────────────────────────

  Widget _buildGrid(List<VehicleEntity> vehicles) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 186,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        return VehicleCard(
          vehicle: vehicles[index],
          onTap: () => context.push('/vehicles/${vehicles[index].id}'),
        );
      },
    );
  }

  // ── Loading Skeleton ────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton(bool isWide) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: isWide
          ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 420,
                mainAxisExtent: 186,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => _skeletonCard(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _skeletonCard(),
              ),
            ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No vehicles found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first vehicle or adjust your filters.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/vehicles/create'),
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }
}
