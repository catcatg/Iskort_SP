import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _email;
  String? _role;
  String? _phone;
  String? _password;
  String? _notifPreference;

  File? _imageFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _name = args['name'];
      _email = args['email'];
      _role = args['role'];
      _phone = args['phone'];
      _notifPreference = args['notifPreference'];
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 600,
                    );
                    if (picked != null)
                      setState(() => _imageFile = File(picked.path));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                      maxWidth: 600,
                    );
                    if (picked != null)
                      setState(() => _imageFile = File(picked.path));
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Send updated data to backend
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile updated!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("Profile Settings"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color.fromARGB(255, 150, 29, 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    _imageFile != null ? FileImage(_imageFile!) : null,
                child:
                    _imageFile == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.edit, color: Colors.green),
              label: const Text("Change Profile Picture"),
            ),
            const SizedBox(height: 20),

            // Display role & notification preference
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("Role: $_role"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("Notification: $_notifPreference"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Editable fields
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(labelText: "Name"),
                    onSaved: (val) => _name = val,
                    validator:
                        (val) =>
                            val == null || val.isEmpty ? "Name required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(labelText: "Email"),
                    onSaved: (val) => _email = val,
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? "Email required"
                                : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                    ),
                    onSaved: (val) => _phone = val,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "New Password (optional)",
                    ),
                    obscureText: true,
                    onSaved: (val) => _password = val,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A4423),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
