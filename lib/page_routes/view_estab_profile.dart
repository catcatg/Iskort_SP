import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EstabProfileForCustomer extends StatefulWidget {
  final String ownerId;

  const EstabProfileForCustomer({super.key, required this.ownerId});

  @override
  State<EstabProfileForCustomer> createState() =>
      _EstabProfileForCustomerState();
}

class _EstabProfileForCustomerState extends State<EstabProfileForCustomer>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? business;
  bool loading = true;
  List<String> businessTags = [];
  List<dynamic> ownerEateries = [];
  List<dynamic> ownerHousings = [];

  // Reviews sorting state
  String reviewSortOrder = 'Newest';

  @override
  void initState() {
    super.initState();
    fetchBusiness();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchBusiness() async {
    try {
      final ownerId = widget.ownerId;

      final eateryResp = await http.get(
        Uri.parse("https://iskort-public-web.onrender.com/api/eatery"),
      );
      final housingResp = await http.get(
        Uri.parse("https://iskort-public-web.onrender.com/api/housing"),
      );

      final eateryData = jsonDecode(eateryResp.body);
      final housingData = jsonDecode(housingResp.body);

      setState(() {
        ownerEateries =
            (eateryData['eateries'] ?? [])
                .where((e) => e['owner_id']?.toString() == ownerId)
                .toList();

        ownerHousings =
            (housingData['housings'] ?? [])
                .where((h) => h['owner_id']?.toString() == ownerId)
                .toList();

        business =
            ownerEateries.isNotEmpty
                ? ownerEateries.first
                : ownerHousings.isNotEmpty
                ? ownerHousings.first
                : null;

        loading = false;
      });
    } catch (e) {
      print("Error fetching establishment: $e");
      setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get sortedReviews {
    if (business?['reviews'] == null) return [];
    List<Map<String, dynamic>> reviews = List<Map<String, dynamic>>.from(
      business!['reviews'] ?? [],
    );

    reviews.sort((a, b) {
      DateTime dateA =
          DateTime.tryParse(a['date'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      DateTime dateB =
          DateTime.tryParse(b['date'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (reviewSortOrder == 'Newest') {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateB);
      }
    });

    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
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
                          // Products tab
                          ListView(
                            padding: const EdgeInsets.all(8),
                            children: [
                              const Text(
                                "Eateries",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF0A4423),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...ownerEateries.map(
                                (e) => _establishmentCard(e, isEatery: true),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Housings",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF0A4423),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...ownerHousings.map(
                                (h) => _establishmentCard(h, isEatery: false),
                              ),
                            ],
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

                          // About tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  business?['bio']?.toString() ??
                                      'No description yet.',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 15),
                                Wrap(
                                  spacing: 8,
                                  children:
                                      (businessTags.isNotEmpty
                                              ? businessTags
                                              : ['No tags yet'])
                                          .map(
                                            (tag) => Chip(
                                              label: Text(tag),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                      business?['email']?.toString() ?? 'N/A',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Color(0xFF0A4423),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Business hours: ${business?['open_time']?.toString() ?? '--'} - ${business?['end_time']?.toString() ?? '--'}",
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            business?['is_open'] == true
                                                ? const Color(0xFF0A4423)
                                                : const Color(0xFF791317),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            business?['is_open'] == true
                                                ? Icons.circle
                                                : Icons.circle_outlined,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            business?['is_open'] == true
                                                ? "Open"
                                                : "Closed",
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
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

  Widget _establishmentCard(
    Map<String, dynamic> est, {
    required bool isEatery,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            est['eatery_photo']?.toString() ?? est['photo']?.toString() ?? "",
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) =>
                    const Icon(Icons.store, size: 40, color: Color(0xFF791317)),
          ),
        ),
        title: Text(
          est['name']?.toString() ?? 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A4423),
          ),
        ),
        subtitle: Text(est['location']?.toString() ?? 'N/A'),
      ),
    );
  }
}
