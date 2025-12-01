import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      final ownerId = widget.currentUser["owner_id"];

      final eateryResp = await http.get(
        Uri.parse("https://iskort-public-web.onrender.com/api/eatery"),
      );
      final housingResp = await http.get(
        Uri.parse("https://iskort-public-web.onrender.com/api/housing"),
      );

      final eateryData = jsonDecode(eateryResp.body);
      final housingData = jsonDecode(housingResp.body);

      setState(() {
        ownerEateries = (eateryData['eateries'] ?? [])
            .where((e) => e['owner_id'] == ownerId)
            .toList();

        ownerHousings = (housingData['housings'] ?? [])
            .where((h) => h['owner_id'] == ownerId)
            .toList();

        loading = false;
      });
    } catch (e) {
      print("Error fetching owner establishments: $e");
      setState(() => loading = false);
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
                                        business!['type'] == 'eatery'
                                    ? Icons.restaurant
                                    : Icons.apartment,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                business != null
                                    ? (business!['type'] == 'eatery'
                                        ? "Food / Eatery"
                                        : "Housing")
                                    : "N/A",
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
                          ////////////// Products Tab /////////////////////////////////////////////////////
                          /////////////////////////////////////////////////////////////////////////////////
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Navigate to add product page
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Add Product",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0A4423),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      const Text(
                                        "Your Eateries",
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

                                      const SizedBox(height: 20),
                                      const Text(
                                        "Your Housings",
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
                                )

                              ],
                            ),
                          ),

                          //////////////////////// Reviews Tab/////////////////////////////////////////////////
                          //////////////////////////////////////////////////////////////////////////////////
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
                                // Ratings summary container
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

                          ///////////////////////////// About Tab//////////////////////////////////////////
                          ///////////////////////////////////////////////////////////////////////////////
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Bio and edit
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          business?['bio'] ??
                                              'Write something about your business',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color(0xFF0A4423),
                                      ),
                                      onPressed: _editBioDialog,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Divider(color: Colors.grey.shade400),
                                // Tags
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Your Product Tags",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF0A4423),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _openTagEditor,
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color(0xFF0A4423),
                                      ),
                                      label: const Text(
                                        "Modify / Add Tags",
                                        style: TextStyle(
                                          color: Color(0xFF0A4423),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 8,
                                  children:
                                      (businessTags.isNotEmpty
                                              ? businessTags
                                              : ["No tags yet"])
                                          .map(
                                            (tag) => Chip(
                                              label: Text(
                                                tag,
                                                style: const TextStyle(
                                                  color: Color(0xFF0A4423),
                                                ),
                                              ),
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

                                Divider(color: Colors.grey.shade400),
                                const SizedBox(height: 15),

                                // Contact info
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF0A4423),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        business?['location'] ?? 'N/A',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      color: Color(0xFF0A4423),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      business?['phone_num'] ??
                                          user['phone_num'] ??
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
                                    Text(user['email'] ?? 'N/A'),
                                  ],
                                ),
                                const SizedBox(height: 15),

                                // Open Hours + Online/Offline Button
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Color(0xFF0A4423),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Business hours: ${business?['open_time'] ?? '--'} - ${business?['end_time'] ?? '--'}",
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            business?['is_open'] == true
                                                ? Color(0xFF0A4423)
                                                : Color(0xFF791317),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          business?['is_open'] =
                                              !(business?['is_open'] ?? false);
                                          // TODO: Make API call to update status on server
                                        });
                                      },
                                      child: Text(
                                        business?['is_open'] == true
                                            ? "Open"
                                            : "Closed",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
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

  Widget _businessCard(Map<String, dynamic> business) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            business['eatery_photo'] ?? "",
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) =>
                    const Icon(Icons.store, size: 40, color: Color(0xFF791317)),
          ),
        ),
        title: Text(
          business['name'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A4423),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(business['location'] ?? ''),
            Text("Open: ${business['open_time']} - ${business['end_time']}"),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
      ),
    );
  }

  Widget _establishmentCard(Map<String, dynamic> est, {required bool isEatery}) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      contentPadding: const EdgeInsets.all(15),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          est['eatery_photo'] ??
              est['photo'] ??
              "", // supports both eatery & housing
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.store, size: 40, color: Color(0xFF791317)),
        ),
      ),
      title: Text(
        est['name'] ?? '',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF0A4423),
        ),
      ),
      subtitle: Text(est['location'] ?? ''),
      trailing: IconButton(
        icon: const Icon(Icons.edit, color: Color(0xFF0A4423)),
        onPressed: () {
          Navigator.pushNamed(
            context,
            isEatery ? '/edit-eatery' : '/edit-housing',
            arguments: est,
          );
        },
      ),
    ),
  );
}


  void _editBioDialog() {
    final TextEditingController bioController = TextEditingController(
      text: business?['bio'] ?? '',
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Bio"),
            content: TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Write something about your business",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  setState(() => business?['bio'] = bioController.text.trim());
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Color(0xFF0A4423)),
                ),
              ),
            ],
          ),
    );
  }

  void _openTagEditor() {
    final TextEditingController tagController = TextEditingController();
    List<String> tempTags = List.from(businessTags);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text(
                    "Modify / Add Tags",
                    style: TextStyle(
                      color: Color(0xFF0A4423),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            tempTags
                                .map(
                                  (tag) => Chip(
                                    label: Text(tag),
                                    deleteIcon: const Icon(Icons.close),
                                    onDeleted:
                                        () => setState(
                                          () => tempTags.remove(tag),
                                        ),
                                    backgroundColor: const Color(0xFFF0E1E1),
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF0A4423),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: tagController,
                        decoration: const InputDecoration(
                          hintText: "Enter new tag...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A4423),
                        ),
                        onPressed: () {
                          if (tagController.text.trim().isEmpty) return;
                          setState(
                            () => tempTags.add(tagController.text.trim()),
                          );
                          tagController.clear();
                        },
                        child: const Text(
                          "Add Tag",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => businessTags = tempTags);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Save",
                        style: TextStyle(color: Color(0xFF0A4423)),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}
