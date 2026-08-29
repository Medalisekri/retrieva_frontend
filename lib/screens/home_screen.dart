import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retrieva/core/router/app_routes.dart';
import '../core/theme/apptheme.dart';
import '../core/widgets/listing_card.dart';
import '../providers/item_provider.dart'; // Your Riverpod provider
import '../models/item_model.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data exactly once when the screen opens
    Future.microtask(() {
      ref.read(myItemsNotifier.notifier).loadMyItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(myItemsNotifier);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Fixed height header
            _buildTopBar(context, currentUser),
            const SizedBox(height: 16),

            // 2. Wrap the rest of the screen in Expanded!
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    _buildTabs(),
                    const SizedBox(height: 8),

                    // 3. Now this inner Expanded works perfectly
                    Expanded(
                      child: itemsState.when(
                        data: (myItems) {
                          final activeItems = myItems.where((i) => i.status == 'active').toList();
                          final resolvedItems = myItems.where((i) => i.status == 'resolved').toList();

                          return TabBarView(
                            children: [
                              _buildItemList(context, activeItems, 'active'),
                              _buildItemList(context, resolvedItems, 'resolved'),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ... keep your other widgets (_buildTopBar, _buildTabs, etc.) exactly the same
}

  Widget _buildTopBar(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome Back!',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(user?.email ?? 'User',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            ],
          ),
          // Add your notification/profile icons here if needed
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppColors.teal,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Resolved'),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context, List<Item> items, String type) {
    if (items.isEmpty) {
      return _buildEmptyState(context, type);
    }

    return
      ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ListingCard(item: items[index]),
        );

      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              type == 'active' ? 'No active listings' : 'No resolved items',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'active'
                  ? 'Tap the button below to post your first item.'
                  : 'Items you mark as found/resolved will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            if (type == 'active') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.post, extra: 'lost'), // Using GoRouter
                icon: const Icon(Icons.add),
                label: const Text('Post an Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
