import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'preference_popup.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _email;
  String? _role;
  String? _phone;
  String? _address;
  String? _password;
  String? _notifPreference;
  String? _businessType;
  File? _imageFile;

  List<String> _selectedFoodPrefs = [];
  List<String> _selectedHousingPrefs = [];

  @override
  void initState() {
    super.initState();
    _loadStoredPreferences();
  }

  Future<void> _loadStoredPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedFoodPrefs = prefs.getStringList("foodPrefs") ?? [];
      _selectedHousingPrefs = prefs.getStringList("housingPrefs") ?? [];
    });
  }

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
      _address = args['address'];
      _businessType = args['businessType'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _changePreferences() {
    showDialog(
      context: context,
      builder:
          (_) => PreferencePopup(
            initialFoodPrefs: _selectedFoodPrefs,
            initialHousingPrefs: _selectedHousingPrefs,
            onSave: (prefsData) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setStringList(
                "foodPrefs",
                List<String>.from(prefsData["food"] ?? []),
              );
              await prefs.setStringList(
                "housingPrefs",
                List<String>.from(prefsData["housing"] ?? []),
              );
              setState(() {
                _selectedFoodPrefs = List<String>.from(prefsData["food"] ?? []);
                _selectedHousingPrefs = List<String>.from(
                  prefsData["housing"] ?? [],
                );
              });
            },
          ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile updated!")));
  }

  Widget _buildPreferenceChips(List<String> selectedPrefs) {
    if (selectedPrefs.isEmpty) return const Text("No preferences selected");
    return Wrap(
      spacing: 6,
      children:
          selectedPrefs
              .map(
                (e) => Chip(label: Text(e), backgroundColor: Colors.green[200]),
              )
              .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = _role?.toLowerCase() == 'owner';

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("Profile Settings"),
        backgroundColor: const Color.fromARGB(255, 150, 29, 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture with Edit Icon
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _imageFile != null ? FileImage(_imageFile!) : null,
                  child:
                      _imageFile == null
                          ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 18, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email, color: Color(0xFF0A4423)),
                const SizedBox(width: 8),
                Text(
                  _email ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 20),

                Icon(Icons.notifications, color: Color(0xFF0A4423)),
                const SizedBox(width: 8),
                Text(
                  _notifPreference ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            //  Business Type
            if (isOwner) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.business, color: Color(0xFF0A4423)),
                  const SizedBox(width: 8),
                  Text(
                    _businessType != null
                        ? (_businessType!.toLowerCase() == 'eatery'
                            ? "Food / Eatery"
                            : "Housing")
                        : "N/A",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(labelText: "Name"),
                    onSaved: (val) => _name = val,
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
                    initialValue: _phone,
                    decoration: const InputDecoration(labelText: "Address"),
                    onSaved: (val) => _address = val,
                  ),

                  const SizedBox(height: 20),

                  // Preferences for non-owners
                  if (!isOwner) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Preferences",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _changePreferences,
                          child: const Text("Change Preferences"),
                        ),
                      ],
                    ),
                    const Text("Food:"),
                    _buildPreferenceChips(_selectedFoodPrefs),
                    const SizedBox(height: 8),
                    const Text("Housing:"),
                    _buildPreferenceChips(_selectedHousingPrefs),
                    const SizedBox(height: 24),
                  ],

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
