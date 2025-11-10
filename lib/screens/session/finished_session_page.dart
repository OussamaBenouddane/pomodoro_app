import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SessionSummaryPage extends ConsumerWidget {
  final String durationSeconds;

  const SessionSummaryPage({super.key, required this.durationSeconds});

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String getMotivationalPhrase() {
    const phrases = [
      "Great job staying focused! 🌟",
      "Every minute counts — keep it up! 💪",
      "Focus like this builds habits that last! 🚀",
      "Your brain thanks you for this session! 🧠",
      "Consistency beats intensity every time! ✨",
    ];
    final random = Random();
    return phrases[random.nextInt(phrases.length)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusDuration = Duration(seconds: int.tryParse(durationSeconds) ?? 0);
    final phrase = getMotivationalPhrase();
    final formattedTime = formatDuration(focusDuration);

    return Scaffold(
      backgroundColor: Colors.deepOrangeAccent.withOpacity(0.08),
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 80,
                color: Colors.deepOrangeAccent,
              ),
              const SizedBox(height: 24),
              Text(
                "Focus Session Complete!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrangeAccent.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Total Focus Time: $formattedTime",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepOrangeAccent.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                phrase,
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Go to Home",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}