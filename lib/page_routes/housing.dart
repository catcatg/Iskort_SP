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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableTags.map((tag) {
                  final isSelected = selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF16984F),
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? selectedTags.add(tag)
                            : selectedTags.remove(tag);
                        applyFilters();
                      });
                    },
                  );
                }).toList(),
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
            ],
          ),
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
