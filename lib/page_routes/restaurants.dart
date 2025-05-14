import 'package:flutter/material.dart';

class RestaurantProfilePage extends StatelessWidget {
  final String restaurantName;
  final String location;
  final List<Map<String, String>> menu;

  const RestaurantProfilePage({
    super.key,
    required this.restaurantName,
    required this.location,
    required this.menu,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF0E1E1),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurantName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(location, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Menu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final food = menu[index];
                return ListTile(
                  leading: Image.asset(
                    food["image"]!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(food["name"]!),
                  subtitle: Text(food["priceRange"]!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
