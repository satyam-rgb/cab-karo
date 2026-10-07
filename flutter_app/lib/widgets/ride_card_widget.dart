import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../models/coordinate_model.dart';
import '../theme/app_theme.dart';
import '../services/provider_launcher_service.dart';

class RideCardWidget extends StatefulWidget {
  final Ride ride;
  final bool isSelected;
  final VoidCallback? onSelect;
  final LocationCoordinate? pickupCoord;
  final LocationCoordinate? dropCoord;
  final String? pickupAddress;
  final String? dropAddress;

  const RideCardWidget({
    super.key,
    required this.ride,
    this.isSelected = false,
    this.onSelect,
    this.pickupCoord,
    this.dropCoord,
    this.pickupAddress,
    this.dropAddress,
  });

  @override
  State<RideCardWidget> createState() => _RideCardWidgetState();
}

class _RideCardWidgetState extends State<RideCardWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final isUber = ride.provider.toLowerCase().contains('uber');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: widget.isSelected ? AppTheme.primary : AppTheme.border,
          width: widget.isSelected ? 2 : 0.8,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onSelect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Highlights & Badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUber ? Colors.black : const Color(0xFF009688),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ride.provider.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ride.category,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Transparent Demo / Fallback Data Notice Badge
                  if (ride.dataSource == 'demo_estimate')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 0.5),
                      ),
                      child: const Text(
                        'Demo Estimate',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Middle Row: Price, ETA, KaroScore
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${ride.fare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'ETA: ${ride.eta} min  •  Trip: ${ride.duration} min',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // KaroScore Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${ride.karoScore.toInt()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const Text(
                              '/100',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const Text(
                          'KaroScore',
                          style: TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Highlights Chips
              if (ride.highlights.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: ride.highlights.map((h) {
                    String label = h;
                    Color bg = const Color(0xFFEFF6FF);
                    Color fg = AppTheme.primary;
                    if (h == 'bestOverall') {
                      label = '🏆 Top Pick';
                      bg = const Color(0xFFEEF2FF);
                      fg = const Color(0xFF4F46E5);
                    } else if (h == 'cheapest') {
                      label = '💰 Lowest Fare';
                      bg = const Color(0xFFECFDF5);
                      fg = const Color(0xFF059669);
                    } else if (h == 'fastest') {
                      label = '⚡ Quickest Pickup';
                      bg = const Color(0xFFFFFBEB);
                      fg = const Color(0xFFD97706);
                    } else if (h == 'safest') {
                      label = '🛡️ High Safety';
                      bg = const Color(0xFFF0FDF4);
                      fg = const Color(0xFF16A34A);
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.border),
              const SizedBox(height: 8),

              // Actions Row: Expand details + Book Now Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18),
                    label: Text(
                      _expanded ? 'Hide Score Breakdown' : 'View Score Breakdown',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ProviderLauncherService.launchProvider(
                        provider: ride.provider,
                        category: ride.category,
                        pickupCoord: widget.pickupCoord,
                        dropCoord: widget.dropCoord,
                        pickupAddress: widget.pickupAddress,
                        dropAddress: widget.dropAddress,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUber ? Colors.black : AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(90, 36),
                    ),
                    child: Text(
                      'Book ${ride.provider}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              // Detailed Score Matrix Expander
              if (_expanded && ride.scores != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.explanation?.summary ?? 'Transparent multi-factor score analysis:',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      _scoreRow('Price (lower is better)', ride.scores!.price, ride.scoreWeights?.price ?? 0.25),
                      _scoreRow('ETA Arrival', ride.scores!.eta, ride.scoreWeights?.eta ?? 0.20),
                      _scoreRow('Trip Duration', ride.scores!.duration, ride.scoreWeights?.duration ?? 0.15),
                      _scoreRow('Safety Rating', ride.scores!.safety, ride.scoreWeights?.safety ?? 0.15),
                      _scoreRow('Comfort Level', ride.scores!.comfort, ride.scoreWeights?.comfort ?? 0.15),
                      _scoreRow('Reliability Record', ride.scores!.reliability, ride.scoreWeights?.reliability ?? 0.10),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreRow(String label, double score, double weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label (${(weight * 100).toInt()}%)',
            style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
          ),
          Text(
            '${score.toInt()}/100',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
