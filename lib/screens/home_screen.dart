import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:karocab/utils/sizeconst.dart';
import 'package:karocab/widgets/button.dart';

import 'chat_screen.dart';
import 'price_alert_screen.dart';
import 'destination_explorer_screen.dart';
import '../utils/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // PRICING DATA
  // ============================================================

  Map<String, dynamic> _pricingData = {};

  // ============================================================
  // DEFAULT CAMERA POSITION
  // ============================================================

  static const CameraPosition _defaultCameraPosition =
      CameraPosition(
    target: LatLng(21.1458, 79.0882),
    zoom: 11.5,
    tilt: 60.0,
  );

  // ============================================================
  // GOOGLE MAP CONTROLLER
  // ============================================================

  GoogleMapController? _googleMapController;

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  double? latitude;
  double? longitude;

  CameraPosition? _initialCameraPosition;

  // ============================================================
  // MARKERS
  // ============================================================

  Map<MarkerId, Marker> markers = {};

  // ============================================================
  // POLYLINES
  // ============================================================

  Map<PolylineId, Polyline> polylines = {};

  List<LatLng> polylineCoordinates = [];

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final TextEditingController fromController =
      TextEditingController();

  final TextEditingController toController =
      TextEditingController();

  // ============================================================
  // DISTANCE / DURATION
  // ============================================================

  String totalDistance = '';
  String totalDuration = '';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _googleMapController?.dispose();
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chat_rounded),
          tooltip: 'KaroAI',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  rideContext: _pricingData,
                ),
              ),
            );
          },
        ),

        // ======================================================
        // PROFILE BUTTON
        // ======================================================

        actions: [
          IconButton(
            icon: const Icon(Icons.explore_rounded),
            tooltip: 'Destination Explorer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const DestinationExplorerScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/profileScreen',
              );
            },
          ),
        ],

        centerTitle: true,

        title: const Text(
          'Karocab',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Column(
        children: [
          // ======================================================
          // GOOGLE MAP
          // ======================================================

          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
              child: GoogleMap(
                onMapCreated: (controller) {
                  _googleMapController = controller;

                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target:
                            _initialCameraPosition?.target ??
                                _defaultCameraPosition.target,
                        zoom:
                            _initialCameraPosition?.zoom ??
                                _defaultCameraPosition.zoom,
                        tilt: 45.0,
                        bearing: 0.0,
                      ),
                    ),
                  );
                },
                initialCameraPosition:
                    _initialCameraPosition ??
                        _defaultCameraPosition,
                markers: Set<Marker>.of(
                  markers.values,
                ),
                polylines: Set<Polyline>.of(
                  polylines.values,
                ),
               myLocationEnabled: false,
               myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                compassEnabled: true,
                buildingsEnabled: true,
                tiltGesturesEnabled: true,
                trafficEnabled: false,
              ),
            ),
          ),

          buildHeight(
            deviceHeight(context) * 0.02,
          ),

          // ======================================================
          // FROM
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              controller: fromController,
              decoration: InputDecoration(
                hintText: 'Where From?',
                labelText: 'From',
                prefixIcon: const Icon(
                  Icons.location_on,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color:
                        AppPallete.buttonGradient1,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: Colors.blue,
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ),

          buildHeight(
            deviceHeight(context) * 0.02,
          ),

          // ======================================================
          // TO
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              controller: toController,
              decoration: InputDecoration(
                hintText: 'Where To?',
                labelText: 'To',
                prefixIcon: const Icon(
                  Icons.flag_rounded,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color:
                        AppPallete.buttonGradient1,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: Colors.blue,
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ),

          buildHeight(
            deviceHeight(context) * 0.02,
          ),

          // ======================================================
          // SUBMIT
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0),
            child: CustomButton.buildCustomButton(
              context: context,
              isArrowVisible: false,
              onPressed: () async {
                if (fromController.text.trim().isEmpty ||
                    toController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter both From and To locations.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await _setOriginAndDestination();

                  if (!mounted) return;

                  await _getRoute();

                  if (!mounted) return;

                  await _showPricingDialog();
                } catch (e) {
                  dev.log('Error: $e');

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'An error occurred: $e',
                      ),
                    ),
                  );
                }
              },
              text: 'Submit',
            ),
          ),

          // ======================================================
          // DISTANCE / DURATION
          // ======================================================

          if (totalDistance.isNotEmpty &&
              totalDuration.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Distance: $totalDistance, '
                'Duration: $totalDuration',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          buildHeight(
            deviceHeight(context) * 0.04,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

 Future<void> _setCurrentLocation() async {
  try {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      dev.log('Location permission denied.');
      return;
    }

    if (permission ==
        LocationPermission.deniedForever) {
      dev.log(
        'Location permissions are permanently denied.',
      );
      return;
    }

    final Position position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // Android emulator kabhi-kabhi USA/Mountain View
    // ki default location return karta hai.
    // KaroCab Indian travel app hai, isliye
    // India ke bahar ki emulator location ignore karenge.
    final bool looksLikeIndia =
        position.latitude >= 6.0 &&
        position.latitude <= 37.5 &&
        position.longitude >= 68.0 &&
        position.longitude <= 97.5;

    if (!looksLikeIndia) {
      dev.log(
        'Ignoring location outside India: '
        '${position.latitude}, ${position.longitude}',
      );

      if (_googleMapController != null) {
        await _googleMapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            _defaultCameraPosition,
          ),
        );
      }

      return;
    }

    if (!mounted) return;

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;

      _initialCameraPosition =
          CameraPosition(
        target: LatLng(
          latitude!,
          longitude!,
        ),
        zoom: 14.5,
        tilt: 45.0,
      );
    });

    if (_googleMapController != null) {
      await _googleMapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          _initialCameraPosition!,
        ),
      );
    }
  } catch (e) {
    dev.log(
      'Error getting current location: $e',
    );
  }
}
  // ============================================================
  // ADD MARKER
  // ============================================================

  void _addMarker(
    LatLng position,
    String id,
    BitmapDescriptor descriptor,
  ) {
    final MarkerId markerId = MarkerId(id);

    final Marker marker = Marker(
      markerId: markerId,
      icon: descriptor,
      position: position,
    );

    markers[markerId] = marker;

    if (mounted) {
      setState(() {});
    }
  }
  // ============================================================
// ROBUST ADDRESS GEOCODING
// ============================================================

Future<List<Location>> _geocodeAddress(
  String address, {
  String contextAddress = '',
}) async {
  final String cleaned = address.trim();

  if (cleaned.isEmpty) {
    return <Location>[];
  }

  final List<String> queries = <String>[
    cleaned,
  ];

  final String lower = cleaned.toLowerCase();

  final bool isGenericPlace =
      lower == 'railway station' ||
      lower == 'railway station.' ||
      lower == 'train station' ||
      lower == 'station' ||
      lower == 'airport' ||
      lower == 'bus stand' ||
      lower == 'bus station' ||
      lower == 'bus stop';

  // Generic places need city context.
  // Example:
  // railway station
  // ->
  // railway station, Nagpur, Maharashtra, India
  if (isGenericPlace) {
    final String contextLower =
        contextAddress.toLowerCase();

    if (contextLower.contains('nagpur')) {
      queries.add(
        '$cleaned, Nagpur, Maharashtra, India',
      );
    } else {
      queries.add(
        '$cleaned, Nagpur, Maharashtra, India',
      );
    }
  }

  if (!lower.contains('india')) {
    queries.add(
      '$cleaned, India',
    );
  }

  if (!lower.contains('maharashtra') &&
      !lower.contains('india')) {
    queries.add(
      '$cleaned, Maharashtra, India',
    );
  }

  final List<String> uniqueQueries =
      queries.toSet().toList();

  for (final String query in uniqueQueries) {
    try {
      dev.log(
        'Geocoding address: $query',
      );

      final List<Location> results =
          await locationFromAddress(query);

      if (results.isNotEmpty) {
        dev.log(
          'Geocoding success: '
          '${results.first.latitude}, '
          '${results.first.longitude}',
        );

        return results;
      }
    } catch (e) {
      dev.log(
        'Geocoding failed for "$query": $e',
      );
    }
  }

  return <Location>[];
}

  // ============================================================
  // SET ORIGIN + DESTINATION
  // ============================================================

  Future<void> _setOriginAndDestination() async {
    try {
      final String from =
          fromController.text.trim();

      final String to =
          toController.text.trim();

     final List<Location> originLocations =
    await _geocodeAddress(
  from,
);

final List<Location> destinationLocations =
    await _geocodeAddress(
  to,
  contextAddress: from,
);

     if (originLocations.isEmpty ||
    destinationLocations.isEmpty) {
  if (originLocations.isEmpty &&
      destinationLocations.isEmpty) {
    throw Exception(
      'Could not find the From and To locations. '
      'Please enter specific locations with city/state, '
      'for example "Nagpur Railway Station".',
    );
  }

  if (originLocations.isEmpty) {
    throw Exception(
      'Could not find the From location. '
      'Please enter a more specific address or place name.',
    );
  }

  throw Exception(
    'Could not find the To location. '
    'If you entered a generic place such as '
    '"railway station", include the city, '
    'for example "Nagpur Railway Station".',
  );
}

final LatLng originLatLng =
    LatLng(
  originLocations.first.latitude,
  originLocations.first.longitude,
);

final LatLng destinationLatLng =
    LatLng(
  destinationLocations.first.latitude,
  destinationLocations.first.longitude,
);

// Prevent routing when From and To are effectively
// the same place.
final double samePlaceDistance =
    Geolocator.distanceBetween(
  originLatLng.latitude,
  originLatLng.longitude,
  destinationLatLng.latitude,
  destinationLatLng.longitude,
);

if (samePlaceDistance < 100) {
  throw Exception(
    'From and To appear to be the same location. '
    'Please enter two different places.',
  );
}
      markers.clear();
      polylines.clear();
      polylineCoordinates.clear();

      _addMarker(
        originLatLng,
        'origin',
        BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      );

      _addMarker(
        destinationLatLng,
        'destination',
        BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      );

      final LatLngBounds bounds =
          LatLngBounds(
        southwest: LatLng(
          originLatLng.latitude <
                  destinationLatLng.latitude
              ? originLatLng.latitude
              : destinationLatLng.latitude,
          originLatLng.longitude <
                  destinationLatLng.longitude
              ? originLatLng.longitude
              : destinationLatLng.longitude,
        ),
        northeast: LatLng(
          originLatLng.latitude >
                  destinationLatLng.latitude
              ? originLatLng.latitude
              : destinationLatLng.latitude,
          originLatLng.longitude >
                  destinationLatLng.longitude
              ? originLatLng.longitude
              : destinationLatLng.longitude,
        ),
      );

      if (_googleMapController != null) {
        await _googleMapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            bounds,
            50,
          ),
        );
      }
    } catch (e) {
      dev.log(
        'Error in _setOriginAndDestination: $e',
      );

      throw Exception(
        'Failed to set origin and destination: $e',
      );
    }
  }

  // ============================================================
  // GET ROUTE FROM OSRM
  // ============================================================

  Future<void> _getRoute() async {
    if (markers.length < 2) {
      throw Exception(
        'Origin and destination are required.',
      );
    }

    final Marker? originMarker =
        markers[const MarkerId('origin')];

    final Marker? destinationMarker =
        markers[const MarkerId('destination')];

    if (originMarker == null ||
        destinationMarker == null) {
      throw Exception(
        'Route locations are missing.',
      );
    }

    final LatLng origin =
        originMarker.position;

    final LatLng destination =
        destinationMarker.position;

    final String url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline';

    final http.Response response =
        await http
            .get(
      Uri.parse(url),
    )
            .timeout(
      const Duration(seconds: 20),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get route. '
        'Status: ${response.statusCode}',
      );
    }

    final dynamic decoded =
        json.decode(response.body);

    final List<dynamic> routes =
        decoded['routes'] as List<dynamic>;

    if (routes.isEmpty) {
      throw Exception(
        'No route found.',
      );
    }

    final Map<String, dynamic> route =
        Map<String, dynamic>.from(
      routes.first as Map,
    );

    final String encodedPolyline =
        route['geometry']?.toString() ?? '';

    if (encodedPolyline.isEmpty) {
      throw Exception(
        'Route geometry unavailable.',
      );
    }

    polylineCoordinates =
        _decodePolyline(
      encodedPolyline,
    );

    final double distanceKm =
        (route['distance'] as num).toDouble() /
            1000;

    final double durationMinutes =
        (route['duration'] as num).toDouble() /
            60;

    totalDistance =
        '${distanceKm.toStringAsFixed(2)} km';

    totalDuration =
        '${durationMinutes.toStringAsFixed(0)} minutes';

    _addPolyLine();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // DECODE POLYLINE
  // ============================================================

  List<LatLng> _decodePolyline(
    String encoded,
  ) {
    final List<LatLng> poly = [];

    int index = 0;
    final int len = encoded.length;

    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b =
            encoded.codeUnitAt(index++) - 63;

        result |=
            (b & 0x1f) << shift;

        shift += 5;
      } while (b >= 0x20);

      final int dlat =
          ((result & 1) != 0)
              ? ~(result >> 1)
              : (result >> 1);

      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b =
            encoded.codeUnitAt(index++) - 63;

        result |=
            (b & 0x1f) << shift;

        shift += 5;
      } while (b >= 0x20);

      final int dlng =
          ((result & 1) != 0)
              ? ~(result >> 1)
              : (result >> 1);

      lng += dlng;

      final double decodedLatitude =
          lat / 1E5;

      final double decodedLongitude =
          lng / 1E5;

      poly.add(
        LatLng(
          decodedLatitude,
          decodedLongitude,
        ),
      );
    }

    return poly;
  }

  // ============================================================
  // ADD POLYLINE
  // ============================================================

  void _addPolyLine() {
    const PolylineId id =
        PolylineId('polyline_id');

    final Polyline polyline =
        Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );

    polylines[id] = polyline;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // HEIGHT HELPER
  // ============================================================

  Widget buildHeight(double height) {
    return SizedBox(
      height: height,
    );
  }

  // ============================================================
  // PRICING DIALOG
  // ============================================================

  Future<void> _showPricingDialog() async {
    BuildContext? loadingDialogContext;

    try {
      if (!mounted) return;

      // Show a dedicated loading dialog while the Render backend
      // wakes up and returns the ride estimates.
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          loadingDialogContext = dialogContext;

          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Finding rides...',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Comparing available ride options',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Give Flutter one frame to render the loading dialog before
      // starting the network request.
      await Future<void>.delayed(
        const Duration(milliseconds: 100),
      );

      final Map<String, dynamic> pricingData =
          await _fetchPricingData();

      // Always close the loading dialog before showing results.
      if (loadingDialogContext != null &&
          Navigator.of(loadingDialogContext!).canPop()) {
        Navigator.of(loadingDialogContext!).pop();
      }

      if (!mounted) return;

      _pricingData = pricingData;

      final List<dynamic> rides =
          pricingData['rides'] ?? [];

      // --------------------------------------------------------
      // FIND RIDE BY ID
      // --------------------------------------------------------

      Map<String, dynamic> getRide(
        String? id,
      ) {
        if (id == null) {
          return <String, dynamic>{};
        }

        for (final dynamic item in rides) {
          if (item is Map &&
              item['id']?.toString() == id) {
            return Map<String, dynamic>.from(
              item,
            );
          }
        }

        return <String, dynamic>{};
      }

      final Map<String, dynamic>
          recommendations =
          pricingData['recommendations'] is Map
              ? Map<String, dynamic>.from(
                  pricingData['recommendations'],
                )
              : <String, dynamic>{};

      final Map<String, dynamic> bestOverall =
          getRide(
        recommendations['bestOverall']
            ?.toString(),
      );

      final Map<String, dynamic> bestBudget =
          getRide(
        recommendations['bestBudget']
            ?.toString(),
      );

      final Map<String, dynamic> fastest =
          getRide(
        recommendations['fastest']
            ?.toString(),
      );

      final Map<String, dynamic>
          budgetButNotSlowest =
          getRide(
        recommendations['budgetButNotSlowest']
            ?.toString(),
      );

      final Map<String, dynamic> balanced =
          getRide(
        recommendations['balanced']
            ?.toString(),
      );

      final Map<String, dynamic> tradeoffs =
          pricingData['tradeoffs'] is Map
              ? Map<String, dynamic>.from(
                  pricingData['tradeoffs'],
                )
              : <String, dynamic>{};

      final String
          budgetButNotSlowestExplanation =
          recommendations[
                      'budgetButNotSlowestExplanation']
                  ?.toString() ??
              '';

      final String balancedExplanation =
          recommendations[
                      'balancedExplanation']
                  ?.toString() ??
              '';

      if (!mounted) return;

      // --------------------------------------------------------
      // DIALOG
      // --------------------------------------------------------

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          final double dialogHeight =
              MediaQuery.of(dialogContext)
                      .size
                      .height *
                  0.88;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 24,
            ),
            child: SizedBox(
              height: dialogHeight,
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 25,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(28),
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      18,
                    ),
                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================

                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration:
                                BoxDecoration(
                              color: Colors.blue
                                  .withOpacity(0.10),
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                            ),
                            child: const Icon(
                              Icons
                                  .local_taxi_rounded,
                              color: Colors.blue,
                              size: 27,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Cab Comparison',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                                SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  'Compare your available ride options',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(
                              dialogContext,
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // TRIP INFORMATION
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.route_rounded,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(
                              width: 9,
                            ),
                            Expanded(
                              child: Text(
                                '$totalDistance  •  '
                                '$totalDuration',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==================================================
                      // AVAILABLE RIDES
                      // ==================================================

                      const Text(
                        'Available Rides',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      ...rides.map<Widget>(
                        (dynamic ride) {
                          if (ride is! Map) {
                            return const SizedBox
                                .shrink();
                          }

                          return _buildRideCard(
                            provider:
                                ride['provider']
                                        ?.toString() ??
                                    'Unknown',
                            category:
                                ride['category']
                                        ?.toString() ??
                                    '',
                            fare:
                                ride['fare']
                                        ?.toString() ??
                                    'N/A',
                            eta:
                                ride['eta']
                                        ?.toString() ??
                                    'N/A',
                            score:
                                ride['karoScore']
                                        ?.toString() ??
                                    'N/A',
                          );
                        },
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==================================================
                      // FARE PREDICTION
                      // ==================================================

                      _buildFarePredictionCard(
                        pricingData[
                            'farePrediction'],
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==================================================
                      // SMART RECOMMENDATIONS
                      // ==================================================

                      const Text(
                        'Smart Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      _buildRecommendationCard(
                        emoji: '🏆',
                        title: 'Best Overall',
                        ride: bestOverall,
                      ),

                      _buildRecommendationCard(
                        emoji: '💰',
                        title: 'Best Budget',
                        ride: bestBudget,
                      ),

                      _buildRecommendationCard(
                        emoji: '⚡',
                        title: 'Fastest',
                        ride: fastest,
                      ),

                      _buildRecommendationCard(
                        emoji: '💡',
                        title:
                            'Budget but Not Slowest',
                        ride:
                            budgetButNotSlowest,
                        explanation:
                            budgetButNotSlowestExplanation,
                      ),

                      _buildRecommendationCard(
                        emoji: '⚖️',
                        title: 'Balanced Choice',
                        ride: balanced,
                        explanation:
                            balancedExplanation,
                      ),

                      if (tradeoffs.isNotEmpty)
                        _buildTradeoffCard(
                          tradeoffs: tradeoffs,
                        ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==================================================
                      // PRICE ALERT
                      // ==================================================

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child:
                            OutlinedButton.icon(
                          onPressed: () =>
                              _showPriceAlertDialog(
                            rides,
                          ),
                          icon: const Icon(
                            Icons
                                .notifications_active_outlined,
                            size: 20,
                          ),
                          label: const Text(
                            'Set Price Alert',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                Colors.blue,
                            side: BorderSide(
                              color:
                                  Colors.blue.shade200,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==================================================
                      // PROVIDER BUTTONS
                      // ==================================================

                      Row(
                        children: [
                          Expanded(
                            child:
                                _buildActionButton(
                              'Open Ola',
                              Colors.yellow[700]!,
                              () async {
                                try {
                                  await LaunchApp
                                      .openApp(
                                    androidPackageName:
                                        'com.olacabs.customer',
                                    openStore: false,
                                  );
                                } catch (e) {
                                  dev.log(
                                    'Could not open Ola: $e',
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child:
                                _buildActionButton(
                              'Open Uber',
                              Colors.black,
                              () async {
                                try {
                                  await LaunchApp
                                      .openApp(
                                    androidPackageName:
                                        'com.ubercab',
                                    openStore: false,
                                  );
                                } catch (e) {
                                  dev.log(
                                    'Could not open Uber: $e',
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==================================================
                      // DISCLAIMER
                      // ==================================================

                      const Center(
                        child: Text(
                          'Fares shown are KaroCab '
                          'estimated/simulated values. '
                          'Fare prediction is model-based.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      dev.log(
        'Error showing pricing dialog: $e',
      );

      // Important: close the loading dialog on every failure too.
      // This prevents the app from staying stuck on
      // "Finding rides..." forever.
      if (loadingDialogContext != null &&
          Navigator.of(loadingDialogContext!).canPop()) {
        Navigator.of(loadingDialogContext!).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load pricing data: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // PRICE ALERT
  // ============================================================

  Future<void> _showPriceAlertDialog(List<dynamic> rides) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PriceAlertScreen(
          rides: rides,
          from: fromController.text.trim(),
          to: toController.text.trim(),
          distance:
              double.tryParse(totalDistance.split(' ').first) ?? 0.0,
          duration:
              int.tryParse(totalDuration.split(' ').first) ?? 0,
        ),
      ),
    );

    if (!mounted || saved != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Price alert saved successfully.'),
      ),
    );
  }

  // ============================================================
  // FARE PREDICTION CARD
  // ============================================================

  Widget _buildFarePredictionCard(
    dynamic predictionData,
  ) {
    if (predictionData is! Map ||
        predictionData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: Colors.grey,
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                'Fare prediction is currently unavailable.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final Map<String, dynamic> prediction =
        Map<String, dynamic>.from(
      predictionData,
    );

    final double? predictedFare =
        _toDouble(
      prediction['predictedFare'],
    );

    final double? currentFare =
        _toDouble(
      prediction['currentFare'],
    );

    final double? expectedChange =
        _toDouble(
      prediction['expectedChange'],
    );

    final double? expectedChangePercent =
        _toDouble(
      prediction['expectedChangePercent'],
    );

    final String trend =
        prediction['trend']
                ?.toString()
                .toLowerCase() ??
            '';

    final String recommendation =
        prediction['recommendation']
                ?.toString() ??
            'N/A';

    final String model =
        prediction['model']
                ?.toString() ??
            prediction['predictionModel']
                ?.toString() ??
            'Linear Regression';

    final String dataType =
        prediction['dataType']
                ?.toString() ??
            'Simulated historical training data';

    final bool isUp =
        trend == 'up';

    final bool isDown =
        trend == 'down';

    final IconData trendIcon =
        isUp
            ? Icons.trending_up_rounded
            : isDown
                ? Icons.trending_down_rounded
                : Icons.trending_flat_rounded;

    final Color trendColor =
        isUp
            ? Colors.red
            : isDown
                ? Colors.green
                : Colors.blue;

    final String trendText =
        isUp
            ? 'Fare may increase'
            : isDown
                ? 'Fare may decrease'
                : 'Fare may stay stable';

    final String recommendationText =
        recommendation
            .toLowerCase()
            .contains('wait')
            ? 'Consider Waiting'
            : recommendation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade50,
            Colors.white,
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              Colors.indigo.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------
          // HEADER
          // --------------------------------------------------------

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.indigo
                      .withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.indigo,
                  size: 24,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare Prediction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Machine-learning based fare trend',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          // --------------------------------------------------------
          // CURRENT + PREDICTED FARE
          // --------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: _buildPredictionValue(
                  label: 'Current Fare',
                  value:
                      currentFare != null
                          ? '₹${currentFare.toStringAsFixed(2)}'
                          : 'N/A',
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: _buildPredictionValue(
                  label: 'Predicted Fare',
                  value:
                      predictedFare != null
                          ? '₹${predictedFare.toStringAsFixed(2)}'
                          : 'N/A',
                  highlight: true,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // --------------------------------------------------------
          // TREND
          // --------------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color:
                  trendColor.withOpacity(0.08),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  trendIcon,
                  color: trendColor,
                  size: 23,
                ),
                const SizedBox(
                  width: 9,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        trendText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                      if (expectedChange != null)
                        Text(
                          '${expectedChange >= 0 ? '+' : ''}'
                          '₹${expectedChange.toStringAsFixed(2)}'
                          '${expectedChangePercent != null ? '  (${expectedChangePercent >= 0 ? '+' : ''}${expectedChangePercent.toStringAsFixed(2)}%)' : ''}',
                          style:
                              const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // --------------------------------------------------------
          // RECOMMENDATION
          // --------------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  recommendationText
                          .toLowerCase()
                          .contains('wait')
                      ? Icons
                          .hourglass_bottom_rounded
                      : Icons.check_circle_rounded,
                  color:
                      recommendationText
                              .toLowerCase()
                              .contains('wait')
                          ? Colors.orange
                          : Colors.green,
                  size: 21,
                ),
                const SizedBox(
                  width: 9,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KaroCab Recommendation',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        recommendationText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 11,
          ),

          // --------------------------------------------------------
          // MODEL INFO
          // --------------------------------------------------------

          Text(
            'Model: $model',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            'Data: $dataType',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREDICTION VALUE
  // ============================================================

  Widget _buildPredictionValue({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            highlight
                ? Colors.indigo.withOpacity(0.07)
                : Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              highlight
                  ? Colors.indigo.withOpacity(0.15)
                  : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
              color:
                  highlight
                      ? Colors.indigo
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAFE DOUBLE CONVERSION
  // ============================================================

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // RIDE CARD
  // ============================================================

  Widget _buildRideCard({
    required String provider,
    required String category,
    required String fare,
    required String eta,
    required String score,
  }) {
    final bool isAuto =
        category
            .toLowerCase()
            .contains('auto');

    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
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
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              isAuto
                  ? Icons.electric_rickshaw_rounded
                  : Icons.local_taxi_rounded,
              color: Colors.blue,
              size: 25,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '$provider $category',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text(
                      '$eta min',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: Colors.blue,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text(
                      score,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Text(
            '₹$fare',
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECOMMENDATION CARD
  // ============================================================

  Widget _buildRecommendationCard({
    required String emoji,
    required String title,
    required Map<String, dynamic> ride,
    String explanation = '',
  }) {
    if (ride.isEmpty) {
      return Container(
        margin:
            const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Text(
          '$emoji  $title: N/A',
          style: const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      );
    }

    final String provider =
        ride['provider']?.toString() ??
            'N/A';

    final String category =
        ride['category']?.toString() ??
            '';

    final String fare =
        ride['fare']?.toString() ??
            'N/A';

    final String score =
        ride['karoScore']?.toString() ??
            'N/A';

    final String eta =
        ride['eta']?.toString() ??
            'N/A';

    return Container(
      margin:
          const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(
              fontSize: 21,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '$provider $category',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '₹$fare  •  ETA $eta min',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                if (explanation
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    explanation,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.blue
                  .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Text(
              '$score/100',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRADE-OFF CARD
  // ============================================================

  Widget _buildTradeoffCard({
    required Map<String, dynamic> tradeoffs,
  }) {
    final String extraCost =
        tradeoffs['extraCostVsBudget']
                ?.toString() ??
            tradeoffs['extraCost']
                ?.toString() ??
            '';

    final String timeSaved =
        tradeoffs['timeSavedVsSlowest']
                ?.toString() ??
            tradeoffs['timeSaved']
                ?.toString() ??
            '';

    if (extraCost.isEmpty &&
        timeSaved.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue
              .withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: Colors.blue,
                size: 20,
              ),
              SizedBox(
                width: 8,
              ),
              Text(
                'Trade-offs',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          if (extraCost.isNotEmpty)
            Text(
              'Extra cost vs cheapest: ₹$extraCost',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          if (timeSaved.isNotEmpty) ...[
            const SizedBox(
              height: 4,
            ),
            Text(
              'Time saved vs slowest: '
              '$timeSaved min',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    final bool isBlack =
        color == Colors.black;

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style:
            ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor:
              isBlack
                  ? Colors.white
                  : Colors.black,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FETCH PRICING DATA
  // ============================================================

  Future<Map<String, dynamic>>
      _fetchPricingData() async {
    if (totalDistance.isEmpty || totalDuration.isEmpty) {
      throw Exception(
        'Distance and duration are not available.',
      );
    }

    final String distanceText =
        totalDistance.split(' ').first;
    final String durationText =
        totalDuration.split(' ').first;

    final double? distance = double.tryParse(distanceText);
    final int? duration = int.tryParse(durationText);

    if (distance == null || duration == null) {
      throw Exception('Invalid distance or duration.');
    }

    const String endpoint =
        'https://cab-karo.onrender.com/estimate';

    final Map<String, dynamic> requestBody = <String, dynamic>{
      'distance': distance,
      'timeTaken': duration,
      'traffic': 'moderate',
      'demand': 'medium',
      'tolls': 0,
      'timeOfDay': 'day',
      'route': 'normal',
      'historicData': 'normal',
      'hour': DateTime.now().hour,
      'weekend': DateTime.now().weekday >= DateTime.saturday,
    };

    // The Render service can sleep on its free instance. Do NOT keep the
    // user on an endless "Finding rides..." screen while waiting for it.
    try {
      dev.log('Calling KaroCab API: $endpoint');

      final http.Response response = await http
          .post(
            Uri.parse(endpoint),
            headers: const <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      dev.log('KaroCab API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        if (decoded is Map) {
          final Map<String, dynamic> result =
              Map<String, dynamic>.from(decoded);
          final dynamic rides = result['rides'];

          if (rides is List && rides.isNotEmpty) {
            dev.log('KaroCab API rides received: ${rides.length}');
            return result;
          }
        }

        dev.log('KaroCab API returned an invalid/empty rides list.');
      } else {
        dev.log(
          'KaroCab API HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      dev.log('KaroCab API timed out after 10 seconds.');
    } catch (e) {
      dev.log('KaroCab API failed: $e');
    }

    // Safe local fallback. This keeps the comparison feature usable even
    // when the Render server is asleep/unavailable. These are simulated
    // estimates, not live Ola/Uber fares.
    dev.log('Using local simulated pricing fallback.');
    return _buildFallbackPricingData(
      distance: distance,
      duration: duration,
    );
  }

  Map<String, dynamic> _buildFallbackPricingData({
    required double distance,
    required int duration,
  }) {
    final double cabBase = 55 + (distance * 14.0);
    final double autoBase = 35 + (distance * 10.0);

    final List<Map<String, dynamic>> rides = <Map<String, dynamic>>[
      {
        'id': 'uber_cab',
        'provider': 'Uber',
        'category': 'Cab',
        'fare': double.parse(cabBase.toStringAsFixed(2)),
        'eta': 5,
        'duration': duration,
        'safety': 80,
        'comfort': 85,
        'reliability': 85,
      },
      {
        'id': 'uber_auto',
        'provider': 'Uber',
        'category': 'Auto',
        'fare': double.parse(autoBase.toStringAsFixed(2)),
        'eta': 4,
        'duration': duration + 2,
        'safety': 80,
        'comfort': 70,
        'reliability': 82,
      },
      {
        'id': 'ola_cab',
        'provider': 'Ola',
        'category': 'Cab',
        'fare': double.parse((cabBase * 0.97).toStringAsFixed(2)),
        'eta': 6,
        'duration': duration + 1,
        'safety': 80,
        'comfort': 84,
        'reliability': 80,
      },
      {
        'id': 'ola_auto',
        'provider': 'Ola',
        'category': 'Auto',
        'fare': double.parse((autoBase * 0.96).toStringAsFixed(2)),
        'eta': 5,
        'duration': duration + 2,
        'safety': 78,
        'comfort': 68,
        'reliability': 78,
      },
    ];

    // Keep the fallback response compatible with the existing UI.
    rides.sort(
      (a, b) =>
          (a['fare'] as num).compareTo(b['fare'] as num),
    );

    for (int i = 0; i < rides.length; i++) {
      rides[i]['karoScore'] =
          (94 - (i * 4)).toDouble();
    }

    final Map<String, dynamic> cheapest = rides.first;
    final Map<String, dynamic> fastest =
        rides.reduce(
      (a, b) =>
          (a['eta'] as num) <= (b['eta'] as num) ? a : b,
    );
    final Map<String, dynamic> bestOverall =
        rides.reduce(
      (a, b) =>
          (a['karoScore'] as num) >= (b['karoScore'] as num)
              ? a
              : b,
    );

    return <String, dynamic>{
      'source': 'local_simulated_fallback',
      'rides': rides,
      'recommendations': <String, dynamic>{
        'bestOverall': bestOverall['id'],
        'bestBudget': cheapest['id'],
        'fastest': fastest['id'],
        'budgetButNotSlowest': cheapest['id'],
        'balanced': bestOverall['id'],
        'budgetButNotSlowestExplanation':
            'Lowest estimated fare among the available options.',
        'balancedExplanation':
            'Balanced choice based on estimated fare, ETA and KaroScore.',
      },
      'tradeoffs': <String, dynamic>{
        'extraCostVsBudget':
            ((bestOverall['fare'] as num) - (cheapest['fare'] as num))
                .toStringAsFixed(2),
        'timeSavedVsSlowest': 0,
      },
      'farePrediction': <String, dynamic>{
        'predictedFare': cheapest['fare'],
        'currentFare': cheapest['fare'],
        'expectedChange': 0,
        'expectedChangePercent': 0,
        'trend': 'stable',
        'recommendation': 'Book based on current estimate',
        'model': 'Local fallback estimate',
        'dataType': 'Simulated estimate',
      },
    };
  }
}