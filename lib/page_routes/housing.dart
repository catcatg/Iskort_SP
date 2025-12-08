import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'view_estab_profile.dart';
import 'map_route.dart';

class HousingPage extends StatefulWidget {
  const HousingPage({super.key});

  @override
  State<HousingPage> createState() => _HousingPageState();
}

class _HousingPageState extends State<HousingPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allHousing = [];
  List<Map<String, dynamic>> filteredHousing = [];
  bool isLoading = true;
  String lastSortOption = 'price_asc';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchVerifiedHousing();
  }

  Map<String, dynamic> normalizeHousing(Map house) {
    return {
      'name': house['name'] ?? '',
      'location': house['location'] ?? '',
      'price': house['price'] ?? 0,
      'priceRange': "₱${house['price'] ?? 'N/A'}",
      'pax': house['pax'] ?? 'N/A',
      'image': house['housing_photo'] ?? 'assets/images/placeholder.png',
      'owner_id': house['owner_id']?.toString() ?? '',
      'type': 'Housing', // unify with HomePage structure
      'tags': house['tags'] ?? [],
    };
  }

  Future<void> fetchVerifiedHousing() async {
    setState(() => isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/housing'),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final verifiedHousing =
            (data['housings'] ?? [])
                .where((h) => h['is_verified'] == 1)
                .map<Map<String, dynamic>>((h) => normalizeHousing(h))
                .toList();

        setState(() {
          allHousing = verifiedHousing;
          filteredHousing = List.from(allHousing);
          _applySort(lastSortOption);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching housing: $e");
      setState(() => isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredHousing =
          allHousing.where((house) {
            final name = house['name'].toString().toLowerCase();
            final location = house['location'].toString().toLowerCase();
            final tagsList =
                (house['tags'] is List)
                    ? (house['tags'] as List)
                        .map((t) => t.toString().toLowerCase())
                        .toList()
                    : [];
            return name.contains(query) ||
                location.contains(query) ||
                tagsList.any((t) => t.contains(query));
          }).toList();
      _applySort(lastSortOption);
    });
  }

  void _applySort(String sortOption) {
    lastSortOption = sortOption;
    setState(() {
      switch (sortOption) {
        case 'price_asc':
          filteredHousing.sort((a, b) => a['price'].compareTo(b['price']));
          break;
        case 'price_desc':
          filteredHousing.sort((a, b) => b['price'].compareTo(a['price']));
          break;
        case 'name_asc':
          filteredHousing.sort((a, b) => a['name'].compareTo(b['name']));
          break;
        case 'name_desc':
          filteredHousing.sort((a, b) => b['name'].compareTo(a['name']));
          break;
      }
    });
  }

  String _getSortLabel(String sortOption) {
    switch (sortOption) {
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

  void _showHousingDialog(Map house) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            house['image'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  height: 200,
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          house['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                house['location'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          house['priceRange'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Max Pax: ${house['pax']}",
                          style: const TextStyle(fontSize: 14),
                        ),
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
                                      ownerId: house['owner_id'],
                                    ),
                              ),
                            );
                          },
                          child: const Text(
                            "View Establishment Profile",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
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
                                    (_) => MapRoutePage(
                                      initialLocation: house['location'],
                                    ),
                              ),
                            );
                          },
                          child: const Text(
                            "View Route",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF0A4423), width: 1.5),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search housing',
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

          // Sort Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  final selected = await showMenu<String>(
                    context: context,
                    position: const RelativeRect.fromLTRB(100, 100, 0, 0),
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
                    color: const Color(0xFF0A4423),
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
                      itemCount: filteredHousing.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemBuilder: (_, i) {
                        final house = filteredHousing[i];
                        return GestureDetector(
                          onTap: () => _showHousingDialog(house),
                          child: Container(
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
                                Stack(
                                  children: [
                                    Container(
                                      height: 180,
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          house['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Container(
                                                width: double.infinity,
                                                alignment: Alignment.center,
                                                color: Colors.grey.shade300,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    4,
                                    8,
                                    4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        house['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Color(0xFF7A1E1E),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              house['location'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        house['priceRange'],
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "Max Pax: ${house['pax']}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
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
    );
  }
}
