import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'homepage.dart';

class SetupBusinessPage extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const SetupBusinessPage({super.key, required this.currentUser});

  @override
  State<SetupBusinessPage> createState() => _SetupBusinessPageState();
}

class _SetupBusinessPageState extends State<SetupBusinessPage> {
  String selectedType = ''; // 'Eatery' or 'Housing'
  final _formKey = GlobalKey<FormState>();

  // Prefilled user info
  late TextEditingController ownerNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController businessNameController;

  // Shared fields
  TextEditingController locationController = TextEditingController();
  TextEditingController photoUrlController = TextEditingController(
    text:
        'https://upload.wikimedia.org/wikipedia/en/b/ba/UP_Visayas_Logo.svg',
  );

  // Eatery-specific
  TimeOfDay? openTime;
  TimeOfDay? closeTime;
  TextEditingController minPriceController = TextEditingController();

  // Housing-specific
  TimeOfDay? curfewTime;
  TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ownerNameController =
        TextEditingController(text: widget.currentUser['name'] ?? '');
    phoneController =
        TextEditingController(text: widget.currentUser['phone_num'] ?? '');
    emailController =
        TextEditingController(text: widget.currentUser['email'] ?? '');
    businessNameController = TextEditingController();
  }

  Future<void> pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (selectedType == 'Eatery') {
          if (isOpen) {
            openTime = picked;
          } else {
            closeTime = picked;
          }
        } else {
          curfewTime = picked;
        }
      });
    }
  }

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (selectedType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a business type first!')),
        );
        return;
      }

      var data;
      var apiUrl;

      if (selectedType == 'Eatery') {
        if (openTime == null || closeTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please pick opening and closing times!')),
          );
          return;
        }

        data = {
          'owner_id': widget.currentUser['owner_id'],
          'name': businessNameController.text,
          'location': locationController.text,
          'open_time': '${openTime!.hour}:${openTime!.minute}',
          'end_time': '${closeTime!.hour}:${closeTime!.minute}',
          'eatery_photo': photoUrlController.text,
          'min_price': minPriceController.text,
          'is_verified': 0,
          'verified_by_admin_id': null,
          'verified_time': null,
        };
        apiUrl = 'https://iskort-public-web.onrender.com/api/eatery';
      } else {
        if (curfewTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a curfew time!')),
          );
          return;
        }

        data = {
          'owner_id': widget.currentUser['owner_id'],
          'name': businessNameController.text,
          'location': locationController.text,
          'curfew': '${curfewTime!.hour}:${curfewTime!.minute}',
          'price': priceController.text,
          'housing_photo': photoUrlController.text,
          'is_verified': 0,
          'verified_by_admin_id': null,
        };
        apiUrl = 'https://iskort-public-web.onrender.com/api/housing';
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$selectedType submitted! Waiting for verification.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Type Choice
              const Text(
                'Select Business Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Eatery'),
                    selected: selectedType == 'Eatery',
                    onSelected: (_) => setState(() => selectedType = 'Eatery'),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Housing'),
                    selected: selectedType == 'Housing',
                    onSelected: (_) => setState(() => selectedType = 'Housing'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (selectedType.isNotEmpty) ...[
                const Text('Personal Information',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: businessNameController,
                  decoration:
                      const InputDecoration(labelText: 'Establishment Name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: ownerNameController,
                  decoration: const InputDecoration(labelText: 'Owner Name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration:
                      const InputDecoration(labelText: 'Phone Number'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration:
                      const InputDecoration(labelText: 'Email (read-only)'),
                  readOnly: true,
                ),
                const SizedBox(height: 20),

                // Common fields
                const Text('Business Information',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: photoUrlController,
                  decoration: const InputDecoration(
                      labelText: 'Profile Photo (Upload URL)'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),

                // Eatery-specific UI
                if (selectedType == 'Eatery') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => pickTime(true),
                          child: Text(openTime == null
                              ? 'Select Opening Time'
                              : 'Opening: ${openTime!.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => pickTime(false),
                          child: Text(closeTime == null
                              ? 'Select Closing Time'
                              : 'Closing: ${closeTime!.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: minPriceController,
                    decoration:
                        const InputDecoration(labelText: 'Minimum Price'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ],

                // Housing-specific UI
                if (selectedType == 'Housing') ...[
                  ElevatedButton(
                    onPressed: () => pickTime(false),
                    child: Text(curfewTime == null
                        ? 'Select Curfew Time'
                        : 'Curfew: ${curfewTime!.format(context)}'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    decoration:
                        const InputDecoration(labelText: 'Monthly Price'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ],

                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: submitForm,
                    child: const Text('Submit / Save'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFF387C44),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
