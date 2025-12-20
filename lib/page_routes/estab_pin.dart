import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:http/http.dart' as http;

class EstabPin {
  final int ownerId;
  final LatLng userLocation;
  final Function(LatLng) onPinAdded;
  final MapController mapController;

  EstabPin({
    required this.ownerId,
    required this.userLocation,
    required this.onPinAdded,
    required this.mapController,
  });

  /// ================= SHOW BOTTOM SHEET =================
  void showAddPinSheet(BuildContext context) async {
    final business = await _fetchOwnerBusiness(ownerId);

    final titleController = TextEditingController(
      text:
          business != null
              ? "${business['name']} (${business['type']})"
              : "My Business",
    );

    final addressController = TextEditingController();

    String? selectedType = business?['type'];

    IconData getIcon(String? type) {
      switch (type) {
        case 'eatery':
          return Icons.restaurant;
        case 'housing':
          return Icons.home;
        default:
          return Icons.location_on;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: MediaQuery.of(sheetContext).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Add Your Establishment Pin",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Show icon if business fetched, otherwise show placeholder icon
                    Icon(
                      getIcon(selectedType),
                      size: 40,
                      color: const Color(0xFF0A4423),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: "Establishment Name",
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Show dropdown only if business is NOT fetched
                          if (business == null)
                            StatefulBuilder(
                              builder: (context, setState) {
                                return Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: selectedType,
                                      decoration: const InputDecoration(
                                        labelText: "Type",
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'eatery',
                                          child: Text("Food"),
                                        ),
                                        DropdownMenuItem(
                                          value: 'housing',
                                          child: Text("Housing"),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedType = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Icon(
                                      getIcon(selectedType),
                                      size: 40,
                                      color: const Color(0xFF0A4423),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: "Enter Complete Address or Landmarks",
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A4423),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final typedAddress = addressController.text.trim();

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please enter the establishment name",
                                ),
                              ),
                            );
                            return;
                          }

                          // ✅ Decide address ONLY here
                          String finalAddress = typedAddress;

                          if (finalAddress.isEmpty) {
                            finalAddress =
                                await reverseGeocode(userLocation) ?? '';
                          }

                          await _savePin(
                            ownerId,
                            title,
                            finalAddress,
                            userLocation,
                            {'type': selectedType},
                          );

                          onPinAdded(userLocation);
                          Navigator.pop(sheetContext);
                        },

                        child: const Text("Save Pin"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= FETCH BUSINESS NAME =================
  Future<Map<String, dynamic>?> _fetchOwnerBusiness(int ownerId) async {
    try {
      final eateryResp = await http.get(
        Uri.parse("https://iskort-public-web.onrender.com/api/eatery"),
      );

      if (eateryResp.statusCode == 200) {
        final data = jsonDecode(eateryResp.body);
        final eateries = data['eateries'] ?? [];

        final match = eateries.firstWhere(
          (e) => e['owner_id'] == ownerId,
          orElse: () => null,
        );

        if (match != null) {
          return {
            'name': match['name'],
            'type': 'eatery',
            'id': match['eatery_id'],
          };
        }
      }

      final housingResp = await http.get(
        Uri.parse("https://iskort-public-web.onrender.com/api/housing"),
      );

      if (housingResp.statusCode == 200) {
        final data = jsonDecode(housingResp.body);
        final housings = data['housings'] ?? [];

        final match = housings.firstWhere(
          (h) => h['owner_id'] == ownerId,
          orElse: () => null,
        );

        if (match != null) {
          return {
            'name': match['name'],
            'type': 'housing',
            'id': match['housing_id'],
          };
        }
      }
    } catch (_) {}

    return null;
  }

  /// reverse geocoding

  Future<String?> reverseGeocode(LatLng coords) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json'
      '&lat=${coords.latitude}'
      '&lon=${coords.longitude}',
    );

    final response = await http.get(url, headers: {'User-Agent': 'iskort-app'});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['display_name'];
    }
    return null;
  }

  /// ================= SAVE PIN =================
  Future<void> _savePin(
    int ownerId,
    String title,
    String address,
    LatLng coords,
    Map<String, dynamic>? business,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('owner_pins') ?? [];

    final newPin = {
      'ownerId': ownerId,
      'title': title,
      'address': address,
      'lat': coords.latitude,
      'lng': coords.longitude,
      'businessType': business?['type'],
      'businessId': business?['id'],
    };

    saved.add(jsonEncode(newPin));
    await prefs.setStringList('owner_pins', saved);
  }

  /// ================= SHOW PIN DETAILS =================
  static void showPinDetailsSheet({
    required BuildContext context,
    required Map<String, dynamic> pin,
    required int? currentOwnerId,
    required Function(LatLng) onPinUpdated,
    required Future<void> Function() reloadPins,
    required void Function(LatLng) navigateToPin,
  }) {
    final bool isOwner =
        currentOwnerId != null && pin['ownerId'] == currentOwnerId;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top-right X button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ),

              // Business name / Title
              if (pin['title'] != null)
                Text(
                  pin['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 6),

              // Owner name
              if (pin['ownerName'] != null)
                Text(
                  "Owner: ${pin['ownerName']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 6),

              // Date added
              if (pin['dateAdded'] != null)
                Text(
                  "Date Added: ${pin['dateAdded']}",
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 6),

              // Address
              if (pin['address'] != null &&
                  pin['address'].toString().isNotEmpty)
                Text(
                  "${pin['address']}",
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 16),

              if (isOwner) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 12),

                        // Delete button
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              await _deletePin(pin);
                              await reloadPins();
                              Navigator.pop(sheetContext);
                            },
                          ),
                        ),
                        SizedBox(width: 20),
                        // Edit button
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text(
                              "Edit",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A4423),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _showEditPinSheet(
                                context: context,
                                pin: pin,
                                onPinUpdated: onPinUpdated,
                                reloadPins: reloadPins,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text("View Route"),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    navigateToPin(LatLng(pin['lat'], pin['lng']));
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// ================= EDIT PIN =================
  static void _showEditPinSheet({
    required BuildContext context,
    required Map<String, dynamic> pin,
    required Function(LatLng) onPinUpdated,
    required Future<void> Function() reloadPins,
  }) {
    final titleController = TextEditingController(text: pin['title']);
    final addressController = TextEditingController(text: pin['address']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: MediaQuery.of(sheetContext).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Pin",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: "Enter Complete Address",
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  child: const Text("Save Changes"),
                  onPressed: () async {
                    await updatePin(
                      oldPin: pin,
                      newTitle: titleController.text.trim(),
                      newAddress: addressController.text.trim(),
                    );
                    await reloadPins();
                    onPinUpdated(LatLng(pin['lat'], pin['lng']));
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= DELETE PIN =================
  static Future<void> _deletePin(Map<String, dynamic> pin) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('owner_pins') ?? [];

    saved.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded['lat'] == pin['lat'] &&
          decoded['lng'] == pin['lng'] &&
          decoded['ownerId'] == pin['ownerId'];
    });

    await prefs.setStringList('owner_pins', saved);
  }

  /// ================= UPDATE PIN =================
  static Future<void> updatePin({
    required Map<String, dynamic> oldPin,
    required String newTitle,
    required String newAddress,
    LatLng? newCoords,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('owner_pins') ?? [];

    final index = saved.indexWhere((item) {
      final decoded = jsonDecode(item);
      return decoded['lat'] == oldPin['lat'] &&
          decoded['lng'] == oldPin['lng'] &&
          decoded['ownerId'] == oldPin['ownerId'];
    });

    if (index != -1) {
      final updatedPin = {
        ...oldPin,
        'title': newTitle,
        'address': newAddress,
        if (newCoords != null) 'lat': newCoords.latitude,
        if (newCoords != null) 'lng': newCoords.longitude,
      };
      saved[index] = jsonEncode(updatedPin);
      await prefs.setStringList('owner_pins', saved);
    }
  }

  /// ================= DRAGGABLE MARKER WIDGET =================
  DragMarker buildDraggableMarker({
    required Map<String, dynamic> pin,
    required int? currentOwnerId,
    required Function(LatLng) onPinUpdated,
    required bool editingMode, // <-- add this
  }) {
    final bool isOwner =
        currentOwnerId != null && pin['ownerId'] == currentOwnerId;

    return DragMarker(
      size: const Size(40, 40),
      point: LatLng(pin['lat'], pin['lng']),
      builder: (ctx, mapState, draggable) {
        return Icon(
          Icons.location_on,
          size: 40,
          color: isOwner ? Colors.blue : Colors.red,
        );
      },
      // Disable dragging unless owner AND editing mode
      disableDrag: !(isOwner && editingMode),

      onDragEnd: (details, newPosition) async {
        if (!isOwner || !editingMode) return;

        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getStringList('owner_pins') ?? [];

        final index = saved.indexWhere((item) {
          final decoded = jsonDecode(item);
          return decoded['lat'] == pin['lat'] &&
              decoded['lng'] == pin['lng'] &&
              decoded['ownerId'] == pin['ownerId'];
        });

        if (index != -1) {
          final updatedPin = {
            ...pin,
            'lat': newPosition.latitude,
            'lng': newPosition.longitude,
          };
          saved[index] = jsonEncode(updatedPin);
          await prefs.setStringList('owner_pins', saved);

          onPinUpdated(newPosition);
        }
      },
    );
  }
}
