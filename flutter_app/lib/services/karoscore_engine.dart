import 'dart:math';
import '../models/ride_model.dart';

class KaroScoreEngine {
  /// Lower-is-better min-max normalization (Fare, ETA, Duration)
  /// Score = ((Max - Current) / (Max - Min)) * 100
  static double lowerIsBetterNormalized(double value, double minVal, double maxVal) {
    if (maxVal == minVal) return 100.0;
    final score = ((maxVal - value) / (maxVal - minVal)) * 100.0;
    return max(0.0, min(100.0, score));
  }

  /// Higher-is-better min-max normalization (Safety, Comfort, Reliability)
  /// Score = ((Current - Min) / (Max - Min)) * 100
  static double higherIsBetterNormalized(double value, double minVal, double maxVal) {
    if (maxVal == minVal) return 100.0;
    final score = ((value - minVal) / (maxVal - minVal)) * 100.0;
    return max(0.0, min(100.0, score));
  }

  /// Exact methodology weights specified for KaroCab
  static RideScoreWeights getWeightsForMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'budget':
        return const RideScoreWeights(
          price: 0.40,
          eta: 0.10,
          duration: 0.10,
          safety: 0.15,
          comfort: 0.10,
          reliability: 0.15,
        );
      case 'hurry':
        return const RideScoreWeights(
          price: 0.10,
          eta: 0.30,
          duration: 0.25,
          safety: 0.15,
          comfort: 0.10,
          reliability: 0.10,
        );
      case 'balanced':
      default:
        return const RideScoreWeights(
          price: 0.25,
          eta: 0.20,
          duration: 0.15,
          safety: 0.15,
          comfort: 0.15,
          reliability: 0.10,
        );
    }
  }

  /// Calculates KaroScores across a list of rides
  static List<Ride> calculateKaroScores(List<Ride> rides, {String mode = 'balanced'}) {
    if (rides.isEmpty) return [];

    final fares = rides.map((r) => r.fare).toList();
    final etas = rides.map((r) => r.eta.toDouble()).toList();
    final durations = rides.map((r) => r.duration.toDouble()).toList();
    final safeties = rides.map((r) => r.safety).toList();
    final comforts = rides.map((r) => r.comfort).toList();
    final reliabilities = rides.map((r) => r.reliability).toList();

    final minFare = fares.reduce(min);
    final maxFare = fares.reduce(max);

    final minEta = etas.reduce(min);
    final maxEta = etas.reduce(max);

    final minDuration = durations.reduce(min);
    final maxDuration = durations.reduce(max);

    final minSafety = safeties.reduce(min);
    final maxSafety = safeties.reduce(max);

    final minComfort = comforts.reduce(min);
    final maxComfort = comforts.reduce(max);

    final minReliability = reliabilities.reduce(min);
    final maxReliability = reliabilities.reduce(max);

    final weights = getWeightsForMode(mode);

    final scoredRides = rides.map((ride) {
      final priceScore = lowerIsBetterNormalized(ride.fare, minFare, maxFare);
      final etaScore = lowerIsBetterNormalized(ride.eta.toDouble(), minEta, maxEta);
      final durationScore = lowerIsBetterNormalized(ride.duration.toDouble(), minDuration, maxDuration);

      final safetyScore = higherIsBetterNormalized(ride.safety, minSafety, maxSafety);
      final comfortScore = higherIsBetterNormalized(ride.comfort, minComfort, maxComfort);
      final reliabilityScore = higherIsBetterNormalized(ride.reliability, minReliability, maxReliability);

      final karoScore = (priceScore * weights.price) +
          (etaScore * weights.eta) +
          (durationScore * weights.duration) +
          (safetyScore * weights.safety) +
          (comfortScore * weights.comfort) +
          (reliabilityScore * weights.reliability);

      final roundedKaro = double.parse(karoScore.toStringAsFixed(1));

      final scores = RideScores(
        price: double.parse(priceScore.toStringAsFixed(1)),
        eta: double.parse(etaScore.toStringAsFixed(1)),
        duration: double.parse(durationScore.toStringAsFixed(1)),
        safety: double.parse(safetyScore.toStringAsFixed(1)),
        comfort: double.parse(comfortScore.toStringAsFixed(1)),
        reliability: double.parse(reliabilityScore.toStringAsFixed(1)),
      );

      final explanation = _generateExplanation(ride, scores, weights, roundedKaro);

      return ride.copyWith(
        karoScore: roundedKaro,
        scores: scores,
        scoreWeights: weights,
        explanation: explanation,
      );
    }).toList();

    // Assign highlights
    return _assignHighlights(scoredRides);
  }

  static ScoreExplanation _generateExplanation(
    Ride ride,
    RideScores scores,
    RideScoreWeights weights,
    double karoScore,
  ) {
    final factors = {
      'price': ScoreExplanationFactor(
        name: 'Fare Economy',
        score: scores.price,
        weight: weights.price,
        contribution: double.parse(((scores.price * weights.price)).toStringAsFixed(1)),
      ),
      'eta': ScoreExplanationFactor(
        name: 'Pickup Speed',
        score: scores.eta,
        weight: weights.eta,
        contribution: double.parse(((scores.eta * weights.eta)).toStringAsFixed(1)),
      ),
      'duration': ScoreExplanationFactor(
        name: 'Trip Duration',
        score: scores.duration,
        weight: weights.duration,
        contribution: double.parse(((scores.duration * weights.duration)).toStringAsFixed(1)),
      ),
      'safety': ScoreExplanationFactor(
        name: 'Safety Rating',
        score: scores.safety,
        weight: weights.safety,
        contribution: double.parse(((scores.safety * weights.safety)).toStringAsFixed(1)),
      ),
      'comfort': ScoreExplanationFactor(
        name: 'Vehicle Comfort',
        score: scores.comfort,
        weight: weights.comfort,
        contribution: double.parse(((scores.comfort * weights.comfort)).toStringAsFixed(1)),
      ),
      'reliability': ScoreExplanationFactor(
        name: 'Driver Reliability',
        score: scores.reliability,
        weight: weights.reliability,
        contribution: double.parse(((scores.reliability * weights.reliability)).toStringAsFixed(1)),
      ),
    };

    String summary = 'Solid balanced choice.';
    if (karoScore >= 80) {
      summary = 'Top-tier recommendation with outstanding metrics.';
    } else if (karoScore >= 70) {
      summary = 'Reliable option with fair value.';
    }

    // Find highest contributing factor
    var strongestKey = 'price';
    var maxContribution = -1.0;
    factors.forEach((k, v) {
      if (v.contribution > maxContribution) {
        maxContribution = v.contribution;
        strongestKey = k;
      }
    });

    final strongest = factors[strongestKey]!;

    return ScoreExplanation(
      summary: summary,
      strongestFactor: strongest.name,
      strongestFactorScore: strongest.score,
      factors: factors,
    );
  }

  static List<Ride> _assignHighlights(List<Ride> rides) {
    if (rides.isEmpty) return rides;

    final sortedByScore = [...rides]..sort((a, b) => b.karoScore.compareTo(a.karoScore));
    final sortedByFare = [...rides]..sort((a, b) => a.fare.compareTo(b.fare));
    final sortedByEta = [...rides]..sort((a, b) => a.eta.compareTo(b.eta));
    final sortedBySafety = [...rides]..sort((a, b) => b.safety.compareTo(a.safety));

    final bestOverallId = sortedByScore.first.id;
    final cheapestId = sortedByFare.first.id;
    final fastestId = sortedByEta.first.id;
    final safestId = sortedBySafety.first.id;

    return rides.map((ride) {
      final highlights = <String>[];
      if (ride.id == bestOverallId) highlights.add('bestOverall');
      if (ride.id == cheapestId) highlights.add('cheapest');
      if (ride.id == fastestId) highlights.add('fastest');
      if (ride.id == safestId) highlights.add('safest');
      return ride.copyWith(highlights: highlights);
    }).toList();
  }
}
