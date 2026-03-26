import 'package:flutter/material.dart';

class RiskBar extends StatelessWidget {
  final double skor;

  const RiskBar({super.key, required this.skor});

  Color getColor() {
    if (skor > 70) return Colors.red;
    if (skor > 40) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Risk Analizi",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              "%${skor.toStringAsFixed(1)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: getColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: skor / 100,
            minHeight: 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(getColor()),
          ),
        ),
      ],
    );
  }
}