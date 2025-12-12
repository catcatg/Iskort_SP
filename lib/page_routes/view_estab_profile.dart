import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Mirrors owner layout but read-only for customers
enum SortMode { classificationName, classificationPrice, globalPrice }

class EstabProfileForCustomer extends StatefulWidget {
  final String ownerId;
  final String estType;       // 'Eatery' or 'Housing'
  final String? eateryId;     // optional, only if Eatery
  final String? housingId;    // optional, only if Housing

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

  Map<String, dynamic>? business;
  bool loading = true;

  // Unified products list for this establishment (foods or facilities)
  List<dynamic> products = [];

  // Derived tags from products (classification for Eatery, type for Housing)
  List<String> businessTags = [];

  // Sorting states
  SortMode sortMode = SortMode.classificationName; // default
  String reviewSortOrder = 'Newest'; // reviews sorting

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

    Future<void> _bootstrap() async {
    await fetchBusiness();
    await _fetchProductsForEstablishment();
    _deriveTagsFromProducts();
    sortProducts();
  }

  Future<void> fetchBusiness() async {
    try {
      if (widget.estType == 'Eatery' && widget.eateryId != null) {
        final res = await http.get(
          Uri.parse("https://iskort-public-web.onrender.com/api/eatery"),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final match = (data['eateries'] ?? [])
              .firstWhere(
                (e) => e['eatery_id'].toString() == widget.eateryId,
                orElse: () => null,
              );
          setState(() {
            business = match;
            loading = false;
          });
        }
      } else if (widget.estType == 'Housing' && widget.housingId != null) {
        final res = await http.get(
          Uri.parse("https://iskort-public-web.onrender.com/api/housing"),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final match = (data['housings'] ?? [])
              .firstWhere(
                (h) => h['housing_id'].toString() == widget.housingId,
                orElse: () => null,
              );
          setState(() {
            business = match;
            loading = false;
          });
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
      if (widget.estType == 'Eatery' && widget.eateryId != null) {
        final res = await http.get(
          Uri.parse("https://iskort-public-web.onrender.com/api/food/${widget.eateryId}"),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final foods = List<Map<String, dynamic>>.from(data['foods'] ?? []);
          // Normalize to include businessType for grouping
          products = foods.map((f) {
            final map = Map<String, dynamic>.from(f);
            map['businessType'] = 'Eatery';
            return map;
          }).toList();
        }
      } else if (widget.estType == 'Housing' && widget.housingId != null) {
        final res = await http.get(
          Uri.parse("https://iskort-public-web.onrender.com/api/facility/${widget.housingId}"),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final facilities = List<Map<String, dynamic>>.from(data['facilities'] ?? []);
          products = facilities.map((f) {
            final map = Map<String, dynamic>.from(f);
            map['businessType'] = 'Housing';
            return map;
          }).toList();
        }
      }
      setState(() {});
    } catch (e) {
      // leave products empty on error
    }
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
    if (sortMode == SortMode.globalPrice) {
      // LOWEST → HIGHEST across all items
      products.sort((a, b) =>
          double.parse(a['price'].toString()).compareTo(double.parse(b['price'].toString())));
    } else {
      products.sort((a, b) {
        // Group order by category (Eatery: classification; Housing: type)
        final groupA = widget.estType == 'Eatery'
            ? (a['classification'] ?? '')
            : (a['type'] ?? '');
        final groupB = widget.estType == 'Eatery'
            ? (b['classification'] ?? '')
            : (b['type'] ?? '');
        final cmp = groupA.compareTo(groupB);
        if (cmp != 0) return cmp;

        // Within group: by price or by name
        if (sortMode == SortMode.classificationPrice) {
          return double.parse(a['price'].toString())
              .compareTo(double.parse(b['price'].toString()));
        } else {
          return (a['name'] ?? '').compareTo(b['name'] ?? '');
        }
      });
    }
    setState(() {});
  }

  List<Widget> _buildCategorizedProductList() {
    // Group products by category key
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

      // Category header
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

      // Category items (read-only cards)
      for (final item in groupItems) {
        widgets.add(
          GestureDetector(
            onTap: () => _showProductDetails(item),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 32),
                  ),
                ),
                title: Text(item['name']?.toString() ?? ''),
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
      builder: (_) => AlertDialog(
        title: Text(item['name']?.toString() ?? 'Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                widget.estType == 'Eatery'
                    ? (item['food_pic']?.toString() ?? '')
                    : (item['facility_pic']?.toString() ?? ''),
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 32),
              ),
              const SizedBox(height: 10),
              if (widget.estType == 'Eatery') ...[
                Text("Classification: ${item['classification'] ?? ''}"),
                Text("Price: ₱${item['price'] ?? ''}"),
              ] else ...[
                Text("Type: ${item['type'] ?? ''}"),
                Text("Price: ₱${item['price'] ?? ''}"),
                if (item.containsKey('has_ac'))
                  Text("Aircon: ${item['has_ac'] == true ? 'Yes' : 'No'}"),
                if (item.containsKey('has_cr'))
                  Text("Comfort Room: ${item['has_cr'] == true ? 'Yes' : 'No'}"),
                if (item.containsKey('has_kitchen'))
                  Text("Kitchen: ${item['has_kitchen'] == true ? 'Yes' : 'No'}"),
                if (item.containsKey('additional_info'))
                  Text("Info: ${item['additional_info'] ?? ''}"),
              ],
            ],
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

    List<Map<String, dynamic>> get sortedReviews {
    if (business?['reviews'] == null) return [];
    final reviews = List<Map<String, dynamic>>.from(
      business!['reviews'] ?? [],
    );

    reviews.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b['date'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return reviewSortOrder == 'Newest' ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    return reviews;
  }

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
      body: loading
          ? const Center(
              child: SizedBox(
                width: 50, height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 5, color: Color(0xFF0A4423),
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
                              children: const [
                                Icon(Icons.storefront, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  "Business Page",
                                  style: TextStyle(
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
                            // Products tab: read-only mirror of owner layout
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  Expanded(
                                    child: products.isEmpty
                                        ? const Center(child: Text("No products yet"))
                                        : ListView(children: _buildCategorizedProductList()),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        style: const TextStyle(color: Color(0xFF0A4423)),
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

                                  // Add review works; keep as-is
                                  ElevatedButton.icon(
                                    onPressed: _showAddReviewDialog,
                                    icon: const Icon(Icons.add),
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xFF0A4423),
                                      foregroundColor: Colors.white,
                                    ),
                                    label: const Text(
                                      "Add a review",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Expanded(
                                    child: sortedReviews.isEmpty
                                        ? const Center(child: Text("No reviews yet"))
                                        : ListView.builder(
                                            itemCount: sortedReviews.length,
                                            itemBuilder: (context, index) {
                                              final review = sortedReviews[index];
                                              final rating = review['rating'] ?? 0;
                                              final comment = review['comment']?.toString() ?? '';
                                              final reviewer = review['reviewer_name']?.toString() ?? 'Anonymous';
                                              final date = review['date']?.toString() ?? '';

                                              return Card(
                                                margin: const EdgeInsets.symmetric(vertical: 6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                elevation: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(10),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            reviewer,
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          const Spacer(),
                                                          Row(
                                                            children: List.generate(
                                                              rating,
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
                                                      Text(comment, style: const TextStyle(fontSize: 14)),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        date,
                                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                                    children: businessTags.isEmpty
                                        ? [const Chip(label: Text('No tags yet'))]
                                        : businessTags
                                            .map((tag) => Chip(
                                                  label: Text(tag),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    side: const BorderSide(color: Color(0xFF0A4423)),
                                                  ),
                                                ))
                                            .toList(),
                                  ),
                                  const SizedBox(height: 15),

                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Color(0xFF0A4423)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(business?['location']?.toString() ?? 'N/A'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      const Icon(Icons.phone, color: Color(0xFF0A4423)),
                                      const SizedBox(width: 8),
                                      Text(business?['owner_phone']?.toString() ??
                                          business?['phone_num']?.toString() ??
                                          'N/A'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      const Icon(Icons.email, color: Color(0xFF0A4423)),
                                      const SizedBox(width: 8),
                                      Text(business?['owner_email']?.toString() ??
                                          business?['email']?.toString() ??
                                          'N/A'),
                                    ],
                                  ),
                                  const SizedBox(height: 15),

                                  // Hours or curfew display
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, color: Color(0xFF0A4423)),
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

  void _showAddReviewDialog() {
    final _nameController = TextEditingController();
    final _commentController = TextEditingController();
    int _rating = 0;

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
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Your Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(labelText: 'Comment'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(5, (index) {
                        final filled = index < _rating;
                        return IconButton(
                          icon: Icon(
                            filled ? Icons.local_florist : Icons.local_florist_outlined,
                            color: filled ? const Color(0xFFFBAC24) : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _rating = index + 1);
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
              onPressed: () {
                if (_nameController.text.isEmpty ||
                    _commentController.text.isEmpty ||
                    _rating == 0) {
                  return;
                }
                setState(() {
                  business ??= {};
                  business!['reviews'] ??= [];
                  (business!['reviews'] as List).add({
                    'reviewer_name': _nameController.text,
                    'comment': _commentController.text,
                    'rating': _rating,
                    'date': DateTime.now().toIso8601String(),
                  });
                });
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
}