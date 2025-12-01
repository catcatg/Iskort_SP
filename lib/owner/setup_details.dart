import 'package:flutter/material.dart';

class SetupDetailsPage extends StatefulWidget {
  const SetupDetailsPage({super.key});

  @override
  State<SetupDetailsPage> createState() => _SetupDetailsPageState();
}

class _SetupDetailsPageState extends State<SetupDetailsPage> {
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final TextEditingController openingTimeController = TextEditingController();
  final TextEditingController closingTimeController = TextEditingController();

  final TextEditingController menuController = TextEditingController();

  void saveDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Details saved successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Colors.black54),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 0, 0, 0),
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          /*boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],*/
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 122, 12, 12),
                Color.fromARGB(255, 10, 62, 17),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Setup Your Business",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        //centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Create your business profile.",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Accordion Section 1: Details
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ExpansionTile(
                title: const Text(
                  "Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 122, 12, 12),
                  ),
                ),
                iconColor: const Color(0xFF6BCB77),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children: [
                  buildInputField("Business Name", businessNameController),
                  buildInputField(
                    "Contact Number",
                    contactNumberController,
                    type: TextInputType.phone,
                  ),
                  buildInputField(
                    "Email",
                    emailController,
                    type: TextInputType.emailAddress,
                  ),
                  buildInputField("Location", locationController),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Accordion Section 2: Business Hours
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ExpansionTile(
                title: const Text(
                  "Business Hours",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 122, 12, 12),
                  ),
                ),
                iconColor: const Color(0xFF6BCB77),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children: [
                  buildInputField("Opening Time", openingTimeController),
                  buildInputField("Closing Time", closingTimeController),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Accordion Section 3: Menu
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ExpansionTile(
                title: const Text(
                  "Menu",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 122, 12, 12),
                  ),
                ),
                iconColor: const Color(0xFF6BCB77),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children: [
                  buildInputField("Menu Items / Description", menuController),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF387C44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
