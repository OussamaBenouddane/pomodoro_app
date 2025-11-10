import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/providers/shared_prefs_provider.dart';
import 'package:lockin_app/repositories/onboarding_repository.dart';

final onboardingRepoProvider = Provider<OnboardingRepository>((ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  return prefsAsync.when(
    data: (prefs) => OnboardingRepository(prefs),
    loading: () => throw Exception('SharedPreferences not ready yet'),
    error: (e, _) => throw Exception('Failed to load SharedPreferences'),
  );
});


class OnboardingController extends Notifier<int> {
  late final PageController pageController;
  late final OnboardingRepository repo;

  @override
  int build() {
    repo = ref.read(onboardingRepoProvider);
    pageController = PageController();
    return 0; // current page index
  }

  void nextPage() {
    final next = state + 1;
    pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    state = next;
  }

  void setPage(int index) => state = index;

  Future<void> completeOnboarding() async {
    await repo.setSeen();
  }
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, int>(
  OnboardingController.new,
);