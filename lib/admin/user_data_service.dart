// lib/user_data_service.dart kf

import 'package:flutter/material.dart';

// 1. Simplified Model (DashboardItem)
class DashboardItem {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const DashboardItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });
}

// 2. Data Fetching Service
class UserDataService {
  // Simulate an asynchronous call (like fetching from an API or database)
  static Future<List<DashboardItem>> fetchUserMetrics() async {
    // A slight delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 500));

    // The dynamic data based on your ADMU app user segments
    final List<DashboardItem> metrics = [
      DashboardItem(
        title: 'Users Total',
        value: '5,000',
        icon: Icons.group,
        iconColor: Colors.blue.shade400,
      ),
      DashboardItem(
        title: 'Business Owners',
        value: '45',
        icon: Icons.store,
        iconColor: Colors.green.shade400,
      ),
      DashboardItem(
        title: 'Regular Users',
        value: '4,955',
        icon: Icons.person,
        iconColor: Colors.orange.shade400,
      ),
      DashboardItem(
        title: 'New Sign-ups (This Week)',
        value: '39',
        icon: Icons.person_add_alt_1,
        iconColor: Colors.purple.shade400,
      ),
    ];

    return metrics;
  }
}
