import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../domain/entities/machine_entity.dart';
import '../providers/machine_provider.dart';
import '../widgets/machine_card.dart';

/// Main machine listing screen with search, filter chips, pull‑to‑refresh,
/// loading skeletons, and responsive grid/list layout.
class MachineListScreen extends ConsumerStatefulWidget {
  const MachineListScreen({super.key});

  @override
  ConsumerState<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends ConsumerState<MachineListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedType;

  static const _statusOptions = [
    'ACTIVE',
    'UNDER_MAINTENANCE',
    'DECOMMISSIONED',
    'IDLE',
  ];

  static const _statusLabels = {
    'ACTIVE': 'Active',
    'UNDER_MAINTENANCE': 'Under Maintenance',
    'DECOMMISSIONED': 'Decommissioned',
    'IDLE': 'Idle',
  };

  static const _typeOptions = [
    'Production',
    'Packaging',
    'Processing',
    'Utility',
    'Transport',
    'Quality Control',
  ];

  MachineListParams get _params => MachineListParams(
    search: _searchController.text.isNotEmpty ? _searchController.text : null,
    status: _selectedStatus,
    type: _selectedType,
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
    final machinesAsync = ref.watch(machineListProvider(_params));
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Column(
        children: [
          // ── Search + Filters ──────────────────────────────────────────
          _buildSearchBar(),
          _buildFilterChips(),

          // ── Machine List / Grid ───────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(machineListProvider(_params));
              },
              child: machinesAsync.when(
                loading: () => _buildLoadingSkeleton(isWide),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(machineListProvider(_params)),
                ),
                data: (machines) {
                  if (machines.isEmpty) {
                    return _buildEmptyState();
                  }
                  return isWide ? _buildGrid(machines) : _buildList(machines);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/machines/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Machine'),
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
          hintText: 'Search machines by name, code or location…',
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
                label: Text(_statusLabels[s] ?? s.replaceAll('_', ' ')),
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

  Widget _buildList(List<MachineEntity> machines) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: machines.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MachineCard(
            machine: machines[index],
            onTap: () => context.push('/machines/${machines[index].id}'),
          ),
        );
      },
    );
  }

  // ── Grid Layout (desktop) ───────────────────────────────────────────────

  Widget _buildGrid(List<MachineEntity> machines) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: machines.length,
      itemBuilder: (context, index) {
        return MachineCard(
          machine: machines[index],
          onTap: () => context.push('/machines/${machines[index].id}'),
        );
      },
    );
  }

  // ── Loading Skeleton ────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton(bool isWide) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
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
            Icons.precision_manufacturing_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No machines found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
