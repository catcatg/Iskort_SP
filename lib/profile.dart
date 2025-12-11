import 'package:flutter/material.dart';
import 'package:iskort/page_routes/saved_locations.dart';
import 'package:iskort/page_routes/edit_establishments.dart';
import 'owner/setup_eatery_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? _name;
  String? _email;
  String? _role;
  String? _phone;
  String? _notifPreference;
  int? _ownerId; // <-- added ownerId

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _name = args['name'] ?? _name;
      _email = args['email'] ?? _email;
      _role = args['role'] ?? _role;
      _phone = args['phone'] ?? _phone;
      _notifPreference = args['notifPreference'] ?? _notifPreference;
      _ownerId = args['owner_id']; // <-- capture owner_id
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _name ?? 'User';
    final email = _email ?? 'No email';
    final role = _role ?? 'No role';

    return Scaffold(
      body: Stack(
        children: [
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.green[100],
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: Color(0xFF0A4423),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildMenuItem(Icons.bookmark, "Saved Locations", () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => SavedLocations(
                                    onSelect: (record) {
                                      Navigator.pushNamed(
                                        context,
                                        '/map_route',
                                        arguments: {
                                          'destination': record.coordinates,
                                        },
                                      );
                                    },
                                  ),
                            ),
                          );
                        }),

                        _buildMenuItem(
                          Icons.notifications,
                          "Your Activity",
                          () {
                            Navigator.pushNamed(context, '/user-reviews');
                          },
                        ),

                        _buildMenuItem(Icons.settings, "Profile Settings", () {
                          Navigator.pushNamed(
                            context,
                            '/profile_settings',
                            arguments: {
                              'name': _name,
                              'email': _email,
                              'role': _role,
                              'phone': _phone,
                              'notifPreference': _notifPreference,
                            },
                          );
                        }),
                        _buildMenuItem(Icons.help, "Help", () {
                          _showHelpDialog(context);
                        }, iconColor: const Color(0xFF7A1E1E)),

                        const Spacer(),

                        // <-- OWNER SPECIFIC BUTTONS
                        if (role.toLowerCase() == "owner") ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SetupEateryPage(
                                          currentUser: {
                                            'name': _name,
                                            'email': _email,
                                            'role': _role,
                                            'phone_num': _phone,
                                            'notif_preference':
                                                _notifPreference,
                                            'owner_id': _ownerId,
                                          },
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                "Set up your business",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A4423),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Back to Homepage',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7A1E1E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text("Confirm Logout"),
                                      content: const Text(
                                        "Are you sure you want to log out?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _name = null;
                                            _email = null;
                                            _role = null;
                                            _phone = null;
                                            _notifPreference = null;
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
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
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
    String label,
    VoidCallback onTap, {
    Color iconColor = const Color(0xFF0A4423),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Help"),
            content: const Text(
              "Need assistance?\nContact iskort.system@gmail.com or call 09123456789.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }
}
