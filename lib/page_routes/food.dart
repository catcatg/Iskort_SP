import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iskort/page_routes/map_route.dart';
import 'package:iskort/page_routes/view_estab_profile.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  List<Map<String, dynamic>> allFoods = [];
  List<Map<String, dynamic>> filteredFoods = [];
  bool isLoading = true;

  List<String> selectedTags = [];
  List<String> availableTags = [];
  double? maxBudget;

  String sortOrder = "none";
  String nameQuery = "";
  String filterMode = "name"; 

  TextEditingController? _tagAutocompleteController;


  @override
  void initState() {
    super.initState();
    fetchVerifiedFoods();
  }

  Future<void> fetchVerifiedFoods() async {
    setState(() => isLoading = true);
    try {
      final eateryResp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/eatery'),
      );
      if (eateryResp.statusCode != 200)
        throw Exception('Failed to load eateries');

      final eateryData = jsonDecode(eateryResp.body);
      final verifiedEateries = (eateryData['eateries'] ?? []).where(
        (e) => e['is_verified'] == 1,
      );

      List<Map<String, dynamic>> foods = [];
      Set<String> tagsSet = {};

      for (var eatery in verifiedEateries) {
        final eateryId = eatery['eatery_id'];
        final eateryName = eatery['name'] ?? '';
        final eateryLocation = eatery['location'] ?? ''; // get location

        final foodResp = await http.get(
          Uri.parse(
            'https://iskort-public-web.onrender.com/api/food/$eateryId',
          ),
        );
        if (foodResp.statusCode != 200) continue;

        final foodData = jsonDecode(foodResp.body);
        for (var f in foodData['foods'] ?? []) {
          final classification = f['classification'] ?? '';
          foods.add({
            "name": f['name'] ?? '',
            "classification": classification,
            "price": double.tryParse(f['price'].toString()) ?? 0,
            "image": f['food_pic'] ?? '',
            "eateryName": eateryName,
            "location": eateryLocation,
            "eatery_id": eateryId.toString(),
            "owner_id": eatery['owner_id']?.toString() ?? '',
          });

          if (classification.isNotEmpty) tagsSet.add(classification);
        }
      }

      foods.sort((a, b) => a['name'].compareTo(b['name']));

      setState(() {
        allFoods = foods;
        filteredFoods = List.from(foods);
        availableTags = tagsSet.toList()..sort();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching foods: $e");
      setState(() => isLoading = false);
    }
  }

  void _applySort() {
  if (sortOrder == "low") {
    filteredFoods.sort((a, b) => a['price'].compareTo(b['price']));
  } else if (sortOrder == "high") {
    filteredFoods.sort((a, b) => b['price'].compareTo(a['price']));
  }
}

  void applyFilters() {
  setState(() {
    if (filterMode == "name") {
      filteredFoods = allFoods.where((f) =>
          f['name']
              .toLowerCase()
              .contains(nameQuery.toLowerCase())).toList();
    } else {
      filteredFoods = allFoods.where((food) {
        final matchesTag =
            selectedTags.isEmpty ||
            selectedTags.contains(food['classification']);

        final matchesBudget =
            maxBudget == null || food['price'] <= maxBudget!;

        return matchesTag && matchesBudget;
      }).toList();
    }

    _applySort();
  });
}


  void _showFoodDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40), 
                        AspectRatio(
                          aspectRatio: 1.2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item['image'] ?? '',
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      const Icon(Icons.image, size: 32),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['name'] ?? 'Details',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Classification: ${item['classification'] ?? ''}"),
                        const SizedBox(height: 4),
                        Text("Price: ₱${item['price'] ?? ''}"),
                        Text("Eatery Name: ${item['eateryName'] ?? ''}"),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A4423),
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => EstabProfileForCustomer(
                                      ownerId: item['owner_id'] ?? '',
                                      estType: 'Eatery',
                                      eateryId: item['eatery_id'],
                                      housingId: null,
                                    ),
                              ),
                            );
                          },
                          child: const Text(
                            "View Establishment Profile",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (item['location'] != null && item['location'] != '')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A4423),
                              minimumSize: const Size(double.infinity, 45),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => MapRoutePage(
                                        initialLocation:
                                            item['location'].toString(),
                                      ),
                                ),
                              );
                            },
                            child: const Text(
                              "View Route",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Top-right close button
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  final nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food', style: TextStyle(color: Colors.white)),
        leading: BackButton(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [_buildSearchBars(), Expanded(child: _buildGrid())],
        ),
      ),
    );
  }

  bool get isTagModeActive => selectedTags.isNotEmpty;
  bool get isNameModeActive => nameQuery.isNotEmpty;


 Widget _buildSearchBars() {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode selector
        Row(
          children: [
            ChoiceChip(
              label: const Text("Search by Name"),
              selected: filterMode == "name",
              onSelected: (_) {
                setState(() {
                  filterMode = "name";
                  nameQuery = "";
                  selectedTags.clear();
                  maxBudget = null;
                  applyFilters();
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text("Search by Preference"),
              selected: filterMode == "tags",
              onSelected: (_) {
                setState(() {
                  filterMode = "tags";
                  nameQuery = "";
                  applyFilters();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search by name
        if (filterMode == "name") ...[
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
              return allFoods.map((f) => f['name'] as String).where((name) =>
                name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (selection) {
              setState(() {
                nameQuery = selection;
                applyFilters();
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (val) {
                  setState(() {
                    nameQuery = val;
                    applyFilters();
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Search Food by Name",
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight, // dropdown on the right side
            child: DropdownButton<String>(
              value: sortOrder,
              items: const [
                DropdownMenuItem(value: "none", child: Text("Sort by")),
                DropdownMenuItem(value: "low", child: Text("Price: Low to High")),
                DropdownMenuItem(value: "high", child: Text("Price: High to Low")),
              ],
              onChanged: (val) {
                setState(() {
                  sortOrder = val!;
                  _applySort();
                });
              },
            ),
          ),
        ],

        // Search by preference
        if (filterMode == "tags") ...[
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return availableTags.where((tag) =>
                tag.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (selection) {
              setState(() {
                if (!selectedTags.contains(selection)) {
                  selectedTags.add(selection);
                  applyFilters();
                }

                // clear input field
                _tagAutocompleteController?.clear();
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              _tagAutocompleteController = controller;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: "Search Food by Type (e.g., Alcoholic Drinks, Snacks, Desserts, etc.)",
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),

          Wrap(
            spacing: 6,
            children: selectedTags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() {
                  selectedTags.remove(tag);
                  applyFilters();
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Max Budget: ₱'),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    hintText: 'Enter amount',
                  ),
                  onChanged: (val) {
                    maxBudget = double.tryParse(val);
                    applyFilters();
                  },
                ),
              ),
              const Spacer(), // pushes dropdown to the opposite side
              DropdownButton<String>(
                value: sortOrder,
                items: const [
                  DropdownMenuItem(value: "none", child: Text("Sort by")),
                  DropdownMenuItem(value: "low", child: Text("Price: Low to High")),
                  DropdownMenuItem(value: "high", child: Text("Price: High to Low")),
                ],
                onChanged: (val) {
                  setState(() {
                    sortOrder = val!;
                    _applySort();
                  });
                },
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

  Widget _buildGrid() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (filteredFoods.isEmpty)
      return const Center(child: Text('No foods found with current filters.'));

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredFoods.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (_, i) {
        final food = filteredFoods[i];
        return GestureDetector(
          onTap: () => _showFoodDetails(food),
          child: _FoodCard(food: food),
        );
      },
    );
  }
}

class _FoodCard extends StatelessWidget {
  final Map<String, dynamic> food;
  const _FoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                food['image'],
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        food['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₱${food['price'].toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    food['eateryName'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                  Text(
                    food['location'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 15),

                  Text(
                    food['classification'],
                    style: const TextStyle(
                      color: Color.fromARGB(255, 133, 133, 133),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
