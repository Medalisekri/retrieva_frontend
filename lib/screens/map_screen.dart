
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:retrieva/core/router/app_routes.dart';
import 'package:retrieva/providers/item_provider.dart';
import '../core/helper/location_helper.dart';
import '../core/theme/app_theme.dart';
import '../models/item_model.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(34.0, 9.5); // Tunis default
  LatLng? _userLocation;
  Item? _selected;
  String _filter         = 'all'; // 'all' | 'lost' | 'found'
  String _addressLabel = '';
  bool   _geocoding    = false;

  Future<void> _loadAddress(Item item) async {
    if (item.lat != null && item.long != null) {
      final point = LatLng(item.lat, item.long);

      // Show loading state
      setState(() {
        _geocoding = true;
        _addressLabel = '';
      });

      // Get address from service
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

   Future.microtask(() {
      ref.read(itemNotifier.notifier).loadItems();
    });
    // In initState or after _item loads
  _getCurrentLocation();
  }

Future<void> _getCurrentLocation() async {
    try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    final loc = LatLng(pos.latitude, pos.longitude);
    setState(() {
    _userLocation = loc;
    });
}catch (e){}

    }

  @override
  Widget build(BuildContext context) {
    final itemState = ref.watch(itemNotifier);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Map View',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),

      ),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 6.5,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.retrieva.app',
              ),

              Builder(
                builder: (context) {
                  final mapCamera = MapCamera.of(context);
                  final visibleBounds = mapCamera.visibleBounds;

                  final visibleItems = itemState.value?.where((item) {
                    final passesFilter =
                        _filter == 'all' ||
                            (_filter == 'lost' && item.isLost) ||
                            (_filter == 'found' && !item.isLost);

                    final isOnScreen = visibleBounds.contains(
                      LatLng(item.lat, item.long),
                    );

                    return passesFilter && isOnScreen;
                  }).toList() ?? [];

                  return MarkerLayer(
                    markers: [
                      if (_userLocation != null)
                        Marker(
                          point: _userLocation!,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),

                      ...visibleItems.map(
                            (item) => Marker(
                          point: LatLng(item.lat, item.long),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selected = item);
                              _loadAddress(item);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: item.isLost
                                    ? const Color(0xFFE24B4A)
                                    : AppColors.teal,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                item.isLost
                                    ? Icons.search_off_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // ── Filter chips (top) ─────────────────────────
          Positioned(
            top: 12, left: 16, right: 16,
            child: Row(children: [
              _filterChip('all',   'All'),
              const SizedBox(width: 8),
              _filterChip('lost',  'Lost'),
              const SizedBox(width: 8),
              _filterChip('found', 'Found'),
            ]),
          ),

          // ── Loading ────────────────────────────────────
          if (itemState.isLoading)
            const Center(
                child: CircularProgressIndicator(color: AppColors.teal)),

          // ── Selected item card (bottom) ────────────────
          if (_selected != null)
            Positioned(
              bottom: 20, left: 16, right: 16,
              child: _buildItemCard(_selected!),
            ),

          // ── My location FAB ────────────────────────────
          Positioned(
            bottom: _selected != null ? 140 : 20,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 14);
                }
              },
              child: const Icon(Icons.my_location_rounded,
                  color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chip ───────────────────────────────────────
  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }

  // ── Selected item card ────────────────────────────────
  Widget _buildItemCard(Item item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        // Image or icon
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: item.isLost
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFE1F5EE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: item.imgUrl?.isNotEmpty == true
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(item.imgUrl ?? '', fit: BoxFit.cover),
          )
              : Icon(
            item.isLost
                ? Icons.search_off_rounded
                : Icons.check_circle_outline_rounded,
            color: item.isLost
                ? const Color(0xFF854F0B)
                : const Color(0xFF0F6E56),
            size: 26,
          ),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(item.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.isLost
                        ? const Color(0xFFFCEBEB)
                        : const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.isLost ? 'Lost' : 'Found',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.isLost
                            ? const Color(0xFFA32D2D)
                            : const Color(0xFF0F6E56)),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Row(
                  children: [
                const SizedBox(width: 3),
                Expanded(child:
                Row(
                  children: [
                    _geocoding
                        ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondary,
                      ),
                    )
                        : const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        _geocoding
                            ? 'Getting address...'
                            : _addressLabel.isNotEmpty
                            ? _addressLabel
                            : 'No address available',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: _geocoding
                              ? AppColors.textSecondary.withOpacity(0.5)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                )
                )]),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.detail,
                      extra: item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Details',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}