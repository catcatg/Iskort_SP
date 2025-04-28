import 'package:flutter/material.dart';

class EstablishmentPage extends StatelessWidget {
  const EstablishmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Establishments")),
      body: const Center(
        child: Text(
          "Welcome to Establishments",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
