import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeControllerProvider = AsyncNotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

class HomeController extends AsyncNotifier<HomeState> {
  @override
  FutureOr<HomeState> build() async {
    // Simulated DB data
    await Future.delayed(const Duration(milliseconds: 300));
    return const HomeState(
      streakDays: 18,
      todayFocusMinutes: 240,
      dailyGoalMinutes: 300,
      nextReminder: 'Today at 8:00 PM',
    );
  }

  void updateGoal(int newGoal) {
    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current == null) return;

    state = AsyncData(current.copyWith(dailyGoalMinutes: newGoal));
  }

  void updateReminder(String newReminder) {
    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current == null) return;
    state = AsyncData(current.copyWith(nextReminder: newReminder));
  }
}

class HomeState {
  final int streakDays;
  final int todayFocusMinutes;
  final int dailyGoalMinutes;
  final String nextReminder;

  const HomeState({
    required this.streakDays,
    required this.todayFocusMinutes,
    required this.dailyGoalMinutes,
    required this.nextReminder,
  });

  HomeState copyWith({
    int? streakDays,
    int? todayFocusMinutes,
    int? dailyGoalMinutes,
    String? nextReminder,
  }) {
    return HomeState(
      streakDays: streakDays ?? this.streakDays,
      todayFocusMinutes: todayFocusMinutes ?? this.todayFocusMinutes,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      nextReminder: nextReminder ?? this.nextReminder,
    );
  }
}
