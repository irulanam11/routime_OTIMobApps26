
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/timer_provider.dart';
import 'timer_input_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();

    final isThisHabit =
        provider.hasTimer && provider.habitId == habit.id;

    final isOtherHabit =
        provider.hasTimer && provider.habitId != habit.id;

    final color = Color(habit.colorValue);

    final displayedTime = !isThisHabit
        ? '00:00'
        : provider.mode == TimerMode.stopwatch
            ? provider.formatDuration(provider.elapsedMs)
            : provider.formatDuration(provider.remainingMs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, color: color),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Timer Kebiasaan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isThisHabit)
                  Chip(
                    label: Text(
                      provider.isRunning ? 'Berjalan' : 'Dijeda',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (isOtherHabit) ...[
              const Center(
                child: Icon(
                  Icons.lock_clock_outlined,
                  size: 36,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Timer sedang digunakan oleh habit lain.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Untuk menggunakan Timer pada habit ini, '
                'buka habit yang sedang menggunakan Timer, '
                'kemudian tekan tombol Akhiri.',
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _modeChip(
                    context,
                    provider,
                    TimerMode.countdown,
                    'Countdown',
                    isThisHabit,
                  ),
                  _modeChip(
                    context,
                    provider,
                    TimerMode.stopwatch,
                    'Stopwatch',
                    isThisHabit,
                  ),
                  _modeChip(
                    context,
                    provider,
                    TimerMode.pomodoro,
                    'Pomodoro',
                    isThisHabit,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (isThisHabit &&
                  provider.mode == TimerMode.pomodoro) ...[
                Center(
                  child: Text(
                    _phaseLabel(provider.phase),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Sesi fokus: '
                    '${provider.completedFocusSessions}/'
                    '${provider.sessionsBeforeLongBreak}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Center(
                child: Text(
                  displayedTime,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (!isThisHabit) ...[
                const Center(
                  child: Text(
                    'Pilih mode Timer untuk mulai.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          if (provider.isRunning)
                            FilledButton.icon(
                              onPressed: provider.pause,
                              icon: const Icon(Icons.pause),
                              label: const Text('Pause'),
                            )
                          else if (provider.mode ==
                                  TimerMode.countdown &&
                              provider.remainingMs == 0)
                            FilledButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.check),
                              label: const Text('Waktu Habis'),
                            )
                          else if (provider.mode ==
                                  TimerMode.pomodoro &&
                              provider.phase ==
                                  PomodoroPhase.completed)
                            FilledButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.check),
                              label: const Text('Selesai'),
                            )
                          else
                            FilledButton.icon(
                              onPressed: provider.resume,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Lanjutkan'),
                            ),
                          OutlinedButton.icon(
                            onPressed: provider.reset,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: provider.clear,
                        icon: const Icon(Icons.close),
                        label: const Text('Akhiri'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _modeChip(
    BuildContext context,
    TimerProvider provider,
    TimerMode mode,
    String label,
    bool isThisHabit,
  ) {
    final selected = isThisHabit && provider.mode == mode;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: provider.isRunning
          ? null
          : (value) async {
              if (!value) return;

              if (mode == TimerMode.countdown) {
                await _showCountdownDialog(context, provider);
              } else if (mode == TimerMode.stopwatch) {
                await provider.startStopwatch(
                  habitId: habit.id,
                );
              } else if (mode == TimerMode.pomodoro) {
                await _showPomodoroDialog(context, provider);
              }
            },
    );
  }
}
