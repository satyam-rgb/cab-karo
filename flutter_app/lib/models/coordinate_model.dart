class LocationCoordinate {
  final double latitude;
  final double longitude;

  const LocationCoordinate({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory LocationCoordinate.fromJson(Map<String, dynamic> json) {
    return LocationCoordinate(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  @override
  String toString() => '($latitude, $longitude)';
}
