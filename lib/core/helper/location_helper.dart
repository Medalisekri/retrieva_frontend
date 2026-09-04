import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';

Future<String> getAddressFromLatLong(double? lat, double? long) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat!, long!);

    if (placemarks.isEmpty) return 'Unknown location';

    final place = placemarks.first;

    // Build a readable address string
    final parts = [
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
    ].where((p) => p != null && p.isNotEmpty);

    return parts.join(', ');
  } catch (e) {
    debugPrint('Geocoding error: $e');
    return 'Location unavailable';
  }
}