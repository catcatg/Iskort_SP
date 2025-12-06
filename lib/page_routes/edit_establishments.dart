import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Safely extract an ID from int, string, or MongoDB ObjectId map
String _extractId(dynamic rawId) {
  if (rawId == null) return '';
  if (rawId is int) return rawId.toString();
  if (rawId is String) return rawId;
  if (rawId is Map && rawId.containsKey(r'$oid')) return rawId[r'$oid'];
  return '';
}

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

  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> facilities = [];

  @override
  void initState() {
    super.initState();
    final biz = widget.business;
    isEatery = biz['type'] == 'eatery';

    nameController = TextEditingController(text: biz['name'] ?? "");
    locationController = TextEditingController(text: biz['location'] ?? "");

    if (isEatery) {
      openTimeController = TextEditingController(text: biz['open_time'] ?? "");
      closeTimeController = TextEditingController(text: biz['end_time'] ?? "");
      _loadMenuItems();
    } else {
      curfewController = TextEditingController(text: biz['curfew'] ?? "");
      _loadFacilities();
    }
  }

  // ===== FOOD FUNCTIONS =====
  Future<void> _loadMenuItems() async {
    final id = _extractId(widget.business['eatery_id'] ?? widget.business['id']);
    final res = await http.get(Uri.parse("https://iskort-public-web.onrender.com/api/food/$id"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        menuItems = List<Map<String, dynamic>>.from(data['foods'] ?? []);
      });
    }
  }

  Future<void> _saveFoodToServer({
    required String food_pic,
    required String foodName,
    required String classification,
    required String price,
  }) async {
    final eateryId = _extractId(widget.business['eatery_id'] ?? widget.business['id']);
    final body = {
      "name": foodName,
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
      _loadMenuItems();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Food added successfully")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add menu item.")));
    }
  }

  Future<void> _updateFoodItem(Map<String, dynamic> item) async {
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

  Future<void> _deleteFoodItem(int foodId) async {
    final res = await http.delete(Uri.parse("https://iskort-public-web.onrender.com/api/food/$foodId"));
    if (res.statusCode == 200) {
      _loadMenuItems();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Food deleted")));
    }
  }

  // ===== FACILITY FUNCTIONS =====
  Future<void> _loadFacilities() async {
    final id = _extractId(widget.business['housing_id'] ?? widget.business['id']);
    final res = await http.get(Uri.parse("https://iskort-public-web.onrender.com/api/facility/$id"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        facilities = List<Map<String, dynamic>>.from(data['facilities'] ?? []);
      });
    }
  }

  Future<void> _saveFacilityToServer({
    required String name,
    required String facilityPic,
    required String price,
    required bool hasAc,
    required bool hasCr,
    required bool hasKitchen,
    required String type,
    required String additionalInfo,
  }) async {
    final housingId = _extractId(widget.business['housing_id'] ?? widget.business['id']);
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
      _loadFacilities();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Facility added successfully")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add facility")));
    }
  }

  Future<void> _updateFacilityItem(Map<String, dynamic> item) async {
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

  Future<void> _deleteFacilityItem(int facilityId) async {
    final res = await http.delete(Uri.parse("https://iskort-public-web.onrender.com/api/facility/$facilityId"));
    if (res.statusCode == 200) {
      _loadFacilities();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Facility deleted")));
    }
  }

  // ===== UI DIALOGS =====
  void _openEditFoodDialog(Map<String, dynamic> item) {
    final name = TextEditingController(text: item['name']);
    final price = TextEditingController(text: item['price'].toString());
    final pic = TextEditingController(text: item['food_pic']);
    final classes = ["Pork","Chicken","Beef","Vegetables","Seafood","Alcoholic Drinks",
                     "Coffee Drinks","Non-Coffee Drinks","Desserts","Snacks","Meal Set"];
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
                  _input(name, hint: "Food Name"),
                  _input(price, hint: "Price"),
                  _input(pic, hint: "Image URL"),
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
                  await _updateFoodItem(item);
                  Navigator.pop(context);
                  _loadMenuItems();
                },
              ),
            ],
          );
        },
      );
    },
    );
  }

  void _openEditFacilityDialog(Map<String, dynamic> item) {
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
                    _input(name, hint: "Facility Name"),
                    _input(price, hint: "Price"),
                    _input(pic, hint: "Image URL"),
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
                    _input(info, hint: "Additional Info"),
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
                    await _updateFacilityItem(item);
                    Navigator.pop(context);
                    _loadFacilities();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _openAddFoodDialog() {
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
              _input(pic, hint: "Image URL"),
              const SizedBox(height: 10),
              _input(name, hint: "Food Name"),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedTag,
                hint: const Text("Classification"),
                items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => selectedTag = val,
              ),
              const SizedBox(height: 10),
              _input(price, hint: "Price (₱)"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () async {
              if (name.text.isEmpty || selectedTag == null) return;

              await _saveFoodToServer(
                food_pic: pic.text.trim(),
                foodName: name.text.trim(),
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

  // ===== Cards with Edit + Delete =====
  Widget _menuCard(Map<String, dynamic> item) {
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
        subtitle: Text("${item['classification']} • ₱${item['price']}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.green),
              onPressed: () => _openEditFoodDialog(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await _deleteFoodItem(item['food_id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _facilityCard(Map<String, dynamic> item) {
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
        subtitle: Text("${item['type']} • ₱${item['price']}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _openEditFacilityDialog(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await _deleteFacilityItem(item['facility_id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helpers =====
  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A4423)),
      );

  Widget _input(TextEditingController controller, {String? hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
            _label("Business Name"),
            _input(nameController),
            const SizedBox(height: 12),
            _label("Location"),
            _input(locationController),

            if (isEatery) ...[
              const SizedBox(height: 20),
              Divider(),
              const SizedBox(height: 12),
              _label("Operating Hours"),
              Row(
                children: [
                  Expanded(child: _input(openTimeController, hint: "Open Time")),
                  const SizedBox(width: 10),
                  Expanded(child: _input(closeTimeController, hint: "Close Time")),
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
                    onPressed: _openAddFoodDialog,
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
              ...menuItems.map(_menuCard).toList(),
            ] else ...[
              _label("Curfew Time"),
              _input(curfewController, hint: "Curfew (e.g. 10:00 PM)"),
              const SizedBox(height: 20),
              Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Facilities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () {
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
                                      _input(name, hint: "Facility Name"),
                                      _input(price, hint: "Price"),
                                      _input(pic, hint: "Image URL"),
                                      DropdownButtonFormField<String>(
                                        value: type,
                                        hint: const Text("Type"),
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
                                      _input(info, hint: "Additional Info"),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                  ElevatedButton(
                                    child: const Text("Add"),
                                    onPressed: () async {
                                      await _saveFacilityToServer(
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
                    },
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
              ...facilities.map(_facilityCard).toList(),
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
    final id = _extractId(widget.business['eatery_id'] ?? widget.business['id']);
    final body = {
      'name': nameController.text.trim(),
      'location': locationController.text.trim(),
      if (isEatery) ...{
        'open_time': openTimeController.text.trim(),
        'end_time': closeTimeController.text.trim(),
      } else ...{
        'curfew': curfewController.text.trim(),
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
          await _updateFoodItem(item);
        }
        _loadMenuItems();
      } else {
        for (var item in facilities) {
          await _updateFacilityItem(item);
        }
        _loadFacilities();
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes saved!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save changes.")));
    }
  }
}