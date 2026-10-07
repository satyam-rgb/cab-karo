import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/coordinate_model.dart';
import '../theme/app_theme.dart';

class KaroMapWidget extends StatefulWidget {
  final LocationCoordinate? origin;
  final LocationCoordinate? destination;
  final List<LocationCoordinate> routeCoordinates;
  final bool isLiveRoute;
  final String? notice;

  const KaroMapWidget({
    super.key,
    this.origin,
    this.destination,
    this.routeCoordinates = const [],
    this.isLiveRoute = true,
    this.notice,
  });

  @override
  State<KaroMapWidget> createState() => _KaroMapWidgetState();
}

class _KaroMapWidgetState extends State<KaroMapWidget> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant KaroMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.origin != null && widget.destination != null) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (widget.origin == null || widget.destination == null) return;
    final bounds = LatLngBounds(
      LatLng(widget.origin!.latitude, widget.origin!.longitude),
      LatLng(widget.destination!.latitude, widget.destination!.longitude),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final centerLat = widget.origin?.latitude ?? 21.1458;
    final centerLng = widget.origin?.longitude ?? 79.0882;

    final polylinePoints = widget.routeCoordinates
        .map((c) => LatLng(c.latitude, c.longitude))
        .toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(centerLat, centerLng),
            initialZoom: 13.0,
            onMapReady: _fitBounds,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.karocab.app',
            ),
            // Route Polyline
            if (polylinePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylinePoints,
                    strokeWidth: 4.5,
                    color: widget.isLiveRoute ? AppTheme.primary : Colors.grey.shade600,
                    pattern: widget.isLiveRoute
                        ? const StrokePattern.solid()
                        : const StrokePattern.dotted(),
                  ),
                ],
              ),
            // Markers
            MarkerLayer(
              markers: [
                if (widget.origin != null)
                  Marker(
                    point: LatLng(widget.origin!.latitude, widget.origin!.longitude),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.circle, size: 10, color: Colors.white),
                    ),
                  ),
                if (widget.destination != null)
                  Marker(
                    point: LatLng(widget.destination!.latitude, widget.destination!.longitude),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.flag, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Live vs Fallback Route Notice Badge
        if (!widget.isLiveRoute)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade600),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 15, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.notice ?? 'Live OSRM routing unavailable. Straight-line fallback displayed.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
