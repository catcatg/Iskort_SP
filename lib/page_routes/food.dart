import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iskort/widgets/reusables.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allFoods = [];
  List<Map<String, dynamic>> _filteredFoods = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVerifiedEateries();
    _searchController.addListener(() {
      _searchFood(_searchController.text);
    });
  }

  // Normalize API eatery into UI format
  Map<String, dynamic> normalizeEatery(Map eatery) {
    return {
      "name": eatery['name'] ?? '',
      "restaurant": eatery['name'] ?? '',
      "location": eatery['location'] ?? '',
      "priceRange": "₱${eatery['min_price'] ?? 'N/A'}",
      "image": eatery['eatery_photo'] ?? 'assets/images/placeholder.png',
      "open_time": eatery['open_time'] ?? '',
      "end_time": eatery['end_time'] ?? '',
    };
  }

  Future<void> fetchVerifiedEateries() async {
    try {
      final resp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/eatery'),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final verifiedEateries =
            (data['eateries'] ?? [])
                .where((e) => e['is_verified'] == 1)
                .map<Map<String, dynamic>>((e) => normalizeEatery(e))
                .toList();

        setState(() {
          _allFoods = verifiedEateries;
          _filteredFoods = verifiedEateries;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching eateries: $e");
      setState(() => isLoading = false);
    }
  }

  void _searchFood(String query) {
    final results =
        _allFoods.where((food) {
          final name = food["name"].toString().toLowerCase();
          final restaurant = food["restaurant"].toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              restaurant.contains(query.toLowerCase());
        }).toList();

    setState(() {
      _filteredFoods = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Food"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
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
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF0A4423), width: 1.5),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search food or restaurant',
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search, color: Color(0xFF0A4423)),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredFoods.isEmpty
                    ? const Center(child: Text("No eateries found"))
                    : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.70,
                          ),
                      itemCount: _filteredFoods.length,
                      itemBuilder: (context, index) {
                        final food = _filteredFoods[index];
                        return GestureDetector(
                          onTap: () => _showEateryDetails(food),
                          child: Card(
                            child: Column(
                              children: [
                                Image.network(
                                  food['image'],
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 40,
                                      ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(food['location']),
                                      Text(food['priceRange']),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/homepage');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  void _showEateryDetails(Map<String, dynamic> eatery) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(eatery['name']),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  eatery['image'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 12),
                Text("Location: ${eatery['location']}"),
                Text("Minimum Price: ${eatery['priceRange']}"),
                Text("Open: ${eatery['open_time']}"),
                Text("Close: ${eatery['end_time']}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }
}
