import 'package:flutter/material.dart';
import '../models/location.dart';

class CustomMapMarker extends StatelessWidget {
  final Location location;
  final VoidCallback onTap;

  const CustomMapMarker({
    super.key,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor();
    final size = location.isVerified ? 40.0 : 32.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: location.isVerified
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Icon(
          _getCategoryIcon(),
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (location.category) {
      case Category.vegan:
        return const Color(0xFF4CAF50);
      case Category.healthcare:
        return const Color(0xFF2196F3);
      case Category.general:
        return const Color(0xFFFF9800);
    }
  }

  IconData _getCategoryIcon() {
    switch (location.category) {
      case Category.vegan:
        return Icons.eco;
      case Category.healthcare:
        return Icons.local_hospital;
      case Category.general:
        return Icons.place;
    }
  }
}
