import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

String getBusinessStatus(Map<String, dynamic> biz) {
  final open = biz['open_time'];
  final close = biz['end_time'];
  if (open == null || close == null) return "N/A";

  final now = TimeOfDay.now();
  final openParts = open.split(":");
  final closeParts = close.split(":");

  final openTime = TimeOfDay(hour: int.parse(openParts[0]), minute: int.parse(openParts[1]));
  final closeTime = TimeOfDay(hour: int.parse(closeParts[0]), minute: int.parse(closeParts[1]));

  bool isOpen = (now.hour > openTime.hour ||
                (now.hour == openTime.hour && now.minute >= openTime.minute)) &&
                (now.hour < closeTime.hour ||
                (now.hour == closeTime.hour && now.minute <= closeTime.minute));

  return isOpen ? "Open" : "Closed";
}

// ===== Global Dialogs =====
void openAddFoodDialog(BuildContext context, Future<void> Function({
  required String food_pic,
  required String name,
  required String classification,
  required String price,
}) saveFoodToServer) {
  final pic = TextEditingController();
  final name = TextEditingController();
  final price = TextEditingController();
  String? selectedTag;

  final classes = [
    "Pork","Chicken","Beef","Vegetables","Seafood",
    "Alcoholic Drinks","Coffee Drinks","Non-Coffee Drinks",
    "Desserts","Snacks","Meal Set"
  ];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Add Menu Item"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              input(pic, hint: "Image URL"),
              const SizedBox(height: 10),
              input(name, hint: "Food Name"),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedTag,
                hint: const Text("Classification"),
                items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => selectedTag = val,
              ),
              const SizedBox(height: 10),
              input(price, hint: "Price (₱)"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () async {
              if (name.text.isEmpty || selectedTag == null) return;
              await saveFoodToServer(
                food_pic: pic.text.trim(),
                name: name.text.trim(),
                classification: selectedTag!,
                price: price.text.trim(),
              );
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

void openAddFacilityDialog(BuildContext context, Future<void> Function({
  required String name,
  required String facilityPic,
  required String price,
  required bool hasAc,
  required bool hasCr,
  required bool hasKitchen,
  required String type,
  required String additionalInfo,
}) saveFacilityToServer) {
  final name = TextEditingController();
  final price = TextEditingController();
  final pic = TextEditingController();
  final info = TextEditingController();
  bool hasAc = false;
  bool hasCr = false;
  bool hasKitchen = false;
  String? type;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Add Facility"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  input(name, hint: "Facility Name"),
                  input(price, hint: "Price"),
                  input(pic, hint: "Image URL"),
                  DropdownButtonFormField<String>(
                    value: type,
                    hint: const Text("Type"),
                    items: ["Solo","Shared"]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => type = val),
                  ),
                  CheckboxListTile(
                    title: const Text("Airconditioned"),
                    value: hasAc,
                    onChanged: (val) => setState(() => hasAc = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text("Comfort Room"),
                    value: hasCr,
                    onChanged: (val) => setState(() => hasCr = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text("Kitchen"),
                    value: hasKitchen,
                    onChanged: (val) => setState(() => hasKitchen = val ?? false),
                  ),
                  input(info, hint: "Additional Info"),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                child: const Text("Add"),
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

void openEditFoodDialog(
    BuildContext context,
    Map<String, dynamic> item,
    Future<void> Function(Map<String, dynamic>) updateFoodItem,
    Future<void> Function() reload) {
  final name = TextEditingController(text: item['name']);
  final price = TextEditingController(text: item['price'].toString());
  final pic = TextEditingController(text: item['food_pic']);
  final classes = [
    "Pork","Chicken","Beef","Vegetables","Seafood","Alcoholic Drinks",
    "Coffee Drinks","Non-Coffee Drinks","Desserts","Snacks","Meal Set"
  ];
  String? classification = classes.contains(item['classification']) ? item['classification'] : null;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Food Item"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                input(name, hint: "Food Name"),
                input(price, hint: "Price"),
                input(pic, hint: "Image URL"),
                DropdownButtonFormField<String>(
                  value: classification,
                  items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => classification = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                child: const Text("Save"),
                onPressed: () async {
                  item['name'] = name.text.trim();
                  item['price'] = price.text.trim();
                  item['food_pic'] = pic.text.trim();
                  item['classification'] = classification ?? "Pork";
                  await updateFoodItem(item);
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

void openEditFacilityDialog(
    BuildContext context,
    Map<String, dynamic> item,
    Future<void> Function(Map<String, dynamic>) updateFacilityItem,
    Future<void> Function() reload) {
  final name = TextEditingController(text: item['name']);
  final price = TextEditingController(text: item['price'].toString());
  final pic = TextEditingController(text: item['facility_pic']);
  final info = TextEditingController(text: item['additional_info']);
  bool hasAc = item['has_ac'] == 1 || item['has_ac'] == true;
  bool hasCr = item['has_cr'] == 1 || item['has_cr'] == true;
  bool hasKitchen = item['has_kitchen'] == 1 || item['has_kitchen'] == true;
  String? type = ["Solo","Shared"].contains(item['type']) ? item['type'] : null;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Facility"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  input(name, hint: "Facility Name"),
                  input(price, hint: "Price"),
                  input(pic, hint: "Image URL"),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: ["Solo","Shared"]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => type = val),
                  ),
                  CheckboxListTile(
                    title: const Text("Airconditioned"),
                    value: hasAc,
                    onChanged: (val) => setState(() => hasAc = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text("Comfort Room"),
                    value: hasCr,
                    onChanged: (val) => setState(() => hasCr = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text("Kitchen"),
                    value: hasKitchen,
                    onChanged: (val) => setState(() => hasKitchen = val ?? false),
                  ),
                  input(info, hint: "Additional Info"),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                child: const Text("Save"),
                onPressed: () async {
                  item['name'] = name.text.trim();
                  item['price'] = price.text.trim();
                  item['facility_pic'] = pic.text.trim();
                  item['additional_info'] = info.text.trim();
                  item['has_ac'] = hasAc;
                  item['has_cr'] = hasCr;
                  item['has_kitchen'] = hasKitchen;
                  item['type'] = type ?? "Solo";
                  await updateFacilityItem(item);
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

// ===== Global Cards =====
Widget menuCard(
  Map<String, dynamic> item, {
  required BuildContext context,
  required Future<void> Function(Map<String, dynamic>) updateFoodItem,
  required Future<void> Function(int) deleteFoodItem,
  required Future<void> Function() reload,
}){
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Image.network(item['food_pic'] ?? "",
          width: 50, height: 50, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood)),
      title: Text(item['name']),
      subtitle: Text("${item['classification']} • ₱${item['price']}"),
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
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Image.network(item['facility_pic'] ?? "",
          width: 50, height: 50, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.home)),
      title: Text(item['name']),
      subtitle: Text("${item['type']} • ₱${item['price']}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => openEditFacilityDialog(context, item, updateFacilityItem, reload),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await deleteFacilityItem(item['facility_id']);
              await reload();
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

  const EditEstablishmentsPage({super.key, required this.business});

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

    if (isEatery) {
      openTimeController = TextEditingController(text: biz['open_time'] ?? "");
      closeTimeController = TextEditingController(text: biz['end_time'] ?? "");
      loadMenuItems();
    } else {
      curfewController = TextEditingController(text: biz['curfew'] ?? "");
      loadFacilities();
    }
  }

  // ===== FOOD FUNCTIONS =====
  Future<void> loadMenuItems() async {
    final id = extractId(widget.business['eatery_id'] ?? widget.business['id']);
    final res = await http.get(Uri.parse("https://iskort-public-web.onrender.com/api/food/$id"));
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
    final eateryId = extractId(widget.business['eatery_id'] ?? widget.business['id']);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Food added successfully")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add menu item.")));
    }
  }

  Future<void> updateFoodItem(Map<String, dynamic> item) async {
    final eateryId = widget.business['eatery_id'] ?? widget.business['id'];
    await http.put(
      Uri.parse("https://iskort-public-web.onrender.com/api/food/${item['food_id']}"),
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
    final res = await http.delete(Uri.parse("https://iskort-public-web.onrender.com/api/food/$foodId"));
    if (res.statusCode == 200) {
      loadMenuItems();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Food deleted")));
    }
  }

  // ===== FACILITY FUNCTIONS =====
  Future<void> loadFacilities() async {
    final id = extractId(widget.business['housing_id'] ?? widget.business['id']);
    final res = await http.get(Uri.parse("https://iskort-public-web.onrender.com/api/facility/$id"));
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
  }) async {
    final housingId = extractId(widget.business['housing_id'] ?? widget.business['id']);
    final body = {
      "name": name,
      "housing_id": housingId,
      "facility_pic": facilityPic,
      "price": price,
      "has_ac": hasAc,
      "has_cr": hasCr,
      "has_kitchen": hasKitchen,
      "type": type,
      "additional_info": additionalInfo,
    };

    final res = await http.post(
      Uri.parse("https://iskort-public-web.onrender.com/api/facility"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      loadFacilities();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Facility added successfully")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add facility")));
    }
  }

  Future<void> updateFacilityItem(Map<String, dynamic> item) async {
    final housingId = widget.business['housing_id'] ?? widget.business['id'];
    await http.put(
      Uri.parse("https://iskort-public-web.onrender.com/api/facility/${item['facility_id']}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": item['name'],
        "housing_id": housingId.toString(),
        "facility_pic": item['facility_pic'],
        "price": item['price'],
        "has_ac": item['has_ac'],
        "has_cr": item['has_cr'],
        "has_kitchen": item['has_kitchen'],
        "type": item['type'],
        "additional_info": item['additional_info'],
      }),
    );
  }

  Future<void> deleteFacilityItem(int facilityId) async {
    final res = await http.delete(Uri.parse("https://iskort-public-web.onrender.com/api/facility/$facilityId"));
    if (res.statusCode == 200) {
      loadFacilities();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Facility deleted")));
    }
  }

  // ==== Build Method ===== //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEatery ? "Edit Eatery" : "Edit Housing")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label("Business Name"),
            input(nameController),
            const SizedBox(height: 12),
            label("Location"),
            input(locationController),

            if (isEatery) ...[
              const SizedBox(height: 20),
              Divider(),
              const SizedBox(height: 12),
              label("Operating Hours"),
              Row(
                children: [
                  Expanded(child: input(openTimeController, hint: "Open Time")),
                  const SizedBox(width: 10),
                  Expanded(child: input(closeTimeController, hint: "Close Time")),
                ],
              ),
              const SizedBox(height: 20),
              Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Menu Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => openAddFoodDialog(context, saveFoodToServer),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Item"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4423),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (menuItems.isEmpty)
                const Text("No menu items yet.", style: TextStyle(color: Colors.grey)),
              ...menuItems.map((item) => menuCard(item,
                context: context,
                updateFoodItem: updateFoodItem,
                deleteFoodItem: deleteFoodItem,
                reload: loadMenuItems,
              )),
            ] else ...[
              label("Curfew Time"),
              input(curfewController, hint: "Curfew (e.g. 10:00 PM)"),
              const SizedBox(height: 20),
              Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Facilities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => openAddFacilityDialog(context, saveFacilityToServer),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Facility"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4423),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
                           const SizedBox(height: 12),
              if (facilities.isEmpty)
                const Text("No facilities yet.", style: TextStyle(color: Colors.grey)),
              ...facilities.map((item) => facilityCard(item,
                context: context,
                updateFacilityItem: updateFacilityItem,
                deleteFacilityItem: deleteFacilityItem,
                reload: loadFacilities,
              )),
            ],

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A4423),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Save Changes =====
  void _saveChanges() async {
    final id = extractId(widget.business['eatery_id'] ?? widget.business['id']);
    final body = {
      'name': nameController.text.trim(),
      'location': locationController.text.trim(),
      if (isEatery) ...{
        'open_time': openTimeController.text.trim(),
        'end_time': closeTimeController.text.trim(),
        'about_desc': aboutController.text.trim(),
        'status': getBusinessStatus(widget.business),
      } else ...{
        'curfew': curfewController.text.trim(),
        'about_desc': aboutController.text.trim(),
        'status': getBusinessStatus(widget.business),
      }
  };

    final endpoint = isEatery
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
        loadMenuItems();
      } else {
        for (var item in facilities) {
          await updateFacilityItem(item);
        }
        loadFacilities();
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes saved!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save changes.")));
    }
  }
}