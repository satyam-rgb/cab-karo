import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaroCabApp());
}

class KaroCabApp extends StatefulWidget {
  const KaroCabApp({super.key});

  @override
  State<KaroCabApp> createState() => _KaroCabAppState();
}

class _KaroCabAppState extends State<KaroCabApp> {
  bool _isOnboarded = false;
  bool _isLoggedIn = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  void _checkInitialState() async {
    final onboarded = await StorageService.isOnboarded();
    final profile = await StorageService.getUserProfile();

    if (mounted) {
      setState(() {
        _isOnboarded = onboarded;
        _isLoggedIn = profile != null;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'KaroCab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: !_isOnboarded
          ? OnboardingScreen(
              onComplete: () => setState(() => _isOnboarded = true),
            )
          : !_isLoggedIn
              ? LoginScreen(
                  onLoginSuccess: () => setState(() => _isLoggedIn = true),
                )
              : HomeScreen(
                  onLogout: () => setState(() => _isLoggedIn = false),
                ),
    );
  }
}
