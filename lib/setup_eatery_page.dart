import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String? establishmentType;
  final nameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final contactEmailController = TextEditingController();
  final contactPhoneController = TextEditingController();
  final locationController = TextEditingController();
  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  File? pickedImage;
  final List<Map<String, dynamic>> menuItems = [];

  final ImagePicker _picker = ImagePicker();

  int step = 0;

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> submitData() async {
    final response = await http.post(
      Uri.parse('http://192.168.68.108:3000/api/eatery'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'owner_id': 1, // TODO: replace with logged-in owner_id
        'name': nameController.text,
        'location': locationController.text,
        'open_time': openTime?.format(context),
        'end_time': closeTime?.format(context),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final eateryId = data['eatery_id'];

      for (var item in menuItems) {
        await http.post(
          Uri.parse('http://192.168.68.108:3000/api/food'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': item['name'],
            'eatery_id': eateryId,
            'classification': item['classification'],
            'price': item['price'],
            'photo': item['photo'] ?? '',
          }),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Business setup complete!")),
      );

      Navigator.pushReplacementNamed(context, '/homepage');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save business setup.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Your Business")),
      body: Stepper(
        currentStep: step,
        onStepContinue: () {
          if (step < 2) {
            setState(() => step++);
          } else {
            submitData();
          }
        },
        onStepCancel: () {
          if (step > 0) setState(() => step--);
        },
        steps: [
          Step(
            title: const Text("Choose Type"),
            content: Column(
              children: [
                RadioListTile(
                  title: const Text("Food"),
                  value: "food",
                  groupValue: establishmentType,
                  onChanged: (val) => setState(() => establishmentType = val),
                ),
                RadioListTile(
                  title: const Text("Lodging"),
                  value: "lodging",
                  groupValue: establishmentType,
                  onChanged: (val) => setState(() => establishmentType = val),
                ),
              ],
            ),
          ),
          Step(
            title: const Text("Details"),
            content: Column(
              children: [
                TextField(controller: ownerNameController, decoration: const InputDecoration(labelText: "Owner Name")),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Establishment Name")),
                TextField(controller: contactEmailController, decoration: const InputDecoration(labelText: "Contact Email")),
                TextField(controller: contactPhoneController, decoration: const InputDecoration(labelText: "Contact Phone")),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: "Location")),
                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) setState(() => openTime = time);
                      },
                      child: Text(openTime == null ? "Set Open Time" : "Open: ${openTime!.format(context)}"),
                    ),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) setState(() => closeTime = time);
                      },
                      child: Text(closeTime == null ? "Set Close Time" : "Close: ${closeTime!.format(context)}"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Step(
            title: const Text("Menu"),
            content: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final itemNameController = TextEditingController();
                    final itemPriceController = TextEditingController();
                    String classification = "chicken";

                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Add Menu Item"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: itemNameController, decoration: const InputDecoration(labelText: "Name")),
                            TextField(controller: itemPriceController, decoration: const InputDecoration(labelText: "Price")),
                            DropdownButton<String>(
                              value: classification,
                              onChanged: (val) => classification = val!,
                              items: ["chicken", "pork", "beef", "coffee", "non-coffee", "alcoholic", "non-alcoholic"]
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                            ),
                            ElevatedButton(
                              onPressed: pickImage,
                              child: const Text("Pick Image"),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                menuItems.add({
                                  "name": itemNameController.text,
                                  "price": itemPriceController.text,
                                  "classification": classification,
                                  "photo": pickedImage?.path,
                                });
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Add"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("Add Menu Item"),
                ),
                ...menuItems.map((item) => ListTile(
                      title: Text(item['name']),
                      subtitle: Text("₱${item['price']} - ${item['classification']}"),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
