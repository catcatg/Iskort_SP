import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iskort/widgets/reusables.dart';
import 'owner/setup_eatery_page.dart';
import 'owner/owner_homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? emailError;
  String? passwordError;

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://iskort-public-web.onrender.com/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Map<String, dynamic> user = data['user'];
        final role = user['role'];

        // 🔹 If role is owner, fetch owner_id from /api/owner
        if (role == 'owner') {
          final ownerResp = await http.get(
            Uri.parse('https://iskort-public-web.onrender.com/api/owner'),
          );
          final ownerData = jsonDecode(ownerResp.body);

          if (ownerData['success'] == true) {
            final owners = List<Map<String, dynamic>>.from(ownerData['owners']);
            print("DEBUG owners list: $owners"); // see what comes back

            final match = owners.firstWhere(
              (o) =>
                  o['email'].toString().trim().toLowerCase() ==
                  user['email'].toString().trim().toLowerCase(),
              orElse: () => {},
            );

            print("DEBUG matched owner: $match");

            if (match.isNotEmpty) {
              user['owner_id'] = match['id']; // attach owner_id
              print("DEBUG attached owner_id: ${user['owner_id']}");
            } else {
              print("DEBUG no matching owner found for email ${user['email']}");
            }
          }

          // 2. Check if owner already has an eatery/housing
          final businessResp = await http.get(
            Uri.parse(
              'https://iskort-public-web.onrender.com/api/eatery?owner_id=${user['owner_id']}',
            ),
          );

          final businessData = jsonDecode(businessResp.body);

          final bool hasBusiness = (businessData['eateries'] ?? []).isNotEmpty;

          // 3. Route based on business status
          if (!hasBusiness) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SetupEateryPage(currentUser: user),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OwnerHomePage(currentUser: user),
              ),
            );
          }
        } else if (role == 'admin') {
          Navigator.pushNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushNamed(context, '/homepage', arguments: user);
        }
      } else if (response.statusCode == 403) {
        showFadingPopup(context, "Account not yet verified by admin.");
      } else if (response.statusCode == 404) {
        showFadingPopup(context, "Account not registered");
      } else if (response.statusCode == 401) {
        showFadingPopup(
          context,
          "Invalid login credentials. Check your email and password.",
        );
      } else {
        showFadingPopup(context, "Login failed: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showFadingPopup(context, "Network or server error: $e");
    }
  }

  void validateFields() {
    setState(() {
      emailError = emailController.text.isEmpty ? 'Email is required' : null;

      passwordError =
          passwordController.text.isEmpty ? 'Password is required' : null;
    });
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
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.02),

                  Text(
                    "Welcome Back!",
                    style: const TextStyle(
                      color: Color(0xFF0A4423),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: const [
                      Text(
                        'Login to ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Iskort',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF791317),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 25),

                  CustomTextField(
                    title: 'Email',
                    label: "Enter your email",
                    controller: emailController,
                    errorText: emailError,
                  ),
                  const SizedBox(height: 15),

                  CustomTextField(
                    title: 'Password',
                    label: "Enter your password",
                    isPassword: true,
                    controller: passwordController,
                    errorText: passwordError,
                    onFieldSubmitted: (_) {
                      if (emailController.text.isNotEmpty &&
                          passwordController.text.isNotEmpty &&
                          !isLoading) {
                        validateFields();
                        if (emailError == null && passwordError == null) {
                          login();
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 25),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Color(0xFF791317),

                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A4423),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed:
                          isLoading
                              ? null
                              : () {
                                validateFields();

                                if (emailError == null &&
                                    passwordError == null) {
                                  login();
                                }
                              },

                      child:
                          isLoading
                              ? const CircularProgressIndicator(
                                color: Color(0xFFFBAC24),
                              )
                              : const Text(
                                'Login',
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
                      onTap: () => Navigator.pushNamed(context, '/select_role'),
                      child: const Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
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
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  bool isLoading = false;

  Future<void> sendReset() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showFadingPopup(context, "Please enter your email");
      return; // Stop execution if email is empty
    }

    setState(() => isLoading = true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Here you would normally call your password reset API
      showFadingPopup(context, "A password reset has been sent to your email.");
    } catch (e) {
      // Handle any errors
      showFadingPopup(context, "Something went wrong. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Enter your email to reset your password.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A4423),
                foregroundColor: const Color(0xFFFBAC24),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: isLoading ? null : sendReset,
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFBAC24),
                        ),
                      )
                      : const Text("Send Reset Link"),
            ),
          ],
        ),
      ),
    );
  }
}
