
import 'package:flutter/material.dart';

class MarketPriceScreen extends StatelessWidget {
  const MarketPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Prices'),
      ),
      body: const Center(
        child: Text('Market Price Screen'),
      ),
    );
  }
}
