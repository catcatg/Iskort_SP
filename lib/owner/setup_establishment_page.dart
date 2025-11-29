import 'package:flutter/material.dart';

class SetupEstablishmentPage extends StatelessWidget {
  const SetupEstablishmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set up your business")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Choose the type of establishment:"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/setup-food');
              },
              child: const Text("🍔 Food"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/setup-lodging');
              },
              child: const Text("🏨 Lodging"),
            ),
          ],
        ),
      ),
    );
  }
}
