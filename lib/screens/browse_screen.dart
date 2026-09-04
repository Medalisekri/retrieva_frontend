import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrieva/core/router/app_routes.dart';
import 'package:retrieva/providers/item_provider.dart';
import '../core/theme/apptheme.dart';
import '../core/widgets/browse_card.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BrowseScreen();

}
class _BrowseScreen extends ConsumerState<BrowseScreen> {
  String selectedCategory = 'All';
  String selectedType = 'All';
  final List<String> categories = [
    'All', 'Keys', 'Wallet', 'Phone', 'Bag',
    'Documents', 'Jewelry', 'Glasses', 'Electronics', 'Clothing', 'Other',
  ];


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemNotifier);

// Combined category and type filter


    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Browse Listings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          ElevatedButton(onPressed: (){
            context.push(AppRoutes.signup);
          }, child: Text('Sign Up')),
// ── Search + Filters (fixed) ─────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                const SizedBox(height: 12),

// Type tabs — All / Lost / Found
                Row(
                  children: [
                    _typeTab('All', selectedType == 'All'),
                    const SizedBox(width: 8),
                    _typeTab('Lost', selectedType == 'Lost'),
                    const SizedBox(width: 8),
                    _typeTab('Found', selectedType == 'Found'),
                  ],
                ),

                const SizedBox(height: 19),

// Category chips — scrollable
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _categoryChip(categories[i]),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          const SizedBox(height: 15,),
          ElevatedButton(onPressed: (){context.push(AppRoutes.mapView);}, child: Text('Map view')),
          const Divider(height: 1, color: AppColors.border),

// ── Results ──────────────────────────────────
          Expanded(
            child: state.when(
            loading: ()=>
                 const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            ),
            error: (error, stackTrace) => Center(
            child: Text(
            'Something went wrong : $error',
              style: const TextStyle(color: Colors.red),
                  ),
                    ),
// Quand les données sont prêtes (items contient la liste brute reçue)
          data : (items) {
    final filteredItems = items.where((c) {
    final matchesCategory = selectedCategory == 'All' ||
    c.category == selectedCategory;
    final matchesType = selectedType == 'All' || c.type == selectedType;
    return matchesCategory && matchesType;
    }).toList();

    if (filteredItems.isEmpty){
    return _buildEmptyState();
    }

    return Card(
    color: AppColors.surface,
    child: ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: filteredItems.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (context, i) =>
    BrowseItemCard(item: filteredItems[i]),
    ),
    );
    }),
          )],
      ),
    );
  }

// ── Type tab ─────────────────────────────────────────
  Widget _typeTab(String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedType = label);
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