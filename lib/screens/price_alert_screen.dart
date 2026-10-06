import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PriceAlertScreen extends StatefulWidget {
  final List<dynamic> rides;
  final String from;
  final String to;
  final double? distance;
  final int? duration;

  const PriceAlertScreen({
    super.key,
    required this.rides,
    required this.from,
    required this.to,
    this.distance,
    this.duration,
  });

  @override
  State<PriceAlertScreen> createState() => _PriceAlertScreenState();
}

class _PriceAlertScreenState extends State<PriceAlertScreen> {
  int? _selectedIndex;
  late final TextEditingController _targetController;
  bool _saving = false;

  List<Map<String, dynamic>> get _validRides {
    return widget.rides
        .whereType<Map>()
        .map((ride) => Map<String, dynamic>.from(ride))
        .where((ride) => _fareOf(ride) != null)
        .toList();
  }

  double? _fareOf(Map<String, dynamic> ride) {
    final dynamic value = ride['fare'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController();
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _selectRide(int index) {
    final ride = _validRides[index];
    final fare = _fareOf(ride) ?? 0;

    setState(() {
      _selectedIndex = index;
      _targetController.text = fare.toStringAsFixed(2);
      _targetController.selection = TextSelection.fromPosition(
        TextPosition(offset: _targetController.text.length),
      );
    });
  }

  Future<void> _saveAlert() async {
    if (_saving) return;

    final int? index = _selectedIndex;
    if (index == null) {
      _showMessage('Please choose a ride first.');
      return;
    }

    final ride = _validRides[index];
    final double? currentFare = _fareOf(ride);
    final double? targetPrice =
        double.tryParse(_targetController.text.trim());

    if (currentFare == null) {
      _showMessage('Current fare is not available.');
      return;
    }

    if (targetPrice == null || targetPrice <= 0) {
      _showMessage('Please enter a valid target fare.');
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please log in before setting a price alert.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        <String, dynamic>{
          'priceAlert': <String, dynamic>{
            'status': 'active',
            'provider': ride['provider']?.toString() ?? '',
            'category': ride['category']?.toString() ?? '',
            'currentFare': currentFare,
            'targetPrice': targetPrice,
            'from': widget.from,
            'to': widget.to,
            'distance': widget.distance,
            'duration': widget.duration,
            'createdAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage('Failed to save price alert: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _rideName(Map<String, dynamic> ride) {
    final String provider = ride['provider']?.toString() ?? 'Unknown';
    final String category = ride['category']?.toString() ?? '';
    return '$provider $category'.trim();
  }

  IconData _rideIcon(Map<String, dynamic> ride) {
    final String category = ride['category']?.toString().toLowerCase() ?? '';
    return category.contains('auto')
        ? Icons.electric_rickshaw_rounded
        : Icons.local_taxi_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final rides = _validRides;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Price Alert',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: rides.isEmpty
          ? const Center(
              child: Text('No ride fare is available for a price alert.'),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Set a fare target',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.from} → ${widget.to}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose a ride',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    rides.length,
                    (index) {
                      final ride = rides[index];
                      final fare = _fareOf(ride) ?? 0;
                      final bool selected = _selectedIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _selectRide(index),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.blue.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _rideIcon(ride),
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _rideName(ride),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Current fare: ₹${fare.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: selected ? Colors.blue : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (_selectedIndex != null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Target fare',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter target fare',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The alert is stored for this selected ride and target.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveAlert,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.notifications_active_outlined,
                              ),
                        label: Text(
                          _saving ? 'Saving...' : 'Set Alert',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
