import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reusables.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List eateries = [];
  bool isLoading = true;

  Future<void> fetchEateries() async {
    try {
      final response = await http.get(Uri.parse('https://iskort-public-web.onrender.com/api/eateries'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          eateries = data['eateries'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching eateries: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchEateries();
  }

  @override
  Widget build(BuildContext context) {
    final cardNames = ['Food', 'Housing', 'Route'];
    final cardIcons = [Icons.fastfood, Icons.home, Icons.directions];
    final cardRoutes = ['/food', '/housing', '/route'];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text(
                  "Hello Iska, \nCatherine!",
                  style: TextStyle(
                    color: Color(0xFF0A4423),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Spacer(),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey,
                  child: Text("😊", style: TextStyle(fontSize: 24)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Recommended for you", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (eateries.isEmpty)
              // Default Angel's Burger if no eateries
              const ProductCard(
                title: "Angel's Burger",
                subtitle: "Unang kagat tinapay lahat.",
                location: "In front of Ginzu",
                imagePath: "assets/images/angels.png",
              )
            else
              Column(
                children: eateries.map((eatery) {
                  return ProductCard(
                    title: eatery['name'],
                    subtitle: "Tap to view menu",
                    location: eatery['location'],
                    imagePath: eatery['photo'] ?? "assets/images/placeholder.png",
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/route');
          if (index == 2) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String location;
  final String imagePath;

  const ProductCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade300,
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: Color(0xFF791317)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF791317))),
                  Text(subtitle),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF791317)),
                      const SizedBox(width: 4),
                      Flexible(child: Text(location)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
