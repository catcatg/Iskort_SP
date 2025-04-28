import 'package:flutter/material.dart';

class HousingPage extends StatelessWidget {
  const HousingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Housing")),
      body: const Center(
        child: Text("Welcome to Housing", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
