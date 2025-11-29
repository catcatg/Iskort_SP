import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../layouts/admin_layout.dart';

class UserManage extends StatefulWidget {
  const UserManage({super.key});

  @override
  State<UserManage> createState() => _UserManageState();
}

class _UserManageState extends State<UserManage> {
  List users = [];
  List filteredUsers = [];
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
          filteredUsers = users;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
    }
  }

  Future<void> performAction(String id, String role, String action) async {
    try {
      late Uri url;
      if (action == 'verify') {
        url = Uri.parse(
          'https://iskort-public-web.onrender.com/api/admin/verify/$role/$id',
        );
        final response = await http.put(url);
        final data = jsonDecode(response.body);
        print('🛠️ Verify -> ${data['message']}');
      } else if (action == 'reject') {
        url = Uri.parse(
          'https://iskort-public-web.onrender.com/api/admin/reject/$role/$id',
        );
        final response = await http.delete(url);
        final data = jsonDecode(response.body);
        print('🛠️ Reject -> ${data['message']}');
      }

      fetchUsers(); // refresh after action
    } catch (e) {
      print('❌ Action error: $e');
    }
  }

  void onSearchChanged(String query) {
    setState(() {
      filteredUsers =
          users
              .where(
                (user) =>
                    (user['name'] ?? '').toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    (user['email'] ?? '').toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      pageTitle: 'User Management',
      onSearchChanged: onSearchChanged, // ✅ functional search callback
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /*
                    const Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    */
                    const SizedBox(height: 25),
                    Expanded(
                      child:
                          filteredUsers.isEmpty
                              ? const Center(
                                child: Text(
                                  'No users found.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  final isVerified =
                                      (user['is_verified'] ?? 0) == 1;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        '${user['name'] ?? 'Unknown'} (${user['role'] ?? 'No role'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(user['email'] ?? 'No email'),
                                          Text(
                                            'Joined: ${user['created_at'] ?? 'N/A'}',
                                          ),
                                        ],
                                      ),
                                      trailing:
                                          isVerified
                                              ? const Text(
                                                '✅ Verified',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                ),
                                              )
                                              : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextButton(
                                                    onPressed:
                                                        () => performAction(
                                                          (user['id'] ?? '')
                                                              .toString(),
                                                          user['table_name'] ??
                                                              'user',
                                                          'verify',
                                                        ),
                                                    child: const Text('Verify'),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => performAction(
                                                          (user['id'] ?? '')
                                                              .toString(),
                                                          user['table_name'] ??
                                                              'user',
                                                          'reject',
                                                        ),
                                                    child: const Text(
                                                      'Reject',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
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
    );
  }
}
