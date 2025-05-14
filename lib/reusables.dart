import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String title;
  final String label;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.title,
    required this.label,
    this.isPassword = false,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 5),
        TextField(
          obscureText: _obscureText,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: widget.label,
            suffixIcon:
                widget.isPassword
                    ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                    : null,
          ),
        ),
      ],
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Color(0xFF791317),
      unselectedItemColor: Colors.brown.shade200,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.location_on), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String location;
  final String imagePath;

  const ProductCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            /// Image (always fixed size)
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade300,
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      color: Colors.red,
                      size: 40,
                    ),
              ),
            ),

            const SizedBox(width: 12),

            /// Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(subtitle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Flexible(child: Text(location)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
