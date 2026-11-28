import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import 'timer_input_dialog.dart';
import 'timer_progress_ring.dart';
import '../services/notification_service.dart';

class TimerWidget extends StatelessWidget {
  final Habit habit;

  const TimerWidget({super.key, required this.habit});

  Future<void> _showCountdownDialog(
    BuildContext context,
    TimerProvider provider,
  ) async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) {
        return const TimerInputDialog(
          title: 'Atur Countdown',
          initialValues: [25],
          labels: ['Durasi (menit)'],
        );
      },
    );

    if (result == null || !context.mounted) return;

    await NotificationService.ensureExactAlarmPermission();
    if (!context.mounted) return;

    await provider.startCountdown(
      habitId: habit.id,
      durationMinutes: result[0],
    );
  }

  Future<void> _showPomodoroDialog(
    BuildContext context,
    TimerProvider provider,
  ) async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) {
        return TimerInputDialog(
          title: 'Pengaturan Pomodoro',
          initialValues: [
            provider.focusMinutes,
            provider.shortBreakMinutes,
            provider.longBreakMinutes,
            provider.sessionsBeforeLongBreak,
          ],
          labels: const [
            'Durasi fokus (menit)',
            'Istirahat pendek (menit)',
            'Istirahat panjang (menit)',
            'Sesi fokus sebelum istirahat panjang',
          ],
        );
      },
    );

    if (result == null || !context.mounted) return;

    await NotificationService.ensureExactAlarmPermission();
    if (!context.mounted) return;

    await provider.startPomodoro(
      habitId: habit.id,
      focusMinutes: result[0],
      shortBreakMinutes: result[1],
      longBreakMinutes: result[2],
      sessionsBeforeLongBreak: result[3],
    );
  }

  String _phaseLabel(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.focus:
        return 'Waktu Fokus';
      case PomodoroPhase.shortBreak:
        return 'Istirahat Pendek';
      case PomodoroPhase.longBreak:
        return 'Istirahat Panjang';
      case PomodoroPhase.completed:
        return 'Pomodoro Selesai';
    }
  }

  int _pomodoroPhaseDuration(TimerProvider provider) {
    switch (provider.phase) {
      case PomodoroPhase.focus:
        return provider.focusMinutes * 60 * 1000;
      case PomodoroPhase.shortBreak:
        return provider.shortBreakMinutes * 60 * 1000;
      case PomodoroPhase.longBreak:
        return provider.longBreakMinutes * 60 * 1000;
      case PomodoroPhase.completed:
        return provider.longBreakMinutes * 60 * 1000;
    }
  }

  double _calculateProgress(TimerProvider provider) {
    if (provider.mode == TimerMode.stopwatch) {
      return 1;
    }

    final totalDuration = provider.mode == TimerMode.countdown
        ? provider.countdownDurationMs
        : _pomodoroPhaseDuration(provider);

    if (totalDuration <= 0) return 0;

    final remaining = provider.remainingMs;

    return ((totalDuration - remaining) / totalDuration)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();

    final isThisHabit = provider.hasTimer && provider.habitId == habit.id;
    final isOtherHabit = provider.hasTimer && provider.habitId != habit.id;

    final color = Color(habit.colorValue);

    final displayedTime = !isThisHabit
        ? '00:00'
        : provider.mode == TimerMode.stopwatch
        ? provider.formatDuration(provider.elapsedMs)
        : provider.formatDuration(provider.remainingMs);

    final progress = isThisHabit ? _calculateProgress(provider) : 0.0;

    final isCountdownFinished =
        isThisHabit &&
        provider.mode == TimerMode.countdown &&
        provider.remainingMs == 0;

    final isPomodoroFinished =
        isThisHabit &&
        provider.mode == TimerMode.pomodoro &&
        provider.phase == PomodoroPhase.completed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(provider, isThisHabit),
            const SizedBox(height: 24),
            if (isOtherHabit)
              _buildLockedState()
            else ...[
              _buildModeSelector(context, provider, isThisHabit),
              const SizedBox(height: 30),
              if (isThisHabit && provider.mode == TimerMode.pomodoro)
                _buildPomodoroInfo(provider, color),
              if (isThisHabit && provider.mode == TimerMode.pomodoro)
                const SizedBox(height: 18),
              _buildTimerCircle(
                context,
                displayedTime,
                progress,
                isThisHabit,
                provider,
                color,
              ),
              const SizedBox(height: 28),
              if (!isThisHabit)
                const Center(
                  child: Text(
                    'Pilih mode Timer untuk mulai.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else
                _buildControls(
                  provider,
                  isCountdownFinished,
                  isPomodoroFinished,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TimerProvider provider, bool isThisHabit) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.timer_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timer Kebiasaan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Atur waktu dan fokus pada tujuanmu',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        if (isThisHabit) _buildStatusBadge(provider.isRunning),
      ],
    );
  }

  Widget _buildStatusBadge(bool isRunning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: isRunning ? AppColors.softGreen : const Color(0xFFFFF1D9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isRunning ? AppColors.primary : AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isRunning ? 'Berjalan' : 'Dijeda',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isRunning ? AppColors.primary : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.softGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Timer sedang digunakan oleh habit lain.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Untuk menggunakan Timer pada habit ini, '
            'buka habit yang sedang menggunakan Timer, '
            'kemudian tekan tombol Akhiri.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(
    BuildContext context,
    TimerProvider provider,
    bool isThisHabit,
  ) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3EA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _modeButton(
            context,
            provider,
            TimerMode.countdown,
            'Countdown',
            isThisHabit,
          ),
          _modeButton(
            context,
            provider,
            TimerMode.stopwatch,
            'Stopwatch',
            isThisHabit,
          ),
          _modeButton(
            context,
            provider,
            TimerMode.pomodoro,
            'Pomodoro',
            isThisHabit,
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    BuildContext context,
    TimerProvider provider,
    TimerMode mode,
    String label,
    bool isThisHabit,
  ) {
    final selected = isThisHabit && provider.mode == mode;
    final disabled = provider.isRunning;

    return Expanded(
      child: GestureDetector(
        onTap: disabled
            ? null
            : () async {
                if (mode == TimerMode.countdown) {
                  await _showCountdownDialog(context, provider);
                } else if (mode == TimerMode.stopwatch) {
                  await provider.startStopwatch(habitId: habit.id);
                } else if (mode == TimerMode.pomodoro) {
                  await _showPomodoroDialog(context, provider);
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : disabled
                    ? AppColors.muted.withValues(alpha: 0.5)
                    : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPomodoroInfo(TimerProvider provider, Color color) {
    return Column(
      children: [
        Text(
          _phaseLabel(provider.phase),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sesi fokus: ${provider.completedFocusSessions}/${provider.sessionsBeforeLongBreak}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTimerCircle(
    BuildContext context,
    String displayedTime,
    double progress,
    bool isThisHabit,
    TimerProvider provider,
    Color color,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ringSize = (constraints.maxWidth - 20)
            .clamp(190.0, 270.0)
            .toDouble();

        return Center(
          child: TimerProgressRing(
            size: ringSize,
            progress: progress,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayedTime,
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  !isThisHabit
                      ? 'SIAP MEMULAI'
                      : provider.mode == TimerMode.stopwatch
                      ? 'WAKTU BERJALAN'
                      : 'WAKTU TERSISA',
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(
    TimerProvider provider,
    bool isCountdownFinished,
    bool isPomodoroFinished,
  ) {
    final isFinished = isCountdownFinished || isPomodoroFinished;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            if (provider.isRunning)
              FilledButton.icon(
                onPressed: provider.pause,
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Pause'),
                style: _primaryButtonStyle(),
              )
            else if (isFinished)
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  isCountdownFinished ? 'Waktu Habis' : 'Selesai',
                ),
                style: _primaryButtonStyle(),
              )
            else
              FilledButton.icon(
                onPressed: provider.resume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Lanjutkan'),
                style: _primaryButtonStyle(),
              ),

            OutlinedButton.icon(
              onPressed: provider.reset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Center(
          child: TextButton.icon(
            onPressed: provider.clear,
            icon: const Icon(
              Icons.stop_circle_outlined,
              size: 19,
            ),
            label: const Text('Akhiri'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.muted,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.ringBackground,
      disabledForegroundColor: AppColors.muted,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
