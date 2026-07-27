import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/theme_ext.dart';

/// Read-only OpenStreetMap showing the rider's live position and the delivery
/// destination, auto-fitted to show both. Used on the order-tracking screen.
class TrackingMap extends StatelessWidget {
  const TrackingMap({
    super.key,
    required this.rider,
    this.destination,
    this.updatedAt,
  });

  final LatLng rider;
  final LatLng? destination;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final points = <LatLng>[rider, if (destination != null) destination!];
    final camera = points.length > 1
        ? CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(48),
            maxZoom: 16,
          )
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: rider,
                initialZoom: 14,
                initialCameraFit: camera,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.farmfresh.farmfresh',
                  maxZoom: 19,
                ),
                if (destination != null)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: [rider, destination!],
                      strokeWidth: 3,
                      color: c.green.withValues(alpha: 0.6),
                    ),
                  ]),
                MarkerLayer(markers: [
                  Marker(
                    point: rider,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.delivery_dining, color: c.green, size: 34),
                  ),
                  if (destination != null)
                    Marker(
                      point: destination!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 34),
                    ),
                ]),
              ],
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  updatedAt == null ? 'Live' : 'Updated ${_ago(updatedAt!)}',
                  style: TextStyle(fontSize: 11, color: c.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime t) {
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 60) return 'just now';
    final m = (s / 60).floor();
    if (m < 60) return '${m}m ago';
    return '${(m / 60).floor()}h ago';
  }
}
