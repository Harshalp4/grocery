import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';

/// OpenStreetMap view for the rider: their own position + the delivery
/// destination, auto-fitted with a straight route line between them.
class DeliveryMap extends StatelessWidget {
  const DeliveryMap({super.key, this.me, this.destination});

  final LatLng? me;
  final LatLng? destination;

  @override
  Widget build(BuildContext context) {
    final points = <LatLng>[
      if (me != null) me!,
      if (destination != null) destination!,
    ];
    if (points.isEmpty) {
      return _frame(
        context,
        const Center(child: Text('Waiting for GPS…')),
      );
    }
    final fit = points.length > 1
        ? CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(44),
            maxZoom: 16,
          )
        : null;

    return _frame(
      context,
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
          if (me != null && destination != null)
            PolylineLayer(polylines: [
              Polyline(
                points: [me!, destination!],
                strokeWidth: 3,
                color: riderBlue.withValues(alpha: 0.6),
              ),
            ]),
          MarkerLayer(markers: [
            if (me != null)
              Marker(
                point: me!,
                width: 40,
                height: 40,
                child: const Icon(Icons.navigation, color: riderBlue, size: 32),
              ),
            if (destination != null)
              Marker(
                point: destination!,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, color: riderRed, size: 34),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _frame(BuildContext context, Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 200, child: child),
      );
}
