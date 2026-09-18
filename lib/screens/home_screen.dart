import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retrieva/core/router/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/labled_field.dart';
import '../core/widgets/listing_card.dart';
import '../providers/contact_provider.dart';
import '../providers/item_provider.dart';
import '../models/item_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl =TextEditingController();
  final _msgCtrl = TextEditingController();
  String? _contactError;
  bool _isSending = false;
  @override
  void dispose() {
    _nameCtrl;
    _emailCtrl;
    _msgCtrl;
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myItemsNotifier.notifier).loadMyItems();
    });
  }
  Future<void> _logout() async{
  await FirebaseAuth.instance.signOut();
  if(mounted){
  context.go(AppRoutes.items);}
  }


  Future<void> _contactUs() async {
    _contactError = null;
    _isSending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Contact Us',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Have a question or need help? Send us a message.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    LabeledField(label: 'Your Name', controller: _nameCtrl),
                    const SizedBox(height: 12),
                    LabeledField(label: 'Your Email', controller: _emailCtrl),
                    const SizedBox(height: 12),
                    LabeledField(label: 'Your Message', controller: _msgCtrl),
                    const SizedBox(height: 20),

                    // Error Text
                    if (_contactError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _contactError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    // Send Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(

                        onPressed: _isSending ? null : () {
                          _sendMessage(setModalState, context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        child: _isSending
                            ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text(
                          'Send Message',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendMessage(StateSetter setModalState, BuildContext modalContext) async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final message = _msgCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || message.isEmpty) {

      setModalState(() => _contactError = 'Please fill all fields');
      return;
    }

    setModalState(() {
      _contactError = null;
      _isSending = true;
    });

    try {
      await ref.read(contactRepositoryProvider).sendMessage(
        name: name,
        email: email,
        message: message,
      );

      _nameCtrl.clear();
      _emailCtrl.clear();
      _msgCtrl.clear();

      if (mounted) {

        Navigator.of(modalContext).pop();

        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully!'),
            backgroundColor: AppColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setModalState(() {
          _contactError = 'Failed to send. Please try again.';
          _isSending = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(myItemsNotifier);
    final currentUser = FirebaseAuth.instance.currentUser;


    Item? item;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, currentUser , item ),
            const SizedBox(height: 16),

            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    _buildTabs(),
                    const SizedBox(height: 8),
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

  Widget _buildMoreMenu(Item? item) {

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.textSecondary,
      ),
      onSelected: (value) {
        switch (value) {
          case 'all listings':
            context.push(
              AppRoutes.listing,
              extra: item,
            );
            break;

          case 'contact us':
            _contactUs();
            break;

          case 'logout':
            _logout();
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'all listings',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
              ),
              SizedBox(width: 10),
              Text('All Listings'),
            ],
          ),
        ),


          const PopupMenuItem(
            value: 'contact us',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text('Contact Us'),
              ],
            ),
          ),

        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Color(0xFFC62828),
              ),
              SizedBox(width: 10),
              Text(
                'Logout',
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
  Widget _buildTopBar(BuildContext context, User? user , Item? item) {
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
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              user?.email?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? 'User',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        _buildMoreMenu(item)
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'active' ? 'No active listings' : 'No resolved items',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
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
                onPressed: () => context.push(AppRoutes.post, extra: 'lost'),
                icon: const Icon(Icons.add),
                label: const Text('Post an Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}