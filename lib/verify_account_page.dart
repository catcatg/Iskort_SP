import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VerifyAccountPage extends StatefulWidget {
  final String token;
  const VerifyAccountPage({Key? key, required this.token}) : super(key: key);

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  String message = '';
  bool loading = false;

  Future<void> verify() async {
    setState(() => loading = true);

    final resp = await http.get(
      Uri.parse('https://iskort-public-web.onrender.com/api/admin/verify-email/${widget.token}'),
    );

    setState(() {
      loading = false;
      if (resp.statusCode == 200) {
        message = 'Your account has been verified! Redirecting to login...';

        // ✅ Navigate to login automatically after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        message = 'Verification failed: ${resp.body}';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // ✅ Trigger verification immediately when page loads
    verify();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify My Account')),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Text(message),
      ),
    );
  }
}