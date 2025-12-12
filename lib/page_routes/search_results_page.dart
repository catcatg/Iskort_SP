import 'package:flutter/material.dart';
import '../widgets/reusables.dart';
import 'map_route.dart';
import 'view_estab_profile.dart';

class SearchResultsPage extends StatefulWidget {
  final String initialQuery;
  const SearchResultsPage({super.key, required this.initialQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late TextEditingController _controller;
  List allEntries = [];
  List filteredEntries = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    allEntries = ModalRoute.of(context)?.settings.arguments as List? ?? [];
    _filterEntries(_controller.text);
  }

  void _onSearchChanged() => _filterEntries(_controller.text);

  void _filterEntries(String query) {
    final q = query.toLowerCase();
    setState(() {
      filteredEntries = allEntries.where((entry) {
        final name = (entry['name'] ?? '').toString().toLowerCase();
        final location = (entry['location'] ?? '').toString().toLowerCase();
        final type = (entry['type'] ?? '').toString().toLowerCase();
        final tagsList = (entry['tags'] is List)
            ? (entry['tags'] as List).map((t) => t.toString().toLowerCase()).toList()
            : [];
        return name.contains(q) ||
            location.contains(q) ||
            type.contains(q) ||
            tagsList.any((t) => t.contains(q));
      }).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final housingResults =
        filteredEntries.where((e) => e['type'] == 'Housing').toList();
    final eateryResults =
        filteredEntries.where((e) => e['type'] == 'Eatery').toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search housing or eateries',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: filteredEntries.isEmpty
          ? Center(child: Text('No results found for "${_controller.text}"'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (housingResults.isNotEmpty) ...[
                  const Text("Housing",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A4423))),
                  const SizedBox(height: 8),
                  ...housingResults.map(
                    (entry) => ProductCard(
                      title: entry['name'] ?? '',
                      subtitle: "Tap to view details",
                      location: entry['location'] ?? '',
                      imagePath: entry['photo'] ?? "assets/images/placeholder.png",
                      onTap: () => _showEntryDetails(entry),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (eateryResults.isNotEmpty) ...[
                  const Text("Eateries",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A4423))),
                  const SizedBox(height: 8),
                  ...eateryResults.map(
                    (entry) => ProductCard(
                      title: entry['name'] ?? '',
                      subtitle: "Tap to view details",
                      location: entry['location'] ?? '',
                      imagePath: entry['photo'] ?? "assets/images/placeholder.png",
                      onTap: () => _showEntryDetails(entry),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  void _showEntryDetails(Map entry) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    entry['photo'] ?? "assets/images/placeholder.png",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "${entry['name'] ?? 'Details'} (${entry['type'] ?? 'Unknown'})",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Color(0xFF7A1E1E)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(entry['location'] ?? '',
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (entry['type'] == 'Eatery') ...[
                  Text("Minimum Price: ₱${entry['min_price'] ?? 'N/A'}"),
                  Text("Open: ${entry['open_time'] ?? ''}"),
                  Text("Close: ${entry['end_time'] ?? ''}"),
                ] else if (entry['type'] == 'Housing') ...[
                  Text("Monthly Price: ₱${entry['price'] ?? 'N/A'}"),
                  Text("Curfew: ${entry['curfew'] ?? 'N/A'}"),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A4423),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EstabProfileForCustomer(
                          ownerId: entry['owner_id']?.toString() ?? '',
                          estType: entry['type']?.toString() ?? '',
                          eateryId: entry['eatery_id']?.toString(),
                          housingId: entry['housing_id']?.toString(),
                        ),
                      ),
                    );
                  },
                  child: const Text("View Establishment Profile",
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A4423),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapRoutePage(
                          initialLocation: entry['location']?.toString() ?? '',
                        ),
                      ),
                    );
                  },
                  child: const Text("View Route",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}