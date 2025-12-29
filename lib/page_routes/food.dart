import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iskort/page_routes/map_route.dart';
import 'package:iskort/page_routes/view_estab_profile.dart';
import 'package:flutter/services.dart'; // <-- needed for input formatters

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
      filteredFoods =
          allFoods.where((food) {
            // Name, classification, or eatery name search
            final searchMatch =
                nameQuery.isEmpty ||
                food['name'].toLowerCase().contains(nameQuery.toLowerCase()) ||
                food['classification'].toLowerCase().contains(
                  nameQuery.toLowerCase(),
                ) ||
                food['eateryName'].toLowerCase().contains(
                  nameQuery.toLowerCase(),
                );

            // Tags filter
            final tagsMatch =
                selectedTags.isEmpty ||
                selectedTags.contains('All') || // "All" bypasses tag filtering
                selectedTags.contains(food['classification']);

            // Max budget filter
            final budgetMatch =
                maxBudget == null || food['price'] <= maxBudget!;

            return searchMatch && tagsMatch && budgetMatch;
          }).toList();

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

  TextEditingController _searchController = TextEditingController();
  bool tagsExpanded = false;

  Widget _buildSearchBars() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search bar + Tags button
          Row(
            children: [
              Expanded(child: generalSearchBar()),
              const SizedBox(width: 8),
              tagsTrigger(),
            ],
          ),

          // Expanded tags list
          tagsList(),

          // Display selected tags as chips
          selectedTagsDisplay(),

          const SizedBox(height: 12),

          // Row 2: Max budget + sort
          Row(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Amount ₱',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 5),
                  SizedBox(
                    width: 120,
                    height: 40,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 14),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(
                            color: Color(0xFF0A4423),
                            width: 1.5,
                          ),
                        ),
                        hintText: 'Enter amount',
                      ),
                      onChanged: (val) {
                        setState(() {
                          maxBudget = double.tryParse(val);
                          applyFilters();
                        });
                      },
                    ),
                  ),
                ],
              ),

              Spacer(),
              Container(
                width: 160, // fixed width
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF0A4423),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sortOrder,
                    isExpanded: true, // now safe because width is fixed
                    items: [
                      DropdownMenuItem(
                        value: "none",
                        child: Text(
                          "Sort by",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      DropdownMenuItem(
                        value: "low",
                        child: Text(
                          "Price: Low to High",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      DropdownMenuItem(
                        value: "high",
                        child: Text(
                          "Price: High to Low",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        sortOrder = val!;
                        _applySort();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget generalSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF0A4423), width: 1.5),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search',
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Color(0xFF0A4423)),
          contentPadding: EdgeInsets.all(12),
        ),
        onChanged: (query) {
          setState(() {
            nameQuery = query;
            applyFilters();
          });
        },
      ),
    );
  }

  Widget tagsTrigger() {
    return GestureDetector(
      onTap: () => setState(() => tagsExpanded = !tagsExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF0A4423), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Tags",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF0A4423),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              tagsExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: const Color(0xFF0A4423),
            ),
          ],
        ),
      ),
    );
  }

  Widget tagsList() {
    if (!tagsExpanded) return const SizedBox.shrink();

    final displayTags = ['All', ...availableTags];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0A4423), width: 1),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children:
            displayTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (tag == 'All') {
                      selectedTags = ['All'];
                    } else {
                      selectedTags.remove('All');
                      if (isSelected) {
                        selectedTags.remove(tag);
                      } else {
                        selectedTags.add(tag);
                      }
                    }
                    applyFilters();
                  });
                },
                selectedColor: const Color(0xFF0A4423),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget selectedTagsDisplay() {
    // Don't show anything if no tags selected or "All" is selected
    if (selectedTags.isEmpty || selectedTags.contains('All'))
      return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children:
            selectedTags.map((tag) {
              return Chip(
                label: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: const Color(0xFF0A4423),
                deleteIconColor: Colors.white, // <-- make "×" white
                onDeleted: () {
                  setState(() {
                    selectedTags.remove(tag);
                    applyFilters();
                  });
                },
              );
            }).toList(),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food name (can wrap)
                      Expanded(
                        child: Text(
                          food['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price container stays at top
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
                  SizedBox(height: 15),
                  Text(
                    food['eateryName'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF0A4423),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
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
