import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reusables.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List allEntries = [];
  bool isLoading = true;
  Map<String, dynamic>? user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && user == null) {
      setState(() {
        user = args.cast<String, dynamic>();
      });
    }
  }

  Future<void> fetchEntries() async {
    try {
      List entries = [];

      // Fetch eateries
      final eateryResp = await http.get(Uri.parse('https://iskort-public-web.onrender.com/api/eatery'));
      if (eateryResp.statusCode == 200) {
        final data = jsonDecode(eateryResp.body);
        final verifiedEateries = (data['eateries'] ?? []).where((e) => e['is_verified'] == 1).toList();
        for (var eatery in verifiedEateries) {
          eatery['type'] = 'Eatery';
          eatery['photo'] = eatery['eatery_photo'] ?? '';
          final ownerId = eatery['owner_id'];
          if (ownerId != null) {
            try {
              final ownerResp = await http.get(Uri.parse('https://iskort-public-web.onrender.com/api/owner/$ownerId'));
              final ownerData = jsonDecode(ownerResp.body);
              if (ownerData['success'] == true && ownerData['owner'] != null) {
                eatery['owner_name'] = ownerData['owner']['name'] ?? 'Unknown';
                eatery['owner_email'] = ownerData['owner']['email'] ?? 'Unknown';
                eatery['owner_phone'] = ownerData['owner']['phone_num'] ?? 'Unknown';
                eatery['owner_photo'] = ownerData['owner']['photo'] ?? '';
              }
            } catch (_) {}
          }
          entries.add(eatery);
        }
      }

      // Fetch housing
      final housingResp = await http.get(Uri.parse('https://iskort-public-web.onrender.com/api/housing'));
      if (housingResp.statusCode == 200) {
        final data = jsonDecode(housingResp.body);
        final verifiedHousing = (data['housing'] ?? []).where((h) => h['is_verified'] == 1).toList();
        for (var house in verifiedHousing) {
          house['type'] = 'Housing';
          house['photo'] = house['housing_photo'] ?? '';
          final ownerId = house['owner_id'];
          if (ownerId != null) {
            try {
              final ownerResp = await http.get(Uri.parse('https://iskort-public-web.onrender.com/api/owner/$ownerId'));
              final ownerData = jsonDecode(ownerResp.body);
              if (ownerData['success'] == true && ownerData['owner'] != null) {
                house['owner_name'] = ownerData['owner']['name'] ?? 'Unknown';
                house['owner_email'] = ownerData['owner']['email'] ?? 'Unknown';
                house['owner_phone'] = ownerData['owner']['phone_num'] ?? 'Unknown';
                house['owner_photo'] = ownerData['owner']['photo'] ?? '';
              }
            } catch (_) {}
          }
          entries.add(house);
        }
      }

      setState(() {
        allEntries = entries;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching entries: $e");
      setState(() => isLoading = false);
    }
  }

  void _showMiniNotif(BuildContext avatarContext) {
    final overlay = Overlay.of(avatarContext);
    final renderBox = avatarContext.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => overlayEntry.remove(),
        child: Stack(
          children: [
            Positioned(
              top: offset.dy + renderBox!.size.height + 5,
              left: offset.dx + renderBox.size.width - 220,
              width: 220,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(
                          size: 20,
                          Icons.notifications,
                          color: Color(0xFF0A4423),
                        ),
                        title: const Text(
                          "3 new notifications",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          "Tap to view all",
                          style: TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          overlayEntry.remove();
                          Navigator.pushNamed(context, '/notifications');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay?.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void showEntryDetails(Map entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${entry['name'] ?? 'Details'} (${entry['type']})"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Personal Info", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if ((entry['owner_photo'] ?? '').isNotEmpty)
                Image.network(
                  entry['owner_photo'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person),
                ),
              Text("Owner: ${entry['owner_name'] ?? 'Unknown'}"),
              Text("Email: ${entry['owner_email'] ?? 'Unknown'}"),
              Text("Phone: ${entry['owner_phone'] ?? 'Unknown'}"),
              const SizedBox(height: 12),
              const Text("Business Details", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if ((entry['photo'] ?? '').isNotEmpty)
                Image.network(
                  entry['photo'],
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              Text("Location: ${entry['location'] ?? 'Unknown'}"),
              if (entry['type'] == 'Eatery')
                Text("Open: ${entry['open_time'] ?? 'N/A'} - ${entry['end_time'] ?? 'N/A'}"),
              Text("Price: ${entry['min_price'] ?? entry['price'] ?? 'N/A'}"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null)
              Row(
                children: [
                  Text(
                    "Hello, ${user!['name'] ?? 'Iska'}!",
                    style: const TextStyle(
                      color: Color(0xFF0A4423),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (avatarContext) => GestureDetector(
                      onTap: () => _showMiniNotif(avatarContext),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: (user!['photo'] ?? '').isNotEmpty
                            ? NetworkImage(user!['photo'])
                            : null,
                        child: (user!['photo'] ?? '').isEmpty ? const Icon(Icons.person, size: 30, color: Color(0xFF0A4423)) : null,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            const Text("Recommended for you", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (allEntries.isEmpty)
              const Text("No entries available")
            else
              Column(
                children: allEntries.map((entry) {
                  return ProductCard(
                    title: entry['name'] ?? '',
                    subtitle: "Tap to view details",
                    location: entry['location'] ?? '',
                    imagePath: entry['photo'] ?? "assets/images/placeholder.png",
                    onTap: () => showEntryDetails(entry),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/route');
          } else if (index == 2 && user != null) {
            Navigator.pushNamed(
              context,
              '/profile',
              arguments: {
                'name': user!['name'],
                'email': user!['email'],
                'role': user!['role'],
                'phone': user!['phone_num'],
                'notifPreference': user!['notif_preference'],
              },
            );
          }
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String location;
  final String imagePath;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade300,
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Color(0xFF791317),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF791317))),
                    Text(subtitle),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Color(0xFF791317)),
                        const SizedBox(width: 4),
                        Flexible(child: Text(location)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
