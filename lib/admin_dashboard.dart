import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// NOTE: Assuming this file exists and contains the DashboardItem model and fetchUserMetrics() function
import 'user_data_service.dart';
// IMPORTANT: Importing the single source of truth for MenuState from the dedicated file
import 'menu_state.dart';

// --- Main Widget ---

class DashboardAdminScreen extends StatelessWidget {
  const DashboardAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF0F0F0), // Light gray background
      body: Row(
        children: [
          // 1. Sidebar/Navigation Menu
          Sidebar(),
          // 2. Main Content Area (Top Bar + Dashboard)
          Expanded(
            child: Column(
              children: [TopBar(), Expanded(child: MainDashboardContent())],
            ),
          ),
        ],
      ),
    );
  }
}

// 1. Sidebar Widget
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  final double expandedWidth = 250;
  final double collapsedWidth = 80;

  @override
  Widget build(BuildContext context) {
    // Consume the MenuState using Consumer. This now correctly uses the imported type.
    return Consumer<MenuState>(
      builder: (context, menuState, child) {
        final isExpanded = menuState.isMenuOpen; // Uses MenuState property
        final selectedIndex = menuState.selectedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Smooth transition
          width: isExpanded ? expandedWidth : collapsedWidth,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(15, 0, 0, 0),
                blurRadius: 10,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/App Title and Menu Button
              Padding(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  top: 20.0,
                  right: 10.0,
                  bottom: 20.0,
                ),
                child: Row(
                  mainAxisAlignment:
                      isExpanded
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                  children: [
                    if (isExpanded)
                      const Text(
                        'Iskort',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color.fromARGB(255, 171, 18, 18),
                        ),
                      ),
                    // Menu Icon Button
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.menu_open : Icons.menu,
                        color: Colors.grey.shade700,
                      ),
                      onPressed: menuState.toggleMenu, // Uses MenuState method
                      tooltip: isExpanded ? 'Collapse Menu' : 'Expand Menu',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),

              // Menu Items
              _buildMenuItem(
                context,
                Icons.dashboard,
                'Dashboard',
                0,
                selectedIndex,
                isExpanded,
                menuState.selectMenuItem,
              ),
              _buildMenuItem(
                context,
                Icons.group_outlined,
                'User Management',
                1,
                selectedIndex,
                isExpanded,
                menuState.selectMenuItem,
              ),
              _buildMenuItem(
                context,
                Icons.bar_chart_outlined,
                'Reports',
                2,
                selectedIndex,
                isExpanded,
                menuState.selectMenuItem,
              ),
              // Add more menu items here if needed
            ],
          ),
        );
      },
    );
  }

  // Helper method to build a clickable menu item
  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
    int selectedIndex,
    bool isExpanded,
    void Function(int) onSelected,
  ) {
    final isActive = index == selectedIndex;
    final horizontalPadding = isExpanded ? 10.0 : 0.0;
    final contentAlignment =
        isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 4.0,
      ),
      // Use InkWell for button functionality and visual ripple effect
      child: InkWell(
        onTap: () {
          onSelected(index);
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/user-management');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/reports');
          }
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          // Active state styling
          decoration: BoxDecoration(
            color:
                isActive
                    ? const Color.fromARGB(255, 177, 63, 63)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisAlignment: contentAlignment,
            children: [
              // Icon
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              // Text (only visible when expanded)
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade800,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// 2. Top Bar Widget
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Color(0xFFF7F7F7),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 10,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),

          // Admin User Info
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.grey,
                  size: 24,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueGrey,
                child: Text('T', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Four Admin',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'testfouradmin@gmail.com',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 3. Main Dashboard Content (Uses FutureBuilder)
class MainDashboardContent extends StatelessWidget {
  const MainDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard Header
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 25),

          // ⭐️ Dynamic Data Loading with FutureBuilder ⭐️
          FutureBuilder<List<DashboardItem>>(
            // Call the service function to fetch data
            future: UserDataService.fetchUserMetrics(),
            builder: (context, snapshot) {
              // 1. Show a loading spinner while data is being fetched
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // 2. Show error if the fetch failed
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading metrics: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              // 3. Display the grid if data is ready
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

              // 4. Fallback for no data
              return const Center(child: Text('No dashboard data available.'));
            },
          ),
        ],
      ),
    );
  }
}

// --- Dashboard Card Widget (UPDATED to use simplified data) ---

class DashboardCard extends StatelessWidget {
  final DashboardItem item;
  const DashboardCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              item.title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 10),

            // Value and Icon
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
                // Icon using the color from the data service
                Icon(item.icon, color: item.iconColor, size: 36),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
