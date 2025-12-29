import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
//import 'user_reviews.dart';

// Mirrors owner layout but read-only for customers
enum SortMode {
  classificationName,
  classificationPrice,
  globalPrice,
  unavailable,
}

class EstabProfileForCustomer extends StatefulWidget {
  final String ownerId;
  final String estType; // 'Eatery' or 'Housing'
  final String? eateryId; // optional, only if Eatery
  final String? housingId; // optional, only if Housing

  const EstabProfileForCustomer({
    super.key,
    required this.ownerId,
    required this.estType,
    this.eateryId,
    this.housingId,
  });

  @override
  State<EstabProfileForCustomer> createState() =>
      _EstabProfileForCustomerState();
}

class _EstabProfileForCustomerState extends State<EstabProfileForCustomer>
    with TickerProviderStateMixin {
  late TabController _tabController;

  //Logged in user

  Future<int?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<String?> getLoggedInUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  Map<String, dynamic>? business;
  bool loading = true;

  // Unified products list for this establishment (foods or facilities)
  List<dynamic> products = [];

  // Derived tags from products (classification for Eatery, type for Housing)
  List<String> businessTags = [];

  // Sorting states
  SortMode sortMode = SortMode.classificationName; // default
  String reviewSortOrder = 'Newest'; // reviews sorting

  // Current logged-in user’s own review (if any)
  Map<String, dynamic>? userReview;

  List<dynamic> allProducts = []; // keep all products fetched

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bootstrap();
    _fetchUserReview(); // ensure your own review shows up
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await fetchBusiness();
    await _fetchProductsForEstablishment();
    _filterAvailableProducts();
    _deriveTagsFromProducts();
    sortProducts();
  }

  //check product availability
  bool _isProductAvailable(Map<String, dynamic> item) {
    if (widget.estType == 'Eatery') return true; // all foods are available

    // Housing availability logic
    if (item['type'] == 'Shared') {
      final rooms = int.tryParse(item['avail_room']?.toString() ?? '0') ?? 0;
      return rooms > 0;
    } else {
      return item['availability'] == true || item['availability'] == 0;
    }
  }

  void _filterAvailableProducts() {
    products = allProducts.where((item) => _isProductAvailable(item)).toList();
  }

  Future<void> fetchBusiness() async {
    try {
      if (widget.estType == 'Eatery' && widget.eateryId != null) {
        final res = await http.get(
          Uri.parse("https://iskort-public-web.onrender.com/api/eatery"),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final list = List<Map<String, dynamic>>.from(data['eateries'] ?? []);

          Map<String, dynamic>? found;

          for (final e in list) {
            if (e['eatery_id'].toString() == widget.eateryId) {
              found = e;
              break;
            }
          }

          setState(() {
            business = found;
            loading = false;
          });
        } else {
          setState(() => loading = false);
        }
      } else if (widget.estType == 'Housing' && widget.housingId != null) {
        final res = await http.get(
          Uri.parse("https://iskort-public-web.onrender.com/api/housing"),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final list = List<Map<String, dynamic>>.from(data['housings'] ?? []);

          Map<String, dynamic>? found;

          for (final h in list) {
            if (h['housing_id'].toString() == widget.housingId) {
              found = h;
              break;
            }
          }

          setState(() {
            business = found;
            loading = false;
          });
        } else {
          setState(() => loading = false);
        }
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _fetchProductsForEstablishment() async {
    try {
      List<dynamic> fetchedProducts = [];

      if (widget.estType == 'Eatery' && widget.eateryId != null) {
        final res = await http.get(
          Uri.parse(
            "https://iskort-public-web.onrender.com/api/food/${widget.eateryId}",
          ),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final foods = List<Map<String, dynamic>>.from(data['foods'] ?? []);
          fetchedProducts =
              foods.map((f) {
                final map = Map<String, dynamic>.from(f);
                map['businessType'] = 'Eatery';
                return map;
              }).toList();
        }
      } else if (widget.estType == 'Housing' && widget.housingId != null) {
        final res = await http.get(
          Uri.parse(
            "https://iskort-public-web.onrender.com/api/facility/${widget.housingId}",
          ),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final facilities = List<Map<String, dynamic>>.from(
            data['facilities'] ?? [],
          );
          fetchedProducts =
              facilities.map((f) {
                final map = Map<String, dynamic>.from(f);
                map['businessType'] = 'Housing';
                return map;
              }).toList();
        }
      }

      setState(() {
        allProducts = fetchedProducts;
        _filterAvailableProducts(); // now products shows available items
      });
    } catch (e) {
      // leave products empty on error
    }
  }

  Future<void> _fetchUserReview() async {
    final userId = await getLoggedInUserId();
    if (userId == null) return;

    final estId =
        widget.estType == 'Eatery' ? widget.eateryId : widget.housingId;
    final endpoint =
        widget.estType == 'Eatery'
            ? 'https://iskort-public-web.onrender.com/api/eatery_reviews/user/$userId/$estId'
            : 'https://iskort-public-web.onrender.com/api/housing_reviews/user/$userId/$estId';

    try {
      final res = await http.get(Uri.parse(endpoint));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          userReview = data['review'];
        });
      }
    } catch (_) {}
  }

  Future<void> _addReview(String type, int rating, String comment) async {
    final baseUrl = 'https://iskort-public-web.onrender.com';
    final userId = await getLoggedInUserId();
    if (userId == null) return;
    final endpoint =
        type == 'Eatery'
            ? '$baseUrl/api/eatery_reviews'
            : '$baseUrl/api/housing_reviews';

    final body = {
      'user_id': userId.toString(),
      if (type == 'Eatery') 'eatery_id': widget.eateryId ?? '',
      if (type == 'Housing') 'housing_id': widget.housingId ?? '',
      'rating': rating.toString(),
      'comment': comment,
    };

    try {
      final res = await http.post(Uri.parse(endpoint), body: body);
      if (res.statusCode == 200) {
        await _fetchUserReview();
        await fetchBusiness();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Your review is saved.")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to save review.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error while saving review.")),
      );
    }
  }

  Future<void> _editReview(
    int reviewId,
    String type,
    int rating,
    String comment,
  ) async {
    final endpoint =
        type == 'Eatery'
            ? 'https://iskort-public-web.onrender.com/api/eatery_reviews/$reviewId'
            : 'https://iskort-public-web.onrender.com/api/housing_reviews/$reviewId';

    try {
      final res = await http.put(
        Uri.parse(endpoint),
        body: {'rating': rating.toString(), 'comment': comment},
      );
      if (res.statusCode == 200) {
        await _fetchUserReview();
        await fetchBusiness();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your review is updated.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update review.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error while updating review.")),
      );
    }
  }

  Future<void> _deleteReview(int reviewId, String type) async {
    final endpoint =
        type == 'Eatery'
            ? 'https://iskort-public-web.onrender.com/api/eatery_reviews/$reviewId'
            : 'https://iskort-public-web.onrender.com/api/housing_reviews/$reviewId';

    try {
      final res = await http.delete(Uri.parse(endpoint));
      if (res.statusCode == 200) {
        setState(() => userReview = null);
        await fetchBusiness();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your review is deleted.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete review.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error while deleting review.")),
      );
    }
  }

  void _showAddReviewDialog() {
    final TextEditingController commentController = TextEditingController();
    int rating = 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Add a review",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A4423),
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setInnerState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(labelText: 'Comment'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(5, (index) {
                        final filled = index < rating;
                        return IconButton(
                          icon: Icon(
                            filled
                                ? Icons.local_florist
                                : Icons.local_florist_outlined,
                            color:
                                filled ? const Color(0xFFFBAC24) : Colors.grey,
                          ),
                          onPressed: () {
                            setInnerState(() => rating = index + 1);
                          },
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF791317),
                foregroundColor: Colors.white,
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.isEmpty || rating == 0) return;
                await _addReview(
                  widget.estType,
                  rating,
                  commentController.text,
                );
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0A4423),
                foregroundColor: Colors.white,
              ),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _showEditReviewDialog(Map<String, dynamic> review) {
    final TextEditingController commentController = TextEditingController(
      text: review['comment'],
    );
    int rating = review['rating'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Review"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: commentController),
              const SizedBox(height: 10),
              Row(
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      Icons.local_florist,
                      color: i < rating ? const Color(0xFFFBAC24) : Colors.grey,
                    ),
                    onPressed: () => setState(() => rating = i + 1),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _editReview(
                  review['review_id'],
                  widget.estType,
                  rating,
                  commentController.text,
                );
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deriveTagsFromProducts() {
    final tags = <String>{};
    for (var item in products) {
      if (widget.estType == 'Eatery') {
        final c = item['classification']?.toString() ?? '';
        if (c.isNotEmpty) tags.add(c);
      } else {
        final t = item['type']?.toString() ?? '';
        if (t.isNotEmpty) tags.add(t);
      }
    }
    businessTags = tags.toList()..sort();
  }

  void sortProducts() {
    List<dynamic> filtered;

    if (sortMode == SortMode.unavailable) {
      filtered =
          allProducts.where((item) => !_isProductAvailable(item)).toList();
    } else {
      filtered =
          allProducts.where((item) => _isProductAvailable(item)).toList();
    }

    // Sorting logic
    if (sortMode == SortMode.globalPrice) {
      filtered.sort(
        (a, b) => double.parse(
          a['price'].toString(),
        ).compareTo(double.parse(b['price'].toString())),
      );
    } else if (sortMode == SortMode.classificationPrice) {
      filtered.sort((a, b) {
        final groupA =
            widget.estType == 'Eatery'
                ? (a['classification'] ?? '')
                : (a['type'] ?? '');
        final groupB =
            widget.estType == 'Eatery'
                ? (b['classification'] ?? '')
                : (b['type'] ?? '');
        final cmp = groupA.compareTo(groupB);
        if (cmp != 0) return cmp;
        return double.parse(
          a['price'].toString(),
        ).compareTo(double.parse(b['price'].toString()));
      });
    } else if (sortMode == SortMode.classificationName) {
      filtered.sort((a, b) {
        final groupA =
            widget.estType == 'Eatery'
                ? (a['classification'] ?? '')
                : (a['type'] ?? '');
        final groupB =
            widget.estType == 'Eatery'
                ? (b['classification'] ?? '')
                : (b['type'] ?? '');
        final cmp = groupA.compareTo(groupB);
        if (cmp != 0) return cmp;
        return (a['name'] ?? '').compareTo(b['name'] ?? '');
      });
    }

    setState(() {
      products = filtered;
    });
  }

  List<Widget> _buildCategorizedProductList() {
    final Map<String, List<dynamic>> grouped = {};

    for (var item in products) {
      String key;
      if (widget.estType == 'Eatery') {
        key = item['classification']?.toString() ?? 'Uncategorized';
      } else {
        key = item['type']?.toString() ?? 'Facilities';
      }
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final widgets = <Widget>[];

    for (final key in sortedKeys) {
      final groupItems = grouped[key]!;

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

      for (final item in groupItems) {
        final isAvailable = _isProductAvailable(item);
        widgets.add(
          GestureDetector(
            onTap: () => _showProductDetails(item),
            child: Card(
              color: isAvailable ? Colors.white : Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.estType == 'Eatery'
                        ? (item['food_pic']?.toString() ?? '')
                        : (item['facility_pic']?.toString() ?? ''),
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => const Icon(Icons.image, size: 32),
                  ),
                ),
                title: Text(
                  item['name']?.toString() ?? '',
                  style: TextStyle(
                    color: isAvailable ? Colors.black : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  widget.estType == 'Eatery'
                      ? "${item['classification'] ?? ''} • ₱${item['price'] ?? ''}"
                      : "${item['type'] ?? ''} • ₱${item['price'] ?? ''}",
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  void _showProductDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']?.toString() ?? 'Details',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A4423),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Image.network(
                          widget.estType == 'Eatery'
                              ? (item['food_pic']?.toString() ?? '')
                              : (item['facility_pic']?.toString() ?? ''),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Icon(Icons.image, size: 32),
                        ),
                        const SizedBox(height: 10),

                        // Eatery info
                        if (widget.estType == 'Eatery') ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.category,
                                color: Color(0xFF0A4423),
                              ),
                              const SizedBox(width: 6),
                              Text(item['classification']?.toString() ?? ''),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.price_check,
                                color: Color(0xFF0A4423),
                              ),
                              const SizedBox(width: 6),
                              Text("₱${item['price'] ?? ''}"),
                            ],
                          ),
                        ]
                        // Housing info
                        else ...[
                          Row(
                            children: [
                              const Icon(Icons.home, color: Color(0xFF0A4423)),
                              const SizedBox(width: 6),
                              Text(item['type']?.toString() ?? ''),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.price_check,
                                color: Color(0xFF0A4423),
                              ),
                              const SizedBox(width: 6),
                              Text("₱${item['price'] ?? ''}"),
                            ],
                          ),
                          Divider(),
                          if (item.containsKey('has_ac'))
                            Row(
                              children: [
                                const Icon(
                                  Icons.ac_unit,
                                  color: Color(0xFF0A4423),
                                ),
                                const SizedBox(width: 6),
                                Text(item['has_ac'] == true ? 'Yes' : 'No'),
                              ],
                            ),
                          if (item.containsKey('has_cr'))
                            Row(
                              children: [
                                const Icon(
                                  Icons.bathtub,
                                  color: Color(0xFF0A4423),
                                ),
                                const SizedBox(width: 6),
                                Text(item['has_cr'] == true ? 'Yes' : 'No'),
                              ],
                            ),
                          if (item.containsKey('has_kitchen'))
                            Row(
                              children: [
                                const Icon(
                                  Icons.kitchen,
                                  color: Color(0xFF0A4423),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item['has_kitchen'] == true ? 'Yes' : 'No',
                                ),
                              ],
                            ),
                          Divider(),
                          if (item.containsKey('additional_info'))
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info,
                                  color: Color(0xFF0A4423),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item['additional_info']?.toString() ?? '',
                                  ),
                                ),
                              ],
                            ),
                        ],
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // Close button at top-right
                Positioned(
                  right: -10,
                  top: -10,
                  child: IconButton(
                    padding: EdgeInsets.all(25),
                    icon: const Icon(Icons.close, color: Color(0xFF0A4423)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  List<Map<String, dynamic>> get sortedReviews {
    if (business?['reviews'] == null) return [];

    final reviews = List<Map<String, dynamic>>.from(business!['reviews']);

    reviews.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
      final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
      return reviewSortOrder == 'Newest'
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });

    return reviews;
  }

  // UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${business?['name'] ?? 'Establishment'}'s Profile",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
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
      body:
          loading
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
              : business == null
              ? const Center(child: Text("Establishment not found"))
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
                        gradient: const LinearGradient(
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                child: const Icon(
                                  Icons.store,
                                  size: 50,
                                  color: Color(0xFF791317),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            business?['name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
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
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 5,
                      tabs: const [
                        Tab(text: "Products"),
                        Tab(text: "Reviews"),
                        Tab(text: "About"),
                      ],
                    ),

                    // Tab views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Products tab
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Sort Products",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    DropdownButton<SortMode>(
                                      value: sortMode,
                                      items: const [
                                        DropdownMenuItem(
                                          value: SortMode.classificationName,
                                          child: Text("By Category (A-Z)"),
                                        ),
                                        DropdownMenuItem(
                                          value: SortMode.classificationPrice,
                                          child: Text("By Category (Price)"),
                                        ),
                                        DropdownMenuItem(
                                          value: SortMode.globalPrice,
                                          child: Text("All"),
                                        ),
                                        DropdownMenuItem(
                                          value: SortMode.unavailable,
                                          child: Text("Unavailable Products"),
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

                          // Reviews tab
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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

                                // Add review button
                                ElevatedButton.icon(
                                  onPressed: _showAddReviewDialog,
                                  icon: const Icon(Icons.add),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFF0A4423),
                                    foregroundColor: Colors.white,
                                  ),
                                  label: const Text("Add a review"),
                                ),

                                const SizedBox(height: 10),

                                // Show user's own review first
                                if (userReview != null) ...[
                                  const Text(
                                    "Your Review",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF0A4423),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                "You",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Spacer(),
                                              Row(
                                                children: List.generate(
                                                  userReview!['rating'] ?? 0,
                                                  (_) => const Icon(
                                                    Icons.local_florist,
                                                    size: 16,
                                                    color: Color(0xFFFBAC24),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            userReview!['comment'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            userReview!['created_at'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  _showEditReviewDialog(
                                                    userReview!,
                                                  );
                                                },
                                                child: const Text("Edit"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _deleteReview(
                                                    userReview!['review_id'],
                                                    widget.estType,
                                                  );
                                                },
                                                child: const Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                ],

                                // Show all reviews
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
                                                  review['comment']
                                                      ?.toString() ??
                                                  '';
                                              final reviewer =
                                                  review['reviewer_name']
                                                      ?.toString() ??
                                                  'Anonymous';
                                              final date =
                                                  review['date']?.toString() ??
                                                  '';

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
                                                                  0xFFFBAC24,
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

                          // About tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  business?['about_desc']?.toString() ??
                                      business?['bio']?.toString() ??
                                      'No description yet.',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 15),
                                Divider(color: Colors.grey.shade400),
                                const SizedBox(height: 15),

                                // Tags derived from products (classification/type)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children:
                                      businessTags.isEmpty
                                          ? [
                                            const Chip(
                                              label: Text('No tags yet'),
                                            ),
                                          ]
                                          : businessTags
                                              .map(
                                                (tag) => Chip(
                                                  label: Text(tag),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    side: const BorderSide(
                                                      color: Color(0xFF0A4423),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                ),
                                const SizedBox(height: 15),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF0A4423),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        business?['location']?.toString() ??
                                            'N/A',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      color: Color(0xFF0A4423),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      business?['owner_phone']?.toString() ??
                                          business?['phone_num']?.toString() ??
                                          'N/A',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email,
                                      color: Color(0xFF0A4423),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      business?['owner_email']?.toString() ??
                                          business?['email']?.toString() ??
                                          'N/A',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),

                                // Hours or curfew display
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Color(0xFF0A4423),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.estType == 'Eatery'
                                            ? "Business hours: ${business?['open_time']?.toString() ?? '--'} - ${business?['end_time']?.toString() ?? '--'}"
                                            : "Curfew: ${business?['curfew']?.toString() ?? '--'}",
                                      ),
                                    ),
                                  ],
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
}
