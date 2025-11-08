import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List users = [];
  bool isLoading = true;

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

  Future<void> performAction(String id, String role, String action, Map user) async {
    try {
      late Uri url;
      if (action == 'verify') {
        url = Uri.parse('https://iskort-public-web.onrender.com/api/admin/verify/$id');
        final response = await http.put(url);
        final data = jsonDecode(response.body);
        print('Verify -> ${data['message']}');

        // SEND notification based on preference
        final pref = (user['notif_preference'] ?? 'email').toString().toLowerCase();
        final email = user['email'] ?? 'unknown';
        final phone = user['phone_num'] ?? 'unknown';
        if (pref == 'email') print('Sent verification to $email via Email');
        else if (pref == 'sms') print('Sent verification to $phone via SMS');
        else print('Sent verification to $email via Email and $phone via SMS');

      } else if (action == 'reject') {
        url = Uri.parse('https://iskort-public-web.onrender.com/api/admin/reject/$id');
        final response = await http.delete(url);
        final data = jsonDecode(response.body);
        print('Reject -> ${data['message']}');

        // SEND notification based on preference
        final pref = (user['notif_preference'] ?? 'email').toString().toLowerCase();
        final email = user['email'] ?? 'unknown';
        final phone = user['phone_num'] ?? 'unknown';
        if (pref == 'email') print('Sent rejection to $email via Email');
        else if (pref == 'sms') print('Sent rejection to $phone via SMS');
        else print('Sent rejection to $email via Email and $phone via SMS');
      }

      fetchUsers(); // refresh list after action
    } catch (e) {
      print('Action error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isVerified = (user['is_verified'] ?? 0) == 1;

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('${user['name'] ?? 'Unknown'} (${user['role'] ?? 'No role'})'),
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
            ),
    );
  }
}
