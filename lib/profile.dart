import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // Static fields to persist values across navigation
  static String? _name;
  static String? _email;
  static String? _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get arguments if passed
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _name = args['name'] ?? _name;
      _email = args['email'] ?? _email;
      _role = args['role'] ?? _role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = _name ?? 'User';
    final String email = _email ?? 'No email';
    final String role = _role ?? 'No role';

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 10),

                // Profile Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue[100],
                          child: const Icon(
                            Icons.face,
                            size: 40,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ✅ Name
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        // ✅ Email
                        Text(
                          email,
                          style: const TextStyle(color: Colors.grey),
                        ),

                        // ✅ Role
                        Text(
                          'Role: $role',
                          style: const TextStyle(fontSize: 14),
                        ),

                        const SizedBox(height: 8),

                        // Online Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF0A4423)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Online Status: On',
                            style: TextStyle(
                              color: Color(0xFF0A4423),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildMenuItem(Icons.bookmark, "Saved"),
                        _buildMenuItem(Icons.notifications, "Notifications"),
                        _buildMenuItem(Icons.comment, "Comments"),
                        _buildMenuItem(Icons.settings, "Settings"),
                        _buildMenuItem(Icons.help, "Help",
                            iconColor: Color(0xFF7A1E1E)),

                        const Spacer(),

              
                        if (role.toLowerCase() == "owner")
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/setup-page');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Set up your business",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Back to Homepage
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/homepage',
                                arguments: {
                                  'name': name,
                                  'email': email,
                                  'role': role,
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Back to Homepage',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7A1E1E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Confirm Logout"),
                                  content: const Text(
                                      "Are you sure you want to log out?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // clear session
                                        _name = null;
                                        _email = null;
                                        _role = null;

                                        Navigator.pop(context);
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/login',
                                          (route) => false,
                                        );
                                      },
                                      child: const Text("Yes"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text(
                              "Logout",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String label, {
    Color iconColor = const Color(0xFF7A1E1E),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
