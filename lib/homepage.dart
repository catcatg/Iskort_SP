import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'widgets/reusables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page_routes/preference_popup.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List allEntries = [];
  bool isLoading = true;
  Map<String, dynamic>? user;

  // Preference lists
  List<String> currentFoodPrefs = [];
  List<String> currentHousingPrefs = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && user == null) {
      setState(() {
        user = args.cast<String, dynamic>();
      });
    }
  }

  //Load preferences from SharedPreferences
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    currentFoodPrefs = prefs.getStringList("foodPrefs") ?? [];
    currentHousingPrefs = prefs.getStringList("housingPrefs") ?? [];
  }

  // Save preferences
  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("foodPrefs", currentFoodPrefs);
    await prefs.setStringList("housingPrefs", currentHousingPrefs);
    await prefs.setBool("hasSeenPreferences", true);
  }

  // First-Time Preference Popup
  Future<void> checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool("hasSeenPreferences") ?? false;

    if (!hasSeen) {
      // Wait for UI build
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          builder:
              (_) => PreferencePopup(
                initialFoodPrefs: currentFoodPrefs,
                initialHousingPrefs: currentHousingPrefs,
                onSave: (prefsSelected) async {
                  setState(() {
                    currentFoodPrefs = prefsSelected["food"];
                    currentHousingPrefs = prefsSelected["housing"];
                  });
                  await savePreferences();
                },
              ),
        );
      });
    }
  }

  // -------------------------------------------------------
  // SEARCH BAR
  // -------------------------------------------------------
  Widget GeneralSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0E1E1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
          contentPadding: EdgeInsets.all(12),
        ),
      ),
    );
  }

  // NAVIGATION CARDS
  Widget _buildNavCardsRow() {
    final navCards = [
      {'name': 'Housing', 'route': '/housing', 'icon': Icons.home},
      {'name': 'Food', 'route': '/food', 'icon': Icons.restaurant_menu},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          navCards.map((card) {
            return Expanded(
              child: GestureDetector(
                onTap:
                    () => Navigator.pushNamed(context, card['route'] as String),
                child: Container(
                  height: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(24),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        card['icon'] as IconData,
                        size: 30,
                        color: Color(0xFF791317),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A4423),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // -------------------------------------------------------
  // FETCH ENTRIES
  // -------------------------------------------------------
  Future<void> fetchEntries() async {
    try {
      List entries = [];

      // 1. Fetch eateries
      final eateryResp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/eatery'),
      );
      if (eateryResp.statusCode == 200) {
        final data = jsonDecode(eateryResp.body);
        final verifiedEateries =
            (data['eateries'] ?? [])
                .where((e) => e['is_verified'] == 1)
                .toList();
        for (var eatery in verifiedEateries) {
          eatery['type'] = 'Eatery';
          eatery['photo'] = eatery['eatery_photo'] ?? '';
          entries.add(eatery);
        }
      }

      // 2. Fetch housing
      final housingResp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/housing'),
      );
      if (housingResp.statusCode == 200) {
        final data = jsonDecode(housingResp.body);
        final verifiedHousing =
            (data['housings'] ?? [])
                .where((h) => h['is_verified'] == 1)
                .toList();
        for (var house in verifiedHousing) {
          house['type'] = 'Housing';
          house['photo'] = house['housing_photo'] ?? '';
          entries.add(house);
        }
      }

      setState(() {
        allEntries = entries;
        isLoading = false;
      });

      await loadPreferences();
      await checkFirstTimeUser();
    } catch (e) {
      print("Error fetching entries: $e");
      setState(() => isLoading = false);
    }
  }

  // -------------------------------------------------------
  // UI BUILD
  // -------------------------------------------------------
  @override
  void initState() {
    super.initState();
    fetchEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null)
              Row(
                children: [
                  Text(
                    "Hello, ${user!['name'] ?? 'Isko!'}!",
                    style: const TextStyle(
                      color: Color(0xFF0A4423),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 25),
            GeneralSearchBar(),
            const SizedBox(height: 30),
            _buildNavCardsRow(),
            const SizedBox(height: 30),

            const Text(
              "Recommended for you",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (allEntries.isEmpty)
              const Text("No entries available")
            else
              Column(
                children:
                    allEntries
                        .map(
                          (entry) => ProductCard(
                            title: entry['name'] ?? '',
                            subtitle: "Tap to view details",
                            location: entry['location'] ?? '',
                            imagePath:
                                entry['photo'] ??
                                "assets/images/placeholder.png",
                            onTap: () => showEntryDetails(entry),
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/route');
          } else if (index == 2 && user != null) {
            Navigator.pushNamed(
              context,
              '/profile',
              arguments: {
                'name': user!['name'],
                'email': user!['email'],
                'role': user!['role'],
                'phone': user!['phone_num'],
                'notifPreference': user!['notif_preference'],
              },
            );
          }
        },
      ),
    );
  }

  // Show entry details
  void showEntryDetails(Map entry) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("${entry['name'] ?? 'Details'} (${entry['type']})"),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ), // finite width
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity, // ensure finite width
                      child: Image.network(
                        entry['photo'] ?? "assets/images/placeholder.png",
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Location: ${entry['location'] ?? ''}"),
                    if (entry['type'] == 'Eatery') ...[
                      Text("Minimum Price: ₱${entry['min_price'] ?? 'N/A'}"),
                      Text("Open: ${entry['open_time'] ?? ''}"),
                      Text("Close: ${entry['end_time'] ?? ''}"),
                    ] else if (entry['type'] == 'Housing') ...[
                      Text("Monthly Price: ₱${entry['price'] ?? 'N/A'}"),
                      Text("Curfew: ${entry['curfew'] ?? 'N/A'}"),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }
}

// --------------------------
// PRODUCT CARD
// --------------------------
class ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String location;
  final String imagePath;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Image.network(
            imagePath,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => const Icon(Icons.broken_image, size: 30),
          ),
          title: Text(title),
          subtitle: Text("$subtitle • $location"),
        ),
      ),
    );
  }
}
