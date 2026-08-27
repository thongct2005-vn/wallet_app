import 'package:flutter/material.dart';

class CircleBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const CircleBackButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_back,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 30,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.8),
      ),
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}