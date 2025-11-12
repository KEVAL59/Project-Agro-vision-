
import 'package:flutter/material.dart';
import 'dart:ui'; // Required for the blur effect (ImageFilter)
import 'dart:async'; // Required for simulating async operations
import 'package:http/http.dart' as http; // For making API calls
import 'dart:convert'; // For JSON decoding

import 'package:agrovision/screens/profile/profile_screen.dart'; // Import ProfileScreen
import 'package:geolocator/geolocator.dart';

// --- Data Models ---

class UserData {
  final String? fullName;
  final String? email;
  final String? mobile;
  final String? city;

  UserData({this.fullName, this.email, this.mobile, this.city});

  factory UserData.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return UserData(city: null);
    }
    return UserData(
      fullName: map['fullName'] as String?,
      email: map['email'] as String?,
      mobile: map['mobile'] as String?,
      city: map['city'] as String?,
    );
  }
}

class Weather {
  final String location;
  final double? temperature;
  final String condition;
  final IconData icon;
  final String? iconCode;

  Weather({
    required this.location,
    this.temperature,
    required this.condition,
    required this.icon,
    this.iconCode,
  });
}

class DashboardItem {
  final IconData icon;
  final String title;
  final String? routeName;
  final Color color;
  final Color startGradient;
  final Color endGradient;
  final Map<String, dynamic>? navigationArgs;

  DashboardItem({
    required this.icon,
    required this.title,
    this.routeName,
    required this.color,
    required this.startGradient,
    required this.endGradient,
    this.navigationArgs,
  });
}

// --- Weather Service ---
class WeatherService {
  final String _apiKey = "343a143fd37d6176444a02142e8232ed";
  final String _baseUrl = "https://api.openweathermap.org/data/2.5/weather";

  // NEW: Fetch weather using precise lat/lon coordinates for reliability
  Future<Weather> fetchWeatherByCoordinates(double lat, double lon) async {
    final Uri url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');
    return _processWeatherRequest(url);
  }

  // Fallback method for fetching by city name
  Future<Weather> fetchWeatherByCity({required String city}) async {
    final Uri url = Uri.parse('$_baseUrl?q=$city&appid=$_apiKey&units=metric');
    return _processWeatherRequest(url);
  }

  Future<Weather> _processWeatherRequest(Uri url) async {
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Weather(
          location: data['name'] ?? 'Unknown Location',
          temperature: (data['main']?['temp'] as num?)?.toDouble(),
          condition: data['weather']?[0]?['description'] ?? 'N/A',
          iconCode: data['weather']?[0]?['icon'] as String?,
          icon: _getWeatherIcon(data['weather']?[0]?['icon'] as String?),
        );
      } else if (response.statusCode == 404) {
        throw Exception('Weather data not found for location.');
      } else {
        throw Exception('API Error (Code: ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('Weather request timed out.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  IconData _getWeatherIcon(String? iconCode) {
    if (iconCode == null) return Icons.help_outline;
    if (iconCode.contains('01')) return Icons.wb_sunny;
    if (iconCode.contains('02') || iconCode.contains('03') || iconCode.contains('04')) return Icons.cloud;
    if (iconCode.contains('09') || iconCode.contains('10')) return Icons.grain;
    if (iconCode.contains('11')) return Icons.flash_on;
    if (iconCode.contains('13')) return Icons.ac_unit;
    if (iconCode.contains('50')) return Icons.foggy;
    return Icons.wb_sunny;
  }
}

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const DashboardScreen({super.key, this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _openWeatherApiKey = "343a143fd37d6176444a02142e8232ed";

  int _selectedIndex = 0; // 0 for Home, 1 for Profile
  late Future<Weather> _weatherFuture;
  final WeatherService _weatherService = WeatherService();
  UserData _currentUserData = UserData();

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _currentUserData = UserData.fromMap(widget.userData);
    }
    _weatherFuture = _fetchWeatherData();
  }

  Future<Weather> _fetchWeatherData() async {
    try {
      // 1. Attempt to get precise GPS position.
      final position = await _determinePosition();
      final weather = await _weatherService.fetchWeatherByCoordinates(position.latitude, position.longitude);

      // After a successful fetch, update the city name for other parts of the UI (like the Forecast button).
      if (mounted) {
        setState(() {
          _currentUserData = UserData(
              fullName: _currentUserData.fullName,
              email: _currentUserData.email,
              mobile: _currentUserData.mobile,
              city: weather.location); // Use the city name returned by the API.
        });
      }
      return weather;

    } catch (e) {
      // 2. This block catches ANY failure from the live location attempt (permissions, GPS signal, etc.).
      print("Live location failed, falling back to profile city. Reason: ${e.toString()}");

      // 3. Attempt to use the fallback city from the user's profile.
      if (_currentUserData.city != null && _currentUserData.city!.isNotEmpty && _currentUserData.city!.toLowerCase() != 'n/a') {
        return _weatherService.fetchWeatherByCity(city: _currentUserData.city!);
      } else {
        // 4. If the fallback ALSO fails, show a clear error to the user.
        // We re-throw the original, more specific error from the location attempt.
        throw Exception(e.toString().replaceAll("Exception: ", ""));
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, please enable them in settings.');
    }

    return await Geolocator.getCurrentPosition();
  }


  List<DashboardItem> get dashboardItems => [
    DashboardItem(
        icon: Icons.camera_alt_outlined,
        title: 'Scan Crop',
        routeName: '/scanner',
        color: Colors.green,
        startGradient: Colors.green.shade300,
        endGradient: Colors.green.shade600),
    DashboardItem(
        icon: Icons.storefront_outlined,
        title: 'Market Prices',
        routeName: '/market',
        color: Colors.teal,
        startGradient: Colors.teal.shade300,
        endGradient: Colors.teal.shade600),
    DashboardItem(
        icon: Icons.show_chart_outlined,
        title: 'Forecast',
        routeName: '/forecast',
        color: Colors.orange,
        startGradient: Colors.orange.shade300,
        endGradient: Colors.orange.shade600,
        navigationArgs: {
          'city': _currentUserData.city ?? 'Unknown',
          'apiKey': _openWeatherApiKey,
        }),
    DashboardItem(
        icon: Icons.article_outlined,
        title: 'Govt. Schemes',
        routeName: '/schemes',
        color: Colors.purple,
        startGradient: Colors.purple.shade300,
        endGradient: Colors.purple.shade600),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  AppBar? _buildHomeAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Agrovision',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24.0)),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: <Widget>[
        if (_currentUserData.fullName != null && _currentUserData.fullName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text('Welcome, ${_currentUserData.fullName!.split(' ').first}',
                  style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87, fontSize: 16)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      ProfileScreen(userData: widget.userData),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0 ? _buildHomeAppBar() : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green.shade600,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            _buildWeatherHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                itemCount: dashboardItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.0,
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
    );
  }

  Widget _buildWeatherHeader() {
    return FutureBuilder<Weather>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 150,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
                color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
            child: const Center(child: CircularProgressIndicator(color: Colors.grey)),
          );
        }
        if (snapshot.hasError) {
          return Container(
            height: 150,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
                color: Colors.red[100], borderRadius: BorderRadius.circular(20)),
            child: Center(
              child: Text('${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[900], fontFamily: 'Poppins', fontSize: 15)),
            ),
          );
        }
        if (snapshot.hasData) {
          final weather = snapshot.data!;
          return Container(
            height: 150,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
                color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(weather.location, style: const TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 22, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(weather.condition, style: TextStyle(fontFamily: 'Poppins', color: Colors.black54, fontSize: 16), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: [
                    Icon(weather.icon, color: Colors.orangeAccent, size: 38),
                    const SizedBox(width: 10),
                    Text(
                      weather.temperature != null ? '${weather.temperature!.toStringAsFixed(1)}°C' : '--°C',
                      style: const TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const SizedBox(height: 150); // Fallback size
      },
    );
  }
}

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
        Future.delayed(const Duration(milliseconds: 150), () {
          if (widget.item.routeName != null) {
            Navigator.pushNamed(context, widget.item.routeName!, arguments: widget.item.navigationArgs);
          }
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.item.startGradient,
                widget.item.endGradient,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(widget.item.icon, size: 52.0, color: Colors.white),
              const SizedBox(height: 16.0),
              Text(widget.item.title, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
