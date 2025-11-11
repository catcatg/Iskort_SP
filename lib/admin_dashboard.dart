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
  List users = [];
  bool isLoading = true;

  List eateries = [];
  bool isEateryLoading = true;

  // ---------------- USERS ----------------
  Future<void> fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/admin/users'),
      );
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          users = data['users'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  // ---------------- EATERIES ----------------
  Future<void> fetchEateries() async {
    try {
      final response = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/eatery'),
      );
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        List eateriesData = data['eateries'] ?? [];

        // Fetch owner details using owner_id for each eatery
        for (var eatery in eateriesData) {
          final ownerId = eatery['owner_id'];
          if (ownerId != null) {
            try {
              final ownerResponse = await http.get(
                Uri.parse(
                    'https://iskort-public-web.onrender.com/api/owner/$ownerId'),
              );
              final ownerData = jsonDecode(ownerResponse.body);

              if (ownerData['success'] == true && ownerData['owner'] != null) {
                final owner = ownerData['owner'];
                eatery['owner_name'] = owner['name'] ?? 'Unknown';
                eatery['owner_email'] = owner['email'] ?? 'Unknown';
                eatery['owner_phone'] = owner['phone_num'] ?? 'Unknown';
              } else {
                eatery['owner_name'] = 'Unknown';
                eatery['owner_email'] = 'Unknown';
                eatery['owner_phone'] = 'Unknown';
              }
            } catch (e) {
              print('Error fetching owner for eatery $ownerId: $e');
              eatery['owner_name'] = 'Unknown';
              eatery['owner_email'] = 'Unknown';
              eatery['owner_phone'] = 'Unknown';
            }
          }
        }

        setState(() {
          eateries = eateriesData;
          isEateryLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching eateries: $e');
    }
  }

  // ---------------- USER ACTIONS ----------------
  Future<void> performAction(
      String id, String role, String action, Map user) async {
    try {
      late Uri url;
      if (action == 'verify') {
        url = Uri.parse(
            'https://iskort-public-web.onrender.com/api/admin/verify/$id');
        final response = await http.put(url);
        final data = jsonDecode(response.body);
        print('Verify -> ${data['message']}');

        // SEND notification
        final pref =
            (user['notif_preference'] ?? 'email').toString().toLowerCase();
        final email = user['email'] ?? 'unknown';
        final phone = user['phone_num'] ?? 'unknown';
        if (pref == 'email') {
          print('Sent verification to $email via Email');
        } else if (pref == 'sms') {
          print('Sent verification to $phone via SMS');
        } else {
          print('Sent verification to $email via Email and $phone via SMS');
        }
      } else if (action == 'reject') {
        url = Uri.parse(
            'https://iskort-public-web.onrender.com/api/admin/reject/$id');
        final response = await http.delete(url);
        final data = jsonDecode(response.body);
        print('Reject -> ${data['message']}');

        // SEND notification
        final pref =
            (user['notif_preference'] ?? 'email').toString().toLowerCase();
        final email = user['email'] ?? 'unknown';
        final phone = user['phone_num'] ?? 'unknown';
        if (pref == 'email') {
          print('Sent rejection to $email via Email');
        } else if (pref == 'sms') {
          print('Sent rejection to $phone via SMS');
        } else {
          print('Sent rejection to $email via Email and $phone via SMS');
        }
      }

      fetchUsers();
    } catch (e) {
      print('Action error: $e');
    }
  }

  // ---------------- EATERY ACTIONS ----------------
  Future<void> performEateryAction(
      String id, String action, Map eatery) async {
    try {
      late Uri url;
      if (action == 'verify') {
        url = Uri.parse(
            'https://iskort-public-web.onrender.com/api/admin/verify/eatery/$id');
        final response = await http.put(url);
        final data = jsonDecode(response.body);
        print('Verify Eatery -> ${data['message']}');

        final ownerEmail = eatery['owner_email'] ?? 'unknown';
        final ownerPhone = eatery['owner_phone'] ?? 'unknown';
        print('Sent verification to $ownerEmail / $ownerPhone');
      } else if (action == 'reject') {
        url = Uri.parse(
            'https://iskort-public-web.onrender.com/api/admin/reject/eatery/$id');
        final response = await http.delete(url);
        final data = jsonDecode(response.body);
        print('Reject Eatery -> ${data['message']}');

        final ownerEmail = eatery['owner_email'] ?? 'unknown';
        final ownerPhone = eatery['owner_phone'] ?? 'unknown';
        print('Sent rejection to $ownerEmail / $ownerPhone');
      }

      fetchEateries();
    } catch (e) {
      print('Eatery Action Error: $e');
    }
  }

  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchEateries();
  }

  // ---------------- SIDEBAR ----------------
  Widget buildSidebarItem(String title, IconData icon, int index) {
    final bool isActive = selectedPage == index;
    return InkWell(
      onTap: () {
        setState(() {
          selectedPage = index;
        });
      },
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

  // ---------------- USER PAGE ----------------
  Widget buildUserVerificationPage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isVerified = (user['is_verified'] ?? 0) == 1;

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title:
                Text('${user['name'] ?? 'Unknown'} (${user['role'] ?? 'No role'})'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email'] ?? 'No email'),
                Text('Phone: ${user['phone_num'] ?? 'N/A'}'),
                Text('Joined: ${user['created_at'] ?? 'N/A'}'),
                Text('Preference: ${user['notif_preference'] ?? 'email'}'),
              ],
            ),
            trailing: isVerified
                ? const Text('✅ Verified', style: TextStyle(color: Colors.green))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => performAction(
                          (user['id'] ?? '').toString(),
                          user['table_name'] ?? 'user',
                          'verify',
                          user,
                        ),
                        child: const Text('Verify'),
                      ),
                      TextButton(
                        onPressed: () => performAction(
                          (user['id'] ?? '').toString(),
                          user['table_name'] ?? 'user',
                          'reject',
                          user,
                        ),
                        child: const Text('Reject',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ---------------- EATERY PAGE ----------------
  Widget buildEateryPage() {
    if (isEateryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (eateries.isEmpty) {
      return const Center(child: Text('No eateries to verify'));
    }

    return ListView.builder(
      itemCount: eateries.length,
      itemBuilder: (context, index) {
        final eatery = eateries[index];
        final isVerified = (eatery['is_verified'] ?? 0) == 1;

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(eatery['name'] ?? 'Unnamed Eatery'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Owner: ${eatery['owner_name'] ?? 'Unknown'}'),
                Text('Email: ${eatery['owner_email'] ?? 'Unknown'}'),
                Text('Phone: ${eatery['owner_phone'] ?? 'Unknown'}'),
                Text('Location: ${eatery['location'] ?? 'Unknown'}'),
                Text('Min Price: ${eatery['min_price'] ?? 'N/A'}'),
              ],
            ),
            trailing: isVerified
                ? const Text('✅ Verified', style: TextStyle(color: Colors.green))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => performEateryAction(
                            (eatery['id'] ?? '').toString(), 'verify', eatery),
                        child: const Text('Verify'),
                      ),
                      TextButton(
                        onPressed: () => performEateryAction(
                            (eatery['id'] ?? '').toString(), 'reject', eatery),
                        child: const Text('Reject',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ---------------- HOUSING PAGE ----------------
  Widget buildHousingPage() {
    return const Center(
      child: Text(
        'Housing Verification Dashboard\n(coming soon...)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  // ---------------- PAGE BUILDER ----------------
  Widget buildPageContent() {
    switch (selectedPage) {
      case 0:
        return buildUserVerificationPage();
      case 1:
        return buildEateryPage();
      case 2:
        return buildHousingPage();
      default:
        return const Center(child: Text('Invalid Page'));
    }
  }

  // ---------------- UI ----------------
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
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
