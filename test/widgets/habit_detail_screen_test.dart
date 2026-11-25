
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:routime/models/habit.dart';
import 'package:routime/providers/timer_provider.dart';
import 'package:routime/widgets/timer_widget.dart';
import 'package:routime/screens/habit_detail_screen.dart';

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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    timerProvider = TimerProvider(
      notificationService: FakeTimerNotificationService(),
    );
  });

  tearDown(() {
    timerProvider.dispose();
  });

  final habitWithTimer = Habit(
    id: 'habit-1',
    name: 'Belajar Flutter',
    colorValue: 0xFF4A7FB5,
    useTimer: true,
  );

  final habitWithoutTimer = Habit(
    id: 'habit-2',
    name: 'Membaca Buku',
    colorValue: 0xFF2F7D4F,
    useTimer: false,
  );

  Future<void> pumpDetailContent(
    WidgetTester tester,
    Habit habit,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<TimerProvider>.value(
        value: timerProvider,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HabitDetailContent(habit: habit),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> runWithCleanup(
    WidgetTester tester,
    Future<void> Function() testBody,
  ) async {
    try {
      await testBody();
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await timerProvider.clear();
      await tester.pump();
    }
  }

  group('HabitDetailContent dan TimerWidget', () {
    testWidgets(
      'Menampilkan Timer jika Habit mengaktifkan useTimer',
      (tester) async {
        await runWithCleanup(tester, () async {
          await pumpDetailContent(
            tester,
            habitWithTimer,
          );

          expect(find.byType(TimerWidget), findsOneWidget);

          expect(find.text('Countdown'), findsOneWidget);
          expect(find.text('Stopwatch'), findsOneWidget);
          expect(find.text('Pomodoro'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'Tidak menampilkan Timer jika Habit menonaktifkan useTimer',
      (tester) async {
        await runWithCleanup(tester, () async {
          await pumpDetailContent(
            tester,
            habitWithoutTimer,
          );

          expect(find.byType(TimerWidget), findsNothing);

          expect(find.text('Countdown'), findsNothing);
          expect(find.text('Stopwatch'), findsNothing);
          expect(find.text('Pomodoro'), findsNothing);

          // Informasi Habit tetap ditampilkan.
          expect(find.text('Streak saat ini'), findsOneWidget);
          expect(find.text('Streak terpanjang'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'Timer dimulai menggunakan ID Habit yang benar',
      (tester) async {
        await runWithCleanup(tester, () async {
          await pumpDetailContent(
            tester,
            habitWithTimer,
          );

          await tester.tap(find.text('Stopwatch'));
          await tester.pump();

          expect(timerProvider.hasTimer, true);
          expect(timerProvider.isRunning, true);
          expect(timerProvider.mode, TimerMode.stopwatch);
          expect(timerProvider.habitId, habitWithTimer.id);
        });
      },
    );

    testWidgets(
      'Timer tidak muncul pada Habit lain yang tidak mengaktifkannya',
      (tester) async {
        await runWithCleanup(tester, () async {
          // Mulai Timer dari Habit pertama.
          await timerProvider.startStopwatch(
            habitId: habitWithTimer.id,
          );

          await timerProvider.pause();

          // Tampilkan detail Habit kedua.
          await pumpDetailContent(
            tester,
            habitWithoutTimer,
          );

          expect(find.byType(TimerWidget), findsNothing);

          // Kepemilikan Timer tidak berubah.
          expect(timerProvider.hasTimer, true);
          expect(timerProvider.habitId, habitWithTimer.id);
          expect(timerProvider.isRunning, false);
        });
      },
    );
  });
}
