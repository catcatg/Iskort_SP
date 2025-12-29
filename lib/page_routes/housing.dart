import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iskort/page_routes/view_estab_profile.dart';
import 'package:flutter/services.dart';

class HousingPage extends StatefulWidget {
  const HousingPage({super.key});

  @override
  State<HousingPage> createState() => _HousingPageState();
}

class _HousingPageState extends State<HousingPage> {
  List<Map<String, dynamic>> allFacilities = [];
  List<Map<String, dynamic>> filteredFacilities = [];
  bool isLoading = true;

  List<String> selectedFacilityTypes = [];
  List<String> selectedAmenities = [];
  List<String> selectedTags = [];

  List<String> availableTags = [];
  double? maxBudget;

  String sortOrder = "none";
  String searchQuery = "";
  bool tagsExpanded = false;

  TextEditingController _searchController = TextEditingController();

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
      bool isAvailable;

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

          bool isAvailable;
          if (classification == 'Shared') {
            final rooms = int.tryParse(f['avail_room']?.toString() ?? '0') ?? 0;
            isAvailable = rooms > 0;
          } else {
            isAvailable =
                f['availability'] ==
                0; // adjust depending on API: 0 = available
          }

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
            "availability": isAvailable,
            "avail_room": int.tryParse(f['avail_room']?.toString() ?? '0') ?? 0,
          });

          if (classification.isNotEmpty) tagsSet.add(classification);
          if (f['has_cr'] == 1) tagsSet.add('Has CR');
          if (f['has_kitchen'] == 1) tagsSet.add('Has Kitchen');
          if (f['has_ac'] == 1) tagsSet.add('Has Aircon');
          tagsSet.add('Available');
          tagsSet.add('Unavailable');
        }
      }

      facilities.sort((a, b) => a['name'].compareTo(b['name']));

      setState(() {
        allFacilities = facilities;
        filteredFacilities = List.from(facilities);
        applyFilters();
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
      filteredFacilities =
          allFacilities.where((fac) {
            // Search filter
            final matchesSearch =
                searchQuery.isEmpty ||
                fac['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
                fac['classification'].toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                fac['housingName'].toLowerCase().contains(
                  searchQuery.toLowerCase(),
                );

            // Facility Type filter
            bool matchesFacilityType = true;
            if (selectedFacilityTypes.isNotEmpty &&
                !selectedFacilityTypes.contains('All')) {
              matchesFacilityType = selectedFacilityTypes.contains(
                fac['classification'],
              );
            }

            // Amenities filter
            bool matchesAmenities = true;
            if (selectedAmenities.isNotEmpty &&
                !selectedAmenities.contains('All')) {
              if (selectedAmenities.contains('Has CR') && fac['has_cr'] != true)
                matchesAmenities = false;
              if (selectedAmenities.contains('Has Kitchen') &&
                  fac['has_kitchen'] != true)
                matchesAmenities = false;
              if (selectedAmenities.contains('Has Aircon') &&
                  fac['has_ac'] != true)
                matchesAmenities = false;
            }

            // Availability filter
            bool matchesAvailability;

            // If 'Unavailable' is selected, show everything
            if (selectedTags.contains('Unavailable')) {
              matchesAvailability = true; // show all
            } else {
              matchesAvailability =
                  fac['availability'] == true; // show only available
            }

            // Max budget filter
            final matchesBudget =
                maxBudget == null || fac['price'] <= maxBudget!;

            return matchesSearch &&
                matchesFacilityType &&
                matchesAmenities &&
                matchesBudget &&
                matchesAvailability;
          }).toList();

      // Sorting
      _applySort();
    });
  }

  void _applySort() {
    if (sortOrder == "low") {
      filteredFacilities.sort((a, b) => a['price'].compareTo(b['price']));
    } else if (sortOrder == "high") {
      filteredFacilities.sort((a, b) => b['price'].compareTo(a['price']));
    }
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
                        Text("Monthly Price: ₱${item['price'] ?? ''}"),
                        Text("Housing Name: ${item['housingName'] ?? ''}"),
                        const SizedBox(height: 20),
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
                    fontSize: 14,
                  ),
                ),
                backgroundColor: const Color(0xFF0A4423),
                deleteIconColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facilities', style: TextStyle(color: Colors.white)),
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
          children: [_buildSearchBars(), Expanded(child: _buildGrid())],
        ),
      ),
    );
  }

  Widget _buildSearchBars() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF0A4423),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or type',
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search, color: Color(0xFF0A4423)),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    onChanged: (query) {
                      searchQuery = query;
                      applyFilters();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => tagsExpanded = !tagsExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF0A4423),
                      width: 1.5,
                    ),
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
              ),
            ],
          ),
          selectedTagsDisplay(),
          if (tagsExpanded)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0A4423), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Facility Type",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        ['All', 'Solo', 'Shared'].map((tag) {
                          final isSelected = selectedFacilityTypes.contains(
                            tag,
                          );
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (tag == 'All') {
                                  selectedFacilityTypes = ['All'];
                                } else {
                                  selectedFacilityTypes.remove('All');
                                  if (isSelected) {
                                    selectedFacilityTypes.remove(tag);
                                  } else {
                                    selectedFacilityTypes.add(tag);
                                  }
                                }

                                // Update selectedTags
                                selectedTags = [
                                  ...selectedFacilityTypes.where(
                                    (t) => t != 'All',
                                  ),
                                  ...selectedAmenities.where((t) => t != 'All'),
                                ];

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
                  const Divider(height: 20, thickness: 1.2, color: Colors.grey),
                  const Text(
                    "Amenities",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        ['All', 'Has CR', 'Has Kitchen', 'Has Aircon'].map((
                          tag,
                        ) {
                          final isSelected = selectedAmenities.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (tag == 'All') {
                                  selectedAmenities = ['All'];
                                } else {
                                  selectedAmenities.remove('All');
                                  if (isSelected) {
                                    selectedAmenities.remove(tag);
                                  } else {
                                    selectedAmenities.add(tag);
                                  }
                                }

                                // Update selectedTags
                                selectedTags = [
                                  ...selectedFacilityTypes.where(
                                    (t) => t != 'All',
                                  ),
                                  ...selectedAmenities.where((t) => t != 'All'),
                                ];

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
                  const Divider(height: 20, thickness: 1.2),
                  const Text(
                    "Availability",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        ['Available', 'Unavailable'].map((tag) {
                          final isSelected = selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
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
                            selectedColor:
                                tag == 'Available'
                                    ? Color(0xFF0A4423)
                                    : Colors.red[700],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
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
              const Spacer(),
              Container(
                width: 160,
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
                    isExpanded: true,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    items: const [
                      DropdownMenuItem(value: "none", child: Text("Sort by")),
                      DropdownMenuItem(
                        value: "low",
                        child: Text("Price: Low to High"),
                      ),
                      DropdownMenuItem(
                        value: "high",
                        child: Text("Price: High to Low"),
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
          const Divider(),
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
        final facility = filteredFacilities[i];
        return GestureDetector(
          onTap: () => _showFacilityDetails(facility),
          child: _FacilityCard(facility: facility),
        );
      },
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final Map<String, dynamic> facility;

  _FacilityCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = facility['availability'] == true;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.45,

      child: Card(
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
                  facility['image'],
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
                        Expanded(
                          child: Text(
                            facility['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            '₱${facility['price'].toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      facility['housingName'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0A4423),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (facility['classification'] == 'Shared' && isAvailable)
                      Text(
                        '${facility['avail_room']} bed space available',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 25, 27, 25),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    if (!isAvailable)
                      const Text(
                        'Not Available',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    const Spacer(),
                    Text(
                      facility['location'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      facility['classification'],
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
      ),
    );
  }
}
