import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SetupMenuPage extends StatefulWidget {
  const SetupMenuPage({super.key});

  @override
  State<SetupMenuPage> createState() => _SetupMenuPageState();
}

class _SetupMenuPageState extends State<SetupMenuPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  String classification = "Chicken";
  File? pickedImage;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => pickedImage = File(file.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Menu Item")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField(
                value: classification,
                items: ["Chicken", "Pork", "Beef", "Coffee", "Non-Coffee", "Alcoholic", "Non-Alcoholic"]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => classification = val!),
                decoration: const InputDecoration(labelText: "Classification"),
              ),
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Item Name")),
              TextFormField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Price")),
              const SizedBox(height: 10),
              pickedImage != null
                  ? Image.file(pickedImage!, height: 120)
                  : const Text("No image selected"),
              TextButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Pick Image"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO: Call API to save item
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Item saved (mock)")),
                  );
                },
                child: const Text("Save Item"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
