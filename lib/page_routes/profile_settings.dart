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
  String? _password;
  String? _notifPreference;

  File? _imageFile;

  List<String> _selectedFoodPrefs = [];
  List<String> _selectedHousingPrefs = [];

  @override
  void initState() {
    super.initState();
    _loadStoredPreferences();
  }

  // Load saved preferences
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
    }
  }

  // Pick profile image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  // Change user preferences
  void _changePreferences() {
    showDialog(
      context: context,
      builder:
          (_) => PreferencePopup(
            initialFoodPrefs: _selectedFoodPrefs, // Persist selections
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

  // Save profile updates
  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    print("Food Prefs: $_selectedFoodPrefs");
    print("Housing Prefs: $_selectedHousingPrefs");

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile updated!")));
  }

  // Render preference chips
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
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("Profile Settings"),
        backgroundColor: Color.fromARGB(255, 150, 29, 20),
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

            const SizedBox(height: 20),

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
                  TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(labelText: "Email"),
                    onSaved: (val) => _email = val,
                  ),
                  TextFormField(
                    initialValue: _phone,
                    decoration: const InputDecoration(labelText: "Phone"),
                    onSaved: (val) => _phone = val,
                  ),

                  const SizedBox(height: 20),

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
