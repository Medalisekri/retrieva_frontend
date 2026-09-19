import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:retrieva/providers/item_provider.dart';
import 'package:retrieva/core/router/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/item_model.dart';
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(myItemsNotifier.notifier).loadMyItems();
    });
  }


  Future<void> _deleteItem(Item item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Delete listing?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This listing will be permanently deleted.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(myItemsNotifier.notifier).deleteMyItem(item);
  }


  Future<void> _toggleResolved(Item item) async {
    if (item.status == 'resolved') {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Mark as resolved?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Only mark this listing as resolved once the item has been found or returned.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(myItemsNotifier.notifier).markAsResolved(item);
  }

  @override
  Widget build(BuildContext context) {
    final myItemsState = ref.watch(myItemsNotifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'My Listings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
      ),

      body: Column(
        children: [
          // Filters
          _buildFilters(),

          Expanded(
            child: myItemsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.teal,
                ),
              ),

              error: (error, _) => _buildErrorState(),

              data: (items) {
                final filteredItems = items.where((item) {
                  final matchesStatus = _statusFilter == 'all' ||
                      item.status == _statusFilter;

                  final matchesType = _typeFilter == 'all' ||
                      item.type == _typeFilter;

                  return matchesStatus && matchesType;
                }).toList();

                if (filteredItems.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    100,
                  ),
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    return _buildCard(filteredItems[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.post);
        },
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Post Item',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _typeFilterChip('all', 'All'),
              const SizedBox(width: 8),
              _typeFilterChip('lost', 'Lost'),
              const SizedBox(width: 8),
              _typeFilterChip('found', 'Found'),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _statusFilterTab('all', 'All'),
                _statusFilterTab('active', 'Active'),
                _statusFilterTab('resolved', 'Resolved'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeFilterChip(String value, String label) {
    final selected = _typeFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _typeFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navy
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.navy
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _statusFilterTab(String value, String label) {
    final selected = _statusFilter == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _statusFilter = value;
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCard(Item item) {
    final isResolved = item.status == 'resolved';

    return GestureDetector(
      onTap: () {
        context.push(
          AppRoutes.detail,
          extra: item,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Opacity(
          opacity: isResolved ? 0.72 : 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 105,
                  height: 145,
                  child: item.imgUrl?.isNotEmpty == true
                      ? Image.network(
                    item.imgUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _placeholder(item);
                    },
                  )
                      : _placeholder(item),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    13,
                    12,
                    8,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                                color: isResolved
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),

                          _buildMoreMenu(item),
                        ],
                      ),

                      const SizedBox(height: 3),

                      Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.incidentDate ?? 'No date',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _typeBadge(item),

                          if (isResolved) ...[
                            const SizedBox(width: 6),
                            _resolvedBadge(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenu(Item item) {
    final isResolved = item.status == 'resolved';

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.textSecondary,
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            context.push(
              AppRoutes.edit,
              extra: item,
            );
            break;

          case 'resolve':
            _toggleResolved(item);
            break;

          case 'delete':
            _deleteItem(item);
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
              ),
              SizedBox(width: 10),
              Text('Edit'),
            ],
          ),
        ),

        if (!isResolved)
          const PopupMenuItem(
            value: 'resolve',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text('Mark as resolved'),
              ],
            ),
          ),

        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Color(0xFFC62828),
              ),
              SizedBox(width: 10),
              Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFC62828),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _typeBadge(Item item) {
    final isLost = item.isLost;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isLost
            ? const Color(0xFFFFF1F1)
            : const Color(0xFFEDF9F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLost ? 'Lost' : 'Found',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isLost
              ? const Color(0xFFB42318)
              : const Color(0xFF087443),
        ),
      ),
    );
  }

  Widget _resolvedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Resolved',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF534AB7),
        ),
      ),
    );
  }


  Widget _placeholder(Item item) {
    final isLost = item.isLost;

    return Container(
      color: isLost
          ? const Color(0xFFFFF7E8)
          : const Color(0xFFEDF9F4),
      child: Center(
        child: Icon(
          isLost
              ? Icons.search_off_rounded
              : Icons.check_circle_outline_rounded,
          size: 30,
          color: isLost
              ? const Color(0xFF9A6700)
              : const Color(0xFF087443),
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    final hasFilters =
        _typeFilter != 'all' || _statusFilter != 'all';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: AppColors.teal,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              hasFilters
                  ? 'No matching listings'
                  : 'No listings yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              hasFilters
                  ? 'Try changing your filters.'
                  : 'Post a lost or found item to get started.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Please try again later.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}