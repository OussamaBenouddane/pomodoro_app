class OnboardingPageModel {
  final String title;
  final String description;
  final String image;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.image,
  });
}

final onboardingPages = [
  OnboardingPageModel(
    title: 'Stay Focused',
    description: 'Lock in on your goals with Pomodoro-style focus sessions.',
    image: 'assets/onboarding1.png',
  ),
  OnboardingPageModel(
    title: 'Track Progress',
    description: 'Visualize your focus time and improve every week.',
    image: 'assets/onboarding2.png',
  ),
  OnboardingPageModel(
    title: 'Build Habits',
    description: 'Turn consistency into results with daily streaks.',
    image: 'assets/onboarding3.png',
  ),
];
