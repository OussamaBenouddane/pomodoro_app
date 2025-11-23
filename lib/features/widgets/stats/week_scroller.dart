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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final accentColor = isDark ? Colors.blue[300] : Colors.blue[600];
    final accentBackground = isDark 
        ? Colors.blue[900]!.withValues(alpha: 0.3) 
        : Colors.blue.shade50;

    final weekEnd = selectedWeekStart!.add(const Duration(days: 6));
    final weekLabel =
        "${DateFormat('MMM d').format(selectedWeekStart!)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}";

    return Card(
      elevation: isDark ? 0 : 2,
      color: accentBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark 
            ? BorderSide(color: Colors.blue[800]!.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 18,
                color: isLoading ? subtextColor : accentColor,
              ),
              onPressed: isLoading ? null : () => onWeekChange(false),
            ),
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        accentColor ?? Colors.blue,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Text(
                        "Selected Week",
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                      Text(
                        weekLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
            IconButton(
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: isLoading ? subtextColor : accentColor,
              ),
              onPressed: isLoading ? null : () => onWeekChange(true),
            ),
          ],
        ),
      ),
    );
  }
}