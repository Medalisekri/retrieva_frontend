import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrieva/providers/item_provider.dart';
import 'package:riverpod/src/framework.dart';
import '../core/router/app_routes.dart';
import '../core/theme/apptheme.dart';
import '../models/item_model.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {


  String _statusFilter = 'all';
  String _typeFilter   = 'all';
 late final int id;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async{
     await  ref.read(myItemsNotifier.notifier).loadMyItems();
    });
  }





  // ── Delete ────────────────────────────────────────────
  Future<void> _deleteItem(Item item) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
            'This will permanently delete this listing.',
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

   await ref.read(myItemsNotifier.notifier).deleteMyItem(item);
  }

  // ── Toggle resolved ───────────────────────────────────
  Future<void> _toggleResolved(Item item) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolve Listing',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
            'This will permanently resolve this item.',
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
   await ref.read(myItemsNotifier.notifier).markAsResolved(item);
  }

  // ── Edit ──────────────────────────────────────────────


  @override
  Widget build(BuildContext context) {
   final myItemsState =  ref.watch(myItemsNotifier);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Listings',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Filters ───────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Row(children: [
                  _typesTab('all', 'All'),
                  const SizedBox(width: 8),
                  _typesTab('lost', 'Lost'),
                  const SizedBox(width: 8),
                  _typesTab('found', 'Found'),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _statusTab('all',      'All',      AppColors.navy),
                  const SizedBox(width: 8),
                  _statusTab('active',   'Active',   const Color(0xFF0F6E56)),
                  const SizedBox(width: 8),
                  _statusTab('resolved', 'Resolved', const Color(0xFF534AB7)),
                ]),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (!myItemsState.isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: AppColors.surface,

            ),
          Expanded(
            child: myItemsState.when(
              data: (myItems) {
                final fileterdItems = myItems.where((item) {
                  final matchStatus = _statusFilter =='all' || _statusFilter == item.status;
                  final matchType = _typeFilter == 'all' || _typeFilter == item.type;


                  return matchStatus && matchType;
                }).toList();
                if (fileterdItems.isEmpty){
                  return _buildEmptyState(context, 'empty');
                }
                return ListView.builder(
                  padding: EdgeInsetsGeometry.all(20),
                    itemCount: fileterdItems.length,
                    itemBuilder:(context , index){
                    return _buildCard(fileterdItems[index]);
                    });
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push( AppRoutes.post);

        },
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Item',
            style: TextStyle(fontWeight: FontWeight.w600)),
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


  Widget _buildCard(Item item) {
    final isResolved = item.status == 'resolved';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isResolved
              ? const Color(0xFFAFA9EC)
              : AppColors.border,
        ),
      ),
      child: Opacity(
        opacity: isResolved ? 0.8 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            GestureDetector(
              onTap: () async {
                await Navigator.pushNamed(context, '/item-detail',
                    arguments: item);

              },
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 90, height: 110,
                  child: item.imgUrl?.isNotEmpty == true
                      ? Image.network(item.imgUrl ?? '' ,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(item))
                      : _placeholder(item),
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.name,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isResolved
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary)),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _typeBadge(item),
                            if (isResolved) ...[
                              const SizedBox(height: 4),
                              _resolvedBadge(),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(item.category,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),

                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.teal),
                      const SizedBox(width: 3),
                      Text(item.incidentDate ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 10),

                    // ── Action buttons ────────────────
                    Row(children: [
                      // Edit
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.edit , extra: item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F1FB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 12,
                                    color: Color(0xFF185FA5)),
                                SizedBox(width: 4),
                                Text('Edit',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF185FA5))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Resolve / Reopen
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleResolved(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? const Color(0xFFE1F5EE)
                                  : const Color(0xFFE1F5EE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isResolved
                                      ? Icons.check
                                      : Icons.check_circle_outline_rounded,
                                  size: 12,
                                  color: isResolved
                                      ? const Color(0xFF534AB7)
                                      : const Color(0xFF0F6E56),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isResolved?
                                  'Resolved'
                                 :  'Resolve',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isResolved
                                          ? const Color(0xFF534AB7)
                                          : const Color(0xFF0F6E56)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Delete
                      GestureDetector(
                        onTap: () => _deleteItem(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEBEB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 12, color: Color(0xFFA32D2D)),
                            SizedBox(width: 4),
                            Text('Delete',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFA32D2D))),
                          ]),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter tabs ───────────────────────────────────────
  Widget _typesTab(String value, String label) {
    final selected = _typeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() => _typeFilter = value);  },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? AppColors.navy : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _statusTab(String value, String label, Color activeColor) {
    final selected = _statusFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() => _statusFilter = value);  },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 32,
          decoration: BoxDecoration(
            color: selected ? activeColor.withOpacity(0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? activeColor : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? activeColor : AppColors.textSecondary)),
        ),
      ),
    );
  }


  Widget _typeBadge(Item item) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: item.isLost
          ? const Color(0xFFFCEBEB) : const Color(0xFFE1F5EE),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(item.isLost ? 'Lost' : 'Found',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: item.isLost
                ? const Color(0xFFA32D2D) : const Color(0xFF0F6E56))),
  );

  Widget _resolvedBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFEEEDFE),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text('Resolved',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: Color(0xFF534AB7))),
  );

  Widget _placeholder(Item item) => Container(
    color: item.isLost
        ? const Color(0xFFFEF3C7) : const Color(0xFFE1F5EE),
    child: Center(
      child: Icon(
        item.isLost
            ? Icons.search_off_rounded
            : Icons.check_circle_outline_rounded,
        size: 28,
        color: item.isLost
            ? const Color(0xFF854F0B) : const Color(0xFF0F6E56),
      ),
    ),
  );

  Widget _buildEmptyState(BuildContext context, String type) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined,
            size: 52,
            color: AppColors.textSecondary.withOpacity(0.3)),
        const SizedBox(height: 14),
        const Text('No listings yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(
          _statusFilter != 'all' || _typeFilter != 'all'
              ? 'No listings match your filters'
              : 'Post your first lost or found item',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.7)),
        ),
      ],
    ),
  );
}