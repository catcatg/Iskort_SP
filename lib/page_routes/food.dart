import 'package:flutter/material.dart';

class FoodPage extends StatelessWidget {
  const FoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Food")),
      body: const Center(
        child: Text("Welcome to Food Page", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
