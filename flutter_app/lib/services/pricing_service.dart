import '../models/ride_model.dart';
import '../models/pricing_response_model.dart';
import 'karoscore_engine.dart';

class PricingService {
  /// Base pricing rates for cab and auto categories
  static double _calculateFare({
    required double baseFare,
    required double perKm,
    required double distanceKm,
    required double perMin,
    required int durationMin,
    double surge = 1.0,
  }) {
    final fare = (baseFare + (distanceKm * perKm) + (durationMin * perMin)) * surge;
    return double.parse(fare.toStringAsFixed(2));
  }

  static PricingResponse generateEstimates({
    required double distanceKm,
    required int durationMin,
    String mode = 'balanced',
    bool isLiveRoute = true,
    String routeSource = 'osrm_live',
  }) {
    // Pricing matrices modeled accurately on Indian market rates (Nagpur / Metro tiers)
    final uberAutoFare = _calculateFare(
      baseFare: 30.0,
      perKm: 12.0,
      distanceKm: distanceKm,
      perMin: 1.2,
      durationMin: durationMin + 2,
    );

    final olaAutoFare = _calculateFare(
      baseFare: 28.0,
      perKm: 12.5,
      distanceKm: distanceKm,
      perMin: 1.1,
      durationMin: durationMin + 2,
    );

    final uberMiniFare = _calculateFare(
      baseFare: 45.0,
      perKm: 15.0,
      distanceKm: distanceKm,
      perMin: 1.8,
      durationMin: durationMin,
    );

    final olaMiniFare = _calculateFare(
      baseFare: 48.0,
      perKm: 14.5,
      distanceKm: distanceKm,
      perMin: 1.9,
      durationMin: durationMin + 1,
    );

    final uberSedanFare = _calculateFare(
      baseFare: 65.0,
      perKm: 18.5,
      distanceKm: distanceKm,
      perMin: 2.2,
      durationMin: durationMin,
    );

    final olaSedanFare = _calculateFare(
      baseFare: 60.0,
      perKm: 19.0,
      distanceKm: distanceKm,
      perMin: 2.3,
      durationMin: durationMin + 1,
    );

    final uberXLFare = _calculateFare(
      baseFare: 90.0,
      perKm: 23.0,
      distanceKm: distanceKm,
      perMin: 3.0,
      durationMin: durationMin,
    );

    final olaXLFare = _calculateFare(
      baseFare: 95.0,
      perKm: 22.5,
      distanceKm: distanceKm,
      perMin: 3.1,
      durationMin: durationMin + 1,
    );

    final rawRides = <Ride>[
      Ride(
        id: 'uberAuto',
        provider: 'Uber',
        category: 'Auto',
        vehicleCategory: 'Auto',
        capacity: 3,
        fare: uberAutoFare,
        eta: 4,
        duration: durationMin + 2,
        comfort: 62.0,
        reliability: 84.0,
        safety: 82.0,
        karoScore: 0.0,
        dataSource: 'demo_estimate',
      ),
      Ride(
        id: 'olaAuto',
        provider: 'Ola',
        category: 'Auto',
        vehicleCategory: 'Auto',
        capacity: 3,
        fare: olaAutoFare,
        eta: 5,
        duration: durationMin + 2,
        comfort: 60.0,
        reliability: 82.0,
        safety: 80.0,
        karoScore: 0.0,
        dataSource: 'demo_estimate',
      ),
      Ride(
        id: 'uberMini',
        provider: 'Uber',
        category: 'Go (Mini)',
        vehicleCategory: 'Mini',
        capacity: 4,
        fare: uberMiniFare,
        eta: 3,
        duration: durationMin,
        comfort: 78.0,
        reliability: 88.0,
        safety: 86.0,
        karoScore: 0.0,
        dataSource: 'demo_estimate',
      ),
      Ride(
        id: 'olaMini',
        provider: 'Ola',
        category: 'Mini',
        vehicleCategory: 'Mini',
        capacity: 4,
        fare: olaMiniFare,
        eta: 6,
        duration: durationMin + 1,
        comfort: 76.0,
        reliability: 86.0,
        safety: 85.0,
        karoScore: 0.0,
        dataSource: 'demo_estimate',
      ),
      Ride(
        id: 'uberSedan',
        provider: 'Uber',
        category: 'Premier (Sedan)',
        vehicleCategory: 'Sedan',
        capacity: 4,
        fare: uberSedanFare,
        eta: 5,
        duration: durationMin,
        comfort: 92.0,
        reliability: 91.0,
        safety: 93.0,
        karoScore: 0.0,
        dataSource: 'demo_estimate',
      ),
      Ride(
        id: 'olaSedan',
        provider: 'Ola',
        category: 'Prime Sedan',
        vehicleCategory: 'Sedan',
        capacity: 4,
        fare: olaSedanFare,
        eta: 7,
        duration: durationMin + 1,
        comfort: 90.0,
        reliability: 89.0,
        safety: 91.0,
        karoScore: 0.0,
        dataSource: 'demo_estimate',
      ),
      Ride(
        id: 'uberXL',
        provider: 'Uber',
        category: 'XL (SUV)',
        vehicleCategory: 'XL',
        capacity: 6,
        fare: uberXLFare,
        eta: 6,
        duration: durationMin,
        comfort: 95.0,
        reliability: 93.0,
        safety: 95.0,
        karoScore: 0.0,
        dataSource: 'demo_estimate',
      ),
      Ride(
        id: 'olaXL',
        provider: 'Ola',
        category: 'Prime SUV (XL)',
        vehicleCategory: 'XL',
        capacity: 6,
        fare: olaXLFare,
        eta: 8,
        duration: durationMin + 1,
        comfort: 94.0,
        reliability: 91.0,
        safety: 94.0,
        karoScore: 0.0,
        dataSource: 'demo_estimate',
      ),
    ];

    final scoredRides = KaroScoreEngine.calculateKaroScores(rawRides, mode: mode);

    final sortedByScore = [...scoredRides]..sort((a, b) => b.karoScore.compareTo(a.karoScore));
    final sortedByFare = [...scoredRides]..sort((a, b) => a.fare.compareTo(b.fare));
    final sortedByEta = [...scoredRides]..sort((a, b) => a.eta.compareTo(b.eta));
    final sortedBySafety = [...scoredRides]..sort((a, b) => b.safety.compareTo(a.safety));

    final bestOverall = sortedByScore.first;
    final cheapest = sortedByFare.first;
    final fastest = sortedByEta.first;
    final safest = sortedBySafety.first;

    final recommendations = SmartRecommendations(
      bestOverall: bestOverall.id,
      bestBudget: cheapest.id,
      cheapest: cheapest.id,
      fastest: fastest.id,
      safest: safest.id,
      explanations: {
        'bestOverall': '${bestOverall.provider} ${bestOverall.category} achieves highest KaroScore (${bestOverall.karoScore}/100)',
        'cheapest': '${cheapest.provider} ${cheapest.category} is the most economical at ₹${cheapest.fare.toStringAsFixed(2)}',
        'fastest': '${fastest.provider} ${fastest.category} arrives earliest in ${fastest.eta} minutes',
        'safest': '${safest.provider} ${safest.category} has the highest safety rating (${safest.safety.toInt()}/100)',
      },
    );

    return PricingResponse(
      source: 'local_engine',
      dataSource: 'demo_estimate',
      pricingNotice: 'Simulated fare estimate benchmark (Live provider APIs not connected)',
      isLiveRoute: isLiveRoute,
      routeSource: routeSource,
      distance: distanceKm,
      duration: durationMin,
      rides: scoredRides,
      recommendations: recommendations,
      scoreMode: mode,
    );
  }
}
