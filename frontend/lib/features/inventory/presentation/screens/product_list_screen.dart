import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../domain/entities/inventory_entity.dart';
import '../providers/inventory_provider.dart';
import '../widgets/product_card.dart';

/// Main product listing screen with category filters, search,
/// low‑stock toggle, card grid / list, and FAB.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;
  bool _lowStockOnly = false;

  ProductListParams get _params => ProductListParams(
    search: _searchController.text.isNotEmpty ? _searchController.text : null,
    categoryId: _selectedCategoryId,
    lowStock: _lowStockOnly ? true : null,
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
      _selectedCategoryId = null;
      _lowStockOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider(_params));
    final categoriesAsync = ref.watch(categoriesProvider);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Column(
        children: [
          // ── Search ────────────────────────────────────────────────────
          _buildSearchBar(),

          // ── Category Filter Chips ─────────────────────────────────────
          _buildFilterChips(categoriesAsync),

          // ── Product List / Grid ───────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(productListProvider(_params));
              },
              child: productsAsync.when(
                loading: () => _buildLoadingSkeleton(isWide),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(productListProvider(_params)),
                ),
                data: (products) {
                  if (products.isEmpty) return _buildEmptyState();
                  return isWide ? _buildGrid(products) : _buildList(products);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/products/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
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
          hintText: 'Search products by name or code…',
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

  Widget _buildFilterChips(AsyncValue<List<CategoryEntity>> categoriesAsync) {
    final categories = categoriesAsync.valueOrNull ?? [];
    final hasActiveFilter = _selectedCategoryId != null || _lowStockOnly;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Low stock toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: _lowStockOnly ? AppColors.error : null,
              ),
              label: const Text('Low Stock'),
              selected: _lowStockOnly,
              selectedColor: AppColors.error.withOpacity(0.15),
              checkmarkColor: AppColors.error,
              onSelected: (selected) {
                setState(() => _lowStockOnly = selected);
              },
            ),
          ),

          // Category chips
          ...categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c.name),
                selected: _selectedCategoryId == c.id,
                selectedColor: AppColors.primaryLight.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategoryId = selected ? c.id : null;
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

  Widget _buildList(List<ProductEntity> products) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProductCard(
            product: products[index],
            onTap: () =>
                context.push('/inventory/products/${products[index].id}'),
          ),
        );
      },
    );
  }

  // ── Grid Layout ─────────────────────────────────────────────────────────

  Widget _buildGrid(List<ProductEntity> products) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(
          product: products[index],
          onTap: () =>
              context.push('/inventory/products/${products[index].id}'),
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
                mainAxisExtent: 200,
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
      height: 180,
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
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first product or adjust your filters.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/inventory/products/create'),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }
}
