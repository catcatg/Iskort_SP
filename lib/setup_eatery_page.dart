import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SetupEateryPage extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const SetupEateryPage({super.key, required this.currentUser});

  @override
  State<SetupEateryPage> createState() => _SetupEateryPageState();
}

class _SetupEateryPageState extends State<SetupEateryPage> {
  String selectedType = '';
  final _formKey = GlobalKey<FormState>();

  // Prefilled / editable info
  late TextEditingController establishmentNameController;
  late TextEditingController ownerNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  // Establishment info
  TextEditingController photoUrlController = TextEditingController(text: 'https://upload.wikimedia.org/wikipedia/en/b/ba/UP_Visayas_Logo.svg');
  TimeOfDay? openTime;
  TimeOfDay? closeTime;
  TextEditingController locationController = TextEditingController();

  // Required files (placeholders)
  bool proofBusinessName = false;
  bool proofOfRight = false;
  bool barangayClearance = false;
  bool cedula = false;
  bool governmentID = false;

  // Services
  TextEditingController minPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefill with logged-in user info
    ownerNameController = TextEditingController(text: widget.currentUser['name'] ?? '');
    phoneController = TextEditingController(text: widget.currentUser['phone_num'] ?? '');
    emailController = TextEditingController(text: widget.currentUser['email'] ?? '');
    establishmentNameController = TextEditingController();
  }

  void selectType(String type) {
    setState(() {
      selectedType = type;
    });
  }

  Future<void> pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          openTime = picked;
        } else {
          closeTime = picked;
        }
      });
    }
  }

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (selectedType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an establishment type!')),
        );
        return;
      }
      if (openTime == null || closeTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick opening and closing time!')),
        );
        return;
      }

      final data = {
        'owner_id': widget.currentUser['owner_id'], // Actual owner ID
        'name': establishmentNameController.text,
        'location': locationController.text,
        'open_time': '${openTime!.hour}:${openTime!.minute}',
        'end_time': '${closeTime!.hour}:${closeTime!.minute}',
        'eatery_photo': photoUrlController.text,
        'min_price': minPriceController.text,
        'is_verified': 0,
        'verified_by_admin_id': null,
        'verified_time': null,
      };

      final response = await http.post(
        Uri.parse('https://iskort-public-web.onrender.com/api/eatery'), // Replace with your actual backend URL if different
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eatery submitted! Waiting for verification.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Business'),
        backgroundColor: const Color(0xFF387C44),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Establishment Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Eatery'),
                    selected: selectedType == 'Eatery',
                    onSelected: (_) => selectType('Eatery'),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Housing'),
                    selected: selectedType == 'Housing',
                    onSelected: (_) => selectType('Housing'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'You can set up multiple establishments in your profile one at a time.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Personal Information
              const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: establishmentNameController,
                decoration: const InputDecoration(labelText: 'Establishment Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: ownerNameController,
                decoration: const InputDecoration(labelText: 'Owner Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email (read-only)'),
                readOnly: true,
              ),
              const SizedBox(height: 20),

              // Proof of Identity
              const Text('Proof of Identity', style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                value: governmentID,
                onChanged: (val) => setState(() => governmentID = val ?? false),
                title: const Text('Government-issued ID'),
              ),
              const SizedBox(height: 20),

              // Establishment Info
              const Text('Establishment Information', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: photoUrlController,
                decoration: const InputDecoration(labelText: 'Profile Photo (Upload Photo URL)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickTime(true),
                      child: Text(openTime == null ? 'Select Opening Time' : 'Opening: ${openTime!.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickTime(false),
                      child: Text(closeTime == null ? 'Select Closing Time' : 'Closing: ${closeTime!.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Required Files
              const Text('Required Files', style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                value: proofBusinessName,
                onChanged: (val) => setState(() => proofBusinessName = val ?? false),
                title: const Text('Proof of Business Name Registration'),
              ),
              CheckboxListTile(
                value: proofOfRight,
                onChanged: (val) => setState(() => proofOfRight = val ?? false),
                title: const Text('Proof of Right (Owned/Rented)'),
              ),
              CheckboxListTile(
                value: barangayClearance,
                onChanged: (val) => setState(() => barangayClearance = val ?? false),
                title: const Text('Barangay Business Clearance'),
              ),
              CheckboxListTile(
                value: cedula,
                onChanged: (val) => setState(() => cedula = val ?? false),
                title: const Text('Cedula'),
              ),
              const SizedBox(height: 20),

              // Services
              const Text('Services', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: minPriceController,
                decoration: const InputDecoration(labelText: 'Minimum Price'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: submitForm,
                  child: const Text('Submit / Save'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
