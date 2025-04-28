import 'package:flutter/material.dart';
import 'page_routes/food.dart';
import 'page_routes/housing.dart';
import 'page_routes/establishments.dart';
import 'page_routes/map_route.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cardNames = ['Food', 'Housing', 'Establishment', 'Route'];
    final cardIcons = [
      Icons.fastfood,
      Icons.home,
      Icons.store,
      Icons.directions,
    ];
    final cardPages = [
      const FoodPage(),
      const HousingPage(),
      const EstablishmentPage(),
      const RoutePage(),
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Hello Iska, \nCatherine!",
                  style: TextStyle(
                    color: Color(0xFF0A4423),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Spacer(),
                CircleAvatar(radius: 30, backgroundColor: Colors.grey[300]),
              ],
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                "What are you looking for today?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),

            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => cardPages[index]),
                        );
                      },
                      child: Container(
                        width: 150,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color.fromARGB(210, 149, 145, 145),
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
                                  color: Color(0xFF0A4423),
                                  size: 40,
                                ),
                                SizedBox(height: 10),
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

            SizedBox(height: 20),
            Text(
              "Recommended for you",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Column(
              children: [
                _buildRecommendation("Best Housing Deals"),
                _buildRecommendation("Top Restaurants"),
                _buildRecommendation("Nearest Routes"),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: "Location",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String title) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(Icons.star, color: Colors.green),
        title: Text(title),
      ),
    );
  }
}
