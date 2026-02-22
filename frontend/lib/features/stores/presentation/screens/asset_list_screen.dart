import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../domain/entities/asset_entity.dart';
import '../providers/asset_provider.dart';
import '../widgets/asset_card.dart';

/// Main asset listing screen with search, condition/status filters,
/// pull-to-refresh, loading skeletons, and responsive grid/list layout.
class AssetListScreen extends ConsumerStatefulWidget {
  const AssetListScreen({super.key});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedCondition;

  static const _statusOptions = [
    'Available',
    'InUse',
    'UnderRepair',
    'Disposed',
    'Lost',
  ];

  static const _conditionOptions = [
    'New',
    'Good',
    'Fair',
    'Poor',
    'Damaged',
  ];

  AssetListParams get _params => AssetListParams(
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        status: _selectedStatus,
        condition: _selectedCondition,
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
      _selectedCondition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetListProvider(_params));
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Column(
        children: [
          // ── Search + Filters ────────────────────────────────────────
          _buildSearchBar(),
          _buildFilterChips(),

          // ── Asset Grid / List ───────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(assetListProvider(_params));
              },
              child: assetsAsync.when(
                loading: () => _buildLoadingSkeleton(isWide),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(assetListProvider(_params)),
                ),
                data: (assets) {
                  if (assets.isEmpty) return _buildEmptyState();
                  return isWide ? _buildGrid(assets) : _buildList(assets);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/stores/assets/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Asset'),
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
          hintText: 'Search assets by name, code or serial number…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  // ── Filter Chips ────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    final hasFilters = _selectedStatus != null || _selectedCondition != null;

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Status chips
          ..._statusOptions.map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(status),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? status : null;
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                ),
              )),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: VerticalDivider(width: 1),
          ),

          // Condition chips
          ..._conditionOptions.map((condition) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(condition),
                  selected: _selectedCondition == condition,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCondition = selected ? condition : null;
                    });
                  },
                  selectedColor: AppColors.secondary.withOpacity(0.15),
                  checkmarkColor: AppColors.secondary,
                ),
              )),

          // Clear button
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.only(left: 4),
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

  // ── Grid Layout (wide) ─────────────────────────────────────────────────

  Widget _buildGrid(List<AssetEntity> assets) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return AssetCard(
          asset: asset,
          onTap: () => context.push('/stores/assets/${asset.id}'),
        );
      },
    );
  }

  // ── List Layout (narrow) ───────────────────────────────────────────────

  Widget _buildList(List<AssetEntity> assets) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AssetCard(
            asset: asset,
            onTap: () => context.push('/stores/assets/${asset.id}'),
          ),
        );
      },
    );
  }

  // ── Loading Skeleton ───────────────────────────────────────────────────

  Widget _buildLoadingSkeleton(bool isWide) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: isWide
          ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No Assets Found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters, or add a new asset.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
