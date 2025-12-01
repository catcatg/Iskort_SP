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

  List<Map<String, dynamic>> menuItems = [];

  @override
  void initState() {
    super.initState();
    final biz = widget.business;
    isEatery = biz['type'] == 'eatery';

    // Shared controllers
    nameController = TextEditingController(text: biz['name'] ?? "");
    locationController = TextEditingController(text: biz['location'] ?? "");

    if (isEatery) {
      openTimeController = TextEditingController(text: biz['open_time'] ?? "");
      closeTimeController = TextEditingController(text: biz['end_time'] ?? "");
      _loadMenuItems();
    }
  }

  Future<void> _loadMenuItems() async {
    final id = _extractId(widget.business['eatery_id'] ?? widget.business['id']);
    final res = await http.get(
      Uri.parse("https://iskort-public-web.onrender.com/api/food/$id"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        menuItems = List<Map<String, dynamic>>.from(data['foods'] ?? []);
      });
    } else {
      setState(() {
        menuItems = [];
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
      _loadMenuItems(); // refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add menu item.")));
    }
    print("Add food response: ${res.statusCode} ${res.body}");
  }

  Future<void> _updateFoodItem(Map<String, dynamic> item) async {
    final eateryId = widget.business['eatery_id'] ?? widget.business['id'];

    final res = await http.put(
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

    if (res.statusCode != 200) {
      print("Failed to update food: ${res.body}");
    }
  }

  void _saveChanges() async {
    final id = _extractId(widget.business['eatery_id'] ?? widget.business['id']);
    final body = {
      'name': nameController.text.trim(),
      'location': locationController.text.trim(),
      if (isEatery) ...{
        'open_time': openTimeController.text.trim(),
        'end_time': closeTimeController.text.trim(),
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
      // ✅ Update menu items if eatery
      if (isEatery) {
        for (var item in menuItems) {
          await _updateFoodItem(item);
        }
        _loadMenuItems(); // refresh menu list
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Changes saved!")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to save changes.")));
    }
    print("Save response: ${res.statusCode} ${res.body}");
  }


  void _openAddFoodDialog() {
    final pic = TextEditingController();
    final name = TextEditingController();
    final price = TextEditingController();
    String? selectedTag;

    final classes = [
      "Pork", "Chicken", "Beef", "Vegetables", "Seafood", "Alcoholic Drinks", "Coffee Drinks", "Non-Coffee Drinks", "Desserts", "Snacks", "Meal Set"
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Menu Item"),
          content: SingleChildScrollView(
            child: Column(
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
      ),
    );
  }

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
                  const Text(
                    "Menu Items",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A4423)),
                  ),
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
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A4423),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48)),
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
