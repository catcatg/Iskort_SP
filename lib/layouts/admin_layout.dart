import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/topbar.dart';

class AdminLayout extends StatelessWidget {
  final String pageTitle;
  final Widget child;
  final Function(String)? onSearchChanged;

  const AdminLayout({
    Key? key,
    required this.pageTitle,
    required this.child,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                TopBar(pageTitle: pageTitle, onSearchChanged: onSearchChanged),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
