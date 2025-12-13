import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  List<Map<String, dynamic>> allFoods = [];
  List<Map<String, dynamic>> filteredFoods = [];
  bool isLoading = true;

  // Filters
  List<String> selectedTags = [];
  List<String> availableTags = [];
  double? maxBudget;

  @override
  void initState() {
    super.initState();
    fetchVerifiedFoods();
  }

  Future<void> fetchVerifiedFoods() async {
    setState(() => isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/eatery'),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final verifiedEateries = (data['eateries'] ?? []).where(
          (e) => e['is_verified'] == 1,
        );

        List<Map<String, dynamic>> foods = [];
        Set<String> tagsSet = {};

        for (var eatery in verifiedEateries) {
          final eateryId = eatery['eatery_id'];
          final eateryName = eatery['name'] ?? '';
          final foodResp = await http.get(
            Uri.parse(
              'https://iskort-public-web.onrender.com/api/food/$eateryId',
            ),
          );
          if (foodResp.statusCode == 200) {
            final foodData = jsonDecode(foodResp.body);
            for (var f in foodData['foods'] ?? []) {
              final classification = f['classification'] ?? '';
              foods.add({
                "name": f['name'] ?? '',
                "classification": classification,
                "price": double.tryParse(f['price'].toString()) ?? 0,
                "image": f['food_pic'] ?? 'assets/images/placeholder.png',
                "eateryName": eateryName,
              });
              if (classification.isNotEmpty) {
                tagsSet.add(classification.toString());
              }
            }
          }
        }

        foods.sort((a, b) => a['name'].compareTo(b['name']));

        setState(() {
          allFoods = foods;
          filteredFoods = List.from(allFoods);
          availableTags = tagsSet.toList()..sort();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching foods: $e");
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    setState(() {
      filteredFoods =
          allFoods.where((food) {
            final matchesTag =
                selectedTags.isEmpty ||
                selectedTags.contains(food['classification']);
            final matchesBudget =
                maxBudget == null || food['price'] <= maxBudget!;
            return matchesTag && matchesBudget;
          }).toList();
    });
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
          // Filter controls
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags with row spacing
                Wrap(
                  spacing: 8,
                  runSpacing: 8, // vertical spacing between rows
                  children:
                      availableTags.map((tag) {
                        // Define isSelected inside the map closure
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(
                            tag,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : Colors.black, // white when selected
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Color.fromARGB(255, 22, 152, 79),
                          checkmarkColor: Colors.white, // checkmark color
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                              applyFilters();
                            });
                          },
                        );
                      }).toList(),
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Max Budget: P "),
                    Container(
                      width: 120,
                      child: Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 14,
                          ), // <-- font size set to 12
                          decoration: const InputDecoration(
                            hintText: "Enter amount",
                            hintStyle: TextStyle(
                              fontSize: 14,
                            ), // optional: hint text matches font size
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setState(() {
                              maxBudget = double.tryParse(val);
                              applyFilters();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0A4423),
                      ),
                    )
                    : filteredFoods.isEmpty
                    ? const Center(
                      child: Text(
                        "No foods found with the selected filters.",
                        style: TextStyle(fontSize: 16),
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
                            childAspectRatio: 0.8, // slightly taller cells
                          ),
                      itemBuilder: (_, i) {
                        final food = filteredFoods[i];
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: AspectRatio(
                                  aspectRatio: 1.2,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      food['image'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.broken_image,
                                              size: 40,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    4,
                                    8,
                                    8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              food['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ), // space between name and price pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors
                                                      .green[800], // darker green pill
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              "₱${food['price'].toStringAsFixed(0)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      Text(
                                        food['eateryName'],
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        food['classification'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
