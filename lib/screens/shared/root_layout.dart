import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/providers/bottom_nav_provider.dart';
import 'package:lockin_app/screens/home.dart';

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(bottomNavControllerProvider.notifier);
    controller.attachContext(context);
    final currentIndex = ref.watch(bottomNavControllerProvider);

    final pages = const [
      HomePage(),
      Placeholder(),
      Placeholder(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: controller.onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
