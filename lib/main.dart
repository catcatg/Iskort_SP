import 'package:flutter/material.dart';
import 'package:iskort/homepage.dart';
import 'package:iskort/page_routes/food.dart';
import 'package:iskort/page_routes/housing.dart';
import 'package:iskort/page_routes/map_route.dart';
import 'package:iskort/profile.dart';

import 'landing_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'admin_dashboard.dart';
import 'admin_dashboard.dart'; 
import 'setup_eatery_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Iskort App',
      theme: ThemeData(primarySwatch: Colors.red),
      initialRoute: '/',
      routes: {
        '/': (context) => LandingPage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/homepage': (context) => HomePage(),
        '/profile': (context) => const UserProfilePage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/food': (context) => const FoodPage(),
        '/housing': (context) => const HousingPage(),
        '/route': (context) => const MapRoutePage(),
        '/setup-page': (context) => const SetupPage(),
      },
    );
  }
}
