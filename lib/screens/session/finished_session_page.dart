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

  Map<String, String> getMotivationalContent(int minutes) {
    if (minutes >= 60) {
      return {
        'title': 'Outstanding Focus! 🌟',
        'message':
            'Over an hour of deep work - you\'re building serious mental stamina!',
      };
    } else if (minutes >= 45) {
      return {
        'title': 'Excellent Session! 💪',
        'message':
            'You pushed through with impressive dedication. Keep this momentum!',
      };
    } else if (minutes >= 25) {
      return {
        'title': 'Great Work! 🚀',
        'message':
            'Solid focus session completed. Consistency is the key to mastery!',
      };
    } else if (minutes >= 10) {
      return {
        'title': 'Nice Start! ✨',
        'message': 'Every minute of focus counts. You\'re building the habit!',
      };
    } else {
      return {
        'title': 'Progress Made! 👍',
        'message': 'Even short sessions add up. Keep going!',
      };
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusDuration = Duration(seconds: int.tryParse(durationSeconds) ?? 0);
    final minutes = focusDuration.inMinutes;
    final content = getMotivationalContent(minutes);
    final formattedTime = formatDuration(focusDuration);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.7);
    final cardColor =
        Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.85 + (value * 0.15),
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green[400]!, Colors.green[600]!],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 72,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Title
                  Text(
                    content['title']!,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Time display card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Focus Time',
                          style: TextStyle(
                            fontSize: 14,
                            color: subtextColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: Colors.deepOrange[isDark ? 400 : 600],
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Motivational message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      content['message']!,
                      style: TextStyle(
                        fontSize: 16,
                        color: subtextColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatBadge(
                        context,
                        icon: Icons.timer_outlined,
                        label: 'Minutes',
                        value: minutes.toString(),
                      ),
                      const SizedBox(width: 20),
                      _buildStatBadge(
                        context,
                        icon: Icons.trending_up,
                        label: 'Streak',
                        value: '+1',
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Action button
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_outlined, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey[200]!;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.deepOrange, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: subtextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
