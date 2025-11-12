import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

/// State provider to track onboarding completion
/// This provider is now the source of truth for onboarding status
final hasSeenOnboardingProvider = StateProvider<bool>((ref) {
  final repo = ref.watch(onboardingRepoProvider);
  return repo.hasSeenOnboarding;
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
    // Update the state provider to trigger router rebuild
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    // Force a small delay to ensure state propagates
    await Future.delayed(const Duration(milliseconds: 100));
  }

 
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, int>(
  OnboardingController.new,
);