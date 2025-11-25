import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockin_app/providers/session_timer_provider.dart';

class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key});

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  final TextEditingController _titleController = TextEditingController();
  String selectedCategory = 'Study';
  String selectedDuration = '25-5';

  final Map<String, IconData> categories = {
    'Study': Icons.school_outlined,
    'Work': Icons.work_outline,
    'Exercise': Icons.fitness_center_outlined,
    'Meditation': Icons.self_improvement_outlined,
    'Reading': Icons.menu_book_outlined,
    'Creative': Icons.palette_outlined,
  };

  final Map<String, String> durations = {
    '25-5': '25 min focus',
    '30-10': '30 min focus',
    '60-15': '60 min focus',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.6);
    final cardColor =
        Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey[300]!;
    final hintColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Setup Focus Session"),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              context,
              "What are you focusing on?",
              Icons.label_outline,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 16, color: textColor),
              decoration: InputDecoration(
                hintText: "e.g., Math homework, Project work...",
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.deepOrange,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.deepOrange,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(context, "Category", Icons.category_outlined),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.entries.map((entry) {
                final isSelected = selectedCategory == entry.key;
                return InkWell(
                  onTap: () => setState(() => selectedCategory = entry.key),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepOrange : cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.deepOrange : borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected && !isDark
                          ? [
                              BoxShadow(
                                color: Colors.deepOrange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.value,
                          color: isSelected ? Colors.white : subtextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(context, "Focus Duration", Icons.timer_outlined),
            const SizedBox(height: 16),
            ...durations.entries.map((entry) {
              final isSelected = selectedDuration == entry.key;
              final parts = entry.key.split('-');
              final breakMin = parts[1];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => setState(() => selectedDuration = entry.key),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepOrange.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            )
                          : cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.deepOrange : borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepOrange
                                : (isDark
                                      ? const Color(0xFF374151)
                                      : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.schedule,
                            color: isSelected ? Colors.white : subtextColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.deepOrange
                                      : textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$breakMin min break",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.deepOrange,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  final parts = selectedDuration.split('-');
                  final focusMinutes = int.parse(parts[0]);
                  final breakMinutes = int.parse(parts[1]);

                  ref
                      .read(sessionTimerProvider.notifier)
                      .initializeTimer(
                        title: _titleController.text.isNotEmpty
                            ? _titleController.text
                            : 'Focus Session',
                        category: selectedCategory,
                        focusMinutes: focusMinutes,
                        breakMinutes: breakMinutes,
                      );

                  context.push('/focus');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Begin Focus Session',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Extra padding for phone's bottom navigation/gesture bar
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.deepOrange),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
