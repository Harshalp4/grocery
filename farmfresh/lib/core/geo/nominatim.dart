import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reverse-geocoding via OpenStreetMap's free Nominatim service (no API key).
///
/// Nominatim's usage policy requires an identifying User-Agent and at most ~1
/// request/second, which comfortably covers a human dragging a map pin.
class NominatimResult {
  const NominatimResult({this.line, this.area, this.city, this.pincode, this.display});
  final String? line;
  final String? area;
  final String? city;
  final String? pincode;
  final String? display;
}

abstract class Nominatim {
  static const _base = 'https://nominatim.openstreetmap.org';
  static const _headers = {
    'User-Agent': 'FarmFresh/0.1 (grocery delivery app)',
    'Accept': 'application/json',
  };

  /// Turn a lat/lng into address parts. Returns an empty result on any failure
  /// so the caller can still keep the coordinates.
  static Future<NominatimResult> reverse(double lat, double lng) async {
    try {
      final uri = Uri.parse(
          '$_base/reverse?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1&zoom=18');
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const NominatimResult();
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final a = (json['address'] as Map<String, dynamic>?) ?? const {};

      String? pick(List<String> keys) {
        for (final k in keys) {
          final v = a[k];
          if (v is String && v.isNotEmpty) return v;
        }
        return null;
      }

      // Build a house/road "line" from the most specific parts available.
      final house = pick(['house_number', 'building', 'amenity', 'shop']);
      final road = pick(['road', 'pedestrian', 'neighbourhood']);
      final line = [house, road].where((e) => e != null && e.isNotEmpty).join(' ');

      return NominatimResult(
        line: line.isEmpty ? null : line,
        area: pick(['suburb', 'neighbourhood', 'village', 'town', 'city_district']),
        city: pick(['city', 'town', 'municipality', 'state_district']),
        pincode: pick(['postcode']),
        display: json['display_name'] as String?,
      );
    } catch (_) {
      return const NominatimResult();
    }
  }
}
