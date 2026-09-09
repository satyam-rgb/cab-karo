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

  static const CameraPosition _defaultCameraPosition = CameraPosition(
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

  final TextEditingController fromController = TextEditingController();

  final TextEditingController toController = TextEditingController();

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
            icon: const Icon(Icons.person_rounded),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.pushNamed(context, '/profileScreen');
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
                        target: _initialCameraPosition?.target ??
                            _defaultCameraPosition.target,
                        zoom: _initialCameraPosition?.zoom ??
                            _defaultCameraPosition.zoom,
                        tilt: 45.0,
                        bearing: 0.0,
                      ),
                    ),
                  );
                },
                initialCameraPosition:
                    _initialCameraPosition ?? _defaultCameraPosition,
                markers: Set<Marker>.of(
                  markers.values,
                ),
                polylines: Set<Polyline>.of(
                  polylines.values,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
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
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: AppPallete.buttonGradient1,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: AppPallete.buttonGradient1,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
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

          if (totalDistance.isNotEmpty && totalDuration.isNotEmpty)
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
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        dev.log('Location permission denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
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

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;

        _initialCameraPosition = CameraPosition(
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
  // SET ORIGIN + DESTINATION
  // ============================================================

  Future<void> _setOriginAndDestination() async {
    try {
      final String from = fromController.text.trim();

      final String to = toController.text.trim();

      final List<Location> originLocations =
          await locationFromAddress(from);

      final List<Location> destinationLocations =
          await locationFromAddress(to);

      if (originLocations.isEmpty ||
          destinationLocations.isEmpty) {
        throw Exception(
          'Could not find one or both locations.',
        );
      }

      final LatLng originLatLng = LatLng(
        originLocations.first.latitude,
        originLocations.first.longitude,
      );

      final LatLng destinationLatLng = LatLng(
        destinationLocations.first.latitude,
        destinationLocations.first.longitude,
      );

      // Clear old route data.
      markers.clear();
      polylines.clear();
      polylineCoordinates.clear();

      // Origin marker.
      _addMarker(
        originLatLng,
        'origin',
        BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      );

      // Destination marker.
      _addMarker(
        destinationLatLng,
        'destination',
        BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      );

      final LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          originLatLng.latitude < destinationLatLng.latitude
              ? originLatLng.latitude
              : destinationLatLng.latitude,
          originLatLng.longitude < destinationLatLng.longitude
              ? originLatLng.longitude
              : destinationLatLng.longitude,
        ),
        northeast: LatLng(
          originLatLng.latitude > destinationLatLng.latitude
              ? originLatLng.latitude
              : destinationLatLng.latitude,
          originLatLng.longitude > destinationLatLng.longitude
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

    final LatLng origin = originMarker.position;

    final LatLng destination = destinationMarker.position;

    final String url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline';

    final http.Response response = await http.get(
      Uri.parse(url),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get route. '
        'Status: ${response.statusCode}',
      );
    }

    final dynamic decoded = json.decode(response.body);

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

    polylineCoordinates = _decodePolyline(
      encodedPolyline,
    );

    final double distanceKm =
        (route['distance'] as num).toDouble() / 1000;

    final double durationMinutes =
        (route['duration'] as num).toDouble() / 60;

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
        b = encoded.codeUnitAt(index++) - 63;

        result |= (b & 0x1f) << shift;

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
        b = encoded.codeUnitAt(index++) - 63;

        result |= (b & 0x1f) << shift;

        shift += 5;
      } while (b >= 0x20);

      final int dlng =
          ((result & 1) != 0)
              ? ~(result >> 1)
              : (result >> 1);

      lng += dlng;

      final double decodedLatitude = lat / 1E5;

      final double decodedLongitude = lng / 1E5;

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

    final Polyline polyline = Polyline(
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
    try {
      final Map<String, dynamic> pricingData =
          await _fetchPricingData();

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

      final Map<String, dynamic> recommendations =
          pricingData['recommendations'] is Map
              ? Map<String, dynamic>.from(
                  pricingData['recommendations'],
                )
              : <String, dynamic>{};

      final Map<String, dynamic> bestOverall =
          getRide(
        recommendations['bestOverall']?.toString(),
      );

      final Map<String, dynamic> bestBudget =
          getRide(
        recommendations['bestBudget']?.toString(),
      );

      final Map<String, dynamic> fastest =
          getRide(
        recommendations['fastest']?.toString(),
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // SHOW DIALOG
      // --------------------------------------------------------

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 24,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(dialogContext).size.height *
                        0.88,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 25,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.10),
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.local_taxi_rounded,
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
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cab Comparison',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(
                                height: 3,
                              ),
                              Text(
                                'Compare your available ride options',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(16),
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
                              style: const TextStyle(
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    ...rides.map<Widget>(
                      (dynamic ride) {
                        if (ride is! Map) {
                          return const SizedBox.shrink();
                        }

                        return _buildRideCard(
                          provider:
                              ride['provider']?.toString() ??
                                  'Unknown',
                          category:
                              ride['category']?.toString() ??
                                  '',
                          fare:
                              ride['fare']?.toString() ??
                                  'N/A',
                          eta:
                              ride['eta']?.toString() ??
                                  'N/A',
                          score:
                              ride['karoScore']?.toString() ??
                                  'N/A',
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==================================================
                    // KAROSCORE
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade50,
                            Colors.white,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              Colors.blue.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.blue,
                                size: 22,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'KaroScore',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          ...rides.map<Widget>(
                            (dynamic ride) {
                              if (ride is! Map) {
                                return const SizedBox
                                    .shrink();
                              }

                              final String score =
                                  ride['karoScore']
                                          ?.toString() ??
                                      'N/A';

                              return Padding(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${ride['provider']} '
                                        '${ride['category']}',
                                        style:
                                            const TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: Colors.blue
                                            .withOpacity(
                                          0.10,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          10,
                                        ),
                                      ),
                                      child: Text(
                                        '$score/100',
                                        style:
                                            const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
                        fontWeight: FontWeight.w800,
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

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // OPEN PROVIDER BUTTONS
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Open Ola',
                            Colors.yellow[700]!,
                            () async {
                              try {
                                await LaunchApp.openApp(
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
                          child: _buildActionButton(
                            'Open Uber',
                            Colors.black,
                            () async {
                              try {
                                await LaunchApp.openApp(
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
                        'estimated/simulated values',
                        textAlign: TextAlign.center,
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
          );
        },
      );
    } catch (e) {
      dev.log(
        'Error showing pricing dialog: $e',
      );

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
        category.toLowerCase().contains('auto');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          // --------------------------------------------------------
          // ICON
          // --------------------------------------------------------

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

          // --------------------------------------------------------
          // DETAILS
          // --------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '$provider $category',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
                      style: const TextStyle(
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
                      style: const TextStyle(
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

          // --------------------------------------------------------
          // FARE
          // --------------------------------------------------------

          Text(
            '₹$fare',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
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
  }) {
    if (ride.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$emoji  $title: N/A',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final String provider =
        ride['provider']?.toString() ?? 'N/A';

    final String category =
        ride['category']?.toString() ?? '';

    final String fare =
        ride['fare']?.toString() ?? 'N/A';

    final String score =
        ride['karoScore']?.toString() ?? 'N/A';

    final String eta =
        ride['eta']?.toString() ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '$provider $category',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Text(
              '$score/100',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
    final bool isBlack = color == Colors.black;

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor:
              isBlack ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
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
    if (totalDistance.isEmpty ||
        totalDuration.isEmpty) {
      throw Exception(
        'Distance and duration are not available.',
      );
    }

    final String distanceText =
        totalDistance.split(' ').first;

    final String durationText =
        totalDuration.split(' ').first;

    final double? distance =
        double.tryParse(distanceText);

    final int? duration =
        int.tryParse(durationText);

    if (distance == null ||
        duration == null) {
      throw Exception(
        'Invalid distance or duration.',
      );
    }

    // ==========================================================
    // KAROCAB BACKEND
    // ==========================================================

    final http.Response response =
        await http.post(
      Uri.parse(
        'https://cab-karo.onrender.com/estimate',
      ),
      headers: const <String, String>{
        'Content-Type':
            'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, dynamic>{
          'distance': distance,
          'timeTaken': duration,
          'traffic': 'moderate',
          'demand': 'medium',
          'tolls': 0,
          'timeOfDay': 'day',
          'route': 'normal',
          'historicData': 'normal',
        },
      ),
    );

    if (response.statusCode == 200) {
      dev.log(
        'KaroCab API response: ${response.body}',
      );

      final dynamic decoded =
          json.decode(response.body);

      if (decoded is! Map) {
        throw Exception(
          'Invalid KaroCab API response.',
        );
      }

      return Map<String, dynamic>.from(
        decoded,
      );
    }

    throw Exception(
      'KaroCab API failed: '
      '${response.statusCode} '
      '${response.body}',
    );
  }
}