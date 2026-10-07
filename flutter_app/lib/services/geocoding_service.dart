import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coordinate_model.dart';
import 'location_search_service.dart';

class CityContext {
  final String name;
  final String state;
  final double lat;
  final double lon;
  final double radiusKm;

  const CityContext({
    required this.name,
    required this.state,
    required this.lat,
    required this.lon,
    required this.radiusKm,
  });
}

class SuggestionItem {
  final String displayName;
  final double latitude;
  final double longitude;
  final String city;

  const SuggestionItem({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.city,
  });
}

class GeocodingService {
  static final Map<String, LocationCoordinate> _cache = {};

  static const Map<String, CityContext> knownCities = {
    'nagpur': CityContext(name: 'Nagpur', state: 'Maharashtra', lat: 21.1458, lon: 79.0882, radiusKm: 45),
    'pune': CityContext(name: 'Pune', state: 'Maharashtra', lat: 18.5204, lon: 73.8567, radiusKm: 55),
    'mumbai': CityContext(name: 'Mumbai', state: 'Maharashtra', lat: 19.0760, lon: 72.8777, radiusKm: 65),
    'delhi': CityContext(name: 'Delhi', state: 'Delhi', lat: 28.6139, lon: 77.2090, radiusKm: 60),
    'jaipur': CityContext(name: 'Jaipur', state: 'Rajasthan', lat: 26.9124, lon: 75.7873, radiusKm: 50),
    'bengaluru': CityContext(name: 'Bengaluru', state: 'Karnataka', lat: 12.9716, lon: 77.5946, radiusKm: 55),
    'bangalore': CityContext(name: 'Bengaluru', state: 'Karnataka', lat: 12.9716, lon: 77.5946, radiusKm: 55),
    'hyderabad': CityContext(name: 'Hyderabad', state: 'Telangana', lat: 17.3850, lon: 78.4867, radiusKm: 55),
    'chennai': CityContext(name: 'Chennai', state: 'Tamil Nadu', lat: 13.0827, lon: 80.2707, radiusKm: 50),
    'kolkata': CityContext(name: 'Kolkata', state: 'West Bengal', lat: 22.5726, lon: 88.3639, radiusKm: 50),
    'ahmedabad': CityContext(name: 'Ahmedabad', state: 'Gujarat', lat: 23.0225, lon: 72.5714, radiusKm: 50),
    'indore': CityContext(name: 'Indore', state: 'Madhya Pradesh', lat: 22.7196, lon: 75.8577, radiusKm: 45),
    'bhopal': CityContext(name: 'Bhopal', state: 'Madhya Pradesh', lat: 23.2599, lon: 77.4126, radiusKm: 45),
  };

  static const Map<String, LocationCoordinate> fallbackLandmarks = {
    'nagpur railway station': LocationCoordinate(latitude: 21.1524, longitude: 79.0887),
    'itwari railway station': LocationCoordinate(latitude: 21.1583, longitude: 79.1171),
    'itwari': LocationCoordinate(latitude: 21.1583, longitude: 79.1171),
    'shantinagar': LocationCoordinate(latitude: 21.159094, longitude: 79.126273),
    'shantinagar nagpur': LocationCoordinate(latitude: 21.159094, longitude: 79.126273),
    'shantinagar marwadi': LocationCoordinate(latitude: 21.159094, longitude: 79.126273),
    'shantinagar marwadi nagpur': LocationCoordinate(latitude: 21.159094, longitude: 79.126273),
    'nagpur airport': LocationCoordinate(latitude: 21.0922, longitude: 79.0474),
    'sitabuldi': LocationCoordinate(latitude: 21.1458, longitude: 79.0882),
    'dharampeth': LocationCoordinate(latitude: 21.1415, longitude: 79.0611),
    'futala lake': LocationCoordinate(latitude: 21.1558, longitude: 79.0442),
    'deekshabhoomi': LocationCoordinate(latitude: 21.1278, longitude: 79.0682),
    'mg road nagpur': LocationCoordinate(latitude: 21.1466, longitude: 79.0832),
    'pune': LocationCoordinate(latitude: 18.5204, longitude: 73.8567),
    'pune railway station': LocationCoordinate(latitude: 18.5284, longitude: 73.8744),
    'shivaji nagar pune': LocationCoordinate(latitude: 18.5314, longitude: 73.8446),
    'mumbai': LocationCoordinate(latitude: 19.0760, longitude: 72.8777),
    'delhi': LocationCoordinate(latitude: 28.6139, longitude: 77.2090),
    'jaipur': LocationCoordinate(latitude: 26.9124, longitude: 75.7873),
    'bengaluru': LocationCoordinate(latitude: 12.9716, longitude: 77.5946),
    'hyderabad': LocationCoordinate(latitude: 17.3850, longitude: 78.4867),
  };

  static CityContext detectCityContext(String query) {
    final lower = query.toLowerCase();
    for (final entry in knownCities.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return knownCities['nagpur']!;
  }

  static List<String> generateProgressiveQueries(String rawQuery, CityContext city) {
    final clean = rawQuery.trim();
    final lower = clean.toLowerCase();
    final hasExplicitCity = lower.contains(city.name.toLowerCase());
    final citySuffix = hasExplicitCity ? '' : ', ${city.name}';
    final fullSuffix = hasExplicitCity ? ', India' : ', ${city.name}, ${city.state}, India';

    final stripped = clean
        .replaceAll(RegExp(r'(?:plot|no|house|flat|ward|block|room|shop|h\.no|p\.no)\s*[:#.]?\s*\w+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d{1,6}\b'), '')
        .replaceAll(RegExp(r',(\s*,)+'), ',')
        .replaceAll(RegExp(r'^[\s,]+|[\s,]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final parts = clean.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

    final queries = <String>[];
    // Attempt 1: Raw query with city suffix
    queries.add('$clean$citySuffix');

    // Attempt 2: Stripped numbers with city suffix
    if (stripped.isNotEmpty && stripped != clean) {
      queries.add('$stripped$citySuffix');
    }

    // Attempt 3: Primary locality / segment
    if (parts.length > 1) {
      final strippedPart = parts[0].replaceAll(RegExp(r'\b\d+\b'), '').trim();
      if (strippedPart.isNotEmpty) {
        queries.add('$strippedPart$citySuffix');
      }
    }

    // Attempt 4: Clean with full context
    queries.add('$clean$fullSuffix');
    if (stripped.isNotEmpty && stripped != clean) {
      queries.add('$stripped$fullSuffix');
    }

    queries.add(clean);
    return queries.toSet().toList();
  }

  static Future<LocationCoordinate?> geocode(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return null;

    final cacheKey = clean.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // Check location search service first
    final searchRes = await LocationSearchService.geocode(clean);
    if (searchRes != null) {
      _cache[cacheKey] = searchRes;
      return searchRes;
    }

    final city = detectCityContext(clean);
    final candidates = generateProgressiveQueries(clean, city);

    for (final candidate in candidates) {
      // 1. Try Nominatim OpenStreetMap
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(candidate)}&limit=1',
        );
        final res = await http.get(uri, headers: {
          'User-Agent': 'KaroCab-CrossPlatform/1.0',
        }).timeout(const Duration(milliseconds: 3500));

        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List<dynamic>;
          if (list.isNotEmpty) {
            final first = list[0] as Map<String, dynamic>;
            if (first['lat'] != null && first['lon'] != null) {
              final coord = LocationCoordinate(
                latitude: double.parse(first['lat'].toString()),
                longitude: double.parse(first['lon'].toString()),
              );
              _cache[cacheKey] = coord;
              return coord;
            }
          }
        }
      } catch (_) {
        // Continue to Photon
      }

      // 2. Try Photon Komoot API
      try {
        final photonUri = Uri.parse(
          'https://photon.komoot.io/api/?q=${Uri.encodeComponent(candidate)}&limit=1&lat=${city.lat}&lon=${city.lon}',
        );
        final res = await http.get(photonUri).timeout(const Duration(milliseconds: 3500));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final features = data['features'] as List<dynamic>?;
          if (features != null && features.isNotEmpty) {
            final geom = features[0]['geometry'] as Map<String, dynamic>?;
            final coords = geom?['coordinates'] as List<dynamic>?;
            if (coords != null && coords.length >= 2) {
              final coord = LocationCoordinate(
                latitude: (coords[1] as num).toDouble(),
                longitude: (coords[0] as num).toDouble(),
              );
              _cache[cacheKey] = coord;
              return coord;
            }
          }
        }
      } catch (_) {
        // Continue to next candidate
      }
    }

    // 3. Fallback to predefined landmarks if offline
    final cleanedLookup = clean
        .toLowerCase()
        .replaceAll(RegExp(r'(?:plot|no|house|flat|ward|block|room|shop)\s*[:#.]?\s*\w+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d{1,6}\b'), '')
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    for (final entry in fallbackLandmarks.entries) {
      if (cacheKey == entry.key ||
          cleanedLookup == entry.key ||
          cacheKey.contains(entry.key) ||
          entry.key.contains(cleanedLookup)) {
        _cache[cacheKey] = entry.value;
        return entry.value;
      }
    }

    return null;
  }

  static Future<List<SuggestionItem>> fetchSuggestions(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return [];

    final city = detectCityContext(clean);
    final results = <SuggestionItem>[];
    final seen = <String>{};

    try {
      final photonUri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent('$clean, ${city.name}')}&limit=5&lat=${city.lat}&lon=${city.lon}',
      );
      final res = await http.get(photonUri).timeout(const Duration(milliseconds: 3000));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;
        if (features != null) {
          for (final f in features) {
            final geom = f['geometry'] as Map<String, dynamic>?;
            final coords = geom?['coordinates'] as List<dynamic>?;
            final props = f['properties'] as Map<String, dynamic>? ?? {};
            if (coords != null && coords.length >= 2) {
              final lat = (coords[1] as num).toDouble();
              final lon = (coords[0] as num).toDouble();
              final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
              if (!seen.contains(key)) {
                seen.add(key);
                final name = props['name']?.toString() ?? clean;
                final disp = [name, props['street'], props['district'], props['city'] ?? city.name]
                    .where((s) => s != null && s.toString().isNotEmpty)
                    .join(', ');
                results.add(SuggestionItem(
                  displayName: disp,
                  latitude: lat,
                  longitude: lon,
                  city: props['city']?.toString() ?? city.name,
                ));
              }
            }
          }
        }
      }
    } catch (_) {}

    return results;
  }
}
