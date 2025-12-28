import 'dart:ui_web';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iskort/page_routes/map_route.dart';

// Cloudinary config
const String _cloudName = "iskort-system";
const String _uploadPreset = "iskort_upload";
// Max image size: 10 MB
const int maxUploadSizeBytes = 10 * 1024 * 1024; // 10 MB

Future<String?> uploadToCloudinary(
  XFile pickedFile, {
  String resourceType = 'image',
  required BuildContext context,
}) async {
  final bytes = await pickedFile.readAsBytes();

  // Check size and notify uploader
  if (bytes.length > maxUploadSizeBytes) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Image is too large. Maximum allowed size per upload is 10 MB.",
        ),
        backgroundColor: Colors.red,
      ),
    );
    return null; // STOP upload
  }

  final url = Uri.parse(
    "https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload",
  );

  final request =
      http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: pickedFile.name,
          ),
        );

  final response = await request.send();
  final resStr = await response.stream.bytesToString();
  final data = jsonDecode(resStr);

  return response.statusCode == 200 ? data['secure_url'] : null;
}

bool asBool(dynamic value) {
  return value == 1 || value == true || value == "1";
}

/// Safely extract an ID from int, string, or MongoDB ObjectId map
String extractId(dynamic rawId) {
  if (rawId == null) return '';
  if (rawId is int) return rawId.toString();
  if (rawId is String) return rawId;
  if (rawId is Map && rawId.containsKey(r'$oid')) return rawId[r'$oid'];
  return '';
}

// ===== Helpers =====
Widget label(String text) => Text(
  text,
  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A4423)),
);

Widget input(TextEditingController controller, {String? hint}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hint,
      labelText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

// Eatery: compute Open/Closed from open_time and end_time
String computeEateryOpenStatus(Map<String, dynamic> biz) {
  final open = biz['open_time'];
  final close = biz['end_time'];
  if (open == null || close == null || open.isEmpty || close.isEmpty)
    return "N/A";

  final now = TimeOfDay.now();
  final openParts = open.split(":");
  final closeParts = close.split(":");

  final openTime = TimeOfDay(
    hour: int.parse(openParts[0]),
    minute: int.parse(openParts[1]),
  );
  final closeTime = TimeOfDay(
    hour: int.parse(closeParts[0]),
    minute: int.parse(closeParts[1]),
  );

  final afterOpen =
      (now.hour > openTime.hour) ||
      (now.hour == openTime.hour && now.minute >= openTime.minute);
  final beforeClose =
      (now.hour < closeTime.hour) ||
      (now.hour == closeTime.hour && now.minute <= closeTime.minute);

  return (afterOpen && beforeClose) ? "Open" : "Closed";
}

// Housing: manual status string
String getHousingStatus(Map<String, dynamic> biz) {
  return (biz['status']?.toString().isNotEmpty == true)
      ? biz['status']
      : "Open for tenants";
}

// ===== Global Dialogs =====
void openAddFoodDialog(
  BuildContext context,
  Future<void> Function({
    required String food_pic,
    required String name,
    required String classification,
    required String price,
    required int availability,
  })
  saveFoodToServer,
) {
  final picController = TextEditingController();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final otherController = TextEditingController();
  String? selectedTag;
  bool isOther = false;
  bool availability = true;

  final classes = [
    "Pork",
    "Chicken",
    "Beef",
    "Vegetables",
    "Seafood",
    "Alcoholic Drinks",
    "Coffee Drinks",
    "Non-Coffee Drinks",
    "Desserts",
    "Snacks",
    "Meal Set",
    "Vegetarian",
  ];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Add Menu Item",
                style: TextStyle(color: Color(0xFF0A4423), fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image preview
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
                      child: picController.text.isNotEmpty
                          ? Image.network(picController.text, fit: BoxFit.cover)
                          : Container(color: Colors.grey[200], child: const Icon(Icons.fastfood, size: 50)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Food Image URL
                  TextFormField(
                    controller: picController,
                    decoration: const InputDecoration(
                      labelText: "Food Image URL",
                      hintText: "Auto-filled after upload",
                    ),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        final url = await uploadToCloudinary(picked, context: context);
                        if (url != null) {
                          setState(() => picController.text = url);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Image uploaded successfully")),
                          );
                        }
                      }
                    },
                    child: const Text("Upload Food Image"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4423),
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextField(controller: nameController, decoration: const InputDecoration(hintText: "Food Name")),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedTag,
                    hint: const Text("Classification"),
                    items: [
                      ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      const DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (val) {
                      setState(() {
                        selectedTag = val;
                        isOther = val == "Other";
                      });
                    },
                  ),

                  if (isOther) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: otherController,
                      decoration: const InputDecoration(hintText: "Enter custom classification"),
                    ),
                  ],

                  const SizedBox(height: 12),
                  TextField(controller: priceController, decoration: const InputDecoration(hintText: "Price (₱)")),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: const Text("Available"),
                    value: availability,
                    onChanged: (val) => setState(() => availability = val ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                child: const Text("Add"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A4423), foregroundColor: Colors.white),
                onPressed: () async {
                  if (nameController.text.isEmpty || selectedTag == null) return;

                  String finalClassification;
                    if (isOther && otherController.text.isNotEmpty) {
                      finalClassification = otherController.text.trim();
                      finalClassification = finalClassification[0].toUpperCase() + finalClassification.substring(1);
                    } else {
                      finalClassification = selectedTag ?? "Misc";
                    }

                    await saveFoodToServer(
                      food_pic: picController.text.trim(),
                      name: nameController.text.trim(),
                      classification: finalClassification, 
                      price: priceController.text.trim(),  
                      availability: availability ? 1 : 0,  
                    );
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> openAddFacilityDialog(
  BuildContext context,
  Future<void> Function({
    required String name,
    required String facilityPic,
    required String price,
    required bool hasAc,
    required bool hasCr,
    required bool hasKitchen,
    required String type,
    required String additionalInfo,
    required int availability,
    required int availRoom,
  }) saveFacilityToServer,
) async {
  final name = TextEditingController();
  final pic = TextEditingController();
  final price = TextEditingController();
  final info = TextEditingController();
  final availRoom = TextEditingController();

  bool hasAc = false;
  bool hasCr = false;
  bool hasKitchen = false;
  String? type;
  bool availabilityBool = true; // default Available

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Add Facility"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Image preview
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
                  child: pic.text.isNotEmpty
                      ? Image.network(pic.text, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.home, size: 50),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Facility Image URL
              TextField(
                controller: pic,
                decoration: const InputDecoration(labelText: "Facility Image URL"),
              ),
              const SizedBox(height: 8),

              // Upload button
              ElevatedButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    final url = await uploadToCloudinary(picked, context: context);
                    if (url != null) {
                      pic.text = url;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Facility image uploaded successfully")),
                      );
                    }
                  }
                },
                child: const Text("Upload Facility Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A4423),
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: price, decoration: const InputDecoration(labelText: "Price")),
              TextField(controller: info, decoration: const InputDecoration(labelText: "Additional Info")),
              TextField(controller: availRoom, decoration: const InputDecoration(labelText: "Available Rooms")),
              CheckboxListTile(title: const Text("AC"), value: hasAc, onChanged: (v) => hasAc = v ?? false),
              CheckboxListTile(title: const Text("CR"), value: hasCr, onChanged: (v) => hasCr = v ?? false),
              CheckboxListTile(title: const Text("Kitchen"), value: hasKitchen, onChanged: (v) => hasKitchen = v ?? false),
              DropdownButton<String>(
                value: type,
                hint: const Text("Select Room Type"),
                items: ["Solo", "Shared"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => type = v,
              ),
              SwitchListTile(
                title: const Text("Available"),
                value: availabilityBool,
                onChanged: (v) => availabilityBool = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await saveFacilityToServer(
                name: name.text.trim(),
                facilityPic: pic.text.trim(),
                price: price.text.trim(),
                hasAc: hasAc,
                hasCr: hasCr,
                hasKitchen: hasKitchen,
                type: type ?? "Solo",
                additionalInfo: info.text.trim(),
                availability: availabilityBool ? 1 : 0,
                availRoom: int.tryParse(availRoom.text.trim()) ?? 0,
              );
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}

void openEditFoodDialog(
  BuildContext context,
  Map<String, dynamic> item,
  Future<void> Function(Map<String, dynamic>) updateFoodItem,
  Future<void> Function() reload,
) {
  final name = TextEditingController(text: item['name']);
  final price = TextEditingController(text: item['price'].toString());
  final pic = TextEditingController(text: item['food_pic']);

  final classes = [
    "Pork",
    "Chicken",
    "Beef",
    "Vegetables",
    "Seafood",
    "Alcoholic Drinks",
    "Coffee Drinks",
    "Non-Coffee Drinks",
    "Desserts",
    "Snacks",
    "Meal Set",
    "Vegetarian",
  ];

  String? classification =
      classes.contains(item['classification']) ? item['classification'] : "Other";
  final otherController = TextEditingController(
    text: !classes.contains(item['classification']) ? item['classification'] : "",
  );
  bool isOther = classification == "Other";
  bool availability = item['availability'] == 1 || item['availability'] == true;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              "Edit Food Item",
              style: TextStyle(
                color: Color(0xFF0A4423),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  input(name, hint: "Food Name"),
                  const SizedBox(height: 10),
                  input(price, hint: "Price"),

                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
                      child: pic.text.isNotEmpty
                          ? Image.network(pic.text, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.fastfood, size: 50),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: pic,
                    decoration: const InputDecoration(
                      labelText: "Food Image URL",
                      hintText: "Auto-filled after upload",
                    ),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        final url = await uploadToCloudinary(picked, context: context);
                        if (url != null) {
                          setState(() => pic.text = url);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Food image uploaded successfully")),
                          );
                        }
                      }
                    },
                    child: const Text("Update Food Image"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4423),
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: classification,
                    items: [
                      ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      const DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (val) {
                      setState(() {
                        classification = val;
                        isOther = val == "Other";
                      });
                    },
                  ),

                  if (isOther) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: otherController,
                      decoration: const InputDecoration(hintText: "Enter custom classification"),
                    ),
                  ],

                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text("Available"),
                    value: availability,
                    onChanged: (val) => setState(() => availability = val ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                child: const Text("Save"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A4423),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  String finalClassification;
                  if (isOther && otherController.text.isNotEmpty) {
                    finalClassification = otherController.text.trim();
                    finalClassification = finalClassification[0].toUpperCase() +
                        finalClassification.substring(1);
                  } else {
                    finalClassification = classification ?? "Misc";
                  }

                  final updatedItem = {
                    "food_id": item['food_id'],
                    "name": name.text.trim(),
                    "price": price.text.trim(),
                    "food_pic": pic.text.trim(),
                    "classification": finalClassification,
                    "availability": availability ? 1 : 0,
                  };

                  await updateFoodItem(updatedItem);
                  Navigator.pop(context);
                  await reload();
                },
              ),
            ],
          );
        },
      );
    },
  );
}

// POP UP AT HOMEPAGE EDIT (PEN ICON)
Future<void> openEditFacilityDialog(
  BuildContext context,
  Map<String, dynamic> item,
  Future<void> Function(Map<String, dynamic>) updateFacilityItem,
  Future<void> Function() reload,
) async {
  final name = TextEditingController(text: item['name']);
  final pic = TextEditingController(text: item['facility_pic']);
  final price = TextEditingController(text: item['price'].toString());
  final info = TextEditingController(text: item['additional_info'] ?? "");
  final availRoom = TextEditingController(text: item['avail_room']?.toString() ?? "0");

  bool hasAc = item['has_ac'] == 1;
  bool hasCr = item['has_cr'] == 1;
  bool hasKitchen = item['has_kitchen'] == 1;
  String? type = item['type'];
  bool availabilityBool = item['availability'] == 1;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Edit Facility"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: pic, decoration: const InputDecoration(labelText: "Facility Image URL")),
              TextField(controller: price, decoration: const InputDecoration(labelText: "Price")),
              TextField(controller: info, decoration: const InputDecoration(labelText: "Additional Info")),
              TextField(controller: availRoom, decoration: const InputDecoration(labelText: "Available Rooms")),
              CheckboxListTile(title: const Text("AC"), value: hasAc, onChanged: (v) => hasAc = v ?? false),
              CheckboxListTile(title: const Text("CR"), value: hasCr, onChanged: (v) => hasCr = v ?? false),
              CheckboxListTile(title: const Text("Kitchen"), value: hasKitchen, onChanged: (v) => hasKitchen = v ?? false),
              DropdownButton<String>(
                value: type,
                hint: const Text("Select Room Type"),
                items: ["Solo", "Shared"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => type = v,
              ),
              SwitchListTile(
                title: const Text("Available"),
                value: availabilityBool,
                onChanged: (v) => availabilityBool = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final updatedItem = {
                "facility_id": item['facility_id'],
                "name": name.text.trim(),
                "facility_pic": pic.text.trim(),
                "price": price.text.trim(),
                "has_ac": hasAc ? 1 : 0,
                "has_cr": hasCr ? 1 : 0,
                "has_kitchen": hasKitchen ? 1 : 0,
                "type": type ?? "Solo",
                "additional_info": info.text.trim(),
                "availability": availabilityBool ? 1 : 0, 
                "avail_room": int.tryParse(availRoom.text.trim()) ?? 0, 
              };
              await updateFacilityItem(updatedItem);
              await reload();
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      );
    },
  );
}

// ===== Global Cards =====
Widget menuCard(
  Map<String, dynamic> item, {
  required BuildContext context,
  required Future<void> Function(Map<String, dynamic>) updateFoodItem,
  required Future<void> Function(int) deleteFoodItem,
  required Future<void> Function() reload,
}) {
  final bool isAvailable = item['availability'] == 1;
  final availabilityText = isAvailable ? "Available" : "Not Available";

  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      Text("₱${item['price']} • ${item['classification']}"),
      Text(
        availabilityText,
        style: TextStyle(color: isAvailable ? Colors.green : Colors.red),
      ),
    ],
  );

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Image.network(
        item['food_pic'] ?? "",
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
      ),
      title: Text(item['name']),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              "${item['classification']} • ₱${item['price']}",
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          Text(
            availabilityText,
            style: TextStyle(
              color: isAvailable ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.green),
            onPressed: () => openEditFoodDialog(context, item, updateFoodItem, reload),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await deleteFoodItem(item['food_id']);
              await reload();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Food deleted successfully")),
              );
            },
          ),
        ],
      ),
    ),
  );
}

Widget facilityCard(
  Map<String, dynamic> item, {
  required BuildContext context,
  required Future<void> Function(Map<String, dynamic>) updateFacilityItem,
  required Future<void> Function(int) deleteFacilityItem,
  required Future<void> Function() reload,
}) {
  final bool isAvailable = item['availability'] == 1;
  final availabilityText = isAvailable ? "Available" : "Not Available";

  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      Text("₱${item['price']} • ${item['type']}"),
      Text("Rooms: ${item['avail_room'] ?? 0}"),
      Text(
        availabilityText,
        style: TextStyle(color: isAvailable ? Colors.green : Colors.red),
      ),
    ],
  );

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Image.network(
        item['facility_pic'] ?? "",
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.home),
      ),
      title: Text(item['name']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "₱${item['price']} • ${item['type']} room",
            style: const TextStyle(color: Colors.black87),
          ),
          Row(
            children: [
              Text(
                availabilityText,
                style: TextStyle(
                  color: isAvailable ? Colors.green : Colors.red, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAvailable && item['avail_room'] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    "Rooms: ${item['avail_room']}", 
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.green),
            onPressed: () => openEditFacilityDialog(context, item, updateFacilityItem, reload),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await deleteFacilityItem(item['facility_id']);
              await reload();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Facility deleted successfully")),
              );
            },
          ),
        ],
      ),
    ),
  );
}

// ===== Main Page =====
class EditEstablishmentsPage extends StatefulWidget {
  final Map<String, dynamic> business; // eatery or housing
  final ownerId;

  const EditEstablishmentsPage({
    super.key,
    required this.business,
    required this.ownerId,
  });

  @override
  State<EditEstablishmentsPage> createState() => _EditEstablishmentsPageState();
}

class _EditEstablishmentsPageState extends State<EditEstablishmentsPage> {
  late bool isEatery;

  // Shared fields
  late TextEditingController nameController;
  late TextEditingController locationController;

  // Eatery only
  late TextEditingController openTimeController;
  late TextEditingController closeTimeController;

  // Housing
  late TextEditingController curfewController;

  // About
  late TextEditingController aboutController;

  // Status (manual for housing)
  String selectedStatus = "Open for tenants";

  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> facilities = [];

  @override
  void initState() {
    super.initState();
    final biz = widget.business;
    isEatery = biz['type'] == 'eatery';

    nameController = TextEditingController(text: biz['name'] ?? "");
    locationController = TextEditingController(text: biz['location'] ?? "");
    aboutController = TextEditingController(text: biz['about_desc'] ?? "");
    selectedStatus = biz['status'] ?? "Open for tenants";

    if (isEatery) {
      openTimeController = TextEditingController(text: biz['open_time'] ?? "");
      closeTimeController = TextEditingController(text: biz['end_time'] ?? "");
      loadMenuItems();
    } else {
      curfewController = TextEditingController(text: biz['curfew'] ?? "");
      loadFacilities();
    }

    fetchBusinessDetails(); // NEW: fetch owner info
  }

  // ===== Fetch Business Details =====
  Future<void> fetchBusinessDetails() async {
    final id = extractId(
      widget.business['eatery_id'] ??
          widget.business['housing_id'] ??
          widget.business['id'],
    );
    final endpoint =
        isEatery
            ? "https://iskort-public-web.onrender.com/api/eatery"
            : "https://iskort-public-web.onrender.com/api/housing";

    final res = await http.get(Uri.parse(endpoint));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = isEatery ? data['eateries'] : data['housings'];
      final match = list.firstWhere(
        (b) => extractId(b[isEatery ? 'eatery_id' : 'housing_id']) == id,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        setState(() {
          widget.business.addAll(
            match,
          ); // merge owner_name, owner_email, owner_phone, etc.
        });
      }
    }
  }

  // ===== FOOD FUNCTIONS =====
  Future<void> loadMenuItems() async {
    final id = extractId(widget.business['eatery_id'] ?? widget.business['id']);
    final res = await http.get(
      Uri.parse("https://iskort-public-web.onrender.com/api/food/$id"),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        menuItems = List<Map<String, dynamic>>.from(data['foods'] ?? []);
      });
    }
  }

  Future<void> saveFoodToServer({
    required String food_pic,
    required String name,
    required String classification,
    required String price,
  }) async {
    final eateryId = extractId(
      widget.business['eatery_id'] ?? widget.business['id'],
    );
    final body = {
      "name": name,
      "eatery_id": eateryId,
      "classification": classification,
      "price": price,
      "food_pic": food_pic,
    };

    final res = await http.post(
      Uri.parse("https://iskort-public-web.onrender.com/api/food"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      loadMenuItems();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Food added successfully")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add menu item.")));
    }
  }

  Future<void> updateFoodItem(Map<String, dynamic> item) async {
    final eateryId = widget.business['eatery_id'] ?? widget.business['id'];
    await http.put(
      Uri.parse(
        "https://iskort-public-web.onrender.com/api/food/${item['food_id']}",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": item['name'],
        "eatery_id": eateryId.toString(),
        "classification": item['classification'],
        "price": item['price'],
        "food_pic": item['food_pic'],
      }),
    );
  }

  // Manual toggle for housings
  String getBusinessStatus(Map<String, dynamic> biz) {
    return biz['status'] ?? "Open for tenants";
  }

  Future<void> deleteFoodItem(int foodId) async {
    final res = await http.delete(
      Uri.parse("https://iskort-public-web.onrender.com/api/food/$foodId"),
    );
    if (res.statusCode == 200) {
      loadMenuItems();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Food deleted")));
    }
  }

  // ===== FACILITY FUNCTIONS =====
  Future<void> loadFacilities() async {
    final id = extractId(
      widget.business['housing_id'] ?? widget.business['id'],
    );
    final res = await http.get(
      Uri.parse("https://iskort-public-web.onrender.com/api/facility/$id"),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        facilities = List<Map<String, dynamic>>.from(data['facilities'] ?? []);
      });
    }
  }

  Future<void> saveFacilityToServer({
    required String name,
    required String facilityPic,
    required String price,
    required bool hasAc,
    required bool hasCr,
    required bool hasKitchen,
    required String type,
    required String additionalInfo,
    required int availability,
    required int availRoom,
  }) async {
    final housingId = extractId(
      widget.business['housing_id'] ?? widget.business['id'],
    );
    final body = {
      "name": name,
      "housing_id": housingId,
      "facility_pic": facilityPic,
      "price": price,
      "has_ac": hasAc ? 1 : 0,
      "has_cr": hasCr ? 1 : 0,
      "has_kitchen": hasKitchen ? 1 : 0,
      "type": type,
      "additional_info": additionalInfo,
      "availability": availability,
      "avail_room": availRoom,
    };

    final res = await http.post(
      Uri.parse("https://iskort-public-web.onrender.com/api/facility"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      loadFacilities();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Facility added successfully")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add facility")));
    }
  }

  Future<void> updateFacilityItem(Map<String, dynamic> item) async {
    final housingId = widget.business['housing_id'] ?? widget.business['id'];
    await http.put(
      Uri.parse(
        "https://iskort-public-web.onrender.com/api/facility/${item['facility_id']}",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": item['name'],
        "housing_id": housingId.toString(),
        "facility_pic": item['facility_pic'],
        "price": item['price'],
        "has_ac": asBool(item['has_ac']) ? 1 : 0,
        "has_cr": asBool(item['has_cr']) ? 1 : 0,
        "has_kitchen": asBool(item['has_kitchen']) ? 1 : 0,
        "type": item['type'],
        "additional_info": item['additional_info'],
        "availability": item['availability'],
        "avail_room": item['avail_room'],
      }),
    );
  }

  Future<void> deleteFacilityItem(int facilityId) async {
    final res = await http.delete(
      Uri.parse(
        "https://iskort-public-web.onrender.com/api/facility/$facilityId",
      ),
    );
    if (res.statusCode == 200) {
      loadFacilities();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Facility deleted")));
    }
  }

  // ==== Build Method ===== //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEatery ? "Edit Eatery" : "Edit Housing",
          style: TextStyle(color: Colors.white),
        ),
        leading: BackButton(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Business details display
            label("Business Details"),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Color(0xFF0A4423)),
                    SizedBox(width: 8),
                    Text(
                      widget.business['owner_name'] ?? '',
                      style: TextStyle(color: Color(0xFF0A4423)),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, color: Color(0xFF0A4423)),
                    SizedBox(width: 8),
                    Text(
                      widget.business['owner_phone'] ?? '',
                      style: TextStyle(color: Color(0xFF0A4423)),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email, color: Color(0xFF0A4423)),
                    SizedBox(width: 8),
                    Text(
                      widget.business['owner_email'] ?? '',
                      style: TextStyle(color: Color(0xFF0A4423)),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF0A4423)),
                    SizedBox(width: 8),
                    Text(
                      widget.business['location'] ?? '',
                      style: TextStyle(color: Color(0xFF0A4423)),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(),
            const SizedBox(height: 12),
            label("Business Name"),
            input(nameController),
            const SizedBox(height: 12),
            label("Location"),
            input(locationController),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_pin),
                label: const Text("Pin your location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A4423),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => MapRoutePage(
                            initialLocation: locationController.text,
                            ownerId: widget.ownerId,
                          ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),

            if (isEatery) ...[
              const SizedBox(height: 20),
              Divider(),
              const SizedBox(height: 12),
              label("Operating Hours"),
              Row(
                children: [
                  Expanded(child: input(openTimeController, hint: "Open Time")),
                  const SizedBox(width: 10),
                  Expanded(
                    child: input(closeTimeController, hint: "Close Time"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(),
              const SizedBox(height: 12),
              label("Menu Items"),
              const SizedBox(height: 12),
              if (menuItems.isEmpty)
                const Text(
                  "No menu items yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              ...menuItems.map(
                (item) => menuCard(
                  item,
                  context: context,
                  updateFoodItem: updateFoodItem,
                  deleteFoodItem: deleteFoodItem,
                  reload: loadMenuItems,
                ),
              ),
            ] else ...[
              label("Curfew Time"),
              input(curfewController, hint: "Curfew (e.g. 10:00 PM)"),
              const SizedBox(height: 20),
              Divider(),
              const SizedBox(height: 12),
              label("Facilities"),
              const SizedBox(height: 12),
              if (facilities.isEmpty)
                const Text(
                  "No facilities yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              ...facilities.map(
                (item) => facilityCard(
                  item,
                  context: context,
                  updateFacilityItem: updateFacilityItem,
                  deleteFacilityItem: deleteFacilityItem,
                  reload: loadFacilities,
                ),
              ),
            ],

            const SizedBox(height: 20),
            Divider(),
            const SizedBox(height: 12),

            // About field
            label("About / Bio"),
            TextField(
              controller: aboutController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe your business",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Status toggle
            label("Status"),
            if (isEatery)
              Text(
                "Auto: ${computeEateryOpenStatus(widget.business)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(
                    value: "Open for tenants",
                    child: Text("Open for tenants"),
                  ),
                  DropdownMenuItem(
                    value: "No longer accepting",
                    child: Text("No longer accepting"),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedStatus = val);
                },
              ),

            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // or your cancel logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                        255,
                        142,
                        142,
                        142,
                      ), // different color for cancel
                      foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16), // spacing between buttons
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4423),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== Save Changes =====
  void _saveChanges() async {
    final id = extractId(
      widget.business['eatery_id'] ??
          widget.business['housing_id'] ??
          widget.business['id'],
    );

    final body = {
      'name': nameController.text.trim(),
      'location': locationController.text.trim(),
      if (isEatery) ...{
        'open_time': openTimeController.text.trim(),
        'end_time': closeTimeController.text.trim(),
        'about_desc': aboutController.text.trim(),
        'status': computeEateryOpenStatus({
          'open_time': openTimeController.text.trim(),
          'end_time': closeTimeController.text.trim(),
        }),
      } else ...{
        'curfew': curfewController.text.trim(),
        'about_desc': aboutController.text.trim(),
        'status': selectedStatus,
      },
    };

    final endpoint =
        isEatery
            ? "https://iskort-public-web.onrender.com/api/eatery/$id"
            : "https://iskort-public-web.onrender.com/api/housing/$id";

    final res = await http.put(
      Uri.parse(endpoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      if (isEatery) {
        for (var item in menuItems) {
          await updateFoodItem(item);
        }
        await loadMenuItems();
      } else {
        for (var item in facilities) {
          await updateFacilityItem(item);
        }
        await loadFacilities();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Changes saved!")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save changes.")));
    }
  }
}
