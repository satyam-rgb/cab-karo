import 'package:flutter/material.dart';
import '../models/price_alert_model.dart';
import '../models/ride_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class PriceAlertScreen extends StatefulWidget {
  final Ride? initialRide;
  final String fromAddress;
  final String toAddress;

  const PriceAlertScreen({
    super.key,
    this.initialRide,
    required this.fromAddress,
    required this.toAddress,
  });

  @override
  State<PriceAlertScreen> createState() => _PriceAlertScreenState();
}

class _PriceAlertScreenState extends State<PriceAlertScreen> {
  List<PriceAlert> _alerts = [];
  final TextEditingController _targetFareController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialRide != null) {
      final target = (widget.initialRide!.fare * 0.85).round();
      _targetFareController.text = target.toString();
    }
    _loadAlerts();
  }

  void _loadAlerts() async {
    final list = await StorageService.getPriceAlerts();
    if (mounted) setState(() { _alerts = list; _isLoading = false; });
  }

  void _createAlert() async {
    final target = double.tryParse(_targetFareController.text.trim());
    if (target == null || target <= 0) return;

    final newAlert = PriceAlert(
      id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
      status: 'active',
      provider: widget.initialRide?.provider ?? 'Uber & Ola',
      category: widget.initialRide?.category ?? 'Any Cab',
      currentFare: widget.initialRide?.fare ?? 200.0,
      targetPrice: target,
      from: widget.fromAddress,
      to: widget.toAddress,
      createdAt: DateTime.now().toIso8601String(),
    );

    await StorageService.savePriceAlert(newAlert);
    _loadAlerts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price alert created! You will be notified when fare drops.')),
      );
    }
  }

  void _deleteAlert(String id) async {
    await StorageService.deletePriceAlert(id);
    _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Drop Alerts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Price Alert',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Route: ${widget.fromAddress} → ${widget.toAddress}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          if (widget.initialRide != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Current ${widget.initialRide!.provider} ${widget.initialRide!.category} Fare: ₹${widget.initialRide!.fare.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _targetFareController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Notify me when fare is below (₹)',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _createAlert,
                              icon: const Icon(Icons.notifications_active_outlined),
                              label: const Text('Set Alert'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Active Alerts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_alerts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        children: const [
                          Icon(Icons.notifications_off_outlined, size: 40, color: AppTheme.textSecondary),
                          SizedBox(height: 8),
                          Text('No active price alerts', style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  else
                    ..._alerts.map((alert) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_down, color: AppTheme.primary),
                            ),
                            title: Text('Target: ₹${alert.targetPrice.toStringAsFixed(0)} (Current: ₹${alert.currentFare.toStringAsFixed(0)})'),
                            subtitle: Text('${alert.from} → ${alert.to}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
                              onPressed: () => _deleteAlert(alert.id),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
