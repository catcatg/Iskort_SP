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

  String? nameError;
  String? emailError;
  String? phoneError;
  String? passwordError;
  String? confirmPasswordError;

  String selectedRole = '';
  String notifPreference = 'email';

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  bool isValidPassword(String password) {
    final passwordRegExp = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    return passwordRegExp.hasMatch(password);
  }

  bool isValidPhone(String phone) {
    final phoneRegExp = RegExp(r'^\d{11}$');
    return phoneRegExp.hasMatch(phone);
  }

  bool isValidUpmail(String email, String role) {
    final roleLower = role.toLowerCase();
    if (roleLower == 'user' || roleLower == 'student') {
      return email.toLowerCase().endsWith('@up.edu.ph');
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    selectedRole = widget.preselectedRole?.toLowerCase() ?? '';
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final phone = phoneController.text.trim();

    // Reset previous errors
    setState(() {
      nameError = null;
      emailError = null;
      phoneError = null;
      passwordError = null;
      confirmPasswordError = null;
    });

    // Validate fields
    setState(() {
      nameError = name.isEmpty ? 'Name is required' : null;
      emailError =
          email.isEmpty
              ? 'Email is required'
              : (!isValidUpmail(email, selectedRole)
                  ? 'Students must use their UP email'
                  : null);
      phoneError =
          !isValidPhone(phone)
              ? 'Enter a valid phone number (11 digits starting with 09)'
              : null;
      passwordError =
          !isValidPassword(password)
              ? 'Password must be 8+ chars, include uppercase, lowercase, and a number'
              : null;
      confirmPasswordError =
          password != confirmPassword ? 'Passwords do not match' : null;
    });

    // Stop if any errors exist
    if ([
      nameError,
      emailError,
      phoneError,
      passwordError,
      confirmPasswordError,
    ].any((e) => e != null))
      return;

    // Send registration request
    try {
      final response = await http.post(
        Uri.parse('https://iskort-public-web.onrender.com/api/admin/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone_num': phone,
          'role': selectedRole,
          'notif_preference': notifPreference,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        showFadingPopup(
          context,
          'Registered successfully! Please wait for admin verification. Your selected notification method will be used.',
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
            content: Text(
              '${body['message'] ?? body['error'] ?? 'Registration failed'}',
            ),
          ),
        );
      }
    } catch (e) {
      showFadingPopup(
        context,
        'Could not connect to the server. Please try again later.',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A4423),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Signing up as: ${selectedRole.isNotEmpty ? capitalize(selectedRole) : 'User'}",
                style: const TextStyle(fontSize: 16, color: Color(0xFFFBAC24)),
              ),
            ),
            const SizedBox(height: 20),

            // Form fields with error messages
            CustomTextField(
              title: 'Name',
              label: 'Enter your full name',
              controller: nameController,
              errorText: nameError,
              hintText: "e.g., Juan Dela Cruz",
            ),
            const SizedBox(height: 15),
            CustomTextField(
              title: 'Email',
              label: 'Enter your email',
              controller: emailController,
              errorText: emailError,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              title: 'Phone Number',
              label: 'Enter your phone number',
              controller: phoneController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              errorText: phoneError,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              title: 'Password',
              label: 'Enter your password',
              isPassword: true,
              controller: passwordController,
              errorText: passwordError,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              title: 'Confirm Password',
              label: 'Confirm your password',
              isPassword: true,
              controller: confirmPasswordController,
              errorText: confirmPasswordError,
            ),
            const SizedBox(height: 20),

            const Text(
              'Preferred way to get notifications:',
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
          ],
        ),
      ),
    );
  }
}
