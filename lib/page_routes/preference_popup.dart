import 'package:flutter/material.dart';

class PreferencePopup extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  // Receive previous preferences
  final List<String> initialFoodPrefs;
  final List<String> initialHousingPrefs;

  const PreferencePopup({
    super.key,
    required this.onSave,
    required this.initialFoodPrefs,
    required this.initialHousingPrefs,
  });

  @override
  State<PreferencePopup> createState() => _PreferencePopupState();
}

class _PreferencePopupState extends State<PreferencePopup> {
  List<String> selectedFoodTags = [];
  List<String> selectedHousingTags = [];

  final List<String> foodOptions = [
    "Chicken",
    "Beef",
    "Lutong Bahay",
    "Pork",
    "Vegetables",
    "Silog Meals",
    "Seafood",
    "Snacks / Merienda",
  ];

  final List<String> housingOptions = [
    "Solo Room",
    "Bedspace",
    "With Aircon",
    "With CR Inside",
    "With Wifi",
    "Pet-friendly",
    "Near Campus",
    "Fully Furnished",
  ];

  @override
  void initState() {
    super.initState();

    // Restore previously selected tags
    selectedFoodTags = List.from(widget.initialFoodPrefs);
    selectedHousingTags = List.from(widget.initialHousingPrefs);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Welcome!\nPlease select your preferences",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------
            // FOOD TAG SELECTION
            // -----------------------
            const Text(
              "Food Preferences",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  foodOptions.map((food) {
                    final selected = selectedFoodTags.contains(food);
                    return FilterChip(
                      label: Text(
                        food,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFF0A4423),
                      onSelected: (_) {
                        setState(() {
                          selected
                              ? selectedFoodTags.remove(food)
                              : selectedFoodTags.add(food);
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),

            // -----------------------
            // HOUSING TAG SELECTION
            // -----------------------
            const Text(
              "Housing Preferences",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  housingOptions.map((house) {
                    final selected = selectedHousingTags.contains(house);
                    return FilterChip(
                      label: Text(
                        house,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFF0A4423),
                      onSelected: (_) {
                        setState(() {
                          selected
                              ? selectedHousingTags.remove(house)
                              : selectedHousingTags.add(house);
                        });
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),

      // BUTTONS
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Close without saving
          child: const Text("Skip"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave({
              "food": selectedFoodTags,
              "housing": selectedHousingTags,
            });
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
