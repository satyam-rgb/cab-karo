import 'package:flutter/material.dart';

class DestinationExplorerScreen extends StatelessWidget {
  const DestinationExplorerScreen({super.key});

  static const List<Map<String, String>> _destinations = [
    {
      'name': 'Nagpur City',
      'subtitle': 'Explore popular places around Nagpur',
      'icon': '🏙️',
    },
    {
      'name': 'Airport',
      'subtitle': 'Plan a ride to or from the airport',
      'icon': '✈️',
    },
    {
      'name': 'Railway Station',
      'subtitle': 'Quick access to Nagpur railway station',
      'icon': '🚆',
    },
    {
      'name': 'Popular Places',
      'subtitle': 'Discover destinations for your next ride',
      'icon': '📍',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Destination Explorer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where do you want to go?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Choose a destination and use KaroCab to compare available rides.',
                    style: TextStyle(color: Colors.grey, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ..._destinations.map(
              (destination) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        destination['icon'] ?? '📍',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination['name'] ?? 'Destination',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destination['subtitle'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: enter your exact From and To locations on the home screen to compare current KaroCab estimates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
