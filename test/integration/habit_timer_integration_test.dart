
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:routime/providers/habit_provider.dart';
import 'package:routime/providers/timer_provider.dart';
import 'package:routime/utils/date_utils.dart';

class FakeTimerNotificationService
    implements TimerNotificationService {
  @override
  Future<void> cancelTimerNotifications() async {}

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HabitProvider habitProvider;
  late TimerProvider timerProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    habitProvider = HabitProvider();

    timerProvider = TimerProvider(
      notificationService: FakeTimerNotificationService(),
    );

    await habitProvider.load();
  });

  tearDown(() {
    habitProvider.dispose();
    timerProvider.dispose();
  });

  group('Integrasi Habit dan Timer', () {
    test('Habit dengan Timer aktif dapat memulai Timer', () async {
      habitProvider.addHabit(
        'Belajar Flutter',
        useTimer: true,
      );

      final habit = habitProvider.habits.last;

      await timerProvider.startCountdown(
        habitId: habit.id,
        durationMinutes: 5,
      );

      expect(habit.useTimer, true);
      expect(timerProvider.hasTimer, true);
      expect(timerProvider.habitId, habit.id);
      expect(timerProvider.isRunning, true);
    });

    test('Timer tetap terhubung dengan Habit pemiliknya', () async {
      habitProvider.addHabit(
        'Belajar Dart',
        useTimer: true,
      );

      final habit = habitProvider.habits.last;

      await timerProvider.startStopwatch(
        habitId: habit.id,
      );

      expect(timerProvider.habitId, habit.id);
      expect(
        habitProvider.habits.any(
          (item) => item.id == timerProvider.habitId,
        ),
        true,
      );
    });

    test('Timer tidak otomatis menyelesaikan Habit', () async {
      habitProvider.addHabit(
        'Mengerjakan tugas',
        useTimer: true,
      );

      final habit = habitProvider.habits.last;

      await timerProvider.startCountdown(
        habitId: habit.id,
        durationMinutes: 1,
      );

      // Hentikan Timer sementara agar state awal tidak
      // mengganggu simulasi pemulihan Timer.
      await timerProvider.clear();

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Simulasikan Timer Countdown yang sudah melewati batas waktu.
      await prefs.setString(
        'routime_timer',
        jsonEncode({
          'mode': 'countdown',
          'phase': 'focus',
          'habitId': habit.id,
          'isRunning': true,
          'remainingMs': 1,
          'countdownDurationMs': 60000,
          'elapsedMs': 0,
          'startedAtMs': now - 100,
          'focusMinutes': 25,
          'shortBreakMinutes': 5,
          'longBreakMinutes': 15,
          'sessionsBeforeLongBreak': 4,
          'completedFocusSessions': 0,
        }),
      );

      // Pulihkan Timer menggunakan provider baru.
      final restoredTimerProvider = TimerProvider(
        notificationService: FakeTimerNotificationService(),
      );

      try {
        await restoredTimerProvider.load();

        // Timer seharusnya sudah selesai.
        expect(restoredTimerProvider.isRunning, false);
        expect(restoredTimerProvider.remainingMs, 0);

        // Habit tidak boleh otomatis diselesaikan.
        expect(
          habit.doneDates.contains(dateKey(DateTime.now())),
          false,
        );

        expect(habitProvider.doneToday, 0);
      } finally {
        restoredTimerProvider.dispose();
      }
    });

    test('Menghapus Habit pemilik Timer menghapus Timer', () async {
      habitProvider.addHabit(
        'Belajar Flutter',
        useTimer: true,
      );

      final habit = habitProvider.habits.last;

      await timerProvider.startStopwatch(
        habitId: habit.id,
      );

      expect(timerProvider.hasTimer, true);

      await habitProvider.deleteHabit(
        habit.id,
        timerProvider,
      );

      expect(timerProvider.hasTimer, false);
      expect(timerProvider.habitId, isNull);

      expect(
        habitProvider.habits.any(
          (item) => item.id == habit.id,
        ),
        false,
      );
    });

    test('Menghapus Habit lain tidak menghapus Timer pemiliknya',
        () async {
      final owner = habitProvider.habits[0];
      final other = habitProvider.habits[1];

      await timerProvider.startStopwatch(
        habitId: owner.id,
      );

      await timerProvider.pause();

      await habitProvider.deleteHabit(
        other.id,
        timerProvider,
      );

      expect(timerProvider.hasTimer, true);
      expect(timerProvider.habitId, owner.id);
    });

    test('Timer dijeda tidak dapat dipindahkan ke Habit lain',
        () async {
      final firstHabit = habitProvider.habits[0];
      final secondHabit = habitProvider.habits[1];

      await timerProvider.startCountdown(
        habitId: firstHabit.id,
        durationMinutes: 5,
      );

      await timerProvider.pause();

      await timerProvider.startStopwatch(
        habitId: secondHabit.id,
      );

      expect(timerProvider.hasTimer, true);
      expect(timerProvider.mode, TimerMode.countdown);
      expect(timerProvider.isRunning, false);
      expect(timerProvider.habitId, firstHabit.id);
    });

    test('Timer dijeda boleh diganti mode untuk Habit yang sama',
        () async {
      final habit = habitProvider.habits.first;

      await timerProvider.startCountdown(
        habitId: habit.id,
        durationMinutes: 5,
      );

      await timerProvider.pause();

      await timerProvider.startStopwatch(
        habitId: habit.id,
      );

      expect(timerProvider.mode, TimerMode.stopwatch);
      expect(timerProvider.isRunning, true);
      expect(timerProvider.habitId, habit.id);
    });

    test('Habit tetap harus diselesaikan secara manual', () async {
      final habit = habitProvider.habits.first;

      await timerProvider.startStopwatch(
        habitId: habit.id,
      );

      await timerProvider.pause();

      expect(
        habit.doneDates.contains(dateKey(DateTime.now())),
        false,
      );

      habitProvider.toggleToday(habit.id);

      expect(
        habit.doneDates.contains(dateKey(DateTime.now())),
        true,
      );
    });
  });
}
