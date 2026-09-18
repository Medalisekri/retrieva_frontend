import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../core/helper/location_helper.dart';
import '../core/theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _picked = const LatLng(34.0, 9.5);
  String _addressLabel = '';
  bool   _geocoding    = false;   // ← shows loading while fetching address

  @override
  void initState() {
    super.initState();
    _goToMyLocation();
  }

  Future<void> _goToMyLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final loc = LatLng(pos.latitude, pos.longitude);


      setState(() {
        _picked = loc;
        _geocoding = true;
        _addressLabel = '';
      });
      _mapController.move(loc, 14);

      final address = await GeocodingService.getAddressFromCoordinates(loc);
      if (mounted) {
        setState(() {
          _addressLabel = address;
          _geocoding = false;
        });
      }
    } catch (_) {}
  }



  String _coordFallback(LatLng point) =>
      '${point.latitude.toStringAsFixed(4)}, '
          '${point.longitude.toStringAsFixed(4)}';

  void _confirm() {
    Navigator.pop<Map<String, dynamic>>(context, {
      'lat':     _picked.latitude,
      'lng':     _picked.longitude,
      'address': _addressLabel.isNotEmpty
          ? _addressLabel
          : _coordFallback(_picked),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Pick Location',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('Confirm',
                style: TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _picked,
              initialZoom: 6.5,
              onTap: (_, point) async {
                setState(() {
                  _picked = point;
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
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.retrieva.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _picked,
                    width: 48, height: 48,
                    child: const Icon(Icons.location_pin,
                        color: Color(0xFFE24B4A), size: 42),
                  ),
                ],
              ),
            ],
          ),

          // ── Instruction banner ────────────────────────
          Positioned(
            top: 12, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.touch_app_outlined,
                    color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Tap anywhere on the map to place pin',
                    style: TextStyle(
                        color: Colors.white, fontSize: 12)),
              ]),
            ),
          ),

          // ── Address label ─────────────────────────────
          Positioned(
            bottom: 80, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                // ✅ Show spinner while geocoding
                _geocoding
                    ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.teal))
                    : const Icon(Icons.location_on_outlined,
                    color: AppColors.teal, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _geocoding
                        ? 'Getting address...'
                        : _addressLabel.isNotEmpty
                        ? _addressLabel
                        : 'Tap the map to select a location',
                    style: TextStyle(
                        fontSize: 13,
                        color: _geocoding || _addressLabel.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary),
                  ),
                ),
              ]),
            ),
          ),

          // ── My location FAB ───────────────────────────
          Positioned(
            bottom: 20, right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location_rounded,
                  color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }
}