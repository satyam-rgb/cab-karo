import 'ride_model.dart';

class SmartRecommendations {
  final String? bestOverall;
  final String? bestBudget;
  final String? cheapest;
  final String? fastest;
  final String? safest;
  final String? budgetButNotSlowest;
  final String? balanced;
  final Map<String, String>? explanations;

  const SmartRecommendations({
    this.bestOverall,
    this.bestBudget,
    this.cheapest,
    this.fastest,
    this.safest,
    this.budgetButNotSlowest,
    this.balanced,
    this.explanations,
  });

  Map<String, dynamic> toJson() => {
    'bestOverall': bestOverall,
    'bestBudget': bestBudget,
    'cheapest': cheapest,
    'fastest': fastest,
    'safest': safest,
    'budgetButNotSlowest': budgetButNotSlowest,
    'balanced': balanced,
    'explanations': explanations,
  };

  factory SmartRecommendations.fromJson(Map<String, dynamic> json) {
    return SmartRecommendations(
      bestOverall: json['bestOverall'] as String?,
      bestBudget: json['bestBudget'] as String?,
      cheapest: json['cheapest'] as String?,
      fastest: json['fastest'] as String?,
      safest: json['safest'] as String?,
      budgetButNotSlowest: json['budgetButNotSlowest'] as String?,
      balanced: json['balanced'] as String?,
      explanations: (json['explanations'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
    );
  }
}

class PricingResponse {
  final String source;
  final String dataSource; // 'real_api' | 'demo_estimate'
  final String pricingNotice;
  final bool isLiveRoute;
  final String routeSource; // 'osrm_live' | 'routing_fallback'
  final double distance;
  final int duration;
  final List<Ride> rides;
  final SmartRecommendations recommendations;
  final String scoreMode; // 'budget' | 'hurry' | 'balanced'

  const PricingResponse({
    required this.source,
    this.dataSource = 'demo_estimate',
    this.pricingNotice = 'Simulated fare estimate benchmark (Live provider APIs not connected)',
    this.isLiveRoute = true,
    this.routeSource = 'osrm_live',
    required this.distance,
    required this.duration,
    required this.rides,
    required this.recommendations,
    this.scoreMode = 'balanced',
  });

  Map<String, dynamic> toJson() => {
    'source': source,
    'dataSource': dataSource,
    'pricingNotice': pricingNotice,
    'isLiveRoute': isLiveRoute,
    'routeSource': routeSource,
    'distance': distance,
    'duration': duration,
    'rides': rides.map((r) => r.toJson()).toList(),
    'recommendations': recommendations.toJson(),
    'scoreMode': scoreMode,
  };

  factory PricingResponse.fromJson(Map<String, dynamic> json) {
    return PricingResponse(
      source: json['source'] as String? ?? 'local_engine',
      dataSource: json['dataSource'] as String? ?? 'demo_estimate',
      pricingNotice: json['pricingNotice'] as String? ?? '',
      isLiveRoute: json['isLiveRoute'] as bool? ?? true,
      routeSource: json['routeSource'] as String? ?? 'osrm_live',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      rides: (json['rides'] as List<dynamic>?)
              ?.map((item) => Ride.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: json['recommendations'] != null
          ? SmartRecommendations.fromJson(json['recommendations'])
          : const SmartRecommendations(),
      scoreMode: json['scoreMode'] as String? ?? 'balanced',
    );
  }
}
