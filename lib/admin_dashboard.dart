import 'package:flutter/material.dart';
import 'user_data_service.dart';
import '../layouts/admin_layout.dart';

// --- Main Widget ---

<<<<<<< Updated upstream
class DashboardAdminScreen extends StatelessWidget {
  const DashboardAdminScreen({super.key});
=======
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
      print('❌ Error fetching users: $e');
    }
  }

  Future<void> performAction(String id, String role, String action, Map user) async {
    try {
      late Uri url;
      if (action == 'verify') {
        url = Uri.parse('https://iskort-public-web.onrender.com/api/admin/verify/$role/$id');
        final response = await http.put(url);
        final data = jsonDecode(response.body);
        print('🛠️ Verify -> ${data['message']}');

        // SEND notification based on preference
        final pref = (user['notif_preference'] ?? 'email').toString().toLowerCase();
        final email = user['email'] ?? 'unknown';
        final phone = user['phone_number'] ?? 'unknown';
        if (pref == 'email') print('Sent verification to $email via Email');
        else if (pref == 'sms') print('Sent verification to $phone via SMS');
        else print('Sent verification to $email via Email and $phone via SMS');

      } else if (action == 'reject') {
        url = Uri.parse('https://iskort-public-web.onrender.com/api/admin/reject/$role/$id');
        final response = await http.delete(url);
        final data = jsonDecode(response.body);
        print('🛠️ Reject -> ${data['message']}');

        // SEND notification based on preference
        final pref = (user['notif_preference'] ?? 'email').toString().toLowerCase();
        final email = user['email'] ?? 'unknown';
        final phone = user['phone_number'] ?? 'unknown';
        if (pref == 'email') print('Sent rejection to $email via Email');
        else if (pref == 'sms') print('Sent rejection to $phone via SMS');
        else print('Sent rejection to $email via Email and $phone via SMS');
      }

      fetchUsers(); // refresh list after action
    } catch (e) {
      print('❌ Action error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      pageTitle: "Dashboard",
      child: MainDashboardContent(),
    );
  }
}

// --- Dashboard Main Content ---

class MainDashboardContent extends StatelessWidget {
  const MainDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          /*
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          */
          const SizedBox(height: 25),

          // Dynamic Data
          FutureBuilder<List<DashboardItem>>(
            future: UserDataService.fetchUserMetrics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading metrics: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snapshot.hasData) {
                final dashboardData = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 20.0,
                    mainAxisSpacing: 20.0,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: dashboardData.length,
                  itemBuilder: (context, index) {
                    return DashboardCard(item: dashboardData[index]);
                  },
                );
              }

              return const Center(child: Text('No dashboard data available.'));
            },
          ),
        ],
      ),
<<<<<<< Updated upstream
    );
  }
}

// --- Dashboard Card Widget ---

class DashboardCard extends StatelessWidget {
  final DashboardItem item;
  const DashboardCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      color: const Color.fromARGB(255, 229, 58, 58),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(item.icon, color: item.iconColor, size: 36),
              ],
            ),
          ],
        ),
      ),
=======
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
                        Text('Phone: ${user['phone_number'] ?? 'N/A'}'),
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
>>>>>>> Stashed changes
    );
  }
}
