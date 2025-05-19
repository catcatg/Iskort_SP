import 'package:flutter/material.dart';

class HousingPage extends StatefulWidget {
  const HousingPage({super.key});

  @override
  State<HousingPage> createState() => _HousingPageState();
}

class _HousingPageState extends State<HousingPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> housingData = [
    {
      'name': 'Nonato’s Boarding',
      'location': 'Paguntalan, Sapa',
      'price': 459,
      'pax': '2pax',
      'image': 'assets/images/housing.jpg',
    },
    {
      'name': 'British Boarding House',
      'location': 'Paguntalan, Sapa',
      'price': 894,
      'pax': '6pax',
      'image': 'assets/images/housing.jpg',
    },
    {
      'name': 'Aonang House',
      'location': 'Mat-y',
      'price': 761,
      'image': 'assets/images/housing.jpg',
      'pax': '2pax',
    },
    {
      'name': 'Tara Rent',
      'location': 'Mat-y',
      'price': 857,
      'image': 'assets/images/housing.jpg',
      'pax': '2pax',
    },
  ];

  // Filtered housing data to show in UI
  late List<Map<String, dynamic>> filteredHousingData;

  @override
  void initState() {
    super.initState();
    filteredHousingData = housingData;

    // search field changes
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredHousingData = housingData;
      } else {
        filteredHousingData =
            housingData.where((house) {
              final name = house['name'].toString().toLowerCase();
              final location = house['location'].toString().toLowerCase();
              return name.contains(query) || location.contains(query);
            }).toList();
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search Housing",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF0E1E1),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sort),
                  label: const Text("Sort"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7A1E1E),
                    side: const BorderSide(color: Color(0xFF7A1E1E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(1, 16, 1, 16),
                itemCount: filteredHousingData.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  child: Image.asset(
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
                  style: TextStyle(
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
