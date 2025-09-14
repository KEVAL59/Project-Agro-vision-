
import 'package:flutter/material.dart';
import 'dart:ui'; // Required for the blur effect (ImageFilter)
import 'dart:async'; // Required for simulating async operations

// --- Data Models ---

// A simple model for our weather data
class Weather {
  final String location;
  final int temperature;
  final String condition;
  final IconData icon;

  Weather({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.icon,
  });
}

// Helper class for dashboard items
class DashboardItem {
  final IconData icon;
  final String title;
  final String? routeName;
  final Color color;
  final Color startGradient;
  final Color endGradient;

  DashboardItem({
    required this.icon,
    required this.title,
    this.routeName,
    required this.color,
    required this.startGradient,
    required this.endGradient,
  });
}

// --- Mock Service for Weather Data ---
// In a real app, this would fetch data from a weather API
class WeatherService {
  Future<Weather> fetchWeather() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));
    // Return mock data
    return Weather(
      location: 'Gandhinagar',
      temperature: 31,
      condition: 'Clear Sky',
      icon: Icons.wb_sunny_outlined,
    );
  }
}


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Weather> _weatherFuture;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    // Start fetching weather data when the screen is initialized
    _weatherFuture = _weatherService.fetchWeather();
  }

  // Define the items for our dashboard with new gradient colors
  final List<DashboardItem> dashboardItems = [
    DashboardItem(
      icon: Icons.person_outline,
      title: 'Profile',
      routeName: '/profile',
      color: Colors.blue.shade300,
      startGradient: Colors.blue.shade300,
      endGradient: Colors.blue.shade600,
    ),
    DashboardItem(
      icon: Icons.camera_alt_outlined,
      title: 'Scan Crop',
      routeName: '/scanner',
      color: Colors.green.shade300,
      startGradient: Colors.green.shade300,
      endGradient: Colors.green.shade600,
    ),
    DashboardItem(
      icon: Icons.storefront_outlined,
      title: 'Market Prices',
      routeName: '/market',
      color: Colors.teal.shade300,
      startGradient: Colors.teal.shade300,
      endGradient: Colors.teal.shade600,
    ),
    DashboardItem(
      icon: Icons.article_outlined,
      title: 'Govt. Schemes',
      routeName: '/schemes',
      color: Colors.purple.shade300,
      startGradient: Colors.purple.shade300,
      endGradient: Colors.purple.shade600,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Agrovision',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black, // Match scaffold background
        elevation: 0, // No shadow for a seamless look
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // const SizedBox(height: 20), // Can be removed or adjusted if AppBar provides enough spacing
              // --- Weather Header ---
              _buildWeatherHeader(),
              const SizedBox(height: 30),
              // --- Dashboard Grid ---
              Expanded(
                child: GridView.builder(
                  itemCount: dashboardItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.0, // Made items square for a better look
                  ),
                  itemBuilder: (context, index) {
                    final item = dashboardItems[index];
                    return AnimatedGridItem(item: item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Weather Header Widget ---
  Widget _buildWeatherHeader() {
    return FutureBuilder<Weather>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        // --- Loading State ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        // --- Error State ---
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load weather', style: TextStyle(color: Colors.red.shade300)));
        }
        // --- Success State ---
        if (snapshot.hasData) {
          final weather = snapshot.data!;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26), // Fixed: withOpacity -> withAlpha
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(51)), // Fixed: withOpacity -> withAlpha
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.location,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.condition,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey[300],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(weather.icon, color: Colors.yellow.shade300, size: 36),
                    const SizedBox(width: 10),
                    Text(
                      '${weather.temperature}°C',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// --- Animated Grid Item Widget ---
class AnimatedGridItem extends StatefulWidget {
  final DashboardItem item;

  const AnimatedGridItem({super.key, required this.item});

  @override
  State<AnimatedGridItem> createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<AnimatedGridItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // Add a small delay for the animation to complete before navigating
        Future.delayed(const Duration(milliseconds: 150), () {
          if (widget.item.routeName != null) {
            // In a real app, you would use Navigator.pushNamed
            // print("Navigating to ${widget.item.routeName}"); // Commented out print statement
            Navigator.pushNamed(context, widget.item.routeName!); // Uncommented for actual navigation
          }
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.item.startGradient.withAlpha(102), // Fixed: withOpacity -> withAlpha
                    widget.item.endGradient.withAlpha(102), // Fixed: withOpacity -> withAlpha
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.white.withAlpha(51)), // Fixed: withOpacity -> withAlpha
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(widget.item.icon, size: 52.0, color: widget.item.color),
                  const SizedBox(height: 16.0),
                  Text(
                    widget.item.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(230), // Fixed: withOpacity -> withAlpha
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
