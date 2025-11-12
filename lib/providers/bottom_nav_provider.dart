import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class BottomNavController extends Notifier<int> {
  late BuildContext _context;

  @override
  int build() => 0; // default tab

  // Attach BuildContext once (in RootLayout)
  void attachContext(BuildContext context) {
    _context = context;
  }

  void onItemTapped(int index) {
    state = index;

    switch (index) {
      case 0:
        _context.go('/home');
        break;
      case 1:
        _context.go('/stats');
        break;
      case 2:
        _context.go('/profile');
        break;
      case 3:
        _context.go('/settings');
        break;
    }
  }
}

final bottomNavControllerProvider =
    NotifierProvider<BottomNavController, int>(BottomNavController.new);
