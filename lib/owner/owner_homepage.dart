import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iskort/page_routes/edit_establishments.dart';
import 'package:intl/intl.dart';

enum SortMode { classificationName, classificationPrice, globalPrice }

class OwnerHomePage extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const OwnerHomePage({super.key, required this.currentUser});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? business;
  bool loading = true;

  List<String> businessTags = [];
  List<dynamic> ownerEateries = [];
  List<dynamic> ownerHousings = [];
  List<dynamic> products = [];

  List<String> get classifications {
    final tags = <String>{};
    for (var item in products) {
      if (item['classification'] != null &&
          item['classification'].toString().isNotEmpty) {
        tags.add(item['classification'].toString());
      }
    }
    return tags.toList()..sort();
  }

  // Product sort state
  SortMode sortMode = SortMode.classificationName; // default

  // Reviews sorting state
  String reviewSortOrder = 'Newest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchBusiness();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchBusiness() async {
    try {
      final ownerId = widget.currentUser["owner_id"];

      final eateryResp = await http.get(
        Uri.parse("https://iskort-public-web.onrender.com/api/eatery"),
      );
      final housingResp = await http.get(
        Uri.parse("https://iskort-public-web.onrender.com/api/housing"),
      );

      final eateryData = jsonDecode(eateryResp.body);
      final housingData = jsonDecode(housingResp.body);

      ownerEateries =
          (eateryData['eateries'] ?? [])
              .where((e) => e['owner_id'] == ownerId)
              .toList();

      ownerHousings =
          (housingData['housings'] ?? [])
              .where((h) => h['owner_id'] == ownerId)
              .toList();

      // Assign the business to display on the About tab:
      // Prefer the first eatery; if none, use the first housing
      Map<String, dynamic>? selected;
      if (ownerEateries.isNotEmpty) {
        selected = Map<String, dynamic>.from(ownerEateries.first);
        selected['type'] = 'eatery';
      } else if (ownerHousings.isNotEmpty) {
        selected = Map<String, dynamic>.from(ownerHousings.first);
        selected['type'] = 'housing';
      }

      // Fetch products for each business the owner has
      List<dynamic> fetchedProducts = [];

      for (var eatery in ownerEateries) {
        final foodResp = await http.get(
          Uri.parse(
            "https://iskort-public-web.onrender.com/api/food/${eatery['eatery_id']}",
          ),
        );
        if (foodResp.statusCode == 200) {
          final foodData = jsonDecode(foodResp.body);
          for (var food in foodData['foods'] ?? []) {
            food['businessType'] = 'Eatery';
            fetchedProducts.add(food);
          }
        }
      }

      for (var house in ownerHousings) {
        final facResp = await http.get(
          Uri.parse(
            "https://iskort-public-web.onrender.com/api/facility/${house['housing_id']}",
          ),
        );
        if (facResp.statusCode == 200) {
          final facData = jsonDecode(facResp.body);
          for (var fac in facData['facilities'] ?? []) {
            fac['businessType'] = 'Housing';
            fetchedProducts.add(fac);
          }
        }
      }

      setState(() {
        business = selected;
        products = fetchedProducts;
        sortProducts();
        loading = false;
      });
    } catch (e) {
      // Handle errors gracefully
      setState(() => loading = false);
    }
  }

  // Reload products list after any add/edit/delete
  Future<void> _reloadProducts() async {
    await fetchBusiness();
  }

  // Update food item (used by menuCard)
  Future<void> _updateFoodItem(Map<String, dynamic> item) async {
    final foodId = item['food_id'];
    final eateryId = item['eatery_id'];

    await http.put(
      Uri.parse("https://iskort-public-web.onrender.com/api/food/$foodId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": item['name'],
        "eatery_id": eateryId.toString(),
        "classification": item['classification'],
        "price": item['price'],
        "food_pic": item['food_pic'],
      
        "availability": (item['availability'] == true || item['availability'] == 1) ? 1 : 0,
      }),
    );
  }

  // Delete food item (used by menuCard)
  Future<void> _deleteFoodItem(int foodId) async {
    final res = await http.delete(
      Uri.parse("https://iskort-public-web.onrender.com/api/food/$foodId"),
    );
    if (res.statusCode == 200) {
      await _reloadProducts();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Food deleted")));
    }
  }

  // Update facility item (used by facilityCard)
  Future<void> _updateFacilityItem(Map<String, dynamic> item) async {
    final facId = item['facility_id'];
    final housingId = item['housing_id'];

    await http.put(
      Uri.parse("https://iskort-public-web.onrender.com/api/facility/$facId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": item['name'],
        "housing_id": housingId.toString(),
        "facility_pic": item['facility_pic'],
        "price": item['price'],
       
        "has_ac": (item['has_ac'] == true || item['has_ac'] == 1) ? 1 : 0,
        "has_cr": (item['has_cr'] == true || item['has_cr'] == 1) ? 1 : 0,
        "has_kitchen": (item['has_kitchen'] == true || item['has_kitchen'] == 1) ? 1 : 0,
        "type": item['type'],
        
        "availability": (item['availability'] == true || item['availability'] == 1) ? 1 : 0,
        "avail_room": item['avail_room'],
        "additional_info": item['additional_info'],
      }),
    );
  }

  // Delete facility item (used by facilityCard)
  Future<void> _deleteFacilityItem(int facilityId) async {
    final res = await http.delete(
      Uri.parse(
        "https://iskort-public-web.onrender.com/api/facility/$facilityId",
      ),
    );
    if (res.statusCode == 200) {
      await _reloadProducts();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Facility deleted")));
    }
  }

  List<Widget> _buildCategorizedProductList() {
    // Group products by classification (Eatery) and type (Housing)
    Map<String, List<dynamic>> grouped = {};

    for (var item in products) {
      String key;

      if (item['businessType'] == 'Eatery') {
        key = item['classification'] ?? 'Uncategorized';
      } else {
        key = item['type'] ?? 'Facilities';
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    // Sort category groups alphabetically (consistent headers)
    final sortedKeys = grouped.keys.toList()..sort();

    List<Widget> widgets = [];

    for (String key in sortedKeys) {
      final groupItems = grouped[key]!;

      // CATEGORY HEADER
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A4423),
            ),
          ),
        ),
      );

      // CATEGORY ITEMS
      for (var item in groupItems) {
        final isEateryProduct = item['businessType'] == 'Eatery';

        widgets.add(
          GestureDetector(
            onTap: () => _showProductDetails(item),
            child:
                isEateryProduct
                    ? menuCard(
                      item,
                      context: context,
                      updateFoodItem: _updateFoodItem,
                      deleteFoodItem: _deleteFoodItem,
                      reload: _reloadProducts,
                    )
                    : facilityCard(
                      item,
                      context: context,
                      updateFacilityItem: _updateFacilityItem,
                      deleteFacilityItem: _deleteFacilityItem,
                      reload: _reloadProducts,
                    ),
          ),
        );
      }
    }

    return widgets;
  }

  void sortProducts() {
    if (sortMode == SortMode.globalPrice) {
      // LOWEST → HIGHEST
      products.sort(
        (a, b) => double.parse(
          a['price'].toString(),
        ).compareTo(double.parse(b['price'].toString())),
      );
    } else {
      products.sort((a, b) {
        // First sort by classification (only for Eatery items)
        final classA = a['classification'] ?? '';
        final classB = b['classification'] ?? '';
        final classCompare = classA.compareTo(classB);
        if (classCompare != 0) return classCompare;

        // Then sort within classification
        if (sortMode == SortMode.classificationPrice) {
          // LOWEST → HIGHEST price
          return double.parse(
            a['price'].toString(),
          ).compareTo(double.parse(b['price'].toString()));
        } else {
          // Sort alphabetically by name
          return (a['name'] ?? '').compareTo(b['name'] ?? '');
        }
      });
    }
  }

  // Popup for product details
  void _showProductDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.white,
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
                        // Title
                        Text(
                          item['businessType'] == 'Eatery'
                              ? item['name'] ?? 'Food Item'
                              : item['name'] ?? 'Facility',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['businessType'] == 'Eatery'
                                ? item['food_pic'] ?? ''
                                : item['facility_pic'] ?? '',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    const Icon(Icons.image, size: 50),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Details
                        ..._buildDetails(item),
                      ],
                    ),
                  ),
                ),

                // Close button top-right
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    color: const Color(0xFF0A4423),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// Build a list of details with icons when possible, fallback to label-only
  List<Widget> _buildDetails(Map<String, dynamic> item) {
    final details = <Widget>[];

    if (item['businessType'] == 'Eatery') {
      details.add(_detailRow(Icons.category, "Classification", item['classification']));
      details.add(_detailRow(Icons.attach_money, "Price", "₱${item['price']}"));
      details.add(_detailRow(Icons.check_circle, "Availability",
          (item['availability'] == 1) ? "Available" : "Not Available"));
    } else {
      details.add(_detailRow(Icons.room_preferences, "Type", item['type']));
      details.add(_detailRow(Icons.money, "Price", "₱${item['price']}"));
      details.add(_detailRow(Icons.ac_unit, "Aircon", item['has_ac'] == 1 ? 'Yes' : 'No'));
      details.add(_detailRow(Icons.bathtub, "Comfort Room", item['has_cr'] == 1 ? 'Yes' : 'No'));
      details.add(_detailRow(Icons.kitchen, "Kitchen", item['has_kitchen'] == 1 ? 'Yes' : 'No'));
      details.add(_detailRow(Icons.check_circle, "Availability",
          (item['availability'] == 1) ? "Available" : "Not Available"));
      details.add(_detailRow(Icons.meeting_room, "Available Rooms",
          item['avail_room']?.toString() ?? "0"));
      details.add(_detailRow(null, "Additional Info", item['additional_info'] ?? ''));
    }

    return details;
  }

  /// Helper: icon + label + value row; if icon is null, just show label + value
  Widget _detailRow(IconData? icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: const Color(0xFF0A4423), size: 20),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text("$label: $value", style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  // Add Product button logic (simplified: first eatery or housing)
void _addProduct() {
  if (ownerEateries.isNotEmpty) {
    final eateryId = ownerEateries.first['eatery_id'];
    openAddFoodDialog(context, ({
      required String food_pic,
      required String name,
      required String classification,
      required String price,
      required int availability,
    }) async {
      final body = {
        "name": name,
        "eatery_id": eateryId.toString(),
        "classification": classification,
        "price": price,
        "food_pic": food_pic,
        "availability": availability,
      };

      print(jsonEncode(body)); 
      final res = await http.post(
        Uri.parse("https://iskort-public-web.onrender.com/api/food"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        await _reloadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Food added successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add food")),
        );
      }
    });
  } else if (ownerHousings.isNotEmpty) {
    final housingId = ownerHousings.first['housing_id'];
    openAddFacilityDialog(context, ({
      required String name,
      required String facilityPic,
      required String price,
      required bool hasAc,
      required bool hasCr,
      required bool hasKitchen,
      required String type,
      required String additionalInfo,
      required int availability, 
      required int availRoom,    
    }) async {
      final body = {
        "name": name,
        "housing_id": housingId.toString(),
        "facility_pic": facilityPic,
        "price": price,
        "has_ac": hasAc ? 1 : 0,
        "has_cr": hasCr ? 1 : 0,
        "has_kitchen": hasKitchen ? 1 : 0,
        "type": type,
        "additional_info": additionalInfo,
        "availability": availability,
        "avail_room": availRoom,     
      };

      print(jsonEncode(body)); 

      final res = await http.post(
        Uri.parse("https://iskort-public-web.onrender.com/api/facility"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        await _reloadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Facility added successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add facility")),
        );
      }
    });
  }
}

  // Computed sorted reviews based on dropdown selection
  List<Map<String, dynamic>> get sortedReviews {
    if (business?['reviews'] == null) return [];
    List<Map<String, dynamic>> reviews = List<Map<String, dynamic>>.from(
      business!['reviews'],
    );

    reviews.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
      DateTime dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
      if (reviewSortOrder == 'Newest') {
        return dateB.compareTo(dateA); // newest first
      } else {
        return dateA.compareTo(dateB); // oldest first
      }
    });

    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;

    return Scaffold(
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile container
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 20),
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF791317),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                onSelected: (value) {
                                  if (value == 'profile_settings') {
                                    Navigator.pushNamed(
                                      context,
                                      '/profile',
                                      arguments: user,
                                    );
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      const PopupMenuItem(
                                        value: 'profile_settings',
                                        child: Center(
                                          child: Text("Profile Settings"),
                                        ),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                business != null &&
                                        business!['type'] == 'housing'
                                    ? Icons.home
                                    : Icons.restaurant,
                                color: Colors.white,
                              ),

                              const SizedBox(width: 8),
                              Text(
                                business != null
                                    ? (business!['type'] == 'eatery'
                                        ? "Eatery"
                                        : "Housing Business")
                                    : "Business Page",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tabs
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF0A4423),
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: const Color(0xFF0A4423),
                      tabs: const [
                        Tab(text: "Products"),
                        Tab(text: "Reviews"),
                        Tab(text: "About"),
                      ],
                    ),
                    // TabBarView
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Products Tab
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (user['role'] == 'owner')
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _addProduct,
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          "Add Product",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0A4423,
                                          ),
                                        ),
                                      ),
                                      const Spacer(), // pushes the dropdown to the right
                                      SizedBox(
                                        width:
                                            200, // optional fixed width for dropdown
                                        child: DropdownButton<SortMode>(
                                          isExpanded: true,
                                          value: sortMode,
                                          items: const [
                                            DropdownMenuItem(
                                              value:
                                                  SortMode.classificationName,
                                              child: Text("By Category (A-Z)"),
                                            ),
                                            DropdownMenuItem(
                                              value:
                                                  SortMode.classificationPrice,
                                              child: Text(
                                                "By Category (Price)",
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: SortMode.globalPrice,
                                              child: Text("All by Price"),
                                            ),
                                          ],
                                          onChanged: (mode) {
                                            if (mode == null) return;
                                            setState(() {
                                              sortMode = mode;
                                              sortProducts();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child:
                                      products.isEmpty
                                          ? const Center(
                                            child: Text("No products yet"),
                                          )
                                          : ListView(
                                            children:
                                                _buildCategorizedProductList(),
                                          ),
                                ),
                              ],
                            ),
                          ),

                          // Reviews Tab
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Sorting Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Reviews",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A4423),
                                      ),
                                    ),
                                    DropdownButton<String>(
                                      style: const TextStyle(
                                        color: Color(0xFF0A4423),
                                      ),
                                      value: reviewSortOrder,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Newest',
                                          child: Text('Newest'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Oldest',
                                          child: Text('Oldest'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          reviewSortOrder = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Ratings summary container (placeholder)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ...List.generate(5, (index) {
                                        int star = 5 - index;
                                        int count =
                                            0; // TODO: replace with real data
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                "$star 🌻",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: LinearProgressIndicator(
                                                  value: count / 10,
                                                  color: Colors.yellow[700],
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  minHeight: 8,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(count.toString()),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: const [
                                          Text(
                                            "Total Rating: 4.5 🌻",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0A4423),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),
                                // Reviews list
                                Expanded(
                                  child:
                                      sortedReviews.isEmpty
                                          ? const Center(
                                            child: Text("No reviews yet"),
                                          )
                                          : ListView.builder(
                                            itemCount: sortedReviews.length,
                                            itemBuilder: (context, index) {
                                              final review =
                                                  sortedReviews[index];
                                              final rating =
                                                  review['rating'] ?? 0;
                                              final comment =
                                                  review['comment'] ?? '';
                                              final reviewer =
                                                  review['reviewer_name'] ??
                                                  'Anonymous';
                                              final date = review['date'] ?? '';
                                              return Card(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 6,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                elevation: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            reviewer,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          const Spacer(),
                                                          Row(
                                                            children: List.generate(
                                                              rating,
                                                              (_) => const Icon(
                                                                Icons
                                                                    .local_florist,
                                                                size: 16,
                                                                color: Color(
                                                                  0xFFFFD700,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        comment,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        date,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
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
                          ),

                          // About Tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.store,
                                            color: Color(0xFF0A4423),
                                          ), // choose an appropriate icon
                                          const SizedBox(width: 8),
                                          Text(
                                            business?['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight
                                                      .bold, // makes it bold
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (business != null)
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final ownerId =
                                              widget.currentUser["owner_id"];
                                          // Navigate to full edit screen; refresh when back
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => EditEstablishmentsPage(
                                                    business: business!,
                                                    ownerId: ownerId,
                                                  ),
                                            ),
                                          );
                                          await fetchBusiness();
                                        },
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          "Edit establishment",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0A4423,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info, // icon for status
                                          color: const Color(0xFF0A4423),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${_statusText(business)}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _statusColor(business),
                                          ),
                                        ),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: Color(0xFF0A4423),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          business?['owner_name'] ?? '',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          color: Color(0xFF0A4423),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          business?['owner_phone'] ?? '',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email,
                                          color: Color(0xFF0A4423),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          business?['owner_email'] ?? '',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Color(0xFF0A4423),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          business?['location'] ?? '',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.money,
                                          color: Color(0xFF0A4423),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          priceRange,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                if (business?['open_time'] != null &&
                                    business?['end_time'] != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Color(0xFF0A4423),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${business?['open_time']} - ${business?['end_time']}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                if (business?['curfew'] != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.nightlight_round,
                                        color: Color(0xFF0A4423),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        business?['curfew'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 6),
                                Divider(color: Colors.grey[400]),
                                const SizedBox(height: 6),

                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(color: Colors.grey[400]),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            "Bio: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            business?['about_desc'] ??
                                                'Write something about your business',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color(0xFF0A4423),
                                      ),
                                      onPressed: () {
                                        if (business == null) return;
                                        final controller =
                                            TextEditingController(
                                              text:
                                                  business?['about_desc'] ?? '',
                                            );
                                        showDialog(
                                          context: context,
                                          builder:
                                              (_) => AlertDialog(
                                                title: const Text("Edit About"),
                                                content: TextField(
                                                  controller: controller,
                                                  maxLines: 4,
                                                  decoration: const InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    hintText:
                                                        "Describe your business",
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      final id =
                                                          business?['eatery_id'] ??
                                                          business?['housing_id'];
                                                      final endpoint =
                                                          business?['eatery_id'] !=
                                                                  null
                                                              ? "https://iskort-public-web.onrender.com/api/eatery/$id"
                                                              : "https://iskort-public-web.onrender.com/api/housing/$id";

                                                      final body = {
                                                        "about_desc":
                                                            controller.text
                                                                .trim(),
                                                      };
                                                      await http.put(
                                                        Uri.parse(endpoint),
                                                        headers: {
                                                          "Content-Type":
                                                              "application/json",
                                                        },
                                                        body: jsonEncode(body),
                                                      );
                                                      Navigator.pop(context);
                                                      await fetchBusiness(); // reload with updated about_desc
                                                    },
                                                    child: const Text("Save"),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Divider(color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                Text(
                                  "Tags:",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children:
                                      classifications.isEmpty
                                          ? [const Text("No tags yet")]
                                          : classifications
                                              .map(
                                                (c) => Chip(
                                                  label: Text(c),
                                                  backgroundColor: const Color(
                                                    0xFFE0F2F1,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  String get priceRange {
    if (products.isEmpty) return "N/A";
    final prices =
        products
            .map((p) => double.tryParse(p['price'].toString()) ?? 0)
            .toList();
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final formatter = NumberFormat("#,###");
    return "₱${formatter.format(min)} - ₱${formatter.format(max)}";
  }

  // Auto status for eateries; manual status string for housing
  String _statusText(Map<String, dynamic>? biz) {
    if (biz == null) return "N/A";
    final isEatery = biz['type'] == 'eatery' || biz.containsKey('open_time');
    if (isEatery) {
      return getBusinessStatus(biz);
    } else {
      return (biz['status']?.toString().isNotEmpty == true)
          ? biz['status']
          : "Open for tenants";
    }
  }

  Color _statusColor(Map<String, dynamic>? biz) {
    final status = _statusText(biz);
    if (status == "Open" || status == "Open for tenants") {
      return Colors.green;
    } else if (status == "Closed" ||
        status == "No longer accepting" ||
        status == "Fully occupied") {
      return Colors.red;
    }
    return Colors.grey[700]!;
  }

  // Eatery open/closed computation
  String getBusinessStatus(Map<String, dynamic> biz) {
    final open = biz['open_time'];
    final close = biz['end_time'];
    if (open == null || close == null) return "N/A";

    final now = TimeOfDay.now();
    final openParts = open.split(":");
    final closeParts = close.split(":");

    final openTime = TimeOfDay(
      hour: int.parse(openParts[0]),
      minute: int.parse(openParts[1]),
    );
    final closeTime = TimeOfDay(
      hour: int.parse(closeParts[0]),
      minute: int.parse(closeParts[1]),
    );

    bool isOpen =
        (now.hour > openTime.hour ||
            (now.hour == openTime.hour && now.minute >= openTime.minute)) &&
        (now.hour < closeTime.hour ||
            (now.hour == closeTime.hour && now.minute <= closeTime.minute));

    return isOpen ? "Open" : "Closed";
  }
/*
  // Stub methods for About tab actions
  void _editBioDialog() {}
  void _openTagEditor() {}*/
}
