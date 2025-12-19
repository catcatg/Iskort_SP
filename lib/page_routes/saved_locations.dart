import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:iskort/page_routes/map_route.dart';
import 'package:iskort/widgets/reusables.dart';

class SavedLocations extends StatefulWidget {
  final Function(LocationRecord)? onSelect;

  const SavedLocations({Key? key, this.onSelect}) : super(key: key);

  @override
  State<SavedLocations> createState() => _SavedLocationsState();
}

class _SavedLocationsState extends State<SavedLocations> {
  List<LocationRecord> savedLocations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedList = prefs.getStringList('saved_locations') ?? [];

    setState(() {
      savedLocations =
          encodedList
              .map((e) => LocationRecord.fromMap(json.decode(e)))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("Saved Locations"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color.fromARGB(255, 150, 29, 20),
      ),
      body:
          savedLocations.isEmpty
              ? const Center(
                child: Text(
                  "No saved locations yet.",
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: savedLocations.length,
                itemBuilder: (context, index) {
                  final record = savedLocations[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFF791317),
                        ),
                      ),
                      title: Text(
                        record.name.isNotEmpty ? record.name : 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0A4423),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color(0xFF791317),
                        ),
                        onPressed: () async {
                          // Show confirmation dialog with location name
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text("Delete Location"),
                                  content: Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text:
                                              "Are you sure you want to delete ",
                                        ),
                                        TextSpan(
                                          text: "'${record.name}'",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const TextSpan(text: "?"),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                          );

                          // If user confirmed deletion
                          if (confirm == true) {
                            final prefs = await SharedPreferences.getInstance();
                            final savedList =
                                prefs.getStringList('saved_locations') ?? [];

                            final updatedList =
                                savedList.where((item) {
                                  final data = jsonDecode(item);
                                  return data['name'] != record.name;
                                }).toList();

                            await prefs.setStringList(
                              'saved_locations',
                              updatedList,
                            );

                            setState(() {
                              savedLocations.removeAt(index);
                            });

                            // Show snackbar confirmation
                            showFadingPopup(
                              context,
                              "Location '${record.name}' deleted.",
                            );
                          }
                        },
                      ),
                      onTap: () {
                        if (widget.onSelect != null) widget.onSelect!(record);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => MapRoutePage(
                                  initialLocation:
                                      record
                                          .name, // will need parsing in MapRoutePage
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}

class LocationRecord {
  final String name;
  final String address;
  final LatLng coordinates;
  final String type;
  final DateTime timestamp;

  LocationRecord({
    required this.name,
    required this.address,
    required this.coordinates,
    required this.type,
    required this.timestamp,
  });

  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    final double lat =
        map['lat'] != null ? (map['lat'] as num).toDouble() : 0.0;
    final double lng =
        map['lng'] != null ? (map['lng'] as num).toDouble() : 0.0;

    return LocationRecord(
      name: (map['name'] ?? '').toString(),

      // some records used "location" instead of "address"
      address: (map['address'] ?? map['location'] ?? '').toString(),

      type: (map['type'] ?? '').toString(),

      coordinates: LatLng(lat, lng),

      timestamp:
          map['timestamp'] != null
              ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}
