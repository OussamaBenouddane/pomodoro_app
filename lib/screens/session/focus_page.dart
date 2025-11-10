import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockin_app/model/session_timer_model.dart';
import 'package:lockin_app/providers/session_timer_provider.dart';
import 'package:lockin_app/providers/session_provider.dart';

class FocusPage extends ConsumerWidget {
  const FocusPage({super.key});

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color _getPhaseColor(SessionPhase phase) {
    return phase == SessionPhase.focusing 
        ? Colors.deepOrangeAccent 
        : Colors.teal;
  }

  String _getPhaseTitle(SessionPhase phase) {
    switch (phase) {
      case SessionPhase.focusing:
        return 'Focus Mode';
      case SessionPhase.onBreak:
        return 'Break Time';
      default:
        return 'Session';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sessionTimerProvider);
    final timer = ref.read(sessionTimerProvider.notifier);
    
    final color = _getPhaseColor(timerState.phase);

    return Scaffold(
      backgroundColor: color.withOpacity(0.08),
      appBar: AppBar(
        title: Text(_getPhaseTitle(timerState.phase)),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          if (timerState.phase != SessionPhase.idle &&
              timerState.phase != SessionPhase.finished)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              color: Colors.white,
              onPressed: () => _confirmStop(context, ref, timer),
            ),
        ],
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: _buildPhaseContent(context, ref, timerState, timer, color),
        ),
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

    return Column(
      key: ValueKey(state.phase),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimerDisplay(state, color),
        const SizedBox(height: 40),
        Text(
          state.title ?? 'Focus Session',
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 60),
        _buildControlButtons(context, ref, state, timer),
      ],
    );
  }

  Widget _buildTimerDisplay(SessionTimerState state, Color color) {
    final isFocus = state.phase == SessionPhase.focusing;
    final totalDuration = isFocus 
        ? state.focusDuration.inSeconds 
        : state.breakDuration.inSeconds;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: state.remaining.inSeconds / totalDuration,
            strokeWidth: 12,
            backgroundColor: Colors.grey.shade300,
            color: color,
          ),
        ),
        Text(
          _formatTime(state.remaining),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    WidgetRef ref,
    SessionTimerState state,
    SessionTimerNotifier timer,
  ) {
    if (state.phase == SessionPhase.idle) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        ),
        onPressed: () => timer.startFocus(
          title: state.title ?? 'Focus Session',
          category: state.category ?? 'General',
          focusDuration: state.focusDuration,
          breakDuration: state.breakDuration,
        ),
        child: const Text('Start Focus', style: TextStyle(fontSize: 18)),
      );
    }

    // For focusing and onBreak phases
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            state.isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled,
            size: 64,
          ),
          color: Colors.blue,
          onPressed: state.isPaused ? timer.resume : timer.pause,
        ),
        const SizedBox(width: 40),
        IconButton(
          icon: const Icon(Icons.stop_circle_outlined, size: 54),
          color: Colors.redAccent,
          onPressed: () => _confirmStop(context, ref, timer),
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
    return Column(
      key: const ValueKey('finished'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Great work! 🎉',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ready for another focus session?',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => timer.startFocus(
                title: state.title ?? 'Focus Session',
                category: state.category ?? 'General',
                focusDuration: state.focusDuration,
                breakDuration: state.breakDuration,
              ),
              child: const Text('Start New Session'),
            ),
            const SizedBox(width: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => _navigateToFinished(context, ref, timer),
              child: const Text('View Summary'),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToFinished(
    BuildContext context,
    WidgetRef ref,
    SessionTimerNotifier timer,
  ) {
    final focusTime = timer.getActualFocusTime();
    timer.stopSession();
    // Navigate with the duration in seconds as a path parameter
    context.go('/finished/${focusTime.inSeconds}');
  }

  void _confirmStop(
    BuildContext context,
    WidgetRef ref,
    SessionTimerNotifier timer,
  ) {
    final timerState = ref.read(sessionTimerProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('Your progress will be saved up to this point.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(sessionProvider.notifier)
                  .saveFinishedSession(timerState);
              final focusTime = timer.getActualFocusTime();
              timer.stopSession();
              if (context.mounted) {
                // Navigate with the duration in seconds as a path parameter
                context.go('/finished/${focusTime.inSeconds}');
              }
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
  }
}