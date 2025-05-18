import 'package:flutter/material.dart';
import 'package:iskort/reusables.dart';
import 'page_routes/food.dart';
import 'page_routes/housing.dart';
import 'page_routes/map_route.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            /// Greeting
            Row(
              children: [
                Text(
                  "Hello Iska, \nCatherine!",
                  style: const TextStyle(
                    color: Color(0xFF0A4423),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  child: const Text("😊", style: TextStyle(fontSize: 24)),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "What are you looking for today?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            /// Horizontal category cards
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cardNames.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, cardRoutes[index]);
                      },
                      child: Container(
                        width: 150,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(210, 149, 145, 145),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  cardIcons[index],
                                  color: const Color(0xFF0A4423),
                                  size: 40,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  cardNames[index],
                                  style: const TextStyle(
                                    color: Color(0xFF0A4423),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Recommended for you",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            /// Product recommendation cards
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF791317),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Column(
                children: [
                  ProductCard(
                    title: "Angels Burger",
                    subtitle: "Unang kagat tinapay lahat.",
                    location: "In front of ginzu",
                    imagePath: "assets/images/angels.png",
                  ),
                  ProductCard(
                    title: "Angels Burger",
                    subtitle: "Unang kagat tinapay lahat.",
                    location: "In front of ginzu",
                    imagePath: "assets/images/angels.png",
                  ),
                  ProductCard(
                    title: "Angels Burger",
                    subtitle: "Unang kagat tinapay lahat.",
                    location: "In front of ginzu",
                    imagePath: "assets/images/angels.png",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/route');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}

/// ✅ Reusable ProductCard widget
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
            /// Image section
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade300,
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      color: Color(0xFF791317),
                      size: 40,
                    ),
              ),
            ),

            const SizedBox(width: 12),

            /// Text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF791317),
                    ),
                  ),
                  Text(subtitle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Color(0xFF791317),
                      ),
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
