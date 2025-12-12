import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HousingPage extends StatefulWidget {
  const HousingPage({super.key});

  @override
  State<HousingPage> createState() => _HousingPageState();
}

class _HousingPageState extends State<HousingPage> {
  List<Map<String, dynamic>> allFacilities = [];
  List<Map<String, dynamic>> filteredFacilities = [];
  List<String> availableTags = [];
  List<String> selectedTags = [];
  double? maxBudget;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVerifiedFacilities();
  }

  Future<void> fetchVerifiedFacilities() async {
    setState(() => isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/housing'),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final verifiedHousing = (data['housings'] ?? []).where(
          (h) => h['is_verified'] == 1,
        );

        List<Map<String, dynamic>> facilities = [];
        Set<String> tagsSet = {};

        for (var house in verifiedHousing) {
          final housingId = house['housing_id'];
          final housingName = house['name'] ?? '';
          final facResp = await http.get(
            Uri.parse(
              'https://iskort-public-web.onrender.com/api/facility/$housingId',
            ),
          );
          if (facResp.statusCode == 200) {
            final facData = jsonDecode(facResp.body);
            for (var f in facData['facilities'] ?? []) {
              final classification = f['type'] ?? '';
              facilities.add({
                "name": f['name'] ?? '',
                "classification": classification,
                "price": double.tryParse(f['price'].toString()) ?? 0,
                "image": f['facility_pic'] ?? 'assets/images/placeholder.png',
                "housingName": housingName,
              });
              if (classification.isNotEmpty) {
                tagsSet.add(classification.toString());
              }
            }
          }
        }

        facilities.sort((a, b) => a['name'].compareTo(b['name']));

        setState(() {
          allFacilities = facilities;
          filteredFacilities = List.from(allFacilities);
          availableTags = tagsSet.toList()..sort();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching facilities: $e");
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    setState(() {
      filteredFacilities =
          allFacilities.where((fac) {
            final matchesTag =
                selectedTags.isEmpty ||
                selectedTags.contains(fac['classification']);
            final matchesBudget =
                maxBudget == null || fac['price'] <= maxBudget!;
            return matchesTag && matchesBudget;
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Housing", style: TextStyle(color: Colors.white)),
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
                    : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredFacilities.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                      itemBuilder: (_, i) {
                        final fac = filteredFacilities[i];
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
                                      fac['image'],
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
                                              fac['name'],
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
                                              "₱${fac['price'].toStringAsFixed(0)}",
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
                                        fac['housingName'],
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        fac['classification'],
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
