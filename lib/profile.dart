import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      horizontal: 24,
                      vertical: 24,
                    ),
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
                        // Avatar
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

                        // Name
                        const Text(
                          'Catherine Adonis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          '@catsudon',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),

                        // Online Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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

                        // Menu Items
                        _buildMenuItem(Icons.bookmark, "Saved"),
                        _buildMenuItem(Icons.notifications, "Notifications"),
                        _buildMenuItem(Icons.comment, "Comments"),
                        _buildMenuItem(Icons.settings, "Settings"),
                        _buildMenuItem(
                          Icons.help,
                          "Help",
                          iconColor: Color(0xFF7A1E1E),
                        ),

                        const Spacer(),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7A1E1E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {},
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
