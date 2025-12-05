import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'widgets/reusables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page_routes/preference_popup.dart';
import 'page_routes/view_estab_profile.dart';
import 'page_routes/map_route.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List allEntries = [];
  bool isLoading = true;
  Map<String, dynamic> user = {};

  // Preference lists
  List<String> currentFoodPrefs = [];
  List<String> currentHousingPrefs = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && user.isEmpty) {
      setState(() {
        user = args.map((k, v) => MapEntry(k.toString(), v));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchEntries();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    currentFoodPrefs = prefs.getStringList("foodPrefs") ?? [];
    currentHousingPrefs = prefs.getStringList("housingPrefs") ?? [];
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("foodPrefs", currentFoodPrefs);
    await prefs.setStringList("housingPrefs", currentHousingPrefs);
    await prefs.setBool("hasSeenPreferences", true);
  }

  Future<void> checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool("hasSeenPreferences") ?? false;

    if (!hasSeen) {
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          builder:
              (_) => PreferencePopup(
                initialFoodPrefs: currentFoodPrefs,
                initialHousingPrefs: currentHousingPrefs,
                onSave: (prefsSelected) async {
                  setState(() {
                    currentFoodPrefs = prefsSelected["food"] ?? [];
                    currentHousingPrefs = prefsSelected["housing"] ?? [];
                  });
                  await savePreferences();
                },
              ),
        );
      });
    }
  }

  Future<void> fetchEntries() async {
    try {
      List entries = [];

      // Fetch eateries
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

      // Fetch housing
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

  Widget GeneralSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Color(0xFF0A4423), width: 1.5),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search housing or eateries',
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Color(0xFF0A4423)),
          contentPadding: EdgeInsets.all(12),
        ),
        onSubmitted: (query) {
          if (query.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchResultsPage(searchQuery: query),
                settings: RouteSettings(arguments: allEntries),
              ),
            );
          }
        },
      ),
    );
  }

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
                    () => Navigator.pushNamed(
                      context,
                      card['route']?.toString() ?? '/',
                    ),
                child: Container(
                  height: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(
                          0x660A4423,
                        ), // slightly transparent for softer shadow
                        blurRadius: 4,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        card['icon'] as IconData? ?? Icons.help_outline,
                        size: 30,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card['name']?.toString() ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  void showEntryDetails(Map entry) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(25),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${entry['name'] ?? 'Details'} (${entry['type'] ?? 'Unknown'})",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
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
                          Text(
                            "Minimum Price: ₱${entry['min_price'] ?? 'N/A'}",
                          ),
                          Text("Open: ${entry['open_time'] ?? ''}"),
                          Text("Close: ${entry['end_time'] ?? ''}"),
                        ] else if (entry['type'] == 'Housing') ...[
                          Text("Monthly Price: ₱${entry['price'] ?? 'N/A'}"),
                          Text("Curfew: ${entry['curfew'] ?? 'N/A'}"),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EstabProfileForCustomer(
                                          ownerId:
                                              entry['owner_id']?.toString() ??
                                              '',
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A4423),
                              ),
                              child: const Text(
                                "View Establishment Profile",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MapRoutePage(
                                          initialLocation:
                                              entry['location']?.toString() ??
                                              '',
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A4423),
                              ),
                              child: const Text(
                                "View Route",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.isNotEmpty)
              Text(
                "Hello, ${user['name'] ?? 'Isko!'}!",
                style: const TextStyle(
                  color: Color(0xFF0A4423),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(height: 25),
            GeneralSearchBar(),
            const SizedBox(height: 30),
            _buildNavCardsRow(),
            const SizedBox(height: 15),

            // ------------------------------
            // RECOMMENDED SECTION (Housing + Eateries)
            // ------------------------------
            Divider(color: Color(0xFF0A4423)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A4423),
                border: Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Recommended for you",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (allEntries.isEmpty)
              const Text("No entries found")
            else ...[
              // --------------------- HOUSING ---------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Housing",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A4423),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/housing');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "View more",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Column(
                children:
                    allEntries
                        .where((e) => e['type'] == 'Housing')
                        .take(5)
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

              const SizedBox(height: 10),
              Divider(color: Color(0xFF0A4423)),
              const SizedBox(height: 10),

              // --------------------- EATERIES ---------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Eateries",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A4423),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/food');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "View more",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              Column(
                children:
                    allEntries
                        .where((e) => e['type'] == 'Eatery')
                        .take(5)
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
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/route');
          } else if (index == 2 && user.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/profile',
              arguments: {
                'name': user['name'] ?? '',
                'email': user['email'] ?? '',
                'role': user['role'] ?? '',
                'phone': user['phone_num'] ?? '',
                'notifPreference': user['notif_preference'] ?? '',
              },
            );
          }
        },
      ),
    );
  }
}

// --------------------------
// SEARCH RESULTS PAGE
// --------------------------
class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  const SearchResultsPage({super.key, required this.searchQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List filteredEntries = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final allEntries =
        ModalRoute.of(context)?.settings.arguments as List? ?? [];
    filterEntries(allEntries);
  }

  void filterEntries(List allEntries) {
    final query = widget.searchQuery.toLowerCase();
    filteredEntries =
        allEntries.where((entry) {
          final name = (entry['name'] ?? '').toString().toLowerCase();
          final location = (entry['location'] ?? '').toString().toLowerCase();
          final type = (entry['type'] ?? '').toString().toLowerCase();
          final tagsList =
              (entry['tags'] is List)
                  ? (entry['tags'] as List)
                      .map((t) => t.toString().toLowerCase())
                      .toList()
                  : [];

          return name.contains(query) ||
              location.contains(query) ||
              type.contains(query) ||
              tagsList.any((t) => t.contains(query));
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final housingResults =
        filteredEntries.where((e) => e['type'] == 'Housing').toList();

    final eateryResults =
        filteredEntries.where((e) => e['type'] == 'Eatery').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results', style: TextStyle(color: Colors.white)),
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
      body:
          filteredEntries.isEmpty
              ? Center(
                child: Text('No results found for "${widget.searchQuery}"'),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Results for "${widget.searchQuery}"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---------------- HOUSING RESULTS ----------------
                  if (housingResults.isNotEmpty) ...[
                    Text(
                      "Housing (${housingResults.length})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A4423),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...housingResults.map(
                      (entry) => ProductCard(
                        title: entry['name'] ?? '',
                        subtitle: "Tap to view details",
                        location: entry['location'] ?? '',
                        imagePath:
                            entry['photo'] ?? "assets/images/placeholder.png",
                        onTap: () => showEntryDetails(entry),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ---------------- EATERY RESULTS ----------------
                  if (eateryResults.isNotEmpty) ...[
                    Text(
                      "Eateries (${eateryResults.length})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A4423),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...eateryResults.map(
                      (entry) => ProductCard(
                        title: entry['name'] ?? '',
                        subtitle: "Tap to view details",
                        location: entry['location'] ?? '',
                        imagePath:
                            entry['photo'] ?? "assets/images/placeholder.png",
                        onTap: () => showEntryDetails(entry),
                      ),
                    ),
                  ],
                ],
              ),
    );
  }

  void showEntryDetails(Map entry) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(25),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${entry['name'] ?? 'Details'} (${entry['type'] ?? 'Unknown'})",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
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
                          Text(
                            "Minimum Price: ₱${entry['min_price'] ?? 'N/A'}",
                          ),
                          Text("Open: ${entry['open_time'] ?? ''}"),
                          Text("Close: ${entry['end_time'] ?? ''}"),
                        ] else if (entry['type'] == 'Housing') ...[
                          Text("Monthly Price: ₱${entry['price'] ?? 'N/A'}"),
                          Text("Curfew: ${entry['curfew'] ?? 'N/A'}"),
                        ],

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EstabProfileForCustomer(
                                          ownerId:
                                              entry['owner_id']?.toString() ??
                                              '',
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A4423),
                              ),
                              child: const Text(
                                "View Establishment Profile",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => MapRoutePage(
                                          initialLocation:
                                              entry['location']?.toString() ??
                                              '',
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A4423),
                              ),
                              child: const Text(
                                "View Route",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imagePath,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => const Icon(Icons.broken_image, size: 35),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A4423),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$subtitle • $location",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF7A1E1E)),
            ],
          ),
        ),
      ),
    );
  }
}
