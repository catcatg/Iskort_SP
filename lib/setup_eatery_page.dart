import 'package:flutter/material.dart';
import 'package:iskort/homepage.dart';
import 'setup_details.dart';

class SetupEateryPage extends StatefulWidget {
  const SetupEateryPage({super.key});

  @override
  State<SetupEateryPage> createState() => _SetupEateryPageState();
}

class _SetupEateryPageState extends State<SetupEateryPage> {
  String selectedType = '';

  void selectType(String type) {
    setState(() {
      selectedType = type;
    });
  }

  void goToNext() {
    if (selectedType.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an establishment type first!"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "What’s your establishment?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 122, 12, 12),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Food Card
            GestureDetector(
              onTap: () => selectType('Food'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      selectedType == 'Food'
                          ? const Color(0xFFF8F8F8)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color:
                          selectedType == 'Food'
                              ? Colors.grey.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color:
                        selectedType == 'Food'
                            ? Colors.redAccent
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.restaurant_rounded,
                      color: Colors.redAccent,
                      size: 36,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Food Establishment",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lodging Card
            GestureDetector(
              onTap: () => selectType('Lodging'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      selectedType == 'Lodging'
                          ? const Color(0xFFF8F8F8)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color:
                          selectedType == 'Lodging'
                              ? Colors.grey.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color:
                        selectedType == 'Lodging'
                            ? Colors.redAccent
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.house_rounded,
                      color: Colors.redAccent,
                      size: 36,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Lodging / Dormitory",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: goToNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF387C44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Next",
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
