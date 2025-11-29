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
  int selectedPage = 0; // 0 = Users, 1 = Eatery, 2 = Housing

  // Base API URL
  final String baseUrl = 'https://iskort-public-web.onrender.com';

  // ========== USERS ==========
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

  Widget buildUserPage() {
    if (isLoadingUsers) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return const Center(child: Text('No users found'));

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index] as Map;
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
            trailing: verified
                ? const Text('✅ Verified', style: TextStyle(color: Colors.green))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => performUserAction(u['id'].toString(), 'verify'),
                        child: const Text('Verify'),
                      ),
                      TextButton(
                        onPressed: () => performUserAction(u['id'].toString(), 'reject'),
                        child: const Text('Reject', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ========== EATERIES ==========
  List eateries = [];
  bool isLoadingEateries = true;

  Future<void> fetchEateries() async {
    setState(() => isLoadingEateries = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/eatery'));
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        // backend returns owner_name/owner_email/owner_phone via JOIN
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
    if (isLoadingEateries) return const Center(child: CircularProgressIndicator());
    if (eateries.isEmpty) return const Center(child: Text('No eateries to verify'));

    return ListView.builder(
      itemCount: eateries.length,
      itemBuilder: (context, index) {
        final e = eateries[index] as Map;
        final verified = (e['is_verified'] ?? 0) == 1;
        final eateryId = e['eatery_id']?.toString() ?? e['id']?.toString() ?? '';

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
            trailing: verified
                ? const Text('✅ Verified', style: TextStyle(color: Colors.green))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => performEateryAction(eateryId, 'verify'),
                        child: const Text('Verify'),
                      ),
                      TextButton(
                        onPressed: () => performEateryAction(eateryId, 'reject'),
                        child: const Text('Reject', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ========== HOUSINGS ==========
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
    if (isLoadingHousings) return const Center(child: CircularProgressIndicator());
    if (housings.isEmpty) return const Center(child: Text('No housings to verify'));

    return ListView.builder(
      itemCount: housings.length,
      itemBuilder: (context, index) {
        final h = housings[index] as Map;
        final verified = (h['is_verified'] ?? 0) == 1;
        final housingId = h['housing_id']?.toString() ?? h['id']?.toString() ?? '';

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
            trailing: verified
                ? const Text('✅ Verified', style: TextStyle(color: Colors.green))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => performHousingAction(housingId, 'verify'),
                        child: const Text('Verify'),
                      ),
                      TextButton(
                        onPressed: () => performHousingAction(housingId, 'reject'),
                        child: const Text('Reject', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ========== UI & Lifecycle ==========
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
          color: isActive ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.blue : Colors.black54),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.blue.shade900 : Colors.black87,
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
        return buildUserPage();
      case 1:
        return buildEateryPage();
      case 2:
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
            color: Colors.grey.shade200,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Admin Panel',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                buildSidebarItem('Users Verification', Icons.people, 0),
                buildSidebarItem('Eatery Verification', Icons.restaurant, 1),
                buildSidebarItem('Housing Verification', Icons.hotel, 2),
                const Spacer(),
                const Divider(),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Profile'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60,
                  color: Colors.blue.shade600,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    selectedPage == 0
                        ? 'User Verification'
                        : selectedPage == 1
                            ? 'Eatery Verification'
                            : 'Housing Verification',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
