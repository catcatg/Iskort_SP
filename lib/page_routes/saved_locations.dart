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
                  return ListTile(
                    leading: const Icon(Icons.location_pin, color: Colors.red),
                    title: Text(record.name),
                    subtitle: Text(
                      'Distance: ${record.distanceKm.toStringAsFixed(2)} km, '
                      'ETA: ${record.durationMin.toStringAsFixed(0)} mins',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final savedList =
                            prefs.getStringList('saved_locations') ?? [];

                        savedList.removeWhere((item) {
                          final data = jsonDecode(item);
                          return data['lat'] == record.coordinates.latitude &&
                              data['lng'] == record.coordinates.longitude &&
                              data['timestamp'] ==
                                  record.timestamp.toIso8601String();
                        });

                        await prefs.setStringList('saved_locations', savedList);

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
                  );
                },
              ),
    );
  }
}
