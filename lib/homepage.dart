import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'widgets/reusables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page_routes/preference_popup.dart';
import 'page_routes/view_estab_profile.dart';
import 'page_routes/map_route.dart';
import 'page_routes/search_results_page.dart';
import 'package:iskort/page_routes/all_establishments.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List allEntries = [];
  bool isLoading = true;
  Map<String, dynamic> user = {};

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

      final eateryResp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/eatery'),
      );

      if (eateryResp.statusCode == 200) {
        final data = jsonDecode(eateryResp.body);
        final verified = (data['eateries'] ?? []).where(
          (e) => e['is_verified'] == 1,
        );

        for (var e in verified) {
          e['type'] = 'Eatery';
          e['photo'] = e['eatery_photo'] ?? '';
          e['tags'] = await _fetchEateryTags(e['eatery_id']);
          entries.add(e);
        }
      }

      final housingResp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/housing'),
      );

      if (housingResp.statusCode == 200) {
        final data = jsonDecode(housingResp.body);
        final verified = (data['housings'] ?? []).where(
          (h) => h['is_verified'] == 1,
        );

        for (var h in verified) {
          h['type'] = 'Housing';
          h['photo'] = h['housing_photo'] ?? '';
          h['tags'] = await _fetchHousingTags(h['housing_id']);
          entries.add(h);
        }
      }

      await loadPreferences();
      await checkFirstTimeUser();

      setState(() {
        allEntries = entries;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching entries: $e");
      setState(() => isLoading = false);
    }
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
                builder: (_) => SearchResultsPage(initialQuery: query),
                settings: RouteSettings(arguments: allEntries),
              ),
            ).then((_) {
              // Clear the search bar after returning from the search results page
              _searchController.clear();
            });
          }
        },
      ),
    );
  }

  Widget _buildNavCardsRow() {
    final navCards = [
      {'name': 'Housing', 'route': '/housing', 'icon': Icons.home},
      {'name': 'Eateries', 'route': '/food', 'icon': Icons.restaurant_menu},
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
                  height: 70,
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
                        color: Color(0x660A4423),
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

  Future<bool> isEntrySaved(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_locations') ?? [];

    return saved.any((item) {
      final decoded = jsonDecode(item);
      return decoded['name'] == name;
    });
  }

  // fetch eatery tags for ueer recommendation
  Future<List<String>> _fetchEateryTags(int eateryId) async {
    final res = await http.get(
      Uri.parse('https://iskort-public-web.onrender.com/api/food/$eateryId'),
    );

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final tags = <String>{};

    for (var food in data['foods'] ?? []) {
      final c = food['classification'];
      if (c != null && c.toString().isNotEmpty) {
        tags.add(c.toString());
      }
    }

    return tags.toList();
  }

  // fetch housing tags for user recommendation
  Future<List<String>> _fetchHousingTags(int housingId) async {
    final res = await http.get(
      Uri.parse(
        'https://iskort-public-web.onrender.com/api/facility/$housingId',
      ),
    );

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final tags = <String>{};

    for (var fac in data['facilities'] ?? []) {
      final t = fac['type'];
      if (t != null && t.toString().isNotEmpty) {
        tags.add(t.toString());
      }
    }

    return tags.toList();
  }

  List<Map<String, dynamic>> _filterByPrefs(String type, List<String> prefs) {
    final matched =
        allEntries
            .where((e) => e['type'] == type)
            .where((e) {
              final tags = List<String>.from(e['tags'] ?? []);
              return tags.any((t) => prefs.contains(t));
            })
            .cast<Map<String, dynamic>>()
            .toList();

    // fallback if no matches
    return (matched.isNotEmpty
            ? matched
            : allEntries.where((e) => e['type'] == type))
        .take(3)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  void showEntryDetails(Map entry) async {
    bool isLiked = await isEntrySaved(entry['name']);

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                void toggleFavorite() async {
                  setState(() => isLiked = !isLiked);

                  final prefs = await SharedPreferences.getInstance();
                  List<String> savedList =
                      prefs.getStringList('saved_locations') ?? [];

                  Map<String, dynamic> record = {
                    'name': entry['name'] ?? '',
                    'address': entry['location'] ?? '',
                    'type': entry['type'] ?? '',
                    'timestamp': DateTime.now().toIso8601String(),
                  };

                  String recordJson = jsonEncode(record);

                  if (isLiked) {
                    savedList.removeWhere((item) {
                      final decoded = jsonDecode(item);
                      return decoded['name'] == entry['name'];
                    });

                    savedList.add(recordJson);
                    await prefs.setStringList('saved_locations', savedList);

                    showFadingPopup(context, "Location added to favorites!");
                  } else {
                    savedList.removeWhere((item) {
                      final decoded = jsonDecode(item);
                      return decoded['name'] == entry['name'];
                    });

                    await prefs.setStringList('saved_locations', savedList);
                    showFadingPopup(context, "Removed from favorites.");
                  }
                }

                return Stack(
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),
                            AspectRatio(
                              aspectRatio: 1.2,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  entry['photo'] ??
                                      "assets/images/placeholder.png",
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
                            ),

                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${entry['name'] ?? 'Details'} (${entry['type'] ?? 'Unknown'})",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: toggleFavorite,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 16,
                                    child: Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked ? Colors.red : Colors.grey,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                                    entry['location'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (entry['type'] == 'Eatery') ...[
                              Text(
                                "Minimum Price: ₱${entry['min_price'] ?? 'N/A'}",
                              ),
                              Text("Open: ${entry['open_time'] ?? ''}"),
                              Text("Close: ${entry['end_time'] ?? ''}"),
                            ] else if (entry['type'] == 'Housing') ...[
                              Text(
                                "Monthly Price: ₱${entry['price'] ?? 'N/A'}",
                              ),
                              Text("Curfew: ${entry['curfew'] ?? 'N/A'}"),
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
                                          ownerId:
                                              entry['owner_id']?.toString() ??
                                              '',
                                          estType:
                                              entry['type']?.toString() ?? '',
                                          eateryId:
                                              entry['eatery_id']?.toString(),
                                          housingId:
                                              entry['housing_id']?.toString(),
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
                                              entry['location']?.toString() ??
                                              '',
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
                );
              },
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text(
                    "Hello, ${user['name'] ?? 'Isko!'}!",
                    style: const TextStyle(
                      color: Color(0xFF0A4423),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 3,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      gradient: LinearGradient(
                        colors: [Color(0xFF0A4423), Color(0xFF1E8A58)],
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 15),
            GeneralSearchBar(),
            const SizedBox(height: 20),
            _buildNavCardsRow(),
            const SizedBox(height: 15),

            Divider(color: Color(0xFF0A4423)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A4423),
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
              const Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: Color(0xFF0A4423),
                  ),
                ),
              )
            else if (allEntries.isEmpty)
              const Text("No entries found")
            else ...[
              // Housing section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Housing",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A4423),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => const AllEstablishmentsPage(
                                establishmentType: 'Housing',
                              ),
                          settings: RouteSettings(arguments: allEntries),
                        ),
                      );
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
              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 3 / 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children:
                    _filterByPrefs('Housing', currentHousingPrefs)
                        .map(
                          (entry) => ProductCard(
                            title: entry['name'] ?? '',
                            location: entry['location'] ?? '',
                            imagePath: entry['photo'] ?? '',
                            onTap: () => showEntryDetails(entry),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 10),
              Divider(color: Color(0xFF0A4423)),
              const SizedBox(height: 10),

              // Eateries section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Eateries",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A4423),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => const AllEstablishmentsPage(
                                establishmentType: 'Eatery',
                              ),
                          settings: RouteSettings(arguments: allEntries),
                        ),
                      );
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
              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 3 / 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children:
                    _filterByPrefs('Eatery', currentFoodPrefs)
                        .map(
                          (entry) => ProductCard(
                            title: entry['name'] ?? '',
                            location: entry['location'] ?? '',
                            imagePath: entry['photo'] ?? '',
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
        onTap: (index) async {
          if (index == 1) {
            Navigator.pushNamed(context, '/route');
          } else if (index == 2 && user.isNotEmpty) {
            final changed = await Navigator.pushNamed(
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

            if (changed == true) {
              fetchEntries();
            }
          }
        },
      ),
    );
  }
}
