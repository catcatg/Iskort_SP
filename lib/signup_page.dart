import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:iskort/widgets/reusables.dart';
import 'verify_account_page.dart';

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

  bool loading = false;

  String? nameError;
  String? emailError;
  String? phoneError;
  String? passwordError;
  String? confirmPasswordError;

  String selectedRole = '';
  String notifPreference = 'email';

  String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  bool isValidPassword(String password) =>
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(password);

  bool isValidPhone(String phone) =>
      RegExp(r'^\d{11}$').hasMatch(phone);

  bool isValidUpmail(String email, String role) =>
      role.toLowerCase() != 'user' ||
      email.toLowerCase().endsWith('@up.edu.ph');

  bool isUserRole() => selectedRole.toLowerCase() == 'user';

  @override
  void initState() {
    super.initState();
    selectedRole = widget.preselectedRole?.toLowerCase() ?? 'user';
    if (isUserRole()) notifPreference = 'email';
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final phone = phoneController.text.trim();

    setState(() {
      nameError = name.isEmpty ? 'Name is required' : null;
      emailError = email.isEmpty
          ? 'Email is required'
          : (!isValidUpmail(email, selectedRole)
              ? 'Students must use their UP email'
              : null);
      phoneError = !isValidPhone(phone)
          ? 'Enter a valid phone number (11 digits)'
          : null;
      passwordError = !isValidPassword(password)
          ? 'Password must be 8+ chars, include uppercase, lowercase, and a number'
          : null;
      confirmPasswordError =
          password != confirmPassword ? 'Passwords do not match' : null;
    });

    if ([nameError, emailError, phoneError, passwordError, confirmPasswordError]
        .any((e) => e != null)) return;

    const endpoint =
        'https://iskort-public-web.onrender.com/api/admin/register';

    try {
    setState(() => loading = true);

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone_num': phone,
        'role': isUserRole() ? 'user' : 'owner',
        'notif_preference': notifPreference.toLowerCase(),
      }),
    );

    setState(() => loading = false);

    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body);
    } catch (_) {}

    print('STATUS CODE: ${response.statusCode}');
    print('RAW BODY: ${response.body}');

    if (response.statusCode != 200) {
      showFadingPopup(
        context,
        body['message'] ?? response.body,
      );
      return;
    }

    final flow = body['flow'];

    if (flow == 'email_verification') {
      showFadingPopup(
        context,
        'Registration successful! Please check your email to verify your account.',
      );

      Navigator.pushReplacementNamed(context, '/login');
    } else if (flow == 'admin_approval') {
      showFadingPopup(
        context,
        'Registration submitted. Waiting for admin approval.',
      );

      Navigator.pushReplacementNamed(context, '/login');
    } else {
      showFadingPopup(context, 'Registration successful.');
    }

  } catch (e) {
    setState(() => loading = false);
    showFadingPopup(
      context,
      'Could not connect to server.',
    );
  }
  }


  Widget notifButton(String label) {
    final isSelected = notifPreference == label.toLowerCase();
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => notifPreference = label.toLowerCase()),
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
                color:
                    isSelected ? const Color(0xFFFBAC24) : Colors.black,
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const SizedBox(height: 100),
                const Row(
                  children: [
                    Text('Welcome to ',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    Text('Iskort',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF791317))),
                  ],
                ),
                const Text("Let's get started!",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),

                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A4423),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Signing up as: ${capitalize(selectedRole)}",
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFFFBAC24)),
                  ),
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  title: 'Name',
                  label: 'Enter your full name',
                  controller: nameController,
                  errorText: nameError,
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
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                if (!isUserRole())
                  Row(
                    children: [
                      notifButton('Email'),
                      notifButton('SMS'),
                      notifButton('Both'),
                    ],
                  )
                else
                  const Text(
                    'Email only (UP accounts require email verification)',
                    style: TextStyle(color: Colors.grey),
                  ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A4423),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                        color: Color(0xFFFBAC24),
                        fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/login'),
                    child: const Text(
                      'Already have an account? Login here',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
