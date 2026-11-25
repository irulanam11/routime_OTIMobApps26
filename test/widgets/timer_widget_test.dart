
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:routime/models/habit.dart';
import 'package:routime/providers/timer_provider.dart';
import 'package:routime/widgets/timer_widget.dart';

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

  late TimerProvider timerProvider;
  late Habit habit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    timerProvider = TimerProvider(
      notificationService: FakeTimerNotificationService(),
    );

    habit = Habit(
      id: 'habit-1',
      name: 'Belajar Flutter',
      colorValue: Colors.blue.toARGB32(),
      useTimer: true,
    );
  });

  tearDown(() {
    // Ticker sudah dihentikan melalui runWithCleanup().
    timerProvider.dispose();
  });

  Widget createWidget(Habit currentHabit) {
    return ChangeNotifierProvider<TimerProvider>.value(
      value: timerProvider,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TimerWidget(habit: currentHabit),
          ),
        ),
      ),
    );
  }

  // Menjalankan test dan selalu membersihkan Timer
  // sebelum testWidgets melakukan verifikasi akhir.
  Future<void> runWithCleanup(
    WidgetTester tester,
    Future<void> Function() testBody,
  ) async {
    try {
      await testBody();
    } finally {
      // Lepaskan widget terlebih dahulu.
      await tester.pumpWidget(const SizedBox.shrink());

      // Hentikan ticker dan bersihkan state Timer.
      await timerProvider.clear();

      await tester.pump();
    }
  }

  group('TimerWidget', () {
    testWidgets(
      'Menampilkan pilihan mode ketika Timer belum digunakan',
      (tester) async {
        await runWithCleanup(tester, () async {
          await tester.pumpWidget(createWidget(habit));

          expect(find.text('Timer Kebiasaan'), findsOneWidget);
          expect(find.text('Countdown'), findsOneWidget);
          expect(find.text('Stopwatch'), findsOneWidget);
          expect(find.text('Pomodoro'), findsOneWidget);

          expect(
            find.text('Pilih mode Timer untuk mulai.'),
            findsOneWidget,
          );
        });
      },
    );

    testWidgets(
      'Memulai Stopwatch dan menampilkan status Berjalan',
      (tester) async {
        await runWithCleanup(tester, () async {
          await tester.pumpWidget(createWidget(habit));

          await tester.tap(find.text('Stopwatch'));
          await tester.pump();

          expect(timerProvider.mode, TimerMode.stopwatch);
          expect(timerProvider.isRunning, true);
          expect(find.text('Berjalan'), findsOneWidget);
          expect(find.text('Pause'), findsOneWidget);
          expect(find.text('Reset'), findsOneWidget);
          expect(find.text('Akhiri'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'Pause mengubah status menjadi Dijeda',
      (tester) async {
        await runWithCleanup(tester, () async {
          await timerProvider.startStopwatch(
            habitId: habit.id,
          );

          await tester.pumpWidget(createWidget(habit));

          await tester.tap(find.text('Pause'));
          await tester.pump();

          expect(timerProvider.isRunning, false);
          expect(find.text('Dijeda'), findsOneWidget);
          expect(find.text('Lanjutkan'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'Lanjutkan menjalankan kembali Timer',
      (tester) async {
        await runWithCleanup(tester, () async {
          await timerProvider.startStopwatch(
            habitId: habit.id,
          );

          await timerProvider.pause();

          await tester.pumpWidget(createWidget(habit));

          await tester.tap(find.text('Lanjutkan'));
          await tester.pump();

          expect(timerProvider.isRunning, true);
          expect(find.text('Berjalan'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'Reset Stopwatch mengembalikan waktu ke nol',
      (tester) async {
        await runWithCleanup(tester, () async {
          await timerProvider.startStopwatch(
            habitId: habit.id,
          );

          await tester.pumpWidget(createWidget(habit));

          await tester.tap(find.text('Reset'));
          await tester.pump();

          expect(timerProvider.isRunning, false);
          expect(timerProvider.elapsedMs, 0);
          expect(find.text('Dijeda'), findsOneWidget);
          expect(find.text('00:00'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'Akhiri menghapus Timer',
      (tester) async {
        await runWithCleanup(tester, () async {
          await timerProvider.startStopwatch(
            habitId: habit.id,
          );

          await tester.pumpWidget(createWidget(habit));

          await tester.tap(find.text('Akhiri'));
          await tester.pump();

          expect(timerProvider.hasTimer, false);

          expect(
            find.text('Pilih mode Timer untuk mulai.'),
            findsOneWidget,
          );
        });
      },
    );

    testWidgets(
      'Countdown menampilkan durasi yang dipilih',
      (tester) async {
        await runWithCleanup(tester, () async {
          await timerProvider.startCountdown(
            habitId: habit.id,
            durationMinutes: 5,
          );

          await tester.pumpWidget(createWidget(habit));

          expect(timerProvider.mode, TimerMode.countdown);
          expect(timerProvider.isRunning, true);

          expect(
            timerProvider.remainingMs,
            greaterThan(0),
          );

          expect(
            timerProvider.remainingMs,
            lessThanOrEqualTo(5 * 60 * 1000),
          );

          // Memastikan widget menampilkan format waktu.
          final timeFinder = find.byWidgetPredicate(
            (widget) {
              if (widget is! Text || widget.data == null) {
                return false;
              }

              return RegExp(
                r'^\d{2}:\d{2}$',
              ).hasMatch(widget.data!);
            },
          );

          expect(timeFinder, findsOneWidget);
          expect(find.text('Berjalan'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'Timer Habit lain menampilkan pesan penggunaan',
      (tester) async {
        await runWithCleanup(tester, () async {
          final ownerHabit = Habit(
            id: 'habit-2',
            name: 'Membaca buku',
            colorValue: Colors.green.toARGB32(),
            useTimer: true,
          );

          await timerProvider.startStopwatch(
            habitId: ownerHabit.id,
          );

          await tester.pumpWidget(createWidget(habit));

          expect(
            find.text('Timer sedang digunakan oleh habit lain.'),
            findsOneWidget,
          );

          expect(
            find.textContaining('kemudian tekan tombol Akhiri.'),
            findsOneWidget,
          );

          expect(find.text('Countdown'), findsNothing);
          expect(find.text('Stopwatch'), findsNothing);
          expect(find.text('Pomodoro'), findsNothing);
        });
      },
    );

    testWidgets(
      'Pomodoro menampilkan fase dan sesi fokus',
      (tester) async {
        await runWithCleanup(tester, () async {
          await timerProvider.startPomodoro(
            habitId: habit.id,
            focusMinutes: 25,
            shortBreakMinutes: 5,
            longBreakMinutes: 15,
            sessionsBeforeLongBreak: 4,
          );

          await tester.pumpWidget(createWidget(habit));

          expect(timerProvider.mode, TimerMode.pomodoro);
          expect(timerProvider.isRunning, true);

          expect(find.text('Waktu Fokus'), findsOneWidget);
          expect(find.text('Sesi fokus: 0/4'), findsOneWidget);

          expect(
            timerProvider.remainingMs,
            greaterThan(0),
          );

          expect(
            timerProvider.remainingMs,
            lessThanOrEqualTo(25 * 60 * 1000),
          );

          // Memastikan tampilan waktu Pomodoro muncul.
          final timeFinder = find.byWidgetPredicate(
            (widget) {
              if (widget is! Text || widget.data == null) {
                return false;
              }

              return RegExp(
                r'^\d{2}:\d{2}$',
              ).hasMatch(widget.data!);
            },
          );

          expect(timeFinder, findsOneWidget);
          expect(find.text('Berjalan'), findsOneWidget);
        });
      },
    );
  });
}
