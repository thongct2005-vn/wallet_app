import 'dart:math' as math;
import 'package:flutter/material.dart';

class FireworkStarSpinner extends StatefulWidget {
  final double size;
  final Color color;
  final int starCount;

  const FireworkStarSpinner({
    super.key,
    this.size = 60,
    this.color = Colors.pink,
    this.starCount = 6,
  });

  @override
  State<FireworkStarSpinner> createState() => _FireworkStarSpinnerState();
}

class _FireworkStarSpinnerState extends State<FireworkStarSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0 -> 1
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(widget.starCount, (i) {
              final angle =
                  (2 * math.pi / widget.starCount) * i + (t * 2 * math.pi);

              // Hiệu ứng "nổ": bán kính co giãn theo chu kỳ
              final phase = (t + i / widget.starCount) % 1.0;
              final radius = widget.size / 2.6 * (0.4 + 0.6 * (0.5 - (phase - 0.5).abs()) * 2);
              final opacity = 0.3 + 0.7 * (0.5 - (phase - 0.5).abs()) * 2;
              final scale = 0.5 + 0.5 * (0.5 - (phase - 0.5).abs()) * 2;

              final dx = radius * math.cos(angle);
              final dy = radius * math.sin(angle);

              return Transform.translate(
                offset: Offset(dx, dy),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale.clamp(0.2, 1.0),
                    child: Icon(
                      Icons.star_rounded,
                      color: widget.color,
                      size: widget.size / 4,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}