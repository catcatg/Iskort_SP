import 'package:provider/provider.dart'; // <-- 1. Added Provider Import
import 'package:iskort/menu_state.dart'; // state
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
import 'setup_eatery_page.dart';
import 'user_manage.dart';

void main() {
  // Wrapping MyApp with the Provider to make MenuState available globally
  runApp(
    ChangeNotifierProvider(
      // The 'create' method instantiates the state object from the imported file.
      create: (context) => MenuState(),
      child: const MyApp(),
    ),
  );
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
        '/admin-dashboard': (context) => const DashboardAdminScreen(),
        '/user-management': (context) => const UserManage(),
        '/food': (context) => const FoodPage(),
        '/housing': (context) => const HousingPage(),
        '/route': (context) => const MapRoutePage(),
        '/setup-page': (context) => const SetupEateryPage(),
      },
    );
  }
}
