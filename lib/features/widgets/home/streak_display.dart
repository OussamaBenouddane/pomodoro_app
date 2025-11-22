import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/home_controller.dart';

class StreakDisplay extends ConsumerStatefulWidget {
  const StreakDisplay({super.key});

  @override
  ConsumerState<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends ConsumerState<StreakDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStreakColor(int streak) {
    if (streak >= 30) return Colors.purple;
    if (streak >= 21) return Colors.deepPurple;
    if (streak >= 14) return Colors.indigo;
    if (streak >= 7) return Colors.orange;
    if (streak >= 3) return Colors.deepOrange;
    return Colors.grey;
  }

  String _getStreakTitle(int streak) {
    if (streak >= 30) return "🔥 LEGENDARY";
    if (streak >= 21) return "🌟 CHAMPION";
    if (streak >= 14) return "💪 WARRIOR";
    if (streak >= 7) return "🚀 ON FIRE";
    if (streak >= 3) return "⚡ HEATING UP";
    if (streak >= 1) return "✨ STARTED";
    return "💤 INACTIVE";
  }

  IconData _getStreakIcon(int streak) {
    if (streak >= 30) return Icons.emoji_events;
    if (streak >= 14) return Icons.whatshot;
    if (streak >= 7) return Icons.local_fire_department;
    if (streak >= 3) return Icons.trending_up;
    return Icons.flag_outlined;
  }

  List<Color> _getGradientColors(int streak) {
    final baseColor = _getStreakColor(streak);
    return [
      baseColor,
      baseColor.withValues(alpha: 0.6),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref
        .watch(homeControllerProvider)
        .maybeWhen(data: (data) => data, orElse: () => null);

    final streak = state?.streakDays ?? 0;
    final streakColor = _getStreakColor(streak);
    final streakTitle = _getStreakTitle(streak);
    final streakIcon = _getStreakIcon(streak);
    final gradientColors = _getGradientColors(streak);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors[0].withValues(alpha: 0.15),
              gradientColors[1].withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            children: [
              // Animated flame icon
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: streak >= 3 ? _scaleAnimation.value : 1.0,
                    child: Transform.rotate(
                      angle: streak >= 3 ? _rotationAnimation.value : 0.0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: streakColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          streakIcon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              // Streak info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "$streak",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: streakColor,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          streak == 1 ? "day" : "days",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      streakTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: streakColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Milestone indicator
              if (streak > 0)
                Column(
                  children: [
                    _buildMilestoneIndicator(streak),
                    const SizedBox(height: 4),
                    Text(
                      _getNextMilestone(streak),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneIndicator(int streak) {
    final milestones = [3, 7, 14, 21, 30];
    final nextMilestone = milestones.firstWhere(
      (m) => m > streak,
      orElse: () => 30,
    );
    final previousMilestone = milestones.lastWhere(
      (m) => m <= streak,
      orElse: () => 0,
    );

    final progress = previousMilestone == 30
        ? 1.0
        : (streak - previousMilestone) / (nextMilestone - previousMilestone);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getStreakColor(streak),
            ),
          ),
        ),
        Text(
          "${(progress * 100).toInt()}%",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _getStreakColor(streak),
          ),
        ),
      ],
    );
  }

  String _getNextMilestone(int streak) {
    final milestones = [3, 7, 14, 21, 30];
    final next = milestones.firstWhere(
      (m) => m > streak,
      orElse: () => 30,
    );
    
    if (streak >= 30) return "Max level!";
    
    final daysLeft = next - streak;
    return "$daysLeft days to $next in a row";
  }
}