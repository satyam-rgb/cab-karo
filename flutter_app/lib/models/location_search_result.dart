enum LocationPlaceType {
  address,
  locality,
  neighbourhood,
  road,
  school,
  college,
  hospital,
  clinic,
  institute,
  business,
  landmark,
  square,
  railwayStation,
  airport,
  postalArea,
  poi,
}

class LocationSearchResult {
  final String id;
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String type;
  final String? category;
  final String? locality;
  final String? city;
  final String? district;
  final String? state;
  final String? postalCode;
  final String source;
  final double confidence;

  const LocationSearchResult({
    required this.id,
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.category,
    this.locality,
    this.city,
    this.district,
    this.state,
    this.postalCode,
    required this.source,
    required this.confidence,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    return LocationSearchResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['name']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      type: json['type']?.toString() ?? 'poi',
      category: json['category']?.toString(),
      locality: json['locality']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postalCode']?.toString(),
      source: json['source']?.toString() ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.9,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'category': category,
      'locality': locality,
      'city': city,
      'district': district,
      'state': state,
      'postalCode': postalCode,
      'source': source,
      'confidence': confidence,
    };
  }
}
