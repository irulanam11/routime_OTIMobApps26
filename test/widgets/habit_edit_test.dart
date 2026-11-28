
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:routime/providers/habit_provider.dart';
import 'package:routime/providers/timer_provider.dart';
import 'package:routime/screens/home_screen.dart';
import 'package:routime/screens/habit_detail_screen.dart';
import 'package:routime/screens/habit_form_screen.dart';
import 'package:routime/utils/date_utils.dart';

class FakeTimerNotificationService implements TimerNotificationService {
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
  });

  tearDown(() {
    habitProvider.dispose();
    timerProvider.dispose();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await habitProvider.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HabitProvider>.value(
            value: habitProvider,
          ),
          ChangeNotifierProvider<TimerProvider>.value(
            value: timerProvider,
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> openEditForm(WidgetTester tester) async {
    await tester.tap(find.text('Belajar Flutter'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitDetailScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Edit kebiasaan'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitFormScreen), findsOneWidget);
  }

  group('Edit Habit', () {
    testWidgets(
      'Menampilkan data Habit sebelumnya pada form Edit',
      (tester) async {
        await pumpApp(tester);

        await openEditForm(tester);

        expect(
          find.widgetWithText(TextFormField, 'Nama kebiasaan'),
          findsOneWidget,
        );

        expect(
          tester.widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Nama kebiasaan'),
          ).controller!.text,
          'Belajar Flutter',
        );

        expect(
          tester.widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Deskripsi'),
          ).controller!.text,
          '',
        );

        expect(find.text('Edit Kebiasaan'), findsOneWidget);
        expect(find.text('Simpan Perubahan'), findsOneWidget);
      },
    );

    testWidgets(
      'Mengubah nama dan deskripsi tanpa membuat Habit baru',
      (tester) async {
        await pumpApp(tester);

        final originalHabit = habitProvider.habits.firstWhere(
          (habit) => habit.id == '3',
        );

        final originalId = originalHabit.id;

        await openEditForm(tester);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nama kebiasaan'),
          'Belajar Flutter Lanjutan',
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Deskripsi'),
          'Belajar Flutter setiap hari',
        );

        await tester.tap(find.text('Simpan Perubahan'));
        await tester.pumpAndSettle();

        final updatedHabit = habitProvider.habits.firstWhere(
          (habit) => habit.id == originalId,
        );

        expect(habitProvider.habits.length, 3);
        expect(updatedHabit.name, 'Belajar Flutter Lanjutan');
        expect(updatedHabit.description, 'Belajar Flutter setiap hari');
        expect(updatedHabit.id, originalId);
        expect(find.byType(HabitFormScreen), findsNothing);

        final updatedHabitWidget = find.text('Belajar Flutter Lanjutan');
        expect(updatedHabitWidget, findsOneWidget);
      },
    );

    testWidgets(
      'Mempertahankan riwayat penyelesaian Habit setelah diedit',
      (tester) async {
        await pumpApp(tester);

        final habit = habitProvider.habits.firstWhere(
          (item) => item.id == '3',
        );

        final yesterday = dateKey(
          DateTime.now().subtract(const Duration(days: 1)),
        );

        habit.doneDates.add(yesterday);

        await openEditForm(tester);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nama kebiasaan'),
          'Belajar Flutter Baru',
        );

        await tester.tap(find.text('Simpan Perubahan'));
        await tester.pumpAndSettle();

        final updatedHabit = habitProvider.habits.firstWhere(
          (item) => item.id == '3',
        );

        expect(updatedHabit.doneDates.contains(yesterday), true);
        expect(updatedHabit.doneDates.length, 1);
      },
    );

    testWidgets(
      'Menolak perubahan jika nama Habit dikosongkan',
      (tester) async {
        await pumpApp(tester);

        await openEditForm(tester);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nama kebiasaan'),
          '',
        );

        await tester.tap(find.text('Simpan Perubahan'));
        await tester.pumpAndSettle();

        expect(find.byType(HabitFormScreen), findsOneWidget);
        expect(find.text('Nama tidak boleh kosong'), findsOneWidget);

        final habit = habitProvider.habits.firstWhere(
          (item) => item.id == '3',
        );

        expect(habit.name, 'Belajar Flutter');
        expect(habitProvider.habits.length, 3);
      },
    );

    testWidgets(
      'Membersihkan Timer ketika Habit diedit dengan Timer nonaktif',
      (tester) async {
        await pumpApp(tester);

        await timerProvider.startStopwatch(habitId: '3');
        await timerProvider.pause();

        expect(timerProvider.hasTimer, true);
        expect(timerProvider.habitId, '3');

        await openEditForm(tester);

        // Timer pada Habit ini memang sudah nonaktif.
        await tester.tap(find.text('Simpan Perubahan'));
        await tester.pumpAndSettle();

        expect(timerProvider.hasTimer, false);

        final habit = habitProvider.habits.firstWhere(
          (item) => item.id == '3',
        );

        expect(habit.useTimer, false);
      },
    );
  });
}
