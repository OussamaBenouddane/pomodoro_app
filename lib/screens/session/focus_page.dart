import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
        ? const Color(0xFF6366F1)
        : const Color(0xFF06B6D4);
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

    final color = _getPhaseColor(timerState.phase);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_getPhaseTitle(timerState.phase)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (timerState.phase != SessionPhase.idle &&
              timerState.phase != SessionPhase.finished)
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.grey[600],
              onPressed: () => _confirmStop(context, ref, timer),
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

    return Center(
      key: ValueKey(state.phase),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Phase icon with background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getPhaseIcon(state.phase),
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(height: 40),
            
            // Timer display
            _buildModernTimerDisplay(state, color),
            const SizedBox(height: 32),
            
            // Session title
            Text(
              state.title ?? 'Focus Session',
              style: const TextStyle(
                fontSize: 22,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Phase subtitle
            Text(
              _getPhaseSubtitle(state.phase),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Control buttons
            _buildControlButtons(context, ref, state, timer, color),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTimerDisplay(SessionTimerState state, Color color) {
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
        // Outer circle background
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[200]!, width: 2),
          ),
        ),
        // Progress indicator
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
        // Time text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(state.remaining),
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w300,
                color: Color(0xFF1F2937),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            if (state.isPaused)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
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
        // Pause/Resume button
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
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
        
        // Stop button
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: IconButton(
            icon: const Icon(Icons.stop, size: 32),
            color: Colors.red[400],
            onPressed: () => _confirmStop(context, ref, timer),
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
                color: Colors.green[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green[200]!, width: 2),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Session Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Great work staying focused',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
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
              onPressed: () => _navigateToFinished(context, ref, timer),
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
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFinished(
    BuildContext context,
    WidgetRef ref,
    SessionTimerNotifier timer,
  ) {
    final focusTime = timer.getActualFocusTime();
    timer.stopSession();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Text(
          'End Session Early?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        content: Text(
          'Your progress will be saved up to this point.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(sessionProvider.notifier)
                  .saveFinishedSession(timerState);
              final focusTime = timer.getActualFocusTime();
              timer.stopSession();
              if (context.mounted) {
                context.go('/finished/${focusTime.inSeconds}');
              }
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}