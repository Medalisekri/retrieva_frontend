import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:retrieva/core/router/app_routes.dart';
import 'package:retrieva/providers/item_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/browse_card.dart';
import '../models/item_model.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final PagingController<int, Item> _pagingController = PagingController(firstPageKey: 1);
  String selectedCategory = 'All';
  String selectedType = 'All';
  final List<String> categories = [
    'All', 'Keys', 'Wallet', 'Phone', 'Bag',
    'Documents', 'Jewelry', 'Glasses', 'Electronics', 'Clothing', 'Other',
  ];
  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }
  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await ref.read(itemRepositoryProvider).getItems(
        page: pageKey,
        type: selectedType == 'All' ? null : selectedType.toLowerCase(),
        category: selectedCategory == 'All' ? null : selectedCategory,
      );

      final isLastPage = newItems.length < 20;

      if (isLastPage) {
        _pagingController.appendLastPage(newItems );
      } else {
        _pagingController.appendPage(newItems , pageKey + 1);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }
  void _applyFilters() {
    _pagingController.refresh();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: context.canPop()
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => context.pop(),
        )
            : null,
        title: const Text(
          'Browse Listings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),

      ),
      body: Column(
        children: [
          if(FirebaseAuth.instance.currentUser == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.login),
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('Login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.mapView),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Map View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _typeTab('All' , 'All'),
                    const SizedBox(width: 8),
                    _typeTab('Lost',  'lost'),
                    const SizedBox(width: 8),
                    _typeTab('Found', 'found'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _categoryChip(categories[i]),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Results
          Expanded(
            child: PagedListView<int, Item>.separated(
              pagingController: _pagingController,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              builderDelegate: PagedChildBuilderDelegate<Item>(
                itemBuilder: (context, item, index) => BrowseItemCard(item: item),

                firstPageProgressIndicatorBuilder: (context) => const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                ),

                newPageProgressIndicatorBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
                ),


                firstPageErrorIndicatorBuilder: (context) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Something went wrong'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _pagingController.retryLastFailedRequest(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),

                noItemsFoundIndicatorBuilder: (context) => _buildEmptyState(),

                noMoreItemsIndicatorBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      "You've reached the end!",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Type tab ─────────────────────────────────────────
  Widget _typeTab(String label, String value) {
    final selected = selectedType ==value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedType =value  );
          _applyFilters();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Category chip ──────────────────────────────────────
  Widget _categoryChip(String label) {
    final selected = selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() => selectedCategory = label);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 52,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 14),
          const Text(
            'No items found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}