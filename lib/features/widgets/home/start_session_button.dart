import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartSessionButton extends StatelessWidget {
  const StartSessionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => context.push('/session'),
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: const Text("Start a Session"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}