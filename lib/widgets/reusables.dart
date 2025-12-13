import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String title;
  final String label;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType; // optional
  final List<TextInputFormatter>? inputFormatters; // optional
  final String? errorText;
  final String? hintText;

  const CustomTextField({
    super.key,
    required this.title,
    required this.label,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.hintText,
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,

          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: widget.label,
            errorText: widget.errorText,
            hintText: widget.hintText,
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
    return Padding(
      padding: EdgeInsets.all(8),
      child: BottomNavigationBar(
        mouseCursor: SystemMouseCursors.click,
        backgroundColor: const Color(0xFF791317),
        currentIndex: currentIndex,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        unselectedItemColor: Colors.brown.shade200,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Homepage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final String location;
  final String imagePath;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.title,
    required this.location,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Make location text wrap instead of overflowing
                  Text(
                    location,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    softWrap: true,
                    overflow: TextOverflow.visible,
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

class DisplayCard extends StatelessWidget {
  final Map<String, String> food;
  final VoidCallback onTap;

  const DisplayCard({super.key, required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7A1E1E)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  food["image"]!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                food["name"]!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                food["restaurant"]!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                food["location"]!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                food["distance"] ?? "Unknown distance",
                style: TextStyle(fontSize: 12, color: Colors.blueGrey[700]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                food["priceRange"]!,
                style: const TextStyle(
                  color: Color(0xFF7A1E1E),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showFadingPopup(BuildContext context, String message) {
  OverlayEntry? entry;

  entry = OverlayEntry(
    builder: (context) {
      return Center(
        child: ConstrainedBox(
          child: _FadingMessage(
            message: message,
            onFinish: () {
              entry?.remove();
            },
          ),
          constraints: const BoxConstraints(maxWidth: 300),
        ),
      );
    },
  );

  Overlay.of(context).insert(entry);
}

class _FadingMessage extends StatefulWidget {
  final String message;
  final VoidCallback onFinish;

  const _FadingMessage({required this.message, required this.onFinish});

  @override
  State<_FadingMessage> createState() => _FadingMessageState();
}

class _FadingMessageState extends State<_FadingMessage> {
  double opacity = 0;

  @override
  void initState() {
    super.initState();

    // Fade in
    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() => opacity = 1);
    });

    // Stay for 2 seconds then fade out
    Future.delayed(const Duration(seconds: 5), () {
      setState(() => opacity = 0);
    });

    // Remove overlay after fade out
    Future.delayed(const Duration(milliseconds: 2800), widget.onFinish);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: opacity,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Color.fromARGB(229, 11, 85, 43),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          child: Text(
            widget.message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

Future<void> showTemporaryPopup(BuildContext context, String message) async {
  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false, // prevents manual dismissal
    builder:
        (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF0A4423)),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
  );

  // Auto close after 3 seconds
  await Future.delayed(const Duration(seconds: 3));
  if (Navigator.canPop(context)) Navigator.pop(context);
}
