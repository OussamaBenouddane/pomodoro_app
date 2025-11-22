import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/providers/bottom_nav_provider.dart';
import 'package:lockin_app/screens/home.dart';
import 'package:lockin_app/screens/settings.dart';
import 'package:lockin_app/screens/stats.dart';

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(bottomNavControllerProvider.notifier);
    controller.attachContext(context);
    final currentIndex = ref.watch(bottomNavControllerProvider);

    final pages = const [
      HomePage(),
      StatsDashboardScreen(),
      SettingsScreen(),
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
        type: BottomNavigationBarType.fixed, // Keep icons visible
        selectedItemColor: const Color(0xFF6A11CB), // Purple for selected
        unselectedItemColor: Colors.grey, // Grey for unselected
        backgroundColor: Colors.white, // White background
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}