import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class KaroSafeScreen extends StatefulWidget {
  const KaroSafeScreen({super.key});

  @override
  State<KaroSafeScreen> createState() => _KaroSafeScreenState();
}

class _KaroSafeScreenState extends State<KaroSafeScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  bool _savingContact = false;
  bool _sendingSos = false;

  String? _savedContactName;
  String? _savedContactPhone;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // FIRESTORE USER DOCUMENT
  // ============================================================

  DocumentReference<Map<String, dynamic>>? get _userDocument {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid);
  }

  // ============================================================
  // LOAD EMERGENCY CONTACT
  // ============================================================

  Future<void> _loadEmergencyContact() async {
    try {
      final DocumentReference<Map<String, dynamic>>?
          document = _userDocument;

      if (document == null) {
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await document.get();

      if (!snapshot.exists) {
        return;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        return;
      }

      final dynamic emergencyContact =
          data['emergencyContact'];

      if (emergencyContact is Map) {
        final String name =
            emergencyContact['name']
                    ?.toString() ??
                '';

        final String phone =
            emergencyContact['phone']
                    ?.toString() ??
                '';

        if (!mounted) {
          return;
        }

        setState(() {
          _savedContactName =
              name.isEmpty ? null : name;

          _savedContactPhone =
              phone.isEmpty ? null : phone;

          _nameController.text = name;
          _phoneController.text = phone;
        });
      } else if (emergencyContact != null) {
        // Supports an older/simple string format.
        final String phone =
            emergencyContact.toString();

        if (!mounted) {
          return;
        }

        setState(() {
          _savedContactPhone =
              phone.isEmpty ? null : phone;

          _phoneController.text = phone;
        });
      }
    } catch (e) {
      debugPrint(
        'KaroSafe contact load error: $e',
      );
    }
  }

  // ============================================================
  // SAVE EMERGENCY CONTACT
  // ============================================================

 Future<void> _saveEmergencyContact() async {
  final name = _nameController.text.trim();
  final phone = _phoneController.text.trim();

  if (name.isEmpty || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter contact name and phone number.'),
      ),
    );
    return;
  }

  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in Firebase user found.',
      );
    }

    debugPrint('KaroSafe UID: ${user.uid}');
    debugPrint('KaroSafe Name: $name');
    debugPrint('KaroSafe Phone: $phone');

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .set(
      {
        'emergencyContact': {
          'name': name,
          'phone': phone,
        },
      },
      SetOptions(merge: true),
    );

    debugPrint(
      'KaroSafe emergency contact saved successfully.',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          'Emergency contact saved successfully.',
        ),
      ),
    );

    FocusScope.of(context).unfocus();
  } on FirebaseException catch (e) {
    debugPrint(
      'KaroSafe Firebase error: '
      '${e.code} - ${e.message}',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'Firebase error: ${e.code}\n${e.message ?? 'Unknown error'}',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  } catch (e) {
    debugPrint(
      'KaroSafe save error: $e',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'Could not save emergency contact:\n$e',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

  // ============================================================
  // LOCATION PERMISSION
  // ============================================================

  Future<bool> _ensureLocationPermission() async {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showMessage(
        'Please turn on Location/GPS first.',
      );
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.denied) {
      _showMessage(
        'Location permission is required for SOS.',
      );
      return false;
    }

    if (permission ==
        LocationPermission.deniedForever) {
      _showLocationSettingsDialog();
      return false;
    }

    return true;
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<Position?> _getCurrentLocation() async {
    final bool permitted =
        await _ensureLocationPermission();

    if (!permitted) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint(
        'KaroSafe location error: $e',
      );

      _showMessage(
        'Could not get your current location.',
      );

      return null;
    }
  }

  // ============================================================
  // SOS
  // ============================================================

  Future<void> _triggerSos() async {
    if (_sendingSos) {
      return;
    }

    final String? phone =
        _savedContactPhone ??
            (_phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim());

    if (phone == null || phone.isEmpty) {
      _showMessage(
        'Please save an emergency contact first.',
      );
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: <Widget>[
              Icon(
                Icons.warning_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text('Emergency SOS'),
            ],
          ),
          content: const Text(
            'KaroSafe will get your current location and open your SMS app with an emergency message prepared for your saved contact.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    WidgetStatePropertyAll(
                  Colors.red,
                ),
                foregroundColor:
                    WidgetStatePropertyAll(
                  Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'SEND SOS',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _sendingSos = true;
    });

    try {
      final Position? position =
          await _getCurrentLocation();

      if (position == null) {
        return;
      }

      final String mapsLink =
          'https://www.google.com/maps/search/?api=1'
          '&query=${position.latitude},${position.longitude}';

      final DateTime now = DateTime.now();

      final String timestamp =
          '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/'
          '${now.year} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';

      final String contactName =
          _savedContactName ??
              _nameController.text.trim();

      final String message =
          '🚨 KaroCab SOS Alert\n\n'
          'I need help.\n\n'
          'Emergency contact: $contactName\n'
          'Current location:\n'
          '$mapsLink\n\n'
          'Time: $timestamp';

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: <String, String>{
          'body': message,
        },
      );

      final bool canOpen =
          await canLaunchUrl(smsUri);

      if (!canOpen) {
        _showMessage(
          'SMS app could not be opened on this device.',
        );
        return;
      }

      await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      if (mounted) {
        _showMessage(
          'SOS message prepared with your current location.',
        );
      }
    } catch (e) {
      debugPrint(
        'KaroSafe SOS error: $e',
      );

      _showMessage(
        'Could not prepare SOS message.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingSos = false;
        });
      }
    }
  }

  // ============================================================
  // LOCATION SETTINGS
  // ============================================================

  void _showLocationSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Location Permission Required',
          ),
          content: const Text(
            'Location permission was permanently denied. Please enable it from Android settings to use KaroSafe SOS.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await Geolocator.openAppSettings();
              },
              child: const Text(
                'Open Settings',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool hasContact =
        _savedContactPhone != null &&
            _savedContactPhone!.isNotEmpty;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text(
          'KaroSafe',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: <Widget>[
              // =================================================
              // HEADER
              // =================================================

              Container(
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: const Column(
                  children: <Widget>[
                    Icon(
                      Icons.shield_rounded,
                      size: 54,
                      color: Colors.red,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'KaroSafe',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Emergency assistance and location sharing',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // SOS BUTTON
              // =================================================

              GestureDetector(
                onTap: _sendingSos
                    ? null
                    : _triggerSos,
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.red
                            .withValues(
                          alpha: 0.28,
                        ),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _sendingSos
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons
                                    .emergency_rounded,
                                size: 58,
                                color: Colors.white,
                              ),
                              SizedBox(height: 5),
                              Text(
                                'SOS',
                                style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 34,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                              Text(
                                'TAP FOR EMERGENCY',
                                style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                hasContact
                    ? 'Your emergency contact is ready.'
                    : 'Save an emergency contact before using SOS.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hasContact
                      ? Colors.green
                      : Colors.red,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 28),

              // =================================================
              // EMERGENCY CONTACT
              // =================================================

              const Text(
                'Emergency Contact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _nameController,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    InputDecoration(
                  labelText:
                      'Contact name',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _phoneController,
                keyboardType:
                    TextInputType.phone,
                decoration:
                    InputDecoration(
                  labelText:
                      'Phone number',
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                  ),
                  hintText:
                      '+91XXXXXXXXXX',
                  filled: true,
                  fillColor: Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _savingContact
                      ? null
                      : _saveEmergencyContact,
                  icon: _savingContact
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.save_rounded,
                        ),
                  label: Text(
                    _savingContact
                        ? 'Saving...'
                        : 'Save Emergency Contact',
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // HOW IT WORKS
              // =================================================

              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'How KaroSafe works',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12),
                    _SafeStep(
                      icon: Icons.touch_app,
                      text:
                          'Tap the red SOS button.',
                    ),
                    _SafeStep(
                      icon: Icons.location_on,
                      text:
                          'KaroCab gets your current GPS location.',
                    ),
                    _SafeStep(
                      icon: Icons.map,
                      text:
                          'A Google Maps location link is created.',
                    ),
                    _SafeStep(
                      icon: Icons.sms,
                      text:
                          'Your SMS app opens with the emergency message prepared.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'KaroSafe does not continuously store your location. Location is obtained when you use SOS.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SAFE STEP WIDGET
// ============================================================

class _SafeStep extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SafeStep({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 21,
            color: Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}