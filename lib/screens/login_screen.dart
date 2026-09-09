import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:karocab/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool isLoading = false;
  bool otpSent = false;
  String? verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------
  // SAVE / UPDATE USER PROFILE IN FIRESTORE
  // ------------------------------------------------------------
  Future<void> _saveUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userRef.get();

    final Map<String, dynamic> data = {
      'phone': user.phoneNumber ?? '',
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    // Create default profile data only for a new user.
    if (!userSnapshot.exists) {
      data.addAll({
        'createdAt': FieldValue.serverTimestamp(),
        'preferences': {
          'mode': 'balanced',
          'comfort': false,
        },
        'monthlyBudget': 0,
      });
    }

    await userRef.set(
      data,
      SetOptions(merge: true),
    );
  }

  // ------------------------------------------------------------
  // SEND OTP
  // ------------------------------------------------------------
  Future<void> handleLogin() async {
    var phone =
        _phoneController.text.trim().replaceAll(RegExp(r'[\s-]'), '');

    // If user enters a 10-digit Indian number, automatically add +91.
    if (RegExp(r'^\d{10}$').hasMatch(phone)) {
      phone = '+91$phone';
    }

    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      _showMessage(
        'Enter a valid phone number, e.g. +919876543210',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),

        // Android may automatically verify the SMS.
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);

            // Save user in Firestore.
            await _saveUserProfile();

            if (mounted) {
              openHomePage();
            }
          } catch (e) {
            if (!mounted) return;

            setState(() {
              isLoading = false;
            });

            _showMessage(
              'Automatic verification failed. Please enter the OTP.',
            );
          }
        },

        // Firebase could not send/verify the OTP.
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;

          setState(() {
            isLoading = false;
          });

          _showMessage(
            e.message ?? 'Could not send OTP.',
          );
        },

        // OTP successfully sent.
        codeSent: (String id, int? resendToken) {
          if (!mounted) return;

          setState(() {
            verificationId = id;
            otpSent = true;
            isLoading = false;
          });

          _showMessage('OTP sent successfully.');
        },

        // Auto-retrieval timed out.
        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ------------------------------------------------------------
  // VERIFY OTP
  // ------------------------------------------------------------
  Future<void> verifyOtp() async {
    final otp = _otpController.text.trim();

    if (verificationId == null) {
      _showMessage('Please request an OTP first.');
      return;
    }

    if (otp.length != 6) {
      _showMessage('Please enter the 6-digit OTP.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);

      // Save user profile to Firestore.
      await _saveUserProfile();

      if (mounted) {
        openHomePage();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (e.code == 'invalid-verification-code') {
        _showMessage('Invalid OTP. Please check and try again.');
      } else if (e.code == 'session-expired') {
        _showMessage(
          'OTP expired. Please request a new OTP.',
        );
      } else {
        _showMessage(
          e.message ?? 'OTP verification failed.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'OTP verification failed. Please try again.',
      );
    }
  }

  // ------------------------------------------------------------
  // OPEN HOME
  // ------------------------------------------------------------
  void openHomePage() {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.055),

                      // ------------------------------------------------
                      // LOGO
                      // ------------------------------------------------
                      Container(
                        width: 118,
                        height: 118,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/karocab.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // ------------------------------------------------
                      // TITLE
                      // ------------------------------------------------
                      const Text(
                        'Welcome to KaroCab',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          letterSpacing: -0.7,
                        ),
                      ),

                      const SizedBox(height: 9),

                      const Text(
                        'Compare. Choose. Ride smarter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ------------------------------------------------
                      // MAIN LOGIN CARD
                      // ------------------------------------------------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          24,
                          20,
                          22,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.045),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.phone_rounded,
                                    color: Color(0xFF1463FF),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Login to continue',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Access your smarter ride experience',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ------------------------------------------------
                            // PHONE NUMBER
                            // ------------------------------------------------
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              enabled: !otpSent && !isLoading,
                              decoration: InputDecoration(
                                labelText: 'Mobile Number',
                                hintText: 'Enter 10-digit mobile number',
                                prefixIcon: const Icon(
                                  Icons.phone_rounded,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1463FF),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            if (otpSent) ...[
                              const SizedBox(height: 16),

                              // ------------------------------------------------
                              // OTP
                              // ------------------------------------------------
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                enabled: !isLoading,
                                decoration: InputDecoration(
                                  labelText: 'Enter OTP',
                                  hintText: '6-digit OTP',
                                  counterText: '',
                                  prefixIcon: const Icon(
                                    Icons.lock_rounded,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1463FF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),

                            // ------------------------------------------------
                            // LOGIN / VERIFY BUTTON
                            // ------------------------------------------------
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : (otpSent
                                        ? verifyOtp
                                        : handleLogin),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF1463FF),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      const Color(0xFF8FB4FF),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 23,
                                        height: 23,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            otpSent
                                                ? Icons.verified_rounded
                                                : Icons.phone_rounded,
                                            size: 21,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            otpSent
                                                ? 'Verify OTP'
                                                : 'Continue with Phone',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 21,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            if (otpSent) ...[
                              const SizedBox(height: 10),

                              Center(
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            otpSent = false;
                                            verificationId = null;
                                            _otpController.clear();
                                          });
                                        },
                                  child: const Text(
                                    'Change phone number',
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 15),

                            // Security note
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 15,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Your login is secure',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ------------------------------------------------
                      // WHY KAROCAB
                      // ------------------------------------------------
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Why KaroCab?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _featureCard(
                              icon: Icons.compare_arrows_rounded,
                              title: 'Compare',
                              subtitle: 'Multiple rides',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _featureCard(
                              icon: Icons.auto_awesome_rounded,
                              title: 'KaroScore',
                              subtitle: 'Smarter choice',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _featureCard(
                              icon: Icons.savings_rounded,
                              title: 'Save',
                              subtitle: 'Money & time',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // ------------------------------------------------
                      // TAGLINE
                      // ------------------------------------------------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 17,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF5FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.directions_car_filled_rounded,
                              color: Color(0xFF1463FF),
                              size: 23,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Don’t just compare. Decide smarter.',
                                style: TextStyle(
                                  color: Color(0xFF174EA6),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // ----------------------------------------------------------
            // BOTTOM TERMS
            // ----------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Text(
                'By continuing, you agree to KaroCab’s Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EBF0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1463FF),
              size: 21,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8A919D),
            ),
          ),
        ],
      ),
    );
  }
}