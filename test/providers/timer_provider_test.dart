
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:routime/providers/timer_provider.dart';

class FakeTimerNotificationService
    implements TimerNotificationService {
  int cancelCount = 0;

  final List<Map<String, dynamic>> scheduledNotifications = [];

  @override
  Future<void> cancelTimerNotifications() async {
    cancelCount++;
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime,
      'payload': payload,
    });
  }
}

void main() {
  late TimerProvider timerProvider;
  late FakeTimerNotificationService fakeNotification;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    fakeNotification = FakeTimerNotificationService();

    timerProvider = TimerProvider(
      notificationService: fakeNotification,
    );
  });

  tearDown(() {
    timerProvider.dispose();
  });

  group('Inisialisasi Timer', () {
    test('Timer memiliki kondisi awal yang benar', () {
      expect(timerProvider.hasTimer, false);
      expect(timerProvider.isRunning, false);
      expect(timerProvider.mode, isNull);
      expect(timerProvider.habitId, isNull);
      expect(timerProvider.remainingMs, 0);
      expect(timerProvider.elapsedMs, 0);
    });

    test('Format durasi ditampilkan dengan benar', () {
      expect(timerProvider.formatDuration(65000), '01:05');
      expect(timerProvider.formatDuration(3661000), '01:01:01');
    });
  });

  group('Countdown', () {
    test('Countdown dapat dimulai', () async {
      await timerProvider.startCountdown(
        habitId: 'habit-1',
        durationMinutes: 1,
      );

      expect(timerProvider.hasTimer, true);
      expect(timerProvider.isRunning, true);
      expect(timerProvider.mode, TimerMode.countdown);
      expect(timerProvider.habitId, 'habit-1');

      expect(
        timerProvider.remainingMs,
        closeTo(60000, 100),
      );

      expect(fakeNotification.scheduledNotifications.length, 1);
      expect(
        fakeNotification.scheduledNotifications.first['id'],
        1000,
      );
    });

    test('Countdown dapat dijeda dan dilanjutkan', () async {
      await timerProvider.startCountdown(
        habitId: 'habit-1',
        durationMinutes: 1,
      );

      await timerProvider.pause();

      expect(timerProvider.isRunning, false);
      expect(timerProvider.mode, TimerMode.countdown);
      expect(timerProvider.remainingMs, greaterThan(0));

      await timerProvider.resume();

      expect(timerProvider.isRunning, true);
      expect(timerProvider.mode, TimerMode.countdown);
    });

    test('Reset Countdown mengembalikan durasi awal', () async {
      await timerProvider.startCountdown(
        habitId: 'habit-1',
        durationMinutes: 1,
      );

      await timerProvider.pause();
      await timerProvider.reset();

      expect(timerProvider.isRunning, false);
      expect(timerProvider.remainingMs, 60000);
      expect(timerProvider.mode, TimerMode.countdown);
    });

    test('Countdown tidak dimulai jika durasi tidak valid', () async {
      await timerProvider.startCountdown(
        habitId: 'habit-1',
        durationMinutes: 0,
      );

      expect(timerProvider.hasTimer, false);
      expect(timerProvider.isRunning, false);
    });
  });

  group('Stopwatch', () {
    test('Stopwatch dapat dimulai', () async {
      await timerProvider.startStopwatch(
        habitId: 'habit-1',
      );

      expect(timerProvider.hasTimer, true);
      expect(timerProvider.isRunning, true);
      expect(timerProvider.mode, TimerMode.stopwatch);
      expect(timerProvider.habitId, 'habit-1');
      expect(timerProvider.elapsedMs, greaterThanOrEqualTo(0));
      expect(fakeNotification.scheduledNotifications, isEmpty);
    });

    test('Stopwatch dapat dijeda dan dilanjutkan', () async {
      await timerProvider.startStopwatch(
        habitId: 'habit-1',
      );

      await Future.delayed(
        const Duration(milliseconds: 30),
      );

      await timerProvider.pause();

      expect(timerProvider.isRunning, false);
      expect(timerProvider.elapsedMs, greaterThan(0));

      final elapsedBeforeResume = timerProvider.elapsedMs;

      await timerProvider.resume();

      expect(timerProvider.isRunning, true);

      await Future.delayed(
        const Duration(milliseconds: 30),
      );

      await timerProvider.pause();

      expect(
        timerProvider.elapsedMs,
        greaterThan(elapsedBeforeResume),
      );
    });

    test('Reset Stopwatch mengembalikan waktu ke nol', () async {
      await timerProvider.startStopwatch(
        habitId: 'habit-1',
      );

      await Future.delayed(
        const Duration(milliseconds: 30),
      );

      await timerProvider.pause();
      await timerProvider.reset();

      expect(timerProvider.isRunning, false);
      expect(timerProvider.elapsedMs, 0);
      expect(timerProvider.mode, TimerMode.stopwatch);
    });
  });

  group('Pomodoro', () {
    test('Pomodoro dapat dimulai dengan konfigurasi khusus', () async {
      await timerProvider.startPomodoro(
        habitId: 'habit-1',
        focusMinutes: 20,
        shortBreakMinutes: 3,
        longBreakMinutes: 10,
        sessionsBeforeLongBreak: 3,
      );

      expect(timerProvider.hasTimer, true);
      expect(timerProvider.isRunning, true);
      expect(timerProvider.mode, TimerMode.pomodoro);
      expect(timerProvider.phase, PomodoroPhase.focus);

      expect(timerProvider.habitId, 'habit-1');
      expect(timerProvider.focusMinutes, 20);
      expect(timerProvider.shortBreakMinutes, 3);
      expect(timerProvider.longBreakMinutes, 10);
      expect(timerProvider.sessionsBeforeLongBreak, 3);

      expect(
        timerProvider.remainingMs,
        closeTo(20 * 60 * 1000, 100),
      );

      expect(
        fakeNotification.scheduledNotifications,
        isNotEmpty,
      );
    });

    test('Pomodoro tidak dimulai dengan konfigurasi tidak valid', () async {
      await timerProvider.startPomodoro(
        habitId: 'habit-1',
        focusMinutes: 0,
      );

      expect(timerProvider.hasTimer, false);
      expect(timerProvider.isRunning, false);
    });

    test('Pomodoro berpindah dari fokus ke istirahat', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(
        'routime_timer',
        jsonEncode({
          'mode': 'pomodoro',
          'phase': 'focus',
          'habitId': 'habit-1',
          'isRunning': true,
          'remainingMs': 1000,
          'countdownDurationMs': 0,
          'elapsedMs': 0,
          'startedAtMs': now - 2000,
          'focusMinutes': 1,
          'shortBreakMinutes': 1,
          'longBreakMinutes': 5,
          'sessionsBeforeLongBreak': 4,
          'completedFocusSessions': 0,
        }),
      );

      await timerProvider.load();

      expect(timerProvider.mode, TimerMode.pomodoro);
      expect(timerProvider.isRunning, true);
      expect(timerProvider.phase, PomodoroPhase.shortBreak);
      expect(timerProvider.completedFocusSessions, 1);
      expect(timerProvider.remainingMs, greaterThan(0));
    });

    test('Pomodoro dapat mencapai fase selesai', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(
        'routime_timer',
        jsonEncode({
          'mode': 'pomodoro',
          'phase': 'longBreak',
          'habitId': 'habit-1',
          'isRunning': true,
          'remainingMs': 1000,
          'countdownDurationMs': 0,
          'elapsedMs': 0,
          'startedAtMs': now - 2000,
          'focusMinutes': 1,
          'shortBreakMinutes': 1,
          'longBreakMinutes': 5,
          'sessionsBeforeLongBreak': 1,
          'completedFocusSessions': 1,
        }),
      );

      await timerProvider.load();

      expect(timerProvider.mode, TimerMode.pomodoro);
      expect(timerProvider.phase, PomodoroPhase.completed);
      expect(timerProvider.isRunning, false);
      expect(timerProvider.remainingMs, 0);
    });
  });

  group('Pergantian Mode Timer', () {
    test('Timer yang dijeda dapat diganti ke mode lain', () async {
      await timerProvider.startCountdown(
        habitId: 'habit-1',
        durationMinutes: 5,
      );

      await timerProvider.pause();

      expect(timerProvider.mode, TimerMode.countdown);
      expect(timerProvider.isRunning, false);

      await timerProvider.startStopwatch(
        habitId: 'habit-1',
      );

      expect(timerProvider.mode, TimerMode.stopwatch);
      expect(timerProvider.isRunning, true);
      expect(timerProvider.habitId, 'habit-1');
    });

    test('Timer yang sedang berjalan tidak dapat diganti', () async {
      await timerProvider.startCountdown(
        habitId: 'habit-1',
        durationMinutes: 5,
      );

      await timerProvider.startStopwatch(
        habitId: 'habit-1',
      );

      expect(timerProvider.mode, TimerMode.countdown);
      expect(timerProvider.isRunning, true);
    });
  });

  group('Penyimpanan Timer', () {
    test('Timer dapat disimpan dan dipulihkan', () async {
      await timerProvider.startCountdown(
        habitId: 'habit-1',
        durationMinutes: 5,
      );

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('routime_timer'), isNotNull);

      await timerProvider.pause();

      final restoredProvider = TimerProvider(
        notificationService: FakeTimerNotificationService(),
      );

      try {
        await restoredProvider.load();

        expect(restoredProvider.hasTimer, true);
        expect(restoredProvider.isRunning, false);
        expect(restoredProvider.mode, TimerMode.countdown);
        expect(restoredProvider.habitId, 'habit-1');
        expect(restoredProvider.remainingMs, greaterThan(0));
      } finally {
        restoredProvider.dispose();
      }
    });

    test('Clear menghapus Timer dan data tersimpan', () async {
      await timerProvider.startCountdown(
        habitId: 'habit-1',
        durationMinutes: 5,
      );

      await timerProvider.clear();

      final prefs = await SharedPreferences.getInstance();

      expect(timerProvider.hasTimer, false);
      expect(timerProvider.isRunning, false);
      expect(timerProvider.mode, isNull);
      expect(timerProvider.habitId, isNull);

      expect(prefs.getString('routime_timer'), isNull);
    });
  });
}
