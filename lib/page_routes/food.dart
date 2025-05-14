import 'package:flutter/material.dart';
import 'package:iskort/reusables.dart';
import 'restaurants.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _allFoods = [
    {
      "name": "Adobo",
      "restaurant": "Juan’s Eatery",
      "location": "Miag-ao, Iloilo",
      "priceRange": "₱80–₱120",
      "image": "assets/images/angels.png",
    },
    {
      "name": "Sinigang",
      "restaurant": "Bahay Kubo Grill",
      "location": "Miag-ao, Iloilo",
      "priceRange": "₱90–₱130",
      "image": "assets/images/angels.png",
    },
    {
      "name": "Lechon",
      "restaurant": "Crispy Corner",
      "location": "Miag-ao, Iloilo",
      "priceRange": "₱150–₱200",
      "image": "assets/images/angels.png",
    },
    {
      "name": "Kare-Kare",
      "restaurant": "Kapamilya Karinderia",
      "location": "Miag-ao, Iloilo",
      "priceRange": "₱120–₱180",
      "image": "assets/images/angels.png",
    },
    {
      "name": "Tocino",
      "restaurant": "Juan’s Eatery",
      "location": "Miag-ao, Iloilo",
      "priceRange": "₱75–₱100",
      "image": "assets/images/angels.png",
    },
  ];

  List<Map<String, String>> _filteredFoods = [];

  @override
  void initState() {
    super.initState();
    _filteredFoods = _allFoods;
  }

  void _searchFood(String query) {
    final results =
        _allFoods
            .where(
              (food) =>
                  food["name"]!.toLowerCase().contains(query.toLowerCase()) ||
                  food["restaurant"]!.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();

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
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchFood,
              decoration: InputDecoration(
                hintText: 'Search food or restaurant',
                suffixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF0E1E1),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _filteredFoods.isEmpty
                    ? const Center(child: Text("No food found"))
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
                          onTap: () {
                            final restaurantMenu =
                                _allFoods
                                    .where(
                                      (item) =>
                                          item["restaurant"] ==
                                          food["restaurant"],
                                    )
                                    .toList();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => RestaurantProfilePage(
                                      restaurantName: food["restaurant"]!,
                                      location: food["location"]!,
                                      menu: restaurantMenu,
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0E1E1),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Image.asset(
                                      food["image"]!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    food["name"]!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    food["restaurant"]!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    food["location"]!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    food["priceRange"]!,
                                    style: const TextStyle(
                                      color: Color(0xFF7A1E1E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
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
}
