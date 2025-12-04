// CLEAN + OPTIMIZED ADMIN DASHBOARD
// Uses backend JOIN results (owner_name, owner_email, owner_phone)
// Single-file admin dashboard with Users / Eateries / Housings

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int selectedPage = 0; // 0 = Dashboard, 1 = Users, 2 = Eatery, 3 = Housing

  final String baseUrl = 'https://iskort-public-web.onrender.com';

  // USERS
  List users = [];
  bool isLoadingUsers = true;

  Future<void> fetchUsers() async {
    setState(() => isLoadingUsers = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/admin/users'));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          users = List.from(data['users'] ?? []);
          isLoadingUsers = false;
        });
      } else {
        setState(() => isLoadingUsers = false);
      }
    } catch (e) {
      print('fetchUsers error: $e');
      setState(() => isLoadingUsers = false);
    }
  }

  Future<void> performUserAction(String id, String action) async {
    try {
      if (action == 'verify') {
        await http.put(Uri.parse('$baseUrl/api/admin/verify/$id'));
      } else {
        await http.delete(Uri.parse('$baseUrl/api/admin/reject/$id'));
      }
      await fetchUsers();
    } catch (e) {
      print('performUserAction error: $e');
    }
  }

  /////////////////USER MANAGEMENT/////////////////////////////////////////////
  Widget buildUserPage() {
    if (isLoadingUsers) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return const Center(child: Text('No users found'));

    // Deduplicate users by email (latest created_at wins)
    final Map<String, Map<String, dynamic>> uniqueUsersMap = {};
    for (var u in users) {
      final email = u['email'] ?? u['id'].toString();
      final existing = uniqueUsersMap[email];
      if (existing == null) {
        uniqueUsersMap[email] = Map<String, dynamic>.from(u);
      } else {
        DateTime existingDate =
            DateTime.tryParse(existing['created_at'] ?? '') ?? DateTime(2000);
        DateTime currentDate =
            DateTime.tryParse(u['created_at'] ?? '') ?? DateTime(2000);
        if (currentDate.isAfter(existingDate)) {
          uniqueUsersMap[email] = Map<String, dynamic>.from(u);
        }
      }
    }
    final uniqueUsers = uniqueUsersMap.values.toList();

    // Separate users into categories
    final verifiedUsers =
        uniqueUsers.where((u) => (u['is_verified'] ?? 0) == 1).toList();
    final unverifiedUsers =
        uniqueUsers.where((u) => (u['is_verified'] ?? 0) == 0).toList();
    final rejectedUsers =
        uniqueUsers.where((u) => (u['is_verified'] ?? 0) == -1).toList();

    // Sort by created_at descending
    int sortByDate(Map a, Map b) {
      DateTime dateA =
          DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      DateTime dateB =
          DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    }

    verifiedUsers.sort(sortByDate);
    unverifiedUsers.sort(sortByDate);
    rejectedUsers.sort(sortByDate);

    Widget buildUserList(List<Map<String, dynamic>> list) {
      if (list.isEmpty)
        return const Center(child: Text('No users in this category'));

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final u = list[index];
          final verified = (u['is_verified'] ?? 0) == 1;

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('${u['name'] ?? 'Unknown'} (${u['role'] ?? 'user'})'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u['email'] ?? 'No email'),
                  Text('Phone: ${u['phone_num'] ?? 'N/A'}'),
                  Text('Joined: ${u['created_at'] ?? 'N/A'}'),
                ],
              ),
              trailing:
                  verified
                      ? const Text(
                        '✅ Verified',
                        style: TextStyle(color: Colors.green),
                      )
                      : u['is_verified'] == -1
                      ? const Text(
                        '❌ Rejected',
                        style: TextStyle(color: Colors.red),
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed:
                                () => performUserAction(
                                  u['id'].toString(),
                                  'verify',
                                ),
                            child: const Text('Verify'),
                          ),
                          TextButton(
                            onPressed:
                                () => performUserAction(
                                  u['id'].toString(),
                                  'reject',
                                ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
            ),
          );
        },
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade200,
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
              indicator: const BoxDecoration(
                color: Color.fromARGB(231, 10, 68, 35),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: 'Verified (${verifiedUsers.length})'),
                Tab(text: 'Unverified (${unverifiedUsers.length})'),
                Tab(text: 'Rejected (${rejectedUsers.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                buildUserList(verifiedUsers),
                buildUserList(unverifiedUsers),
                buildUserList(rejectedUsers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // EATERIES
  List eateries = [];
  bool isLoadingEateries = true;

  Future<void> fetchEateries() async {
    setState(() => isLoadingEateries = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/eatery'));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          eateries = List.from(data['eateries'] ?? []);
          isLoadingEateries = false;
        });
      } else {
        setState(() => isLoadingEateries = false);
      }
    } catch (e) {
      print('fetchEateries error: $e');
      setState(() => isLoadingEateries = false);
    }
  }

  Future<void> performEateryAction(String id, String action) async {
    try {
      if (action == 'verify') {
        await http.put(Uri.parse('$baseUrl/api/admin/verify/eatery/$id'));
      } else {
        await http.delete(Uri.parse('$baseUrl/api/admin/reject/eatery/$id'));
      }
      await fetchEateries();
    } catch (e) {
      print('performEateryAction error: $e');
    }
  }

  Widget buildEateryPage() {
    if (isLoadingEateries)
      return const Center(child: CircularProgressIndicator());
    if (eateries.isEmpty)
      return const Center(child: Text('No eateries to verify'));

    return ListView.builder(
      itemCount: eateries.length,
      itemBuilder: (context, index) {
        final e = eateries[index] as Map;
        final verified = (e['is_verified'] ?? 0) == 1;
        final eateryId =
            e['eatery_id']?.toString() ?? e['id']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(e['name'] ?? 'Unnamed Eatery'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Owner: ${e['owner_name'] ?? 'Unknown'}'),
                Text('Email: ${e['owner_email'] ?? 'Unknown'}'),
                Text('Phone: ${e['owner_phone'] ?? 'Unknown'}'),
                Text('Location: ${e['location'] ?? 'Unknown'}'),
                Text('Min Price: ${e['min_price'] ?? 'N/A'}'),
              ],
            ),
            trailing:
                verified
                    ? const Text(
                      '✅ Verified',
                      style: TextStyle(color: Colors.green),
                    )
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed:
                              () => performEateryAction(eateryId, 'verify'),
                          child: const Text('Verify'),
                        ),
                        TextButton(
                          onPressed:
                              () => performEateryAction(eateryId, 'reject'),
                          child: const Text(
                            'Reject',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }

  // HOUSINGS
  List housings = [];
  bool isLoadingHousings = true;

  Future<void> fetchHousings() async {
    setState(() => isLoadingHousings = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/housing'));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          housings = List.from(data['housings'] ?? []);
          isLoadingHousings = false;
        });
      } else {
        setState(() => isLoadingHousings = false);
      }
    } catch (e) {
      print('fetchHousings error: $e');
      setState(() => isLoadingHousings = false);
    }
  }

  Future<void> performHousingAction(String id, String action) async {
    try {
      if (action == 'verify') {
        await http.put(Uri.parse('$baseUrl/api/admin/verify/housing/$id'));
      } else {
        await http.delete(Uri.parse('$baseUrl/api/admin/reject/housing/$id'));
      }
      await fetchHousings();
    } catch (e) {
      print('performHousingAction error: $e');
    }
  }

  Widget buildHousingPage() {
    if (isLoadingHousings)
      return const Center(child: CircularProgressIndicator());
    if (housings.isEmpty)
      return const Center(child: Text('No housings to verify'));

    return ListView.builder(
      itemCount: housings.length,
      itemBuilder: (context, index) {
        final h = housings[index] as Map;
        final verified = (h['is_verified'] ?? 0) == 1;
        final housingId =
            h['housing_id']?.toString() ?? h['id']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(h['name'] ?? 'Unnamed Housing'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Owner: ${h['owner_name'] ?? 'Unknown'}'),
                Text('Email: ${h['owner_email'] ?? 'Unknown'}'),
                Text('Phone: ${h['owner_phone'] ?? 'Unknown'}'),
                Text('Address: ${h['location'] ?? h['address'] ?? 'Unknown'}'),
                Text('Price: ${h['price'] ?? h['rent_price'] ?? 'N/A'}'),
              ],
            ),
            trailing:
                verified
                    ? const Text(
                      '✅ Verified',
                      style: TextStyle(color: Colors.green),
                    )
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed:
                              () => performHousingAction(housingId, 'verify'),
                          child: const Text('Verify'),
                        ),
                        TextButton(
                          onPressed:
                              () => performHousingAction(housingId, 'reject'),
                          child: const Text(
                            'Reject',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }

  // DASHBOARD SUMMARY
  Widget buildAdminDashboard() {
    // Count unverified users
    final unverifiedUsersCount =
        users.where((u) => (u['is_verified'] ?? 0) != 1).length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300, // Max width of each card
          childAspectRatio: 2.5, // Keep card shape consistent
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        children: [
          buildDashboardCard(
            'Total Users',
            users.length,
            Icons.people,
            Colors.blue,
          ),
          buildDashboardCard(
            'Unverified Users',
            unverifiedUsersCount,
            Icons.person_off,
            Colors.red,
          ),
          buildDashboardCard(
            'Eateries',
            eateries.length,
            Icons.restaurant,
            Colors.orange,
          ),
          buildDashboardCard(
            'Housings',
            housings.length,
            Icons.hotel,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget buildDashboardCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Scale font sizes based on screen width
    double titleFontSize = screenWidth < 350 ? 14 : 16;
    double countFontSize = screenWidth < 350 ? 16 : 18;
    double iconSize = screenWidth < 350 ? 28 : 35;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0A4423),
                    ),
                    overflow: TextOverflow.ellipsis, // prevent overflow
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: countFontSize,
                      fontWeight: FontWeight.bold,
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

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchEateries();
    fetchHousings();
  }

  Widget buildSidebarItem(String title, IconData icon, int index) {
    final bool isActive = selectedPage == index;
    return InkWell(
      onTap: () => setState(() => selectedPage = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color:
              isActive ? Color.fromARGB(110, 121, 19, 22) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Color(0xFF791317) : Colors.black54),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Color(0xFF791317) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPageContent() {
    switch (selectedPage) {
      case 0:
        return buildAdminDashboard();
      case 1:
        return buildUserPage();
      case 2:
        return buildEateryPage();
      case 3:
        return buildHousingPage();
      default:
        return const Center(child: Text('Invalid Page'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 230,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A4423),
                  ),
                ),
                Divider(color: Colors.grey.shade400),
                const SizedBox(height: 30),

                // Sidebar items
                buildSidebarItem('Admin Dashboard', Icons.dashboard, 0),
                const SizedBox(height: 10),
                buildSidebarItem('Users Verification', Icons.people, 1),
                const SizedBox(height: 10),
                buildSidebarItem('Eatery Verification', Icons.restaurant, 2),
                const SizedBox(height: 10),
                buildSidebarItem('Housing Verification', Icons.hotel, 3),

                const Spacer(),
                const Divider(thickness: 2, color: Colors.grey),
                const SizedBox(height: 10),

                SizedBox(
                  width:
                      double
                          .infinity, // Makes the button fill the available width
                  child: TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text(
                      'View Admin Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4423),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    selectedPage == 0
                        ? 'Admin Dashboard'
                        : selectedPage == 1
                        ? 'User Management'
                        : selectedPage == 2
                        ? 'Eatery Verification'
                        : 'Housing Verification',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: buildPageContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
