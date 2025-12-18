import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iskort/page_routes/map_route.dart';
import 'package:iskort/page_routes/view_estab_profile.dart';

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

  String searchQuery = "";
  String filterMode = "name";
  bool showAmenities = true;

  TextEditingController? _tagAutocompleteController;

  double? maxBudget;
  bool isLoading = true;
  bool hasCR = false;
  bool hasKitchen = false;
  bool hasAC = false;


  @override
  void initState() {
    super.initState();
    fetchVerifiedFacilities();
  }

  Future<void> fetchVerifiedFacilities() async {
    setState(() => isLoading = true);
    try {
      final housingResp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/housing'),
      );
      if (housingResp.statusCode != 200)
        throw Exception('Failed to load housings');

      final housingData = jsonDecode(housingResp.body);
      final verifiedHousing = (housingData['housings'] ?? []).where(
        (h) => h['is_verified'] == 1,
      );

      List<Map<String, dynamic>> facilities = [];
      Set<String> tagsSet = {};

      for (var house in verifiedHousing) {
        final housingId = house['housing_id'];
        final housingName = house['name'] ?? '';
        final housingLocation = house['location'] ?? '';

        final facResp = await http.get(
          Uri.parse(
            'https://iskort-public-web.onrender.com/api/facility/$housingId',
          ),
        );
        if (facResp.statusCode != 200) continue;

        final facData = jsonDecode(facResp.body);
        for (var f in facData['facilities'] ?? []) {
          final classification = f['type'] ?? '';
          facilities.add({
            "name": f['name'] ?? '',
            "classification": classification,
            "price": double.tryParse(f['price'].toString()) ?? 0,
            "image": f['facility_pic'] ?? '',
            "housingName": housingName,
            "location": housingLocation,
            "housing_id": housingId.toString(),
            "owner_id": house['owner_id']?.toString() ?? '',
            "has_cr": f['has_cr'] == 1,
            "has_kitchen": f['has_kitchen'] == 1,
            "has_ac": f['has_ac'] == 1,
          });
          if (classification.isNotEmpty) tagsSet.add(classification);
        }
      }

      facilities.sort((a, b) => a['name'].compareTo(b['name']));

      setState(() {
        allFacilities = facilities;
        filteredFacilities = List.from(facilities);
        availableTags = tagsSet.toList()..sort();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching facilities: $e");
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    setState(() {
      filteredFacilities = allFacilities.where((fac) {
        if (filterMode == "name") {
          return fac['name']
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
        }

        final matchesTag =
            selectedTags.isEmpty ||
            selectedTags.contains(fac['classification']);

        final matchesBudget =
            maxBudget == null || fac['price'] <= maxBudget!;

        final matchesCR = !hasCR || fac['has_cr'] == true;
        final matchesKitchen = !hasKitchen || fac['has_kitchen'] == true;
        final matchesAC = !hasAC || fac['has_ac'] == true;

        return matchesTag &&
            matchesBudget &&
            matchesCR &&
            matchesKitchen &&
            matchesAC;
      }).toList();
    });
  }

  void _showFacilityDetails(Map<String, dynamic> item) {
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
                        Text("Type: ${item['classification'] ?? ''}"),
                        const SizedBox(height: 4),
                        Text("Price: ₱${item['price'] ?? ''}"),
                        Text("Housing Name: ${item['housingName'] ?? ''}"),
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
                                      estType: 'Housing',
                                      eateryId: null,
                                      housingId: item['housing_id'],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Housing', style: TextStyle(color: Colors.white)),
        leading: BackButton(color: Colors.white),
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
      body: SafeArea(
        child: Column(
          children: [_buildFilters(), Expanded(child: _buildGrid())],
        ),
      ),
    );
  }

  Widget _buildFilters() {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // search by selector
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text("Search by Name"),
                value: "name",
                groupValue: filterMode,
                onChanged: (val) {
                  setState(() {
                    filterMode = val!;
                    searchQuery = "";
                    selectedTags.clear();
                    maxBudget = null;
                    hasCR = hasKitchen = hasAC = false;
                    applyFilters();
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text("Search by Preferences"),
                value: "filters",
                groupValue: filterMode,
                onChanged: (val) {
                  setState(() {
                    filterMode = val!;
                    searchQuery = "";
                    applyFilters();
                  });
                },
              ),
            ),
          ],
        ),

        const Divider(),

        // search name
        if (filterMode == "name")
          TextField(
            decoration: const InputDecoration(
              labelText: "Search by Room Name",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) {
              setState(() {
                searchQuery = val;
                applyFilters();
              });
            },
          ),

        // search preference
        if (filterMode == "filters") ...[

          // type autocomplete
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return availableTags.where(
                (tag) => tag
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()),
              );
            },
            onSelected: (selection) {
              setState(() {
                if (!selectedTags.contains(selection)) {
                  selectedTags.add(selection);
                  applyFilters();
                }
                _tagAutocompleteController?.clear();
              });
            },
            fieldViewBuilder: (context, controller, focusNode, _) {
              _tagAutocompleteController = controller;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: "Facility Type (Shared, Solo, etc.)",
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // selected tags
          Wrap(
            spacing: 6,
            children: selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    selectedTags.remove(tag);
                    applyFilters();
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // max budget
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
                    setState(() {
                      maxBudget = val.isEmpty ? null : double.tryParse(val);
                      applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Amenities
          GestureDetector(
            onTap: () {
              setState(() => showAmenities = !showAmenities);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Amenities",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Icon(
                  showAmenities ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // collapsible
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: showAmenities
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                CheckboxListTile(
                  title: const Text("Has CR"),
                  value: hasCR,
                  onChanged: (val) {
                    setState(() {
                      hasCR = val ?? false;
                    });
                    applyFilters();
                  },
                ),
                CheckboxListTile(
                  title: const Text("Has Kitchen"),
                  value: hasKitchen,
                  onChanged: (val) {
                    setState(() {
                      hasKitchen = val ?? false;
                    });
                    applyFilters();
                  },
                ),
                CheckboxListTile(
                  title: const Text("Has Aircon"),
                  value: hasAC,
                  onChanged: (val) {
                    setState(() {
                      hasAC = val ?? false;
                    });
                    applyFilters();
                  },
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),

        ],
      ],
    ),
  );
}


  Widget _buildGrid() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (filteredFacilities.isEmpty)
      return const Center(
        child: Text('No facilities found with current filters.'),
      );

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredFacilities.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (_, i) {
        final fac = filteredFacilities[i];
        return GestureDetector(
          onTap: () => _showFacilityDetails(fac),
          child: _FacilityCard(fac: fac),
        );
      },
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final Map<String, dynamic> fac;
  const _FacilityCard({required this.fac});

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
                fac['image'],
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
                      Expanded(
                        child: Text(
                          fac['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                          '₱${fac['price'].toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    fac['housingName'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    fac['location'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    fac['classification'],
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
