import 'package:flutter/material.dart';

class InfoRowWidget extends StatelessWidget {
  final String label;
  final String value;

  const InfoRowWidget({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                fontFamily: 'RobotoMono',
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
