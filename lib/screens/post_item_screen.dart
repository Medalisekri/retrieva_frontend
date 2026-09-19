import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:retrieva/core/router/app_routes.dart';
import 'package:retrieva/core/services/cloudinary_service.dart';
import 'package:retrieva/providers/item_provider.dart';
import 'package:flutter/foundation.dart';
import '../core/theme/app_theme.dart';
import '../models/item_model.dart';

class PostItemScreen extends ConsumerStatefulWidget {
final Item? existingItem;
  const PostItemScreen({super.key, this.existingItem});

  @override
  ConsumerState<PostItemScreen> createState() => _PostItemScreenState();
}


class _PostItemScreenState extends ConsumerState<PostItemScreen> {
  String? _networkImageUrl;
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _locCtrl    = TextEditingController();
  var _dateCtrl   = TextEditingController();
  double? _lat;
  double? _lng;
  String _type      = 'lost';   // 'lost' or 'found'
  String _status = 'active';
  String _category  = 'Keys';
  bool   _loading   = false;
  DateTime? _selectedDate;
  XFile? _pickedFile;

  final List<String> _categories = [
    'Keys', 'Wallet', 'Phone', 'Bag', 'Documents',
    'Jewelry', 'Glasses', 'Electronics', 'Clothing', 'Other',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.existingItem != null) {
      final item = widget.existingItem!;

      _nameCtrl.text = item.name;
      _descCtrl.text = item.description ?? '';

      _type = item.type;
      _category = item.category;
      _status = item.status;

      _lat = item.lat;
      _lng = item.long;
      if (_lat != null && _lng != null) {
        _locCtrl.text = '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}';
      }

      if (item.incidentDate != null && item.incidentDate!.isNotEmpty) {
        _selectedDate = DateTime.tryParse(item.incidentDate!);
        if (_selectedDate != null) {
          _dateCtrl.text = DateFormat('dd MMM yyyy').format(_selectedDate!);
        }
      }

      _networkImageUrl = item.imgUrl;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arg = GoRouterState.of(context).extra as String?;
      if (arg != null && widget.existingItem == null) {
        setState(() => _type = arg);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  // ── Pick image ────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    setState(() {
      _pickedFile = picked;
      _networkImageUrl = null;
    });
  }
  // ── Pick date ─────────────────────────────────────────
  Future<void> _pickDate() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.teal),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateCtrl.text = DateFormat('dd MMM yyyy').format(date);
      });
    }
  }

  // ── Submit ────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null || _selectedDate == null) return;

    setState(() => _loading = true);

    try {
      String? finalImageUrl = _networkImageUrl;

      if (_pickedFile != null) {
        final cloudinary = CloudinaryService();

        final bytes = await _pickedFile!.readAsBytes();

        finalImageUrl = await cloudinary.uploadBytes(
          bytes,
          folder: 'retrieva/items',
          filename: _pickedFile!.name,
        );

        if (finalImageUrl == null) {
          throw Exception('Image upload failed');
        }
      }


      final itemData = Item(
        id: widget.existingItem?.id,
        type: _type,
        category: _category,
        name: _nameCtrl.text.trim(),
        imgUrl: finalImageUrl ?? '',
        description: _descCtrl.text.trim(),
        lat: double.parse(_lat!.toStringAsFixed(7)),
        long: double.parse(_lng!.toStringAsFixed(7)),
        status: _status,
        incidentDate: _selectedDate!.toIso8601String().split('T')[0],
        isReported: false
      );


      if (widget.existingItem != null) {

        await ref.read(myItemsNotifier.notifier).editMyItem(itemData);
      } else {
        await ref.read(itemNotifier.notifier).addItem(itemData);
        ref.invalidate(myItemsNotifier);
      }

      if (!mounted) return;
      context.pop();


    }catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
      content: Text(e.toString().replaceFirst('Exception: ', '')),
      backgroundColor: Colors.red,
      ),
      );
      }} finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final itemState =ref.watch(itemNotifier);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Post an Item',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Report Type ──────────────────────────
              _label('Report Type *'),
              const SizedBox(height: 10),
              _buildTypeSwitcher(),
              const SizedBox(height: 24),

              // ── Photo ────────────────────────────────
              _label('Photo'),
              const SizedBox(height: 10),
              _buildPhotoPicker(),
              const SizedBox(height: 24),

              // ── Item Name ────────────────────────────
              _label('Item Name *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameCtrl,
                hint: 'e.g. Black leather wallet',
                validator: (v) =>
                v == null || v.isEmpty ? 'Item name is required' : null,
              ),
              const SizedBox(height: 20),

              // ── Category ─────────────────────────────
              _label('Category *'),
              const SizedBox(height: 8),
              _buildCategoryDropdown(),
              const SizedBox(height: 20),

              // ── Description ──────────────────────────
              _label('Description'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descCtrl,
                hint: 'Describe the item (color, brand, any details...)',
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // ── Location ─────────────────────────────
              _label('Location *'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final raw    = await context.push(AppRoutes.map);
                  final result = raw is Map ? Map<String, dynamic>.from(raw) : null;

                  if (result != null) {
                    setState(() {
                      _lat = (result['lat'] as num?)?.toDouble();
                      _lng = (result['lng'] as num?)?.toDouble();

                      final address = result['address'] as String?;
                      _locCtrl.text = (address != null && address.isNotEmpty)
                          ? address
                          : '${_lat?.toStringAsFixed(4) ?? ''}, '
                          '${_lng?.toStringAsFixed(4) ?? ''}';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _locCtrl,
                    hint: 'Tap to pick location on map',
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: _lat != null ? AppColors.teal : AppColors.textSecondary,
                    ),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Location is required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Date ─────────────────────────────────
              _label('Incident Date *'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _dateCtrl,
                    hint: 'Select date',
                    prefixIcon: const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textSecondary),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Date is required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Note ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.teal.withOpacity(0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(children: [
                    Text(
                      'Your name will be auto-added when published.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.navyMid),
                    ),
                      const SizedBox(height: 7,),
                      Text(
                        'All items will expire after 2 months from posting date.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.navyMid),
                      ),
                    ])
                  ),
                ]),
              ),
              const SizedBox(height: 28),

              // ── Publish Button ───────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: itemState.isLoading ? null : (){if (_formKey.currentState!.validate()){
                     _submit();}},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child:_loading ?
                      const SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      :Text(widget.existingItem !=null ? 'Update' : 'Publish' ,
                    style:const TextStyle(fontSize: 16, fontWeight: FontWeight.w600) ,),

                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Type Switcher ─────────────────────────────────────
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

  Widget _typeTab(String value, String label) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }

  // ── Photo Picker ──────────────────────────────────────
  Widget _buildPhotoPicker() {
    final hasLocalImage = _pickedFile != null;
    final hasNetworkImage = !hasLocalImage && _networkImageUrl != null && _networkImageUrl!.isNotEmpty;
    final hasAnyImage = hasLocalImage || hasNetworkImage;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasAnyImage ? AppColors.teal : AppColors.border,
            width: hasAnyImage ? 1.5 : 1,
          ),
        ),
        child: hasAnyImage
            ? ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Show Local OR Network image
              if (hasLocalImage)
                Image.file(File(_pickedFile!.path), fit: BoxFit.cover)
              else if (hasNetworkImage)
                Image.network(_networkImageUrl!, fit: BoxFit.cover),

              // "Change" badge
              Positioned(
                bottom: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Change', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              )
            ],
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  color: AppColors.teal, size: 24),
            ),
            const SizedBox(height: 10),
            const Text('Tap to add photo',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Optional',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
  // ── Category Dropdown ─────────────────────────────────
  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary),
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _category = val);
          },
        ),
      ),
    );
  }

  // ── Text Field ────────────────────────────────────────
  Widget _buildTextField({
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
      style: const TextStyle(
          fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.5),
            fontSize: 14),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  // ── Label ─────────────────────────────────────────────
  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary));
  }
}