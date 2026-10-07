import 'package:flutter/material.dart';
import '../models/coordinate_model.dart';
import '../models/pricing_response_model.dart';
import '../models/ride_model.dart';
import '../services/geocoding_service.dart';
import '../services/routing_service.dart';
import '../services/pricing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/karo_map_widget.dart';
import '../widgets/ride_card_widget.dart';
import '../widgets/category_filter_widget.dart';
import '../widgets/mode_selector_widget.dart';
import 'karo_ai_screen.dart';
import 'karo_safe_screen.dart';
import 'price_alert_screen.dart';
import 'destination_explorer_screen.dart';
import 'profile_screen.dart';
import 'comparison_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreen({super.key, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _fromController = TextEditingController(text: 'Nagpur Railway Station');
  final TextEditingController _toController = TextEditingController(text: 'Nagpur Airport');

  LocationCoordinate? _originCoord = const LocationCoordinate(latitude: 21.1524, longitude: 79.0887);
  LocationCoordinate? _destCoord = const LocationCoordinate(latitude: 21.0922, longitude: 79.0474);
  List<LocationCoordinate> _routeCoords = [];
  bool _isLiveRoute = true;
  String? _routeNotice;

  String _totalDistance = '8.45 km';
  String _totalDuration = '22 minutes';
  String? _errorMessage;

  bool _isLoadingRoute = false;
  PricingResponse? _pricingData;
  String _activeMode = 'balanced';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _calculateRouteAndPrices();
  }

  Future<void> _calculateRouteAndPrices() async {
    final fromText = _fromController.text.trim();
    final toText = _toController.text.trim();

    if (fromText.isEmpty || toText.isEmpty) {
      setState(() => _errorMessage = 'Please enter both pickup and destination locations.');
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _errorMessage = null;
      _routeCoords = [];
    });

    try {
      // 1. Geocode Pickup & Destination
      final origin = await GeocodingService.geocode(fromText);
      final dest = await GeocodingService.geocode(toText);

      if (origin == null || dest == null) {
        throw Exception('Could not find one or both locations. Please check the spelling.');
      }

      // 2. Fetch Driving Route from OSRM
      final routeRes = await RoutingService.fetchRoute(origin, dest);

      // 3. Generate Pricing & KaroScores
      final pricing = PricingService.generateEstimates(
        distanceKm: routeRes.distanceKm,
        durationMin: routeRes.durationMinutes,
        mode: _activeMode,
        isLiveRoute: routeRes.isLiveRoute,
        routeSource: routeRes.routeSource,
      );

      if (mounted) {
        setState(() {
          _originCoord = origin;
          _destCoord = dest;
          _routeCoords = routeRes.coordinates;
          _isLiveRoute = routeRes.isLiveRoute;
          _routeNotice = routeRes.notice;
          _totalDistance = '${routeRes.distanceKm.toStringAsFixed(2)} km';
          _totalDuration = '${routeRes.durationMinutes} min';
          _pricingData = pricing;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _totalDistance = '--';
          _totalDuration = '--';
          _pricingData = null;
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _swapLocations() {
    final temp = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = temp;
    _calculateRouteAndPrices();
  }

  void _onModeChanged(String newMode) {
    setState(() => _activeMode = newMode);
    if (_pricingData != null) {
      setState(() {
        _pricingData = PricingService.generateEstimates(
          distanceKm: _pricingData!.distance,
          durationMin: _pricingData!.duration,
          mode: newMode,
          isLiveRoute: _pricingData!.isLiveRoute,
          routeSource: _pricingData!.routeSource,
        );
      });
    }
  }

  List<Ride> _getFilteredRides() {
    if (_pricingData == null) return [];
    if (_selectedCategory == 'all') return _pricingData!.rides;
    return _pricingData!.rides.where((r) {
      return r.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          r.vehicleCategory.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rides = _getFilteredRides();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_taxi, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('KaroCab', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'Destination Explorer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DestinationExplorerScreen(
                    onSelectDestination: (dest) {
                      _toController.text = dest;
                      _calculateRouteAndPrices();
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppTheme.accentRed),
            tooltip: 'KaroSafe SOS',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KaroSafeScreen(currentCoord: _originCoord),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(onLogout: widget.onLogout),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Input Search Box Card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.8)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      children: const [
                        Icon(Icons.circle, size: 12, color: AppTheme.accentGreen),
                        SizedBox(height: 18),
                        Icon(Icons.square, size: 10, color: AppTheme.accentRed),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: _fromController,
                            decoration: const InputDecoration(
                              hintText: 'Enter Pickup Location',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _calculateRouteAndPrices(),
                          ),
                          const Divider(height: 8, color: AppTheme.border),
                          TextField(
                            controller: _toController,
                            decoration: const InputDecoration(
                              hintText: 'Enter Destination',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _calculateRouteAndPrices(),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_vert, color: AppTheme.primary),
                      onPressed: _swapLocations,
                    ),
                    IconButton(
                      icon: _isLoadingRoute
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search, color: AppTheme.primary),
                      onPressed: _calculateRouteAndPrices,
                    ),
                  ],
                ),

                // Error Banner
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.accentRed),
                    ),
                  ),

                // Route summary strip
                if (_pricingData != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Route: $_totalDistance  •  $_totalDuration',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ComparisonScreen(
                                  pricing: _pricingData!,
                                  fromAddress: _fromController.text,
                                  toAddress: _toController.text,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.compare, size: 14),
                          label: const Text('Compare All', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Scrollable content area: Map + Filters + Rides
          Expanded(
            child: ListView(
              children: [
                // Map container
                SizedBox(
                  height: 200,
                  child: KaroMapWidget(
                    origin: _originCoord,
                    destination: _destCoord,
                    routeCoordinates: _routeCoords,
                    isLiveRoute: _isLiveRoute,
                    notice: _routeNotice,
                  ),
                ),

                // Mode Selector Bar (Budget / Hurry / Balanced)
                ModeSelectorWidget(
                  activeMode: _activeMode,
                  onSelectMode: _onModeChanged,
                ),

                // Vehicle Category Chips
                CategoryFilterWidget(
                  selectedCategory: _selectedCategory,
                  onSelect: (cat) => setState(() => _selectedCategory = cat),
                ),

                const SizedBox(height: 8),

                // Rides List
                if (rides.isEmpty && !_isLoadingRoute)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: const Text('No rides available for this category.'),
                  )
                else
                  ...rides.map((ride) => RideCardWidget(
                        ride: ride,
                        pickupCoord: _originCoord,
                        dropCoord: _destCoord,
                        pickupAddress: _fromController.text,
                        dropAddress: _toController.text,
                      )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KaroAiScreen(
                        pricingContext: _pricingData,
                        fromAddress: _fromController.text,
                        toAddress: _toController.text,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Ask KaroAI'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PriceAlertScreen(
                        initialRide: _pricingData?.rides.isNotEmpty == true ? _pricingData!.rides.first : null,
                        fromAddress: _fromController.text,
                        toAddress: _toController.text,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none, size: 18),
                label: const Text('Price Alert'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
