import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockin_app/model/session_timer_model.dart';
import 'package:lockin_app/providers/session_timer_provider.dart';

class FocusPage extends ConsumerWidget {
  const FocusPage({super.key});

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color _getPhaseColor(SessionPhase phase, bool isDark) {
    if (phase == SessionPhase.focusing) {
      return isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1);
    } else {
      return isDark ? const Color(0xFF22D3EE) : const Color(0xFF06B6D4);
    }
  }

  String _getPhaseTitle(SessionPhase phase) {
    switch (phase) {
      case SessionPhase.focusing:
        return 'Focus Time';
      case SessionPhase.onBreak:
        return 'Break Time';
      default:
        return 'Session';
    }
  }

  String _getPhaseSubtitle(SessionPhase phase) {
    switch (phase) {
      case SessionPhase.focusing:
        return 'Stay focused and block out distractions';
      case SessionPhase.onBreak:
        return 'Relax and recharge for the next session';
      default:
        return '';
    }
  }

  IconData _getPhaseIcon(SessionPhase phase) {
    return phase == SessionPhase.focusing
        ? Icons.psychology_outlined
        : Icons.coffee_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sessionTimerProvider);
    final timer = ref.read(sessionTimerProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getPhaseColor(timerState.phase, isDark);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final subtextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.6);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(_getPhaseTitle(timerState.phase)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (timerState.phase != SessionPhase.idle &&
              timerState.phase != SessionPhase.finished)
            IconButton(
              icon: const Icon(Icons.close),
              color: subtextColor,
              onPressed: () => _showStopConfirmation(context, ref),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildPhaseContent(context, ref, timerState, timer, color),
      ),
    );
  }

  Widget _buildPhaseContent(
    BuildContext context,
    WidgetRef ref,
    SessionTimerState state,
    SessionTimerNotifier timer,
    Color color,
  ) {
    if (state.phase == SessionPhase.finished) {
      return _buildFinishedContent(context, ref, state, timer);
    }

    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.6);

    return Center(
      key: ValueKey(state.phase),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getPhaseIcon(state.phase), size: 48, color: color),
            ),
            const SizedBox(height: 40),
            _buildModernTimerDisplay(context, state, color),
            const SizedBox(height: 32),
            Text(
              state.title ?? 'Focus Session',
              style: TextStyle(
                fontSize: 22,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getPhaseSubtitle(state.phase),
              style: TextStyle(fontSize: 15, color: subtextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildControlButtons(context, ref, state, timer, color),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTimerDisplay(
    BuildContext context,
    SessionTimerState state,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey[200]!;
    final circleBackground = isDark
        ? const Color(0xFF1F2937)
        : Colors.grey[50]!;

    final isFocus = state.phase == SessionPhase.focusing;
    final totalDuration = isFocus
        ? state.focusDuration.inSeconds
        : state.breakDuration.inSeconds;
    final progress = totalDuration > 0
        ? state.remaining.inSeconds / totalDuration
        : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleBackground,
            border: Border.all(color: borderColor, width: 2),
          ),
        ),
        SizedBox(
          width: 240,
          height: 240,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(state.remaining),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w300,
                color: textColor,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            if (state.isPaused)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[isDark ? 900 : 50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange[isDark ? 700 : 200]!),
                ),
                child: Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[isDark ? 300 : 700],
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    WidgetRef ref,
    SessionTimerState state,
    SessionTimerNotifier timer,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonBg = isDark ? const Color(0xFF1F2937) : Colors.grey[50]!;
    final buttonBorder = isDark ? const Color(0xFF374151) : Colors.grey[300]!;

    if (state.phase == SessionPhase.idle) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => timer.startFocus(
          title: state.title ?? 'Focus Session',
          category: state.category ?? 'General',
          focusDuration: state.focusDuration,
          breakDuration: state.breakDuration,
        ),
        child: const Text(
          'Start Session',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: buttonBg,
            shape: BoxShape.circle,
            border: Border.all(color: buttonBorder, width: 2),
          ),
          child: IconButton(
            icon: Icon(
              state.isPaused ? Icons.play_arrow : Icons.pause,
              size: 36,
            ),
            color: color,
            onPressed: state.isPaused ? timer.resume : timer.pause,
            padding: const EdgeInsets.all(18),
          ),
        ),
        const SizedBox(width: 24),
        Container(
          decoration: BoxDecoration(
            color: buttonBg,
            shape: BoxShape.circle,
            border: Border.all(color: buttonBorder, width: 2),
          ),
          child: IconButton(
            icon: const Icon(Icons.stop, size: 32),
            color: Colors.red[isDark ? 300 : 400],
            onPressed: () => _showStopConfirmation(context, ref),
            padding: const EdgeInsets.all(18),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedContent(
    BuildContext context,
    WidgetRef ref,
    SessionTimerState state,
    SessionTimerNotifier timer,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.6);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final circleColor = isDark ? Colors.green[900] : Colors.green[50];

    return Center(
      key: const ValueKey('finished'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green[isDark ? 700 : 200]!,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green[isDark ? 400 : 600],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Session Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Great work staying focused',
              style: TextStyle(fontSize: 16, color: subtextColor),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _handleSessionEnd(context, ref),
              child: const Text(
                'View Summary',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => timer.startFocus(
                title: state.title ?? 'Focus Session',
                category: state.category ?? 'General',
                focusDuration: state.focusDuration,
                breakDuration: state.breakDuration,
              ),
              child: Text(
                'Start Another Session',
                style: TextStyle(
                  fontSize: 16,
                  color: subtextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSessionEnd(BuildContext context, WidgetRef ref) async {
    final timerState = ref.read(sessionTimerProvider);
    final timer = ref.read(sessionTimerProvider.notifier);
    
    // Get actual focus minutes from state (set by background service)
    final focusMinutes = timerState.actualFocusMinutes ?? 0;
    
    if (kDebugMode) {
      print("🎯 Ending session with focus time: $focusMinutes minutes");
      print("   Phase: ${timerState.phase}");
      print("   Has actualFocusMinutes: ${timerState.actualFocusMinutes != null}");
    }

    // Stop the timer
    timer.stopSession();
    
    // Navigate to finished page with MINUTES (not seconds)
    if (context.mounted) {
      context.go('/finished/$focusMinutes');
    }
  }

  void _showStopConfirmation(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.6);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cardColor,
        title: Text(
          'End Session Early?',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        content: Text(
          'Your progress will be saved up to this point.',
          style: TextStyle(fontSize: 15, color: subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: subtextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[isDark ? 300 : 400],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleSessionEnd(context, ref);
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}