import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/nominatim.dart';
import '../../../core/theme/theme_ext.dart';

/// What the picker hands back: the chosen coordinates plus the reverse-geocoded
/// address parts (so the form can prefill line/area/city/pincode).
class PickedLocation {
  const PickedLocation({required this.lat, required this.lng, this.address});
  final double lat;
  final double lng;
  final NominatimResult? address;
}

/// Full-screen OpenStreetMap picker. A pin stays fixed at the centre; the user
/// drags the map under it, and we reverse-geocode the centre after they stop.
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, this.initial});

  /// Where to open the map. Falls back to central Navi Mumbai.
  final LatLng? initial;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  static const _fallback = LatLng(19.0330, 73.0297); // Vashi, Navi Mumbai

  final _map = MapController();
  LatLng _center = _fallback;
  NominatimResult? _resolved;
  bool _resolving = false;
  bool _locating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? _fallback;
    // Resolve the initial centre once the first frame is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve(_center));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _map.dispose();
    super.dispose();
  }

  Future<void> _resolve(LatLng at) async {
    setState(() => _resolving = true);
    final r = await Nominatim.reverse(at.latitude, at.longitude);
    if (!mounted) return;
    setState(() {
      _resolved = r;
      _resolving = false;
    });
  }

  void _onMoved(MapCamera cam, bool hasGesture) {
    _center = cam.center;
    if (!hasGesture) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () => _resolve(_center));
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _toast('Location permission denied');
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast('Turn on location services');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      _map.move(here, 16);
      _center = here;
      await _resolve(here);
    } catch (_) {
      _toast('Could not get your location');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Pin your location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: _onMoved,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.farmfresh.farmfresh',
                maxZoom: 19,
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          // Fixed centre pin (sits slightly above centre so the tip marks it).
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_on, size: 44, color: c.green),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 150,
            child: FloatingActionButton.small(
              heroTag: 'locate',
              backgroundColor: c.surface,
              foregroundColor: c.green,
              onPressed: _locating ? null : _locateMe,
              child: _locating
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
            ),
          ),
          // Bottom sheet: resolved address + confirm.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery location',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: c.muted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 18, color: c.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _resolving
                              ? 'Finding address…'
                              : (_resolved?.display ?? 'Move the map to pick a spot'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        PickedLocation(
                          lat: _center.latitude,
                          lng: _center.longitude,
                          address: _resolved,
                        ),
                      ),
                      child: const Text('Confirm location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
