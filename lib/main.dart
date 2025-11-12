
import 'package:flutter/material.dart';
import 'package:agrovision/screens/auth/login_screen.dart';
import 'package:agrovision/screens/auth/signup_screen.dart';
import 'package:agrovision/screens/profile/profile_screen.dart';
import 'package:agrovision/screens/weather/weather_screen.dart';
import 'package:agrovision/screens/market/market_price_screen.dart';
import 'package:agrovision/screens/dashboard/dashboard_screen.dart';
import 'package:agrovision/screens/weather/forecast_screen.dart';
import 'package:agrovision/screens/onboarding_screen.dart';
import 'package:agrovision/database/database_helper.dart';

// All localization and provider logic has been removed.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroVision', // Reverted to a hardcoded title
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        fontFamily: 'Poppins',
      ),
      // All localization properties have been removed.
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) {
          final userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ProfileScreen(userData: userData);
        },
        '/weather': (context) => const WeatherScreen(),
        '/market': (context) => const MarketPriceScreen(),
        '/dashboard': (context) {
          final userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return DashboardScreen(userData: userData);
        },
        '/forecast': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final city = args?['city'] as String?;
          final apiKey = args?['apiKey'] as String?;

          if (city == null || apiKey == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Error', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              backgroundColor: Colors.black,
              body: const Center(
                child: Text(
                  'Forecast data is currently unavailable. Please ensure your city is set correctly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            );
          }
          return ForecastScreen(city: city, apiKey: apiKey);
        },
      },
    );
  }
}
