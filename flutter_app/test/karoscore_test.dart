import 'package:flutter_test/flutter_test.dart';
import 'package:karocab/models/ride_model.dart';
import 'package:karocab/services/karoscore_engine.dart';

void main() {
  group('KaroScore Weighting Methodology Tests', () {
    test('Verify exact documented weights for all modes', () {
      final budget = KaroScoreEngine.getWeightsForMode('budget');
      expect(budget.price, equals(0.40));
      expect(budget.eta, equals(0.10));
      expect(budget.duration, equals(0.10));
      expect(budget.safety, equals(0.15));
      expect(budget.comfort, equals(0.10));
      expect(budget.reliability, equals(0.15));
      expect(budget.price + budget.eta + budget.duration + budget.safety + budget.comfort + budget.reliability,
          closeTo(1.0, 0.0001));

      final hurry = KaroScoreEngine.getWeightsForMode('hurry');
      expect(hurry.price, equals(0.10));
      expect(hurry.eta, equals(0.30));
      expect(hurry.duration, equals(0.25));
      expect(hurry.safety, equals(0.15));
      expect(hurry.comfort, equals(0.10));
      expect(hurry.reliability, equals(0.10));
      expect(hurry.price + hurry.eta + hurry.duration + hurry.safety + hurry.comfort + hurry.reliability,
          closeTo(1.0, 0.0001));

      final balanced = KaroScoreEngine.getWeightsForMode('balanced');
      expect(balanced.price, equals(0.25));
      expect(balanced.eta, equals(0.20));
      expect(balanced.duration, equals(0.15));
      expect(balanced.safety, equals(0.15));
      expect(balanced.comfort, equals(0.15));
      expect(balanced.reliability, equals(0.10));
      expect(balanced.price + balanced.eta + balanced.duration + balanced.safety + balanced.comfort + balanced.reliability,
          closeTo(1.0, 0.0001));
    });

    test('Verify Min-Max Normalization formulas', () {
      // Lower is better: Min gets 100, Max gets 0
      expect(KaroScoreEngine.lowerIsBetterNormalized(100, 100, 200), equals(100.0));
      expect(KaroScoreEngine.lowerIsBetterNormalized(200, 100, 200), equals(0.0));
      expect(KaroScoreEngine.lowerIsBetterNormalized(150, 100, 200), equals(50.0));

      // Higher is better: Min gets 0, Max gets 100
      expect(KaroScoreEngine.higherIsBetterNormalized(80, 80, 100), equals(0.0));
      expect(KaroScoreEngine.higherIsBetterNormalized(100, 80, 100), equals(100.0));
      expect(KaroScoreEngine.higherIsBetterNormalized(90, 80, 100), equals(50.0));

      // Equal min-max safeguard: returns 100
      expect(KaroScoreEngine.lowerIsBetterNormalized(150, 150, 150), equals(100.0));
      expect(KaroScoreEngine.higherIsBetterNormalized(90, 90, 90), equals(100.0));
    });

    test('Verify KaroScore calculations across sample rides', () {
      final sampleRides = [
        const Ride(
          id: 'uberAuto',
          provider: 'Uber',
          category: 'Auto',
          fare: 100.0,
          eta: 5,
          duration: 20,
          comfort: 60.0,
          reliability: 80.0,
          safety: 85.0,
          karoScore: 0.0,
        ),
        const Ride(
          id: 'uberMini',
          provider: 'Uber',
          category: 'Mini',
          fare: 180.0,
          eta: 3,
          duration: 18,
          comfort: 80.0,
          reliability: 90.0,
          safety: 90.0,
          karoScore: 0.0,
        ),
      ];

      final scored = KaroScoreEngine.calculateKaroScores(sampleRides, mode: 'balanced');
      expect(scored.length, equals(2));
      expect(scored[0].karoScore, greaterThan(0.0));
      expect(scored[1].karoScore, greaterThan(0.0));
      expect(scored[0].scores, isNotNull);
      expect(scored[0].explanation, isNotNull);
    });
  });
}
