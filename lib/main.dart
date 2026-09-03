import 'package:flutter/material.dart';
import 'package:karocab/screens/onboarding_screen.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //home: Screen0(),
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/loginScreen': (context) => const LoginScreen(),
        '/homeScreen': (context) => const HomeScreen(),
      },
    );
  }
}

