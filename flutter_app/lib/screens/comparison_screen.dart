import 'package:flutter/material.dart';
import '../models/pricing_response_model.dart';
import '../theme/app_theme.dart';

class ComparisonScreen extends StatelessWidget {
  final PricingResponse pricing;
  final String fromAddress;
  final String toAddress;

  const ComparisonScreen({
    super.key,
    required this.pricing,
    required this.fromAddress,
    required this.toAddress,
  });

  @override
  Widget build(BuildContext context) {
    final rides = pricing.rides;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Side-by-Side Comparison'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$fromAddress → $toAddress', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('${pricing.distance} km  •  ${pricing.duration} min', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Comprehensive Matrix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            // Comparison Table
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                  columns: const [
                    DataColumn(label: Text('Ride', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Fare', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ETA', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Safety', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('KaroScore', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: rides.map((r) {
                    final isTop = pricing.recommendations.bestOverall == r.id;
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${r.provider} ${r.category}'),
                              if (isTop) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                              ]
                            ],
                          ),
                        ),
                        DataCell(Text('₹${r.fare.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text('${r.eta}m')),
                        DataCell(Text('${r.duration}m')),
                        DataCell(Text('${r.safety.toInt()}%')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isTop ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${r.karoScore.toInt()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isTop ? AppTheme.primary : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
