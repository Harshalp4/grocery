import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';

/// OpenStreetMap view for the rider: their own position + the delivery
/// destination, with a road-following route line (via OSRM) and a button to
/// open turn-by-turn navigation in Google Maps.
class DeliveryMap extends StatefulWidget {
  const DeliveryMap({super.key, this.me, this.destination});

  final LatLng? me;
  final LatLng? destination;

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  static const _distance = Distance();

  List<LatLng>? _route; // road-following path from OSRM (null = not loaded yet)
  LatLng? _routedFrom;
  LatLng? _routedTo;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _maybeFetchRoute();
  }

  @override
  void didUpdateWidget(covariant DeliveryMap old) {
    super.didUpdateWidget(old);
    _maybeFetchRoute();
  }

  void _maybeFetchRoute() {
    final me = widget.me, dest = widget.destination;
    if (me == null || dest == null || _fetching) return;
    // Refetch only when the destination changes or the rider has moved a
    // meaningful distance — so live GPS ticks don't hammer the routing server.
    final destMoved = _routedTo == null || _distance(_routedTo!, dest) > 30;
    final meMoved = _routedFrom == null || _distance(_routedFrom!, me) > 120;
    if (_route != null && !destMoved && !meMoved) return;
    _fetchRoute(me, dest);
  }

  Future<void> _fetchRoute(LatLng me, LatLng dest) async {
    _fetching = true;
    _routedFrom = me;
    _routedTo = dest;
    try {
      // OSRM public demo server (no key). For heavy production traffic, host
      // your own OSRM / use a paid routing API.
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${me.longitude},${me.latitude};${dest.longitude},${dest.latitude}'
          '?overview=full&geometries=geojson');
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = j['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final coords = (routes.first['geometry']['coordinates'] as List)
              .map((c) => LatLng(
                  (c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (mounted && coords.length > 1) {
            setState(() => _route = coords);
          }
        }
      }
    } catch (_) {
      // Network/routing failure — keep the straight-line fallback.
    } finally {
      _fetching = false;
    }
  }

  Future<void> _openInGoogleMaps() async {
    final dest = widget.destination;
    if (dest == null) return;
    // api=1 dir link → opens the Google Maps app (origin defaults to the
    // device's live location) for turn-by-turn navigation.
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1'
        '&destination=${dest.latitude},${dest.longitude}&travelmode=driving');
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me, dest = widget.destination;
    final points = <LatLng>[
      if (me != null) me,
      if (dest != null) dest,
    ];
    if (points.isEmpty) {
      return _frame(context, const Center(child: Text('Waiting for GPS…')));
    }
    final fit = points.length > 1
        ? CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(44),
            maxZoom: 16,
          )
        : null;
    // Prefer the road-following route; fall back to a straight line until it loads.
    final line = _route ??
        (me != null && dest != null ? <LatLng>[me, dest] : const <LatLng>[]);

    return _frame(
      context,
      Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: points.first,
              initialZoom: 15,
              initialCameraFit: fit,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.farmfresh.partner',
                maxZoom: 19,
              ),
              if (line.length > 1)
                PolylineLayer(polylines: [
                  Polyline(
                    points: line,
                    strokeWidth: 4,
                    color: riderBlue.withValues(alpha: 0.7),
                  ),
                ]),
              MarkerLayer(markers: [
                if (me != null)
                  Marker(
                    point: me,
                    width: 40,
                    height: 40,
                    child:
                        const Icon(Icons.navigation, color: riderBlue, size: 32),
                  ),
                if (dest != null)
                  Marker(
                    point: dest,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: riderRed, size: 34),
                  ),
              ]),
            ],
          ),
          if (dest != null)
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _openInGoogleMaps,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions, color: riderBlue, size: 20),
                        SizedBox(width: 6),
                        Text('Navigate',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: riderBlue)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _frame(BuildContext context, Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 200, child: child),
      );
}
