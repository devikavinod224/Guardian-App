import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  final List<Bubble> _bubbles = [];
  final Random _random = Random();
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Static/Gradient Background (White/Light)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF), // White
                Color(0xFFF0F4F8), // Very Light Blue/Grey
              ],
            ),
          ),
        ),

        // 2. Animated Bubbles
        LayoutBuilder(
          builder: (context, constraints) {
            if (_bubbles.isEmpty) {
              for (int i = 0; i < 20; i++) {
                _bubbles.add(
                  _generateBubble(constraints.maxWidth, constraints.maxHeight),
                );
              }
            }

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  children: _bubbles.map((bubble) {
                    // Update bubble position
                    bubble.position = Offset(
                      bubble.position.dx,
                      bubble.position.dy - bubble.speed,
                    );

                    // Reset if goes off top
                    if (bubble.position.dy + bubble.size < 0) {
                      bubble.position = Offset(
                        _random.nextDouble() * constraints.maxWidth,
                        constraints.maxHeight + bubble.size,
                      );
                    }

                    return Positioned(
                      left: bubble.position.dx,
                      top: bubble.position.dy,
                      child: Container(
                        width: bubble.size,
                        height: bubble.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bubble.color,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),

        // 3. Child Content
        widget.child,
      ],
    );
  }

  Bubble _generateBubble(double maxWidth, double maxHeight) {
    return Bubble(
      position: Offset(
        _random.nextDouble() * maxWidth,
        _random.nextDouble() * maxHeight + maxHeight, // Start below or random
      ),
      size: _random.nextDouble() * 30 + 10,
      speed: _random.nextDouble() * 1.0 + 0.2, // Slower speed
      color: Colors.blue.withValues(
        alpha: 0.05 + _random.nextDouble() * 0.05,
      ), // Varying subtle opacity
    );
  }
}

class Bubble {
  Offset position;
  final double size;
  final double speed;
  final Color color;

  Bubble({
    required this.position,
    required this.size,
    required this.speed,
    required this.color,
  });
}
