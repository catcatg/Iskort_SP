import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iskort/reusables.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = '';

  bool get isRoleSelected => selectedRole.isNotEmpty;

  Future<void> login() async {
  try {
    final response = await http.post(
      Uri.parse('http://192.168.68.108:3000/api/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text,
        'password': passwordController.text,
        'role': selectedRole, // ✅ Include role
      }),
    );

    print('🔁 Response status: ${response.statusCode}');
    print('🧾 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      final user = responseJson['user'];
      final name = user['name'];

      Navigator.pushNamed(
        context,
        '/profile',
        arguments: {
          'name': name,
          'email': user['email'],
          'role': user['role'],
        },
      );
    } else {
      try {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${body['message'] ?? 'Login failed'}')),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected server error (HTML response)')),
        );
      }
    }
  } catch (e, stackTrace) {
    print('🔥 Error during login: $e');
    print('📍 Stack trace:\n$stackTrace');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network or backend error')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Login to Iskort',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Select your role:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                roleButton("ADMIN"),
                roleButton("OWNER"),
                roleButton("USER"),
              ],
            ),
            const SizedBox(height: 30),
            AbsorbPointer(
              absorbing: !isRoleSelected,
              child: Opacity(
                opacity: isRoleSelected ? 1.0 : 0.5,
                child: Column(
                  children: [
                    CustomTextField(
                      title: 'Email',
                      label: "Enter your email",
                      controller: emailController,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      title: 'Password',
                      label: "Enter your password",
                      isPassword: true,
                      controller: passwordController,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A4423),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: isRoleSelected ? login : null,
                        child: const Text(
                          'Login',
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
                onTap: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: const Text.rich(
                  TextSpan(
                    text: 'Don\'t have an account yet? ',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    children: [
                      TextSpan(
                        text: 'Sign up',
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
