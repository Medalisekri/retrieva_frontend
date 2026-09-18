
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:retrieva/core/helper/location_helper.dart';
import 'package:retrieva/core/router/app_routes.dart';
import 'package:retrieva/models/chat_model.dart';
import 'package:retrieva/providers/item_provider.dart';
import '../core/theme/app_theme.dart';
import '../models/item_model.dart';
import '../providers/chat_provider.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final Item? item;

  const ItemDetailScreen({
    super.key,
    this.item,
  });

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late Item _item;
  bool _itemLoaded = false;
  bool _loading = true;
  String _addressLabel = '';
  bool   _geocoding    = false;
  Future<void> _loadAddress(Item item) async {
    if (item.lat != null && item.long != null) {
      final point = LatLng(item.lat!, item.long!);

      if (!mounted) return;
      setState(() {
        _geocoding = true;
        _addressLabel = '';
      });


      final address = await GeocodingService.getAddressFromCoordinates(point);

      if (mounted) {
        setState(() {
          _addressLabel = address;
          _geocoding = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.item != null) {
      _item = widget.item!;
      _itemLoaded = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadItemDetail();
      });
      _loadAddress(_item);
    }
  }

  Future<void> _loadItemDetail() async {
    try {
      final itemDetail = await ref
          .read(myItemsNotifier.notifier)
          .loadItemDetail(_item.id!);

      if (!mounted) return;

      setState(() {
        _item = itemDetail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      debugPrint('Failed to load item details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {

    if (!_itemLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.teal,
          ),
        ),
      );
    }


    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _buildImageHeader(),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),

                          if (_item.description?.isNotEmpty == true) ...[
                            _buildSectionTitle('Description'),
                            const SizedBox(height: 10),
                            Text(
                              _item.description!,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.55,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],

                          _buildSectionTitle('Information'),
                          const SizedBox(height: 12),
                          _buildInformationCard(),

                          if (!_loading &&_item.isOwner != true) ...[
                            const SizedBox(height: 28),
                            _buildSectionTitle('Posted By'),
                            const SizedBox(height: 12),
                            _buildPosterCard(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (!_loading && _item.isOwner != true)
              _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _circleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _item.imgUrl?.isNotEmpty == true
            ? Image.network(
          _item.imgUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _item.name,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _statusBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _item.category,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge() {
    final isLost = _item.isLost;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
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
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isLost
              ? const Color(0xFFB42318)
              : const Color(0xFF087443),
        ),
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Incident Date',
            value: _item.incidentDate ?? 'Not specified',
          ),

           const SizedBox(height: 16),
           _infoRow(
             icon: Icons.location_on_outlined,
             label: 'Location',
               value: _geocoding ? 'Getting address...': (_addressLabel.isNotEmpty ?
               _addressLabel : 'Unknown Location'),
           ),


          if (_item.status == 'resolved') ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(
                height: 1,
                color: AppColors.border,
              ),
            ),
            _infoRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'Status',
              value: 'Resolved',
              valueColor: const Color(0xFF534AB7),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPosterCard() {
    if (_loading) {
      return Container(
        height: 72,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.teal,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.teal.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Posted by',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _item.posterName?.isNotEmpty == true
                      ? _item.posterName!
                      : 'User',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    final isResolved = _item.status == 'resolved';

    if (isResolved) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: AppColors.border,
              ),
            ),
          ),
          child: const SizedBox(
            height: 52,
            child: Center(
              child: Text(
                'This report has been resolved',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
            ),
          ),
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
          if (_item.id == null) return;

            try {
            final newConversation = await ref.read(conversationNotifier.notifier).createConversation(
            itemId: _item.id ?? 0,
            otherUserId: _item.userId ?? 0,
          );

          if (context.mounted) {
        context.push(AppRoutes.message, extra: newConversation);
            }
          } catch (e) {
              if(context.mounted){
                ScaffoldMessenger.of(context).
                showSnackBar(SnackBar(content: Text('Could not load chat $e')));

              }
            }
            },
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 19,
            ),
            label: const Text(
              'Message Poster',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 19,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    final isLost = _item.isLost;

    return Container(
      color: isLost
          ? const Color(0xFFFFF7E8)
          : const Color(0xFFEDF9F4),
      child: Center(
        child: Icon(
          isLost
              ? Icons.search_off_rounded
              : Icons.check_circle_outline_rounded,
          size: 60,
          color: isLost
              ? const Color(0xFF9A6700)
              : const Color(0xFF087443),
        ),
      ),
    );
  }
}