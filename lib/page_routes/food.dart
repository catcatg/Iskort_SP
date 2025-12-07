import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> allFoods = [];
  List<Map<String, dynamic>> filteredFoods = [];
  bool isLoading = true;
  String lastSortOption = 'price_asc';

  @override
  void initState() {
    super.initState();
    filteredFoods = allFoods;
    _searchController.addListener(_onSearchChanged);
    fetchVerifiedEateries();
  }

  // Normalize API eatery into UI format
  Map<String, dynamic> normalizeEatery(Map eatery) {
    return {
      "name": eatery['name'] ?? '',
      "location": eatery['location'] ?? '',
      "price": eatery['min_price'] ?? 0,
      "priceRange": "₱${eatery['min_price'] ?? 'N/A'}",
      "image": eatery['eatery_photo'] ?? 'assets/images/placeholder.png',
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
          allFoods = verifiedEateries;
          filteredFoods = List.from(allFoods);
          _applySort(lastSortOption);
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

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredFoods = List.from(allFoods);
      } else {
        filteredFoods =
            allFoods.where((food) {
              final name = food["name"].toString().toLowerCase();
              final location = food["location"].toString().toLowerCase();
              return name.contains(query) || location.contains(query);
            }).toList();
      }
      _applySort(lastSortOption);
    });
  }

  void _applySort(String sortOption) {
    lastSortOption = sortOption;

    setState(() {
      switch (sortOption) {
        case 'price_asc':
          filteredFoods.sort((a, b) => a['price'].compareTo(b['price']));
          break;
        case 'price_desc':
          filteredFoods.sort((a, b) => b['price'].compareTo(a['price']));
          break;
        case 'name_asc':
          filteredFoods.sort((a, b) => a['name'].compareTo(b['name']));
          break;
        case 'name_desc':
          filteredFoods.sort((a, b) => b['name'].compareTo(a['name']));
          break;
      }
    });
  }

  String _getSortLabel(String option) {
    switch (option) {
      case 'price_asc':
        return 'Price: Low → High';
      case 'price_desc':
        return 'Price: High → Low';
      case 'name_asc':
        return 'Name: A → Z';
      case 'name_desc':
        return 'Name: Z → A';
      default:
        return 'Sort';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Food", style: TextStyle(color: Colors.white)),
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
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Color(0xFF0A4423), width: 1.5),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search food',
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

          // Sort menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  final selected = await showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(100, 100, 0, 0),
                    items: const [
                      PopupMenuItem(
                        value: 'price_asc',
                        child: Text('Price: Low → High'),
                      ),
                      PopupMenuItem(
                        value: 'price_desc',
                        child: Text('Price: High → Low'),
                      ),
                      PopupMenuItem(
                        value: 'name_asc',
                        child: Text('Name: A → Z'),
                      ),
                      PopupMenuItem(
                        value: 'name_desc',
                        child: Text('Name: Z → A'),
                      ),
                    ],
                  );
                  if (selected != null) _applySort(selected);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF0A4423),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _getSortLabel(lastSortOption),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Grid
          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0A4423),
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredFoods.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemBuilder: (_, i) {
                        final food = filteredFoods[i];
                        return FoodCard(
                          name: food["name"],
                          location: food["location"],
                          priceRange: food["priceRange"],
                          imagePath: food["image"],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class FoodCard extends StatefulWidget {
  final String name;
  final String location;
  final String priceRange;
  final String imagePath;

  const FoodCard({
    super.key,
    required this.name,
    required this.location,
    required this.priceRange,
    required this.imagePath,
  });

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                  ),
                ),
              ),

              // HEART
              Positioned(
                top: 14,
                right: 13,
                child: GestureDetector(
                  onTap: () => setState(() => isLiked = !isLiked),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // INFO
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.location,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.priceRange,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
