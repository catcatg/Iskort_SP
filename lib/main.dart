import 'package:iskort/admin/user_manage.dart';
import 'package:iskort/owner/setup_details.dart';
import 'package:iskort/widgets/menu_state.dart';
import 'package:provider/provider.dart'; // <-- 1. Added Provider Import
import 'package:flutter/material.dart';
import 'package:iskort/homepage.dart';
import 'package:iskort/page_routes/food.dart';
import 'package:iskort/page_routes/housing.dart';
import 'package:iskort/page_routes/map_route.dart';
//import 'package:iskort/page_routes/user_reviews.dart'; // i deleted this since it returns an error. i saved the copy tho for later
//import 'package:iskort/page_routes/saved_locations.dart';
import 'package:iskort/page_routes/profile_settings.dart';
import 'package:iskort/profile.dart';
import 'package:iskort/select_role.dart';

import 'landing_page.dart';
import 'login_page.dart';
//import 'signup_page.dart';
import 'admin/admin_dashboard.dart';
import 'owner/setup_eatery_page.dart';
import 'package:iskort/page_routes/edit_establishments.dart';

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
        '/select_role': (context) => ChooseRolePage(),
        '/homepage': (context) => HomePage(),
        '/profile': (context) => const UserProfilePage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/user-management': (context) => const UserManage(),
        '/food': (context) => const FoodPage(),
        '/housing': (context) => const HousingPage(),
        '/route': (context) => const MapRoutePage(),
        '/setup-details': (context) => const SetupDetailsPage(),
        //'/user-reviews': (context) => const YourReviews(),
        '/profile_settings': (context) => const ProfileSettingsPage(),
        '/setup-eatery-page': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return SetupEateryPage(currentUser: args);
        },
        '/edit-establishments': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return EditEstablishmentsPage(business: args);
        },
      },
    );
  }
}
