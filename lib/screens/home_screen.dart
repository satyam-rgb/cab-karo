import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

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
  // default camera position
  static const _defaultCameraPosition = CameraPosition(
    target: LatLng(21.1458, 79.0882),
    zoom: 11.5,
    tilt: 60.0, // Added tilt for 3D effect
  );

  // google map controller
  late GoogleMapController _googleMapController;

  // latitude and longitude
  double? latitude;
  double? longitude;

  // initial camera position
  CameraPosition? _initialCameraPosition;

  // markers
  Map<MarkerId, Marker> markers = {};

  // polylines
  Map<PolylineId, Polyline> polylines = {};

  // polyline coordinates
  List<LatLng> polylineCoordinates = [];

  // from controller
  final TextEditingController fromController = TextEditingController();

  // to controller
  final TextEditingController toController = TextEditingController();

  // total distance and duration
  String totalDistance = '';
  String totalDuration = '';

  @override
  void initState() {
    super.initState();
    // set current location
    _setCurrentLocation();
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chat),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatScreen(),
              ),
            );
          },
        ),
        centerTitle: true,
        title: const Text('Karocab'),
      ),
      body: Column(
        children: [
          // google map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0)),
              child: GoogleMap(
                onMapCreated: (controller) {
                  setState(() {
                    _googleMapController = controller;
                    // Set 3D view
                    _googleMapController.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _initialCameraPosition?.target ??
                              _defaultCameraPosition.target,
                          zoom: _initialCameraPosition?.zoom ??
                              _defaultCameraPosition.zoom,
                          tilt: 45.0, // Set tilt for 3D effect
                          bearing: 0.0,
                        ),
                      ),
                    );
                  });
                },
                initialCameraPosition:
                    _initialCameraPosition ?? _defaultCameraPosition,
                markers: Set<Marker>.of(markers.values),
                polylines: Set<Polyline>.of(polylines.values),
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
          buildHeight(deviceHeight(context) * 0.02),

          // from text field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              controller: fromController,
              decoration: InputDecoration(
                hintText: 'Where From?',
                labelText: 'From',
                prefixIcon: const Icon(Icons.location_on),
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
          buildHeight(deviceHeight(context) * 0.02),

          // to text field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              controller: toController,
              decoration: InputDecoration(
                hintText: 'Where To?',
                labelText: 'To',
                prefixIcon: const Icon(Icons.flag),
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
          buildHeight(deviceHeight(context) * 0.02),

          // submit button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: CustomButton.buildCustomButton(
              context: context,
              isArrowVisible: false,
              onPressed: () async {
                try {
                  await _setOriginAndDestination();
                  await _getRoute();
                  await _showPricingDialog();
                } catch (e) {
                  dev.log('Error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                }
              },
              text: "Submit ",
            ),
          ),
          if (totalDistance.isNotEmpty && totalDuration.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Distance: $totalDistance, Duration: $totalDuration',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          buildHeight(deviceHeight(context) * 0.04),
        ],
      ),
    );
  }

//  _setCurrentLocation method
  Future<void> _setCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      dev.log('Location permissions are permanently denied.');
    } else {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        _initialCameraPosition = CameraPosition(
          target: LatLng(latitude!, longitude!),
          zoom: 14.5,
          tilt: 45.0, // Added tilt for 3D effect
        );
      });
    }
  }

// _addMarker method
  void _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
        Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
    setState(() {});
  }

// _setOriginAndDestination method
  Future<void> _setOriginAndDestination() async {
    try {
      List<Location> originLocations =
          await locationFromAddress(fromController.text);
      List<Location> destinationLocations =
          await locationFromAddress(toController.text);

      if (originLocations.isNotEmpty && destinationLocations.isNotEmpty) {
        LatLng originLatLng = LatLng(
            originLocations.first.latitude, originLocations.first.longitude);
        LatLng destinationLatLng = LatLng(destinationLocations.first.latitude,
            destinationLocations.first.longitude);

        _addMarker(originLatLng, "origin",
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
        _addMarker(destinationLatLng, "destination",
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed));

        LatLngBounds bounds = LatLngBounds(
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

        _googleMapController
            .animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    } catch (e) {
      dev.log('Error in _setOriginAndDestination: $e');
      throw Exception('Failed to set origin and destination: $e');
    }
  }

// _getRoute method
  Future<void> _getRoute() async {
    if (markers.length < 2) return;

    LatLng origin = markers[const MarkerId("origin")]!.position;
    LatLng destination = markers[const MarkerId("destination")]!.position;

    String url = 'http://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      String encodedPolyline = data['routes'][0]['geometry'];

      polylineCoordinates = _decodePolyline(encodedPolyline);

      totalDistance =
          (data['routes'][0]['distance'] / 1000).toStringAsFixed(2) + ' km';
      totalDuration =
          (data['routes'][0]['duration'] / 60).toStringAsFixed(0) + ' minutes';

      _addPolyLine();
      setState(() {});
    } else {
      dev.log('Failed to get route');
    }
  }

// _decodePolyline method
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;
      poly.add(LatLng(latitude, longitude));
    }
    return poly;
  }

// _addPolyLine method
  void _addPolyLine() {
    PolylineId id = const PolylineId("polyline_id");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  Widget buildHeight(double height) {
    return SizedBox(
      height: height,
    );
  }

  // Removed _setMapStyle method

  Future<void> _showPricingDialog() async {
    try {
      Map<String, dynamic> pricingData = await _fetchPricingData();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cab Pricing',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPriceRow('Ola Cab', pricingData['uberCabFare'] ?? 'N/A',
                      Icons.local_taxi),
                  _buildPriceRow(
                      'Ola Auto',
                      pricingData['uberAutoFare'] ?? 'N/A',
                      Icons.electric_rickshaw),
                  _buildPriceRow('Uber Cab', pricingData['olaCabFare'] ?? 'N/A',
                      Icons.local_taxi),
                  _buildPriceRow(
                      'Uber Auto',
                      pricingData['olaAutoFare'] ?? 'N/A',
                      Icons.electric_rickshaw),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton('Open Ola', Colors.yellow[700]!,
                          () async {
                        await LaunchApp.openApp(
                          androidPackageName: 'com.olacabs.customer',
                          openStore: false,
                        );
                      }),
                      _buildActionButton('Open Uber', Colors.black, () async {
                        await LaunchApp.openApp(
                          androidPackageName: 'com.ubercab',
                          openStore: false,
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    child: const Text('Close',
                        style: TextStyle(color: Colors.grey)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      dev.log('Error showing pricing dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load pricing data: $e')),
      );
    }
  }

  Widget _buildPriceRow(String title, String price, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
          Text('₹$price',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }

  Future<Map<String, dynamic>> _fetchPricingData() async {
    double distance = double.parse(totalDistance.split(' ')[0]);
    int duration = int.parse(totalDuration.split(' ')[0]);

    // Create a Random instance
    final random = Random();

    // Define possible values for random selection
    List<String> trafficConditions = ['light', 'moderate', 'heavy'];
    List<String> demandLevels = ['low', 'medium', 'high'];
    List<String> timeOfDayOptions = ['day', 'night'];
    List<String> routeOptions = ['shortest', 'fastest'];
    List<String> historicDataOptions = ['high_demand_area', 'low_demand_area'];

    final response = await http.post(
      Uri.parse('your_api_key_for_pricing_data'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'distance': distance,
        'timeTaken': duration,
        'traffic': trafficConditions[random
            .nextInt(trafficConditions.length)], // Random traffic condition
        'demand': demandLevels[
            random.nextInt(demandLevels.length)], // Random demand level
        'tolls': random.nextInt(10), // Random tolls (0-9 currency units)
        'timeOfDay': timeOfDayOptions[
            random.nextInt(timeOfDayOptions.length)], // Random time of day
        'route': routeOptions[
            random.nextInt(routeOptions.length)], // Random route type
        'historicData': historicDataOptions[
            random.nextInt(historicDataOptions.length)] // Random historic data
      }),
    );

    if (response.statusCode == 200) {
      dev.log('Pricing data: ${response.body}');
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load pricing data: ${response.statusCode}');
    }
  }
}
