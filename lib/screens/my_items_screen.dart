import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:retrieva/core/services/cloudinary_service.dart';
import 'package:retrieva/providers/item_provider.dart';
import 'package:riverpod/src/framework.dart';
import '../core/router/app_routes.dart';
import '../core/theme/apptheme.dart';
import '../core/widgets/listing_card.dart';
import '../models/item_model.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {




  bool   _loading      = true;
  String _statusFilter = 'all';
  String _typeFilter   = 'all';

 late final int id;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myItemsNotifier.notifier).loadMyItems();
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

    ref.read(myItemsNotifier.notifier).deleteMyItem(item);
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
              backgroundColor: Colors.redAccent,
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
    ref.read(myItemsNotifier.notifier).markAsResolved(item);
  }

  // ── Edit ──────────────────────────────────────────────
  void _editItem(Item item ) {
    final nameCtrl = TextEditingController(text: item.name);
    final descCtrl = TextEditingController(text: item.description);
    final dateCtrl = TextEditingController(text: item.incidentDate );
    final typeCtrl = TextEditingController(text: item.type);
    final formKey  = GlobalKey<FormState>();

    String     category        = item.category;
    DateTime?  selectedDate;
    Uint8List? pickedBytes;
    String?     currentImageUrl = item.imgUrl;
    double?    lat             = item.lat;
    double?    lng             = item.long;
    bool       saving          = false;

    final categories = [
      'Keys', 'Wallet', 'Phone', 'Bag', 'Documents',
      'Jewelry', 'Glasses', 'Electronics', 'Clothing', 'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {

          Future<void> pickImage() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
                source: ImageSource.gallery, imageQuality: 75);
            if (picked == null) return;
            final bytes = await picked.readAsBytes();
            setSheet(() => pickedBytes = bytes);
          }

          Future<void> pickDate() async {
            final now  = DateTime.now();
            final date = await showDatePicker(
              context: ctx,
              initialDate: selectedDate ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: now,
              builder: (c, child) => Theme(
                data: Theme.of(c).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: AppColors.teal)),
                child: child!,
              ),
            );
            if (date != null) {
              setState(() {
                selectedDate = date;
                dateCtrl.text = DateFormat('dd MMM yyyy').format(date);
              });
            }
          }



          Future<void> save() async {
          final cloudinary=  CloudinaryService() ;
            if (!formKey.currentState!.validate()) return;
            setSheet(() => saving = true);

            try {
              String? newImageUrl;
              if (pickedBytes != null) {
                newImageUrl = await cloudinary.uploadBytes(pickedBytes!);
                if (newImageUrl == null) throw 'Image upload failed.';
              }




                  final updated = Item(
                    id: item.id, userId: item.userId,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    category: category, type: item.type,
                    status: item.status,

                    imgUrl: newImageUrl ?? currentImageUrl,

                    createdAt: item.createdAt, lat: lat, long: lng,isReported: false
                  );


              ref.read(myItemsNotifier.notifier).editMyItem(updated);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Listing updated!'),
                    backgroundColor: AppColors.teal,
                    behavior: SnackBarBehavior.floating,
                  ),
                );

            } }catch (e) {
              setSheet(() => saving = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20,
                MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const Text('Edit Listing',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 20),
                    _buildTypeSwitcher(),
                    const SizedBox(height: 20,),
                    // Photo
                    _label('Photo'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: double.infinity, height: 130,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pickedBytes != null
                                ? AppColors.teal : AppColors.border,
                            width: pickedBytes != null ? 1.5 : 1,
                          ),
                        ),
                        child: pickedBytes != null
                            ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.memory(pickedBytes!,
                                fit: BoxFit.cover))
                            : currentImageUrl?.isNotEmpty == true
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(currentImageUrl ?? '',
                                  fit: BoxFit.cover),
                              Positioned(
                                bottom: 8, right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.navy.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Change photo',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.teal.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.teal, size: 20),
                            ),
                            const SizedBox(height: 8),
                            const Text('Add photo',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Item Name
                    _label('Item Name *'),
                    const SizedBox(height: 6),
                    _field(controller: nameCtrl, hint: 'Item name',
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),

                    // Category
                    _label('Category'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: category,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary),
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textPrimary),
                          items: categories.map((c) =>
                              DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) setSheet(() => category = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    _label('Description'),
                    const SizedBox(height: 6),
                    _field(controller: descCtrl,
                        hint: 'Describe the item...', maxLines: 3),
                    const SizedBox(height: 12),

                    // Location

                    const SizedBox(height: 12),

                    // Date
                    _label('Date *'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: pickDate,
                      child: AbsorbPointer(
                        child: _field(
                          controller: dateCtrl,
                          hint: 'Select date',
                          prefixIcon: const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.textSecondary),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: saving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: saving
                            ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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

          if (!_loading)
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
          await Navigator.pushNamed(context, '/postitem');

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
          ElevatedButton(onPressed: (){context.push(AppRoutes.listing);}, child: Text('View all')),
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
  Widget _buildTypeSwitcher() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        _typeTab('lost', 'Lost Item'),
        _typeTab('found', 'Found Item'),
      ]),
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
                                  ? const Color(0xFFEEEDFE)
                                  : const Color(0xFFE1F5EE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isResolved
                                      ? Icons.refresh_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 12,
                                  color: isResolved
                                      ? const Color(0xFF534AB7)
                                      : const Color(0xFF0F6E56),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                   'Resolve',
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

  // ── Helpers ───────────────────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.4)),
  );

  Widget _field({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.5), fontSize: 14),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
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
  Widget _typeTab(String value, String label) {
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