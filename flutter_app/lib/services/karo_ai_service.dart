import '../models/pricing_response_model.dart';
import '../models/ride_model.dart';

class KaroAiService {
  static String respond({
    required String query,
    required PricingResponse? context,
    required String fromAddress,
    required String toAddress,
  }) {
    final q = query.toLowerCase().trim();

    if (context == null || context.rides.isEmpty) {
      return 'Please enter your pickup and destination on the home screen to calculate real route estimates first!';
    }

    final rides = context.rides;

    if (q.contains('cheapest') || q.contains('lowest fare') || q.contains('budget')) {
      final sortedByFare = [...rides]..sort((a, b) => a.fare.compareTo(b.fare));
      final cheapest = sortedByFare.first;
      final second = sortedByFare.length > 1 ? sortedByFare[1] : null;
      final savings = second != null ? (second.fare - cheapest.fare).toStringAsFixed(2) : '0';

      return '💰 **Cheapest Ride:**\n\n**${cheapest.provider} ${cheapest.category}** at estimated ₹${cheapest.fare.toStringAsFixed(2)} (ETA: ${cheapest.eta}m, KaroScore: ${cheapest.karoScore}/100).\n\nIt saves you ₹$savings compared to ${second?.provider ?? 'other options'}.';
    }

    if (q.contains('fastest') || q.contains('quickest') || q.contains('hurry') || q.contains('eta')) {
      final sortedByEta = [...rides]..sort((a, b) => a.eta.compareTo(b.eta));
      final fastest = sortedByEta.first;

      return '⚡ **Fastest Arrival:**\n\n**${fastest.provider} ${fastest.category}** is closest with pickup in **${fastest.eta} minutes** (Fare: ₹${fastest.fare.toStringAsFixed(2)}, Duration: ${fastest.duration}m).';
    }

    if (q.contains('which ride should i take') || q.contains('recommend') || q.contains('best')) {
      final sortedByScore = [...rides]..sort((a, b) => b.karoScore.compareTo(a.karoScore));
      final best = sortedByScore.first;

      return '🏆 **KaroScore Top Recommendation:**\n\n**${best.provider} ${best.category}** achieves the highest overall KaroScore of **${best.karoScore}/100**.\n\nSummary: ${best.explanation?.summary ?? 'Balanced value across price, speed, and safety.'}';
    }

    if (q.contains('worth') || q.contains('price') || q.contains('fair')) {
      return '📊 **Fare Evaluation:**\n\nFor this **${context.distance} km** trip, standard rates range from ₹${rides.map((r) => r.fare).reduce((a, b) => a < b ? a : b).toStringAsFixed(0)} to ₹${rides.map((r) => r.fare).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}.\n\nAll estimates are transparently benchmarked based on distance and duration.';
    }

    // Default overview
    final bestId = context.recommendations.bestOverall;
    final best = rides.firstWhere((r) => r.id == bestId, orElse: () => rides.first);
    return '👋 I am **KaroAI**, your trip mobility advisor.\n\nFor your **${context.distance} km** ride from *$fromAddress* to *$toAddress*, top recommendation is **${best.provider} ${best.category}** (₹${best.fare.toStringAsFixed(2)}, KaroScore ${best.karoScore}/100).\n\nFeel free to ask which ride is fastest or cheapest!';
  }
}
