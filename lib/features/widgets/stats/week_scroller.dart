import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekScroller extends StatelessWidget {
  final DateTime? selectedWeekStart;
  final bool isLoading;
  final Function(bool forward) onWeekChange;

  const WeekScroller({
    super.key,
    required this.selectedWeekStart,
    required this.isLoading,
    required this.onWeekChange,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedWeekStart == null) {
      return const SizedBox.shrink();
    }

    final weekEnd = selectedWeekStart!.add(const Duration(days: 6));
    final weekLabel =
        "${DateFormat('MMM d').format(selectedWeekStart!)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}";

    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: isLoading ? null : () => onWeekChange(false),
            ),
            isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Column(
                    children: [
                      const Text(
                        "Selected Week",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        weekLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
              onPressed: isLoading ? null : () => onWeekChange(true),
            ),
          ],
        ),
      ),
    );
  }
}