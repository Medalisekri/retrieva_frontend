import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:retrieva/providers/auth_provider.dart';
import 'package:retrieva/providers/item_provider.dart';
import '../core/theme/apptheme.dart';
import '../models/item_model.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final Item? item;
  const ItemDetailScreen({super.key, this.item});

  @override
ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late Item _item;
  bool _itemLoaded = false;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        if(widget.item !=null){
          _item = widget.item!;
          _itemLoaded = true;
          _loadItemDetail();
        }else{
        _itemLoaded = false;
      }
        debugPrint('isOwner value: ${_item.isOwner}');
        debugPrint('isOwner runtimeType: ${_item.isOwner.runtimeType}');
      });

    });

  }
  Future<void> _loadItemDetail() async{
    try{
  final itemDetail =   await ref.read(myItemsNotifier.notifier).loadItemDetail(_item.id!);
    if(mounted) {
      setState(() {
        _item = itemDetail;
      });
    }
  }catch(e){
      throw Exception(e);
    }
}


 // String get _myUid => _auth.currentUser!.uid;

  //Future<void> _openChat() async {
   // if (_myUid == _item.userId) {
     // ScaffoldMessenger.of(context).showSnackBar(
      //  const SnackBar(
       //   content: Text('This is your own listing.'),
        //  behavior: SnackBarBehavior.floating,
      //  ),
     // );
    //  return;
   // }

   // final chatId  = ([_myUid, _item.userId]..sort()).join('_');
   // final chatRef = _db.collection('chats').doc(chatId);

   // if (!(await chatRef.get()).exists) {
     // await chatRef.set({
      //  'participants':  [_myUid, _item.userId],
      //  'itemId':        _item.id,
      //  'itemTitle':     _item.name,
       // 'createdAt':     DateTime.now().toIso8601String(),
       // 'lastMessage':   '',
     //   'lastMessageAt': DateTime.now().toIso8601String(),
      //  'blockedBy':     [],
     // });
   // }

   // if (mounted) {
      //Navigator.pushNamed(context, '/chat', arguments: {
     //   'chatId':      chatId,
      //  'otherUserId': _item.userId,
      //  'otherName':   _poster?.name ?? 'User',
     //   'itemTitle':   _item.title,
    //  });
   // }
 // }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
      final profile = ref.watch(profileProvider);

    if (!_itemLoaded) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }

    final isOwner = currentUser?.uid == _item.userId;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── AppBar with image ─────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  size: 18, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: const Text('Details',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)),
            flexibleSpace: FlexibleSpaceBar(
              background: _item.imgUrl?.isNotEmpty ==true
                  ? Image.network(_item.imgUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _imagePlaceholder(_item))
                  : _imagePlaceholder(_item),
            ),
          ),

          // ── Body ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Title + badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(_item.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _item.isLost
                                  ? const Color(0xFFFCEBEB)
                                  : const Color(0xFFE1F5EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _item.isLost ? 'Lost' : 'Found',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _item.isLost
                                      ? const Color(0xFFA32D2D)
                                      : const Color(0xFF0F6E56)),
                            ),
                          ),
                          // Resolved badge
                          if (_item.status == 'resolved') ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEDFE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Resolved',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF534AB7))),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(_item.category,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 14),

                  if (_item.description?.isNotEmpty ==true) ...[
                    Text(_item.description ?? '',
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.6)),
                    const SizedBox(height: 20),
                  ],

                  // ── Information ───────────────────────
                  _sectionTitle('Information'),
                  const SizedBox(height: 12),
                 // _infoRow(
                 //   Icons.location_on_outlined,
                  //  _item.isLost ? 'Location Lost' : 'Location Found',
                  //  _item.location,
                //  ),
                  const Divider(color: AppColors.border, height: 24),
                  _infoRow(Icons.calendar_today_outlined, 'Date', _item.incidentDate ?? ''),
                  const SizedBox(height: 24),

                  // ── Contact ───────────────────────────
                  // Only show contact for non-owners
                  if (_item.isOwner != true ) ...[
                    _sectionTitle('Contact'),
                    const SizedBox(height: 12),
                    if (!_loading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.teal))
                    else if (currentUser != null) ...[
                      _infoRow(Icons.person_outline_rounded,
                         ' Posted By', _item.posterName ?? ''),

                    ],
                    const SizedBox(height: 28),

                    // ── Send Message ──────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                       onPressed: (){},
                        icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18),
                        label: const Text('Send Message',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],

                 // const SizedBox(height: 24),
           //   ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder(Item item) {
    return Container(
      color: item.isLost
          ? const Color(0xFFFEF3C7)
          : const Color(0xFFE1F5EE),
      child: Center(
        child: Icon(
          item.isLost
              ? Icons.search_off_rounded
              : Icons.check_circle_outline_rounded,
          size: 64,
          color: item.isLost
              ? const Color(0xFF854F0B)
              : const Color(0xFF0F6E56),
        ),
      ),
    );
  }
}