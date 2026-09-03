import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:karocab/screens/home_screen.dart';
import 'package:otpless_flutter/otpless_flutter.dart';

import '../../utils/colors.dart';
import '../utils/sizeconst.dart';
import '../widgets/button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // instance of otpless
  final _otplessFlutterPlugin = Otpless();
  String phoneOrEmail = '';
  bool isInitIos = false;
  bool isLoading = false;

  // app id
  static const String appId = "OTP_LESS_APP_ID";

  @override
  void initState() {
    super.initState();

    // enable debug logging
    _otplessFlutterPlugin.enableDebugLogging(true);

    // set webview inspectable
    _otplessFlutterPlugin.setWebviewInspectable(true);

    // init headless for android
    if (Platform.isAndroid) {
      _otplessFlutterPlugin.initHeadless(appId);
      _otplessFlutterPlugin.setHeadlessCallback(onHeadlessResult);
      log("Otpless SDK initialized for Android");
    }
  }

  // open login page
  Future<void> openLoginPage() async {
    Map<String, dynamic> arg = {'appId': appId, 'phone': phoneOrEmail};
    try {
      await _otplessFlutterPlugin.openLoginPage(onHeadlessResult, arg);
    } catch (e) {
      log("Error opening login page: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to open login page. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // on headless result
  void onHeadlessResult(dynamic result) {
    setState(() {
      log("Result: ${result.toString()}");

      if (result != null &&
          result['data'] != null &&
          result['data']['status'] != null) {
        log("Result status: ${result['data']['status']}");

        if (result['data']['status'] == 'SUCCESS') {
          log("Login Successful");
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false);
        } else {
          log("Login Failed");
          _showErrorSnackBar("Login failed. Please try again.");
        }
      } else {
        log("Invalid result format");
        _showErrorSnackBar("An error occurred. Please try again.");
      }
    });
  }

  // show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildHeight(deviceHeight(context) * 0.1),

            // app logo
            ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Image.asset('assets/images/karocab.jpg',
                    fit: BoxFit.contain, height: 200.0)),
            buildHeight(deviceHeight(context) * 0.05),

            // login container
            Container(
              height: deviceHeight(context) * 0.55,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppPallete.greyPrimary, width: 1),
                color: AppPallete.greySecondary,
                borderRadius: BorderRadius.circular(35),
              ),
              child: Column(
                children: [
                  buildHeight(deviceHeight(context) * 0.06),

                  // login with phone number button
                  CustomButton.buildCustomButton(
                    context: context,
                    isArrowVisible: true,
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      await openLoginPage();
                      setState(() {
                        isLoading = false;
                      });
                    },
                    text: "Login with Phone Number",
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
