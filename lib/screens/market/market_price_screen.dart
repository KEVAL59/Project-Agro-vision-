
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import for TimeoutException

// Data Model for Mandi Price records
class MandiPrice {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String grade;
  final int minPrice;
  final int maxPrice;
  final int modalPrice;
  final String priceUnit;
  final DateTime arrivalDate;

  MandiPrice({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.grade,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.priceUnit,
    required this.arrivalDate,
  });

  factory MandiPrice.fromJson(Map<String, dynamic> json) {
    return MandiPrice(
      state: json['state'] ?? 'N/A',
      district: json['district'] ?? 'N/A',
      market: json['market'] ?? 'N/A',
      commodity: json['commodity'] ?? 'N/A',
      variety: json['variety'] ?? 'Standard',
      grade: json['grade'] ?? 'N/A',
      minPrice: int.tryParse(json['min_price'] ?? '0') ?? 0,
      maxPrice: int.tryParse(json['max_price'] ?? '0') ?? 0,
      modalPrice: int.tryParse(json['modal_price'] ?? '0') ?? 0,
      priceUnit: json['price_unit'] ?? 'Rs/Quintal',
      arrivalDate: DateTime.tryParse(json['arrival_date'] ?? '') ?? DateTime.now(),
    );
  }
}

class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen> {
  late Future<List<MandiPrice>> _marketDataFuture;
  String _targetDistrict = 'RAJKOT';

  // API Configuration from your script
  final String _apiKey = "579b464db66ec23bdd000001260d416bdd7249327cf76dba0cd49101";
  final String _resourceId = "9ef84268-d588-465a-a308-a864a43d0070";
  final String _targetState = 'GUJARAT';

  // List of districts for suggestions
  static const List<String> _kGujaratDistricts = <String>[
    'AHMEDABAD', 'AMRELI', 'ANAND', 'ARAVALLI', 'BANASKANTHA', 'BHARUCH', 
    'BHAVNAGAR', 'BOTAD', 'CHHOTA UDAIPUR', 'DAHOD', 'DANG', 'DEVBHOOMI DWARKA', 
    'GANDHINAGAR', 'GIR SOMNATH', 'JAMNAGAR', 'JUNAGADH', 'KHEDA', 'KUTCH', 
    'MAHISAGAR', 'MEHSANA', 'MORBI', 'NARMADA', 'NAVSARI', 'PANCHMAHAL', 
    'PATAN', 'PORBANDAR', 'RAJKOT', 'SABARKANTHA', 'SURAT', 'SURENDRANAGAR', 
    'TAPI', 'VADODARA', 'VALSAD',
  ];

  @override
  void initState() {
    super.initState();
    _marketDataFuture = _fetchMarketData(_targetDistrict);
  }

  Future<List<MandiPrice>> _fetchMarketData(String district) async {
    final String apiEndpoint = "https://api.data.gov.in/resource/$_resourceId";
    final Map<String, String> params = {
      'api-key': _apiKey,
      'format': 'json',
      'limit': '100',
      'filters[state]': _targetState,
      'filters[district]': district.toUpperCase(),
    };

    final Uri uri = Uri.parse(apiEndpoint).replace(queryParameters: params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['records'] is List) {
          final List<dynamic> records = data['records'];
          if (records.isEmpty) {
            throw Exception('No commodity records found for ${district.toUpperCase()}.');
          }
          return records.map((json) => MandiPrice.fromJson(json)).toList();
        } else {
          throw Exception('Invalid data format received from API.');
        }
      } else {
        throw Exception('API Error (Code: ${response.statusCode})');
      }
    } on TimeoutException {
        throw Exception('The request timed out. Please check your connection.');
    } on http.ClientException {
        throw Exception('A network error occurred. Please try again later.');
    }
  }

  // --- UPDATED to take district as a parameter ---
  void _updateMarketData(String district) {
    final String searchedDistrict = district.trim();
    if (searchedDistrict.isNotEmpty) {
      setState(() {
        _targetDistrict = searchedDistrict.toUpperCase();
        _marketDataFuture = _fetchMarketData(_targetDistrict);
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: _buildSearchBar(),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black26,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<MandiPrice>>(
        future: _marketDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  snapshot.error.toString().replaceAll("Exception: ", ""),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[800], fontSize: 16, fontFamily: 'Poppins'),
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final prices = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: prices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = prices[index];
                return Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.commodity,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.storefront, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item.market} (${item.variety})',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey[200]),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Modal Price:',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.black54),
                            ),
                            Text(
                              '₹${item.modalPrice} / ${item.priceUnit.replaceAll("Rs/", "")}',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text(
                'No market data available at this time.',
                style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
              ),
            );
          }
        },
      ),
    );
  }

  // --- UPDATED for simpler logic ---
  Widget _buildSearchBar() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _targetDistrict),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return _kGujaratDistricts.where((String option) {
          return option.contains(textEditingValue.text.toUpperCase());
        });
      },
      onSelected: (String selection) {
        _updateMarketData(selection);
      },
      fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: fieldController,
            focusNode: fieldFocusNode,
            onSubmitted: (String value) => _updateMarketData(value),
            decoration: InputDecoration(
              hintText: 'Search District...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.green),
                onPressed: () => _updateMarketData(fieldController.text),
              ),
            ),
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        );
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 48, // Match screen padding
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(option, style: const TextStyle(fontFamily: 'Poppins')),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
