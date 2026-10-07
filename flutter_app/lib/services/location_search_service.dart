import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/coordinate_model.dart';
import '../models/location_search_result.dart';

class LocationSearchService {
  static final Map<String, List<LocationSearchResult>> _cache = {};

  // Verified Local Gazetteer for Nagpur & Maharashtra
  static const List<Map<String, dynamic>> localGazetteer = [
    {
      'id': 'nagpur-vinayak-deshmukh',
      'name': 'Vinayak Deshmukh High School',
      'displayName': 'Vinayak Deshmukh High School, Shantinagar, Nagpur',
      'aliases': [
        'vinayak lodishmukh',
        'vinayak deshmukh',
        'vinayak lodishmukh school',
        'vinayak deshmukh vidyalaya',
        'vinayak high school'
      ],
      'type': 'school',
      'category': 'High School',
      'locality': 'Shantinagar',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'postalCode': '440002',
      'latitude': 21.1594,
      'longitude': 79.1258,
      'source': 'local_gazetteer',
      'confidence': 0.98,
    },
    {
      'id': 'nagpur-mudliha-square',
      'name': 'Mudliha Square',
      'displayName': 'Mudliha Square, Shantinagar, Nagpur',
      'aliases': [
        'mudliha sq',
        'mudliha chowk',
        'mudliar square',
        'mudliya chowk'
      ],
      'type': 'square',
      'category': 'Square / Chowk',
      'locality': 'Shantinagar',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'postalCode': '440002',
      'latitude': 21.1588,
      'longitude': 79.1245,
      'source': 'local_gazetteer',
      'confidence': 0.96,
    },
    {
      'id': 'nagpur-shantinagar-marwadi',
      'name': 'Shantinagar Marwadi',
      'displayName': 'Shantinagar Marwadi, Nagpur',
      'aliases': [
        'marwarivadi',
        'marwadi',
        'marwadi shantinagar',
        'marwadi mohalla',
        'shantinagar marwadi 4002'
      ],
      'type': 'neighbourhood',
      'category': 'Neighbourhood',
      'locality': 'Shantinagar',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'postalCode': '440002',
      'latitude': 21.1591,
      'longitude': 79.1263,
      'source': 'local_gazetteer',
      'confidence': 0.97,
    },
    {
      'id': 'nagpur-tulsi-nagar',
      'name': 'Tulsi Nagar',
      'displayName': 'Tulsi Nagar, Shantinagar, Nagpur',
      'aliases': ['tulsinagar', 'tulsi nagar nagpur', 'tulsi nagar shantinagar'],
      'type': 'locality',
      'category': 'Locality',
      'locality': 'Shantinagar',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'postalCode': '440002',
      'latitude': 21.1610,
      'longitude': 79.1285,
      'source': 'local_gazetteer',
      'confidence': 0.95,
    },
    {
      'id': 'nagpur-shantinagar',
      'name': 'Shantinagar',
      'displayName': 'Shantinagar, Itwari, Nagpur',
      'aliases': ['shanti nagar', 'shantinagar nagpur', 'shantinagr'],
      'type': 'locality',
      'category': 'Locality',
      'locality': 'Itwari',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'postalCode': '440002',
      'latitude': 21.1591,
      'longitude': 79.1263,
      'source': 'local_gazetteer',
      'confidence': 0.98,
    },
    {
      'id': 'nagpur-uphc-shantinagar',
      'name': 'UPHC Shantinagar Health Clinic',
      'displayName': 'UPHC Shantinagar Health Clinic, NH53, Itwari, Nagpur',
      'aliases': [
        'shantinagar hospital',
        'shantinagar clinic',
        'hospital near shantinagar',
        'uphc shantinagar'
      ],
      'type': 'hospital',
      'category': 'Hospital / Clinic',
      'locality': 'Shantinagar',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'postalCode': '440002',
      'latitude': 21.159094,
      'longitude': 79.126273,
      'source': 'local_gazetteer',
      'confidence': 0.96,
    },
    {
      'id': 'nagpur-itwari-railway-station',
      'name': 'Itwari Railway Station',
      'displayName': 'Itwari Railway Station, Itwari, Nagpur',
      'aliases': ['itwari', 'itwari station', 'itwari junction'],
      'type': 'railway_station',
      'category': 'Railway Station',
      'locality': 'Itwari',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'postalCode': '440002',
      'latitude': 21.1583,
      'longitude': 79.1171,
      'source': 'local_gazetteer',
      'confidence': 0.99,
    },
    {
      'id': 'nagpur-railway-station',
      'name': 'Nagpur Railway Station',
      'displayName': 'Nagpur Railway Station Junction, Sitabuldi, Nagpur',
      'aliases': ['nagpur junction', 'nagpur central', 'nagpur rly stn'],
      'type': 'railway_station',
      'category': 'Railway Station',
      'locality': 'Sitabuldi',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'postalCode': '440001',
      'latitude': 21.1524,
      'longitude': 79.0887,
      'source': 'local_gazetteer',
      'confidence': 0.99,
    },
    {
      'id': 'nagpur-airport',
      'name': 'Dr. Babasaheb Ambedkar International Airport',
      'displayName': 'Dr. Babasaheb Ambedkar International Airport, Sonegaon, Nagpur',
      'aliases': ['nagpur airport', 'sonegaon airport'],
      'type': 'airport',
      'category': 'Airport',
      'locality': 'Sonegaon',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'postalCode': '440005',
      'latitude': 21.0922,
      'longitude': 79.0474,
      'source': 'local_gazetteer',
      'confidence': 0.99,
    },
    {
      'id': 'nagpur-mg-road',
      'name': 'Mahatma Gandhi Road',
      'displayName': 'Mahatma Gandhi Road (MG Road), Sitabuldi, Nagpur',
      'aliases': ['mg road', 'mg road nagpur', 'm.g. road'],
      'type': 'road',
      'category': 'Road',
      'locality': 'Sitabuldi',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'postalCode': '440001',
      'latitude': 21.1466,
      'longitude': 79.0832,
      'source': 'local_gazetteer',
      'confidence': 0.95,
    },
  ];

  // PIN Code Database
  static const Map<String, Map<String, dynamic>> pinCodeDb = {
    '440001': {
      'name': '440001 — Civil Lines / Sadar / Sitabuldi',
      'locality': 'Civil Lines, Sadar',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'lat': 21.1530,
      'lon': 79.0750,
    },
    '440002': {
      'name': '440002 — Shantinagar / Itwari / Gandhibagh',
      'locality': 'Shantinagar, Itwari',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'lat': 21.1591,
      'lon': 79.1263,
    },
    '440010': {
      'name': '440010 — Dharampeth / Ramdaspeth / Bajaj Nagar',
      'locality': 'Dharampeth, Ramdaspeth',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'lat': 21.1415,
      'lon': 79.0611,
    },
    '440012': {
      'name': '440012 — Sitabuldi / Cotton Market',
      'locality': 'Sitabuldi Central',
      'city': 'Nagpur',
      'state': 'Maharashtra',
      'lat': 21.1466,
      'lon': 79.0832,
    },
  };

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static String _expandTypos(String query) {
    var s = query.trim();
    s = s.replaceAll(RegExp(r'\blodishmukh\b', caseSensitive: false), 'Deshmukh');
    s = s.replaceAll(RegExp(r'\bshantinagr\b', caseSensitive: false), 'Shantinagar');
    s = s.replaceAll(RegExp(r'\bmarwarivadi\b', caseSensitive: false), 'Marwadi');
    s = s.replaceAll(RegExp(r'\bmudliha\s*(?:sq|sq\.|chowk)\b', caseSensitive: false), 'Mudliha Square');
    s = s.replaceAll(RegExp(r'\bitwri\b', caseSensitive: false), 'Itwari');
    s = s.replaceAll(RegExp(r'\bvadi\b', caseSensitive: false), 'wadi');
    return s;
  }

  static Future<List<LocationSearchResult>> search(
    String rawQuery, {
    LocationCoordinate? mapCenter,
    int limit = 7,
  }) async {
    final clean = rawQuery.trim();
    if (clean.length < 2) return [];

    final cacheKey = clean.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final corrected = _expandTypos(clean);
    final results = <LocationSearchResult>[];
    final center = mapCenter ?? const LocationCoordinate(latitude: 21.1458, longitude: 79.0882);

    // 1. PIN code check
    final pinMatch = RegExp(r'\b([1-9][0-9]{5})\b').firstMatch(clean);
    if (pinMatch != null) {
      final pin = pinMatch.group(1)!;
      final postal = pinCodeDb[pin];
      if (postal != null) {
        results.add(LocationSearchResult(
          id: 'pin-$pin',
          name: postal['name'] as String,
          displayName: '${postal['name']}, ${postal['city']}',
          latitude: (postal['lat'] as num).toDouble(),
          longitude: (postal['lon'] as num).toDouble(),
          type: 'postal_area',
          category: 'Postal Area / PIN Code',
          locality: postal['locality'] as String?,
          city: postal['city'] as String?,
          state: postal['state'] as String?,
          postalCode: pin,
          source: 'postal_service',
          confidence: 0.98,
        ));
      }
    }

    // 2. Local gazetteer check
    final lowerClean = clean.toLowerCase();
    final lowerCorrected = corrected.toLowerCase();
    for (final place in localGazetteer) {
      final pName = (place['name'] as String).toLowerCase();
      final aliases = (place['aliases'] as List<dynamic>).map((a) => a.toString().toLowerCase()).toList();

      if (pName.contains(lowerClean) ||
          pName.contains(lowerCorrected) ||
          aliases.any((a) => a.contains(lowerClean) || a.contains(lowerCorrected))) {
        results.add(LocationSearchResult.fromJson(place));
      }
    }

    // 3. Photon Komoot API with map center bias
    try {
      final photonUri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent('$corrected, Nagpur')}&limit=5&lat=${center.latitude}&lon=${center.longitude}',
      );
      final res = await http.get(photonUri).timeout(const Duration(milliseconds: 3200));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;
        if (features != null) {
          for (final f in features) {
            final geom = f['geometry'] as Map<String, dynamic>?;
            final coords = geom?['coordinates'] as List<dynamic>?;
            final p = f['properties'] as Map<String, dynamic>? ?? {};
            if (coords != null && coords.length >= 2) {
              final lat = (coords[1] as num).toDouble();
              final lon = (coords[0] as num).toDouble();
              final name = p['name']?.toString() ?? corrected;
              final disp = [name, p['street'], p['district'], p['city'] ?? 'Nagpur'].where((s) => s != null && s.isNotEmpty).join(', ');

              results.add(LocationSearchResult(
                id: 'pho-${p['osm_id'] ?? math.Random().nextInt(99999)}',
                name: name,
                displayName: disp,
                latitude: lat,
                longitude: lon,
                type: p['osm_value']?.toString() ?? 'poi',
                category: p['osm_value']?.toString(),
                locality: p['district']?.toString() ?? p['street']?.toString(),
                city: p['city']?.toString() ?? 'Nagpur',
                state: p['state']?.toString() ?? 'Maharashtra',
                postalCode: p['postcode']?.toString(),
                source: 'photon',
                confidence: 0.90,
              ));
            }
          }
        }
      }
    } catch (_) {}

    // 4. Nominatim fallback
    if (results.length < 3) {
      try {
        final nomUri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent('$corrected, Nagpur, India')}&limit=4&addressdetails=1',
        );
        final res = await http.get(nomUri, headers: {
          'User-Agent': 'KaroCab-Mobile-Search/2.0',
        }).timeout(const Duration(milliseconds: 3500));

        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List<dynamic>;
          for (final item in list) {
            final map = item as Map<String, dynamic>;
            final lat = double.tryParse(map['lat']?.toString() ?? '');
            final lon = double.tryParse(map['lon']?.toString() ?? '');
            if (lat != null && lon != null) {
              final addr = map['address'] as Map<String, dynamic>? ?? {};
              results.add(LocationSearchResult(
                id: 'nom-${map['osm_id'] ?? math.Random().nextInt(99999)}',
                name: map['display_name']?.toString().split(',')[0] ?? corrected,
                displayName: map['display_name']?.toString() ?? corrected,
                latitude: lat,
                longitude: lon,
                type: map['type']?.toString() ?? 'locality',
                category: map['type']?.toString(),
                locality: addr['suburb']?.toString() ?? addr['neighbourhood']?.toString(),
                city: addr['city']?.toString() ?? 'Nagpur',
                state: addr['state']?.toString() ?? 'Maharashtra',
                postalCode: addr['postcode']?.toString(),
                source: 'nominatim',
                confidence: 0.92,
              ));
            }
          }
        }
      } catch (_) {}
    }

    // Deduplicate
    final deduped = <LocationSearchResult>[];
    for (final item in results) {
      final exists = deduped.any((ex) {
        final dist = _haversineKm(item.latitude, item.longitude, ex.latitude, ex.longitude);
        return dist < 0.25 || (dist < 1.0 && item.name.toLowerCase() == ex.name.toLowerCase());
      });
      if (!exists) {
        deduped.add(item);
      }
    }

    final finalResults = deduped.take(limit).toList();
    _cache[cacheKey] = finalResults;
    return finalResults;
  }

  static Future<LocationCoordinate?> geocode(String query, {LocationCoordinate? mapCenter}) async {
    final list = await search(query, mapCenter: mapCenter, limit: 3);
    if (list.isNotEmpty) {
      return LocationCoordinate(latitude: list.first.latitude, longitude: list.first.longitude);
    }
    return null;
  }
}
