import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartSessionButton extends StatelessWidget {
  const StartSessionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => context.push('/session'),
        icon: const Icon(Icons.play_arrow_rounded, size: 34),
        label: const Text("Start a Session"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrangeAccent,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: Colors.deepOrangeAccent.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
