import 'package:flutter/material.dart';

class MonthSelector extends StatelessWidget {
  final String monthLabel;
  final Function(bool forward) onMonthChange;

  const MonthSelector({
    super.key,
    required this.monthLabel,
    required this.onMonthChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onMonthChange(false),
            ),
            Text(
              monthLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => onMonthChange(true),
            ),
          ],
        ),
      ),
    );
  }
}