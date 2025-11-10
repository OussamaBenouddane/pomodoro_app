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

  final List<String> categories = [
    'Study',
    'Work',
    'Exercise',
    'Meditation',
    'Reading',
  ];
  final List<String> durations = ['1-1', '25-5', '30-10', '60-15'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Session"),
        centerTitle: true,
        backgroundColor: Colors.deepOrangeAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Category",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: Colors.deepOrangeAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (_) => setState(() => selectedCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const Text(
              "Duration",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: durations.map((d) {
                final isSelected = selectedDuration == d;
                return ChoiceChip(
                  label: Text(d),
                  selected: isSelected,
                  selectedColor: Colors.deepOrangeAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (_) => setState(() => selectedDuration = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const Text(
              "Session Title",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "What will you focus on?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final parts = selectedDuration.split('-');
                  final focusMinutes = int.parse(parts[0]);
                  final breakMinutes = int.parse(parts[1]);

                  ref.read(sessionTimerProvider.notifier).initializeTimer(
                        title: _titleController.text.isNotEmpty
                            ? _titleController.text
                            : 'Focus Session',
                        category: selectedCategory,
                        focusMinutes: focusMinutes,
                        breakMinutes: breakMinutes,
                      );

                  context.push('/focus');
                },
                child: const Text('Start Session', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
