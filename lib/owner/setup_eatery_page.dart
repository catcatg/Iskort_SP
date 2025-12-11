import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../profile.dart';

class SetupEateryPage extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const SetupEateryPage({super.key, required this.currentUser});

  @override
  State<SetupEateryPage> createState() => _SetupEateryPage();
}

class _SetupEateryPage extends State<SetupEateryPage> {
  String selectedType = ''; // 'Eatery' or 'Housing'
  final _formKey = GlobalKey<FormState>();

  // Prefilled user info
  late TextEditingController ownerNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController businessNameController;

  // Shared fields
  final TextEditingController locationController = TextEditingController();

  // Profile photo (eatery_photo / housing_photo)
  final TextEditingController photoUrlController = TextEditingController(
    text: 'https://upload.wikimedia.org/wikipedia/en/b/ba/UP_Visayas_Logo.svg',
  );

  // Eatery-specific
  TimeOfDay? openTime;
  TimeOfDay? closeTime;
  final TextEditingController minPriceController = TextEditingController();

  // Housing-specific
  TimeOfDay? curfewTime;
  final TextEditingController priceController = TextEditingController();

  // Eatery documents
  final TextEditingController validIdController = TextEditingController();
  final TextEditingController businessPermitController = TextEditingController();
  final TextEditingController dtiCertificateController = TextEditingController();
  final TextEditingController healthPermitController = TextEditingController();

  // Housing documents
  final TextEditingController proofOfOwnershipController = TextEditingController();

  // Cloudinary config (replace with your actual values)
  static const String _cloudName = "iskort-system";
  static const String _uploadPreset = "iskort_upload";

  @override
  void initState() {
    super.initState();
    ownerNameController = TextEditingController(text: widget.currentUser['name'] ?? '');
    phoneController = TextEditingController(text: widget.currentUser['phone_num'] ?? '');
    emailController = TextEditingController(text: widget.currentUser['email'] ?? '');
    businessNameController = TextEditingController();
  }

  Future<void> pickTime(bool isOpen) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
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

  // Upload file to Cloudinary and return secure_url
  Future<String?> uploadToCloudinary(File file, {String resourceType = 'image'}) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload");
    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final data = jsonDecode(resStr);
      return data['secure_url'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: ${response.statusCode}")),
      );
      return null;
    }
  }

  // Reusable helper: pick file (image or doc) and upload, then set controller
  Future<void> pickAndUpload(TextEditingController controller, String label,
      {bool allowDocs = false}) async {
    final ImagePicker picker = ImagePicker();

    XFile? picked;
    if (allowDocs) {
      // For documents, prefer picking any file. If your app targets mobile,
      // you can still use ImagePicker for photos and add a file_picker package for PDFs/docs later.
      // For now, we allow picking images for permits; switch to file_picker if needed.
      picked = await picker.pickImage(source: ImageSource.gallery);
    } else {
      picked = await picker.pickImage(source: ImageSource.gallery);
    }

    if (picked != null) {
      final File file = File(picked.path);
      final String? url = await uploadToCloudinary(file, resourceType: 'image');
      if (url != null) {
        setState(() {
          controller.text = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$label uploaded successfully")),
        );
      }
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

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
        'valid_id_base64': validIdController.text,
        'business_permit_base64': businessPermitController.text,
        'dti_certificate_base64': dtiCertificateController.text,
        'health_permit_base64': healthPermitController.text,
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
        'valid_id_base64': validIdController.text,
        'proof_of_ownership_base64': proofOfOwnershipController.text,
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
        SnackBar(
          content: Text(
            '$selectedType submitted! Waiting for verification. Check your email/sms for updates.',
          ),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserProfilePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  Widget _docRow(String label, TextEditingController controller, {bool allowDocs = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '$label URL',
            hintText: 'Auto-filled after upload',
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => pickAndUpload(controller, label, allowDocs: allowDocs),
                child: Text('Upload $label'),
              ),
            ),
            const SizedBox(width: 10),
            if (controller.text.isNotEmpty)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => controller.clear()),
                  child: const Text('Clear'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
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
            Navigator.pushReplacementNamed(
              context,
              '/profile',
              arguments: widget.currentUser,
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
                const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: businessNameController,
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

                const Text('Business Information', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Photo URL + Upload
                TextFormField(
                  controller: photoUrlController,
                  decoration: const InputDecoration(labelText: 'Profile Photo (Upload URL)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => pickAndUpload(photoUrlController, "Profile Photo"),
                  child: const Text("Upload Photo"),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Eatery-specific UI
                if (selectedType == 'Eatery') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => pickTime(true),
                          child: Text(
                            openTime == null
                                ? 'Select Opening Time'
                                : 'Opening: ${openTime!.format(context)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => pickTime(false),
                          child: Text(
                            closeTime == null
                                ? 'Select Closing Time'
                                : 'Closing: ${closeTime!.format(context)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: minPriceController,
                    decoration: const InputDecoration(labelText: 'Minimum Price'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  const Text('Required documents (eatery)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _docRow('Valid ID', validIdController),
                  _docRow('Business Permit', businessPermitController),
                  _docRow('DTI Certificate', dtiCertificateController),
                  _docRow('Health Permit', healthPermitController),
                ],

                // Housing-specific UI
                if (selectedType == 'Housing') ...[
                  ElevatedButton(
                    onPressed: () => pickTime(false),
                    child: Text(
                      curfewTime == null
                          ? 'Select Curfew Time'
                          : 'Curfew: ${curfewTime!.format(context)}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Monthly Price'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  const Text('Required documents (housing)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _docRow('Valid ID', validIdController),
                  _docRow('Proof of Ownership', proofOfOwnershipController),
                ],

                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: submitForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFF387C44),
                    ),
                    child: const Text('Submit Application'),
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