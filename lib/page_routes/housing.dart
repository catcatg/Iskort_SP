import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HousingPage extends StatefulWidget {
  const HousingPage({super.key});

  @override
  State<HousingPage> createState() => _HousingPageState();
}

class _HousingPageState extends State<HousingPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> housingData = [];
  late List<Map<String, dynamic>> filteredHousingData;
  bool isLoading = true;

  String lastSortOption = 'price_asc';

  @override
  void initState() {
    super.initState();
    filteredHousingData = housingData;
    _searchController.addListener(_onSearchChanged);
    fetchVerifiedHousing();
  }

  Map<String, dynamic> normalizeHousing(Map house) {
    return {
      'name': house['name'] ?? '',
      'location': house['location'] ?? '',
      'price': house['price'] ?? 0,
      'pax': house['pax'] ?? 'N/A',
      'image': house['housing_photo'] ?? 'assets/images/housing.jpg',
    };
  }

  Future<void> fetchVerifiedHousing() async {
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
          housingData.addAll(verifiedHousing);
          filteredHousingData = List.from(housingData);
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
      if (query.isEmpty) {
        filteredHousingData = List.from(housingData);
      } else {
        filteredHousingData =
            housingData.where((house) {
              final name = house['name'].toString().toLowerCase();
              final location = house['location'].toString().toLowerCase();
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
          filteredHousingData.sort((a, b) => a['price'].compareTo(b['price']));
          break;
        case 'price_desc':
          filteredHousingData.sort((a, b) => b['price'].compareTo(a['price']));
          break;
        case 'name_asc':
          filteredHousingData.sort((a, b) => a['name'].compareTo(b['name']));
          break;
        case 'name_desc':
          filteredHousingData.sort((a, b) => b['name'].compareTo(a['name']));
          break;
      }
    });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Housing', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF0A4423), width: 1.5),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Search housing",
                  suffixIcon: Icon(Icons.search, color: Color(0xFF0A4423)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Sorting menu under search bar
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  final selected = await showMenu<String>(
                    context: context,
                    position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                    items: [
                      const PopupMenuItem(
                        value: 'price_asc',
                        child: Text('Price: Low → High'),
                      ),
                      const PopupMenuItem(
                        value: 'price_desc',
                        child: Text('Price: High → Low'),
                      ),
                      const PopupMenuItem(
                        value: 'name_asc',
                        child: Text('Name: A → Z'),
                      ),
                      const PopupMenuItem(
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
                    border: Border.all(color: const Color(0xFF0A4423)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sort,
                        color: Color.fromARGB(255, 255, 255, 255),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getSortLabel(lastSortOption),
                        style: const TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Housing Grid
            Expanded(
              child:
                  isLoading
                      ? const Center(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            color: Color(0xFF0A4423),
                          ),
                        ),
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(1, 16, 1, 16),
                        itemCount: filteredHousingData.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                        itemBuilder: (context, index) {
                          final house = filteredHousingData[index];
                          return HousingCard(
                            name: house['name'],
                            location: house['location'],
                            price: house['price'],
                            pax: house['pax'],
                            imagePath: house['image'],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class HousingCard extends StatefulWidget {
  final String name;
  final String location;
  final int price;
  final String pax;
  final String imagePath;

  const HousingCard({
    super.key,
    required this.name,
    required this.location,
    required this.price,
    required this.pax,
    required this.imagePath,
  });

  @override
  State<HousingCard> createState() => _HousingCardState();
}

class _HousingCardState extends State<HousingCard> {
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
          // Image with heart icon
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
                    width: double.infinity,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 13,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isLiked = !isLiked;
                    });
                  },
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

          // Info
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
                  "₱${widget.price}/Person",
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.pax, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
