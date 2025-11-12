
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

// Data Model for a single forecast entry
class ForecastEntry {
  final String time; // Formatted time string for the list
  final DateTime dateTime; // Actual DateTime for chart plotting
  final double temperature;
  final String condition;
  final IconData icon;
  final String rawIconCode;

  ForecastEntry({
    required this.time,
    required this.dateTime,
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.rawIconCode,
  });
}

class ForecastScreen extends StatefulWidget {
  final String city;
  final String apiKey;

  const ForecastScreen({super.key, required this.city, required this.apiKey});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  late Future<List<ForecastEntry>> _forecastFuture;

  @override
  void initState() {
    super.initState();
    _forecastFuture = _fetchForecastData(widget.city, widget.apiKey);
  }

  Future<List<ForecastEntry>> _fetchForecastData(String city, String apiKey) async {
    final Uri url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forecastList = data['list'];
        final List<ForecastEntry> tomorrowEntries = [];
        
        final now = DateTime.now();
        final tomorrowDate = DateUtils.dateOnly(now.add(const Duration(days: 1)));
        
        for (var item in forecastList) {
          final int timestamp = item['dt'];
          final forecastDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true).toLocal();
          final forecastDate = DateUtils.dateOnly(forecastDateTime);

          if (forecastDate.isAtSameMomentAs(tomorrowDate)) {
            final rawIcon = item['weather'][0]['icon'] as String? ?? '';
            tomorrowEntries.add(
              ForecastEntry(
                time: TimeOfDay.fromDateTime(forecastDateTime).format(context), 
                dateTime: forecastDateTime,
                temperature: (item['main']['temp'] as num).toDouble(),
                condition: item['weather'][0]['description'] as String? ?? 'N/A',
                icon: _getWeatherIcon(rawIcon),
                rawIconCode: rawIcon,
              ),
            );
          }
        }
        if (tomorrowEntries.isEmpty) {
          throw Exception('No forecast data available for tomorrow in $city.');
        }
        tomorrowEntries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        return tomorrowEntries;
      } else if (response.statusCode == 404) {
        throw Exception('City not found for forecast: $city');
      } else {
        throw Exception('Failed to load forecast (Error: ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('Forecast request timed out. Check your connection.');
    } catch (e) {
      throw Exception('Error fetching forecast: ${e.toString()}');
    }
  }

  IconData _getWeatherIcon(String? iconCode) {
    if (iconCode == null) return Icons.help_outline;
    switch (iconCode) {
      case '01d': return Icons.wb_sunny_outlined;
      case '01n': return Icons.nights_stay_outlined;
      case '02d': return Icons.cloud_outlined;
      case '02n': return Icons.cloud_outlined;
      case '03d': case '03n': return Icons.cloud;
      case '04d': case '04n': return Icons.cloudy_snowing;
      case '09d': case '09n': return Icons.grain;
      case '10d': return Icons.wb_cloudy_outlined;
      case '10n': return Icons.wb_cloudy_outlined;
      case '11d': case '11n': return Icons.flash_on_outlined;
      case '13d': case '13n': return Icons.ac_unit_outlined;
      case '50d': case '50n': return Icons.foggy;
      default: return Icons.help_outline;
    }
  }

  Widget _buildTemperatureChart(List<ForecastEntry> forecastEntries) {
    if (forecastEntries.isEmpty) return const SizedBox.shrink();

    List<FlSpot> spots = forecastEntries.map((entry) {
      double xValue = entry.dateTime.hour + (entry.dateTime.minute / 60.0);
      return FlSpot(xValue, entry.temperature);
    }).toList();

    double minTemp = forecastEntries.map((e) => e.temperature).reduce(math.min);
    double maxTemp = forecastEntries.map((e) => e.temperature).reduce(math.max);
    minTemp = (minTemp - 2).floorToDouble(); 
    maxTemp = (maxTemp + 2).ceilToDouble();
    if (minTemp == maxTemp) {
        minTemp -= 2;
        maxTemp += 2;
    }

    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, right: 20, bottom: 10), 
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 24,
            minY: minTemp,
            maxY: maxTemp,
            backgroundColor: Colors.grey[100],
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
              getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300, width: 1)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text('${value.toInt()}°C', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 3,
                  getTitlesWidget: (value, meta) => Text(value.toInt().toString().padLeft(2, '0'), style: const TextStyle(color: Colors.black54, fontSize: 10)),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.orangeAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                    show: true, 
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.orange, strokeColor: Colors.white, strokeWidth: 1)
                ),
                belowBarData: BarAreaData(show: true, color: Colors.orangeAccent.withOpacity(0.2)),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Forecast for ${widget.city}',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<ForecastEntry>>(
        future: _forecastFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.grey));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[900], fontFamily: 'Poppins', fontSize: 16),
                ),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final forecastEntries = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTemperatureChart(forecastEntries),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      'Hourly Details',
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: forecastEntries.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey[200], height: 1),
                    itemBuilder: (context, index) {
                      final entry = forecastEntries[index];
                      return ListTile(
                        leading: Icon(entry.icon, color: Colors.orangeAccent, size: 36),
                        title: Text(
                          '${entry.time}: ${entry.temperature.toStringAsFixed(1)}°C',
                          style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          entry.condition,
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.black54, fontSize: 15),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Text(
                'No forecast data available for tomorrow in ${widget.city}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600], fontSize: 16),
              ),
            );
          }
        },
      ),
    );
  }
}
