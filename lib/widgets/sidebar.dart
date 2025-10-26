import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../menu_state.dart';

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
