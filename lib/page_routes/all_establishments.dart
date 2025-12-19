import 'package:flutter/material.dart';
import '../widgets/reusables.dart';
import 'map_route.dart';
import 'view_estab_profile.dart';

class AllEstablishmentsPage extends StatefulWidget {
  final String establishmentType; // 'Housing' or 'Eatery'

  const AllEstablishmentsPage({super.key, required this.establishmentType});

  @override
  State<AllEstablishmentsPage> createState() => _AllEstablishmentsPageState();
}

class _AllEstablishmentsPageState extends State<AllEstablishmentsPage> {
  List allEntries = [];
  List filteredEntries = [];
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  String filterMode = "filter";

  // Eatery filters
  double? maxFoodBudget;
  List<String> selectedFoodTags = [];

  // Housing filters
  double? maxRent;
  bool hasCR = false;
  bool hasKitchen = false;
  bool hasAC = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    allEntries = ModalRoute.of(context)?.settings.arguments as List? ?? [];

    filteredEntries =
        allEntries.where((e) => e['type'] == widget.establishmentType).toList();
  }

  void applyFilters() {
    setState(() {
      filteredEntries =
          allEntries.where((entry) {
            // must match page type
            if (entry['type'] != widget.establishmentType) return false;

            // 🔍 name search
            final matchesName = entry['name'].toString().toLowerCase().contains(
              searchQuery.toLowerCase(),
            );

            if (!matchesName) return false;

            return true;
          }).toList();
    });
  }

  Widget GeneralSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF0A4423), width: 1.5),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search establishment name',
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Color(0xFF0A4423)),
          contentPadding: EdgeInsets.all(12),
        ),
        onChanged: (query) {
          searchQuery = query;
          applyFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.establishmentType == 'Housing'
              ? 'All Housing'
              : 'All Eateries',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GeneralSearchBar(),

            const SizedBox(height: 16),

            Expanded(
              child:
                  filteredEntries.isEmpty
                      ? const Center(
                        child: Text(
                          'No establishments found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : GridView.builder(
                        itemCount: filteredEntries.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.7,
                            ),
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return ProductCard(
                            title: entry['name'] ?? '',
                            location: entry['location'] ?? '',
                            imagePath:
                                entry['photo'] ??
                                "assets/images/placeholder.png",
                            onTap: () => _showEntryDetails(entry),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryDetails(Map entry) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        entry['photo'] ?? "assets/images/placeholder.png",
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      entry['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(entry['location'] ?? ''),
                    const SizedBox(height: 10),

                    if (entry['type'] == 'Eatery') ...[
                      Text("Min Price: ₱${entry['min_price']}"),
                      Text("Open: ${entry['open_time']}"),
                      Text("Close: ${entry['end_time']}"),
                    ] else ...[
                      Text("Monthly Price: ₱${entry['price']}"),
                      Text("Curfew: ${entry['curfew']}"),
                    ],

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
                                  ownerId: entry['owner_id']?.toString() ?? '',
                                  estType: entry['type']?.toString() ?? '',
                                  eateryId: entry['eatery_id']?.toString(),
                                  housingId: entry['housing_id']?.toString(),
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
                                  initialLocation:
                                      entry['location']?.toString() ?? '',
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
          ),
    );
  }
}
