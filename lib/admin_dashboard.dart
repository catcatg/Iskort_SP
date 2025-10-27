import 'package:flutter/material.dart';
import 'user_data_service.dart';
import '../layouts/admin_layout.dart';

// --- Main Widget ---

class DashboardAdminScreen extends StatelessWidget {
  const DashboardAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      pageTitle: "Dashboard",
      child: MainDashboardContent(),
    );
  }
}

// --- Dashboard Main Content ---

class MainDashboardContent extends StatelessWidget {
  const MainDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          /*
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          */
          const SizedBox(height: 25),

          // Dynamic Data
          FutureBuilder<List<DashboardItem>>(
            future: UserDataService.fetchUserMetrics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading metrics: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snapshot.hasData) {
                final dashboardData = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 20.0,
                    mainAxisSpacing: 20.0,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: dashboardData.length,
                  itemBuilder: (context, index) {
                    return DashboardCard(item: dashboardData[index]);
                  },
                );
              }

              return const Center(child: Text('No dashboard data available.'));
            },
          ),
        ],
      ),
    );
  }
}

// --- Dashboard Card Widget ---

class DashboardCard extends StatelessWidget {
  final DashboardItem item;
  const DashboardCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      color: const Color.fromARGB(255, 229, 58, 58),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(item.icon, color: item.iconColor, size: 36),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
