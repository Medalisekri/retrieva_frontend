import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  /// Reverse geocode coordinates to an address string
  /// Returns coordinates as fallback if geocoding fails
  static Future<String> getAddressFromCoordinates(LatLng point) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?lat=${point.latitude}&lon=${point.longitude}'
            '&format=json&accept-language=en',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'RetrievaApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final parts = <String>[];
        if (address['road'] != null) parts.add(address['road']);
        if (address['suburb'] != null) parts.add(address['suburb']);
        if (address['city'] != null) {
          parts.add(address['city']);
        } else if (address['town'] != null) {
          parts.add(address['town']);
        } else if (address['village'] != null) {
          parts.add(address['village']);
        }

        return parts.isNotEmpty
            ? parts.join(', ')
            : (data['display_name'] as String?) ?? _coordFallback(point);
      } else {
        return _coordFallback(point);
      }
    } catch (_) {
      return _coordFallback(point);
    }
  }

  static String _coordFallback(LatLng point) =>
      '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
}