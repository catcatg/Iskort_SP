import 'package:flutter/foundation.dart';

/// Manages the state for the sidebar (expanded/collapsed) and the selected menu item.
/// This file is separate to ensure a single, consistent type definition across the app.
class MenuState extends ChangeNotifier {
  bool _isMenuOpen = true; // Changed to 'true' default for dashboard visibility
  int _selectedIndex = 0; // 0: Dashboard, 1: User Management, etc.

  bool get isMenuOpen => _isMenuOpen;
  int get selectedIndex => _selectedIndex;

  /// Toggles the sidebar's expanded state.
  void toggleMenu() {
    _isMenuOpen = !_isMenuOpen;
    notifyListeners();
  }

  /// Sets the currently selected menu item index.
  void selectMenuItem(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
