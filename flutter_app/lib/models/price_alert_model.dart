class PriceAlert {
  final String id;
  final String status; // 'active' | 'triggered' | 'dismissed'
  final String provider;
  final String category;
  final double currentFare;
  final double targetPrice;
  final String from;
  final String to;
  final double? distance;
  final int? duration;
  final String createdAt;

  const PriceAlert({
    required this.id,
    this.status = 'active',
    required this.provider,
    required this.category,
    required this.currentFare,
    required this.targetPrice,
    required this.from,
    required this.to,
    this.distance,
    this.duration,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'provider': provider,
    'category': category,
    'currentFare': currentFare,
    'targetPrice': targetPrice,
    'from': from,
    'to': to,
    'distance': distance,
    'duration': duration,
    'createdAt': createdAt,
  };

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'active',
      provider: json['provider'] as String,
      category: json['category'] as String,
      currentFare: (json['currentFare'] as num).toDouble(),
      targetPrice: (json['targetPrice'] as num).toDouble(),
      from: json['from'] as String,
      to: json['to'] as String,
      distance: (json['distance'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String,
    );
  }
}
