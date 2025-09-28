import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool isActive;

  const GlassCard({super.key, required this.child, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: GlassmorphicContainer(
        width: double.infinity,
        borderRadius: 16,
        blur: 20,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  Colors.lightBlue.withOpacity(0.3),
                  Colors.lightBlueAccent.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
          stops: const [0.1, 1],
        ),
        borderGradient: LinearGradient(
          colors: isActive
              ? [
                  Colors.blueAccent.withOpacity(0.6),
                  Colors.lightBlueAccent.withOpacity(0.2),
                ]
              : [
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.1),
                ],
        ),
        height: null,
        child: child,
      ),
    );
  }
}
