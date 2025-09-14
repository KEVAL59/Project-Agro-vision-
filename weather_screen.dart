
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String _weatherData = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    const latitude = 23.0216;
    const longitude = 72.5797;
    const url =
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentWeather = data['current_weather'];
        setState(() {
          _weatherData = '''
            Temperature: ${currentWeather['temperature']}°C
            Wind Speed: ${currentWeather['windspeed']} km/h
            Wind Direction: ${currentWeather['winddirection']}°
            Weather Code: ${currentWeather['weathercode']}
          ''';
        });
      } else {
        setState(() {
          _weatherData = 'Failed to fetch weather data.';
        });
      }
    } catch (e) {
      setState(() {
        _weatherData = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Prediction'),
      ),
      body: Center(
        child: Text(_weatherData),
      ),
    );
  }
}
