import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/coordinate_model.dart';

class RouteResult {
  final double distanceKm;
  final int durationMinutes;
  final List<LocationCoordinate> coordinates;
  final bool isLiveRoute;
  final String routeSource; // 'osrm_live' | 'routing_fallback'
  final String? notice;

  const RouteResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.coordinates,
    required this.isLiveRoute,
    required this.routeSource,
    this.notice,
  });
}

class RoutingService {
  /// Fetches actual driving route from OSRM
  static Future<RouteResult> fetchRoute(
    LocationCoordinate origin,
    LocationCoordinate destination,
  ) async {
    final latDiff = (origin.latitude - destination.latitude).abs();
    final lonDiff = (origin.longitude - destination.longitude).abs();

    if (latDiff < 0.0003 && lonDiff < 0.0003) {
      throw Exception('Pickup and destination locations are virtually identical.');
    }

    // Attempt live OSRM public routing API
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=polyline',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' && data['routes'] != null) {
          final routes = data['routes'] as List<dynamic>;
          if (routes.isNotEmpty) {
            final route = routes[0] as Map<String, dynamic>;
            final rawDistKm = (route['distance'] as num).toDouble() / 1000.0;
            final distanceKm = max(0.5, double.parse(rawDistKm.toStringAsFixed(2)));
            final durationMinutes = max(2, ((route['duration'] as num).toDouble() / 60.0).round());
            final polyline = route['geometry'] as String;
            final coordinates = decodePolyline(polyline);

            if (coordinates.length > 1) {
              return RouteResult(
                distanceKm: distanceKm,
                durationMinutes: durationMinutes,
                coordinates: coordinates,
                isLiveRoute: true,
                routeSource: 'osrm_live',
              );
            }
          }
        }
      }
    } catch (_) {
      // Routing service unreachable - use explicit fallback state
    }

    // Explicit fallback: Great-circle / Haversine distance with straight line path
    final dist = _calculateHaversineDistance(origin, destination);
    final roadDist = max(0.8, double.parse((dist * 1.35).toStringAsFixed(2)));
    final roadDuration = max(3, ((roadDist / 32.0) * 60.0).round());

    return RouteResult(
      distanceKm: roadDist,
      durationMinutes: roadDuration,
      coordinates: [origin, destination],
      isLiveRoute: false,
      routeSource: 'routing_fallback',
      notice: 'Live OSRM routing service was unavailable. Displaying straight-line fallback.',
    );
  }

  static double _calculateHaversineDistance(
    LocationCoordinate origin,
    LocationCoordinate destination,
  ) {
    const r = 6371.0; // Earth radius in km
    final dLat = (destination.latitude - origin.latitude) * (pi / 180.0);
    final dLon = (destination.longitude - origin.longitude) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(origin.latitude * (pi / 180.0)) *
            cos(destination.latitude * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Decodes Google-encoded polyline string into list of LocationCoordinates
  static List<LocationCoordinate> decodePolyline(String encoded) {
    final List<LocationCoordinate> poly = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LocationCoordinate(
        latitude: lat / 1e5,
        longitude: lng / 1e5,
      ));
    }
    return poly;
  }
}
