import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:iskort/page_routes/map_route.dart';

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
                        record.name ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0A4423),
                        ),
                      ),
                      subtitle: Text(
                        'Distance: ${record.distanceKm?.toStringAsFixed(2) ?? '0.00'} km, '
                        'ETA: ${record.durationMin?.toStringAsFixed(0) ?? '0'} mins',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color(0xFF791317),
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final savedList =
                              prefs.getStringList('saved_locations') ?? [];

                          final updatedList =
                              savedList.where((item) {
                                final data = jsonDecode(item);
                                return !(data['lat'] ==
                                        record.coordinates.latitude &&
                                    data['lng'] ==
                                        record.coordinates.longitude &&
                                    data['timestamp'] ==
                                        record.timestamp.toIso8601String());
                              }).toList();

                          await prefs.setStringList(
                            'saved_locations',
                            updatedList,
                          );

                          setState(() {
                            savedLocations.removeAt(index);
                          });
                        },
                      ),
                      onTap: () {
                        if (widget.onSelect != null) {
                          widget.onSelect!(record);
                        } else {
                          Navigator.pop(context, record);
                        }
                      },
                    ),
                  );
                },
              ),
    );
  }
}
