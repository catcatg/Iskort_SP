import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:iskort/widgets/reusables.dart';

class SignupPage extends StatefulWidget {
  final String preselectedRole; // role from ChooseRolePage

  const SignupPage({super.key, required this.preselectedRole});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  late String selectedRole;
  bool get isRoleSelected => selectedRole.isNotEmpty;

  String notifPreference = 'email';

  @override
  void initState() {
    super.initState();
    selectedRole =
        widget
            .preselectedRole; // set chosen role automatically from select role page
  }

  Future<void> register() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://iskort-public-web.onrender.com/api/admin/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text,
          'email': emailController.text,
          'password': passwordController.text,
          'phone_num': phoneController.text,
          'role': selectedRole,
          'notif_preference': notifPreference,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registered successfully! Please login.'),
          ),
        );
        nameController.clear();
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();
        phoneController.clear();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${body['message'] ?? 'Registration failed'}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server')),
      );
    }
  }

  Widget notifButton(String label) {
    final isSelected = notifPreference == label.toLowerCase();
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            notifPreference = label.toLowerCase();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0A4423) : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFFBAC24) : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.03),

                  const Row(
                    children: [
                      Text(
                        'Welcome to ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Iskort',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF791317),
                        ),
                      ),
                    ],
                  ),

                  const Text(
                    "Let's get started!",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),

                  const SizedBox(height: 20),

                  // Selected Role Display
                  Text(
                    "Signing up as: ${selectedRole.toUpperCase()}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A4423),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Form fields
                  CustomTextField(
                    title: 'Name',
                    label: 'Enter your full name',
                    controller: nameController,
                  ),
                  const SizedBox(height: 15),

                  CustomTextField(
                    title: 'Email',
                    label: 'Enter your email',
                    controller: emailController,
                  ),
                  const SizedBox(height: 15),

                  CustomTextField(
                    title: 'Phone Number',
                    label: 'Enter your phone number',
                    controller: phoneController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 15),

                  CustomTextField(
                    title: 'Password',
                    label: 'Enter your password',
                    isPassword: true,
                    controller: passwordController,
                  ),
                  const SizedBox(height: 15),

                  CustomTextField(
                    title: 'Confirm Password',
                    label: 'Confirm your password',
                    isPassword: true,
                    controller: confirmPasswordController,
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Select your preferred way to receive updates:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      notifButton('Email'),
                      notifButton('SMS'),
                      notifButton('Both'),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A4423),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: register,
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFBAC24),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: const Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                          children: [
                            TextSpan(
                              text: 'Login here',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
