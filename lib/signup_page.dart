import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:iskort/widgets/reusables.dart';

class SignupPage extends StatefulWidget {
  final String? preselectedRole; 

  const SignupPage({super.key, this.preselectedRole}); 

  @override
  State<SignupPage> createState() => _SignupPageState();
}


class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();


  String selectedRole = '';
  bool get isRoleSelected => selectedRole.isNotEmpty;

  String notifPreference = 'email';

  void initState() {
  super.initState();
  // Initialize role if passed from ChooseRolePage
  selectedRole = widget.preselectedRole?.toLowerCase() ?? '';
  }

  Future<void> register() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('api/admin/register'),
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
          const SnackBar(content: Text('Registered successfully! Please login.')),
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
          SnackBar(content: Text('${body['message'] ?? 'Registration failed'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server')),
      );
    }
  }

  Widget roleButton(String roleLabel) {
    final isSelected = selectedRole == roleLabel.toLowerCase();
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedRole = roleLabel.toLowerCase();
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
              roleLabel,
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 100),
            const Row(
              children: [
                Text(
                  'Welcome to ',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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

            // Role selection
            Row(
              children: [
                roleButton("ADMIN"),
                roleButton("OWNER"),
                roleButton("USER"),
              ],
            ),

            const SizedBox(height: 20),

            // Notification preference selection
            const Text(
              'Preferred way to receive updates:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                notifButton('Email'),
                notifButton('SMS'),
                notifButton('Both'),
              ],
            ),

            const SizedBox(height: 20),

            AbsorbPointer(
              absorbing: !isRoleSelected,
              child: Opacity(
                opacity: isRoleSelected ? 1.0 : 0.5,
                child: Column(
                  children: [
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A4423),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: isRoleSelected ? register : null,
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
                  ],
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
          ],
        ),
      ),
    );
  }
}
