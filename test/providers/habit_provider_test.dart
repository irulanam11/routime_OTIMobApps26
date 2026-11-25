
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routime/providers/habit_provider.dart';
import 'package:routime/providers/timer_provider.dart';
import 'package:routime/utils/date_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HabitProvider habitProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    habitProvider = HabitProvider();
  });

  tearDown(() {
    habitProvider.dispose();
  });

  group('HabitProvider', () {
    test('Load pertama kali membuat tiga Habit contoh', () async {
      await habitProvider.load();

      expect(habitProvider.habits.length, 3);
      expect(habitProvider.habits[0].name, 'Minum 8 gelas air');
      expect(habitProvider.habits[1].name, 'Baca 15 menit');
      expect(habitProvider.habits[2].name, 'Belajar Flutter');
    });

    test('Add Habit menyimpan data dengan benar', () async {
      habitProvider.addHabit(
        '  Belajar Dart  ',
        colorValue: 0xFF4A7FB5,
        useTimer: true,
      );

      await Future<void>.delayed(Duration.zero);

      expect(habitProvider.habits.length, 1);
      expect(habitProvider.habits.first.name, 'Belajar Dart');
      expect(habitProvider.habits.first.colorValue, 0xFF4A7FB5);
      expect(habitProvider.habits.first.useTimer, true);
    });

    test('ToggleToday menandai Habit selesai', () async {
      await habitProvider.load();

      final habit = habitProvider.habits.first;
      habitProvider.toggleToday(habit.id);

      expect(habit.doneDates, contains(dateKey(DateTime.now())));
      expect(habitProvider.doneToday, 1);
    });

    test('ToggleToday membatalkan penyelesaian Habit', () async {
      await habitProvider.load();

      final habit = habitProvider.habits.first;

      habitProvider.toggleToday(habit.id);
      habitProvider.toggleToday(habit.id);

      expect(habit.doneDates, isEmpty);
      expect(habitProvider.doneToday, 0);
    });

    test('Habit tersimpan dan dapat dimuat kembali', () async {
      habitProvider.addHabit(
        'Belajar Flutter',
        useTimer: true,
      );

      await Future<void>.delayed(Duration.zero);

      final newProvider = HabitProvider();

      await newProvider.load();

      expect(newProvider.habits.length, 1);
      expect(newProvider.habits.first.name, 'Belajar Flutter');
      expect(newProvider.habits.first.useTimer, true);

      newProvider.dispose();
    });

    test('DeleteHabit menghapus Habit', () async {
      await habitProvider.load();

      final habit = habitProvider.habits.first;
      final timerProvider = TimerProvider();

      await habitProvider.deleteHabit(habit.id, timerProvider);

      expect(
        habitProvider.habits.any((h) => h.id == habit.id),
        false,
      );

      timerProvider.dispose();
    });


    test('Habit dengan Timer aktif tetap terhubung saat Habit lain dihapus',
        () async {
      await habitProvider.load();

      final timerProvider = TimerProvider();
      final owner = habitProvider.habits.first;
      final other = habitProvider.habits[1];

      // Siapkan Timer Stopwatch dalam kondisi pause
      // melalui SharedPreferences tanpa memanggil plugin notifikasi.
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'routime_timer',
        '''
        {
          "mode": "stopwatch",
          "phase": "focus",
          "habitId": "${owner.id}",
          "isRunning": false,
          "remainingMs": 0,
          "elapsedMs": 5000
        }
        ''',
      );

      await timerProvider.load();

      expect(timerProvider.hasTimer, true);
      expect(timerProvider.habitId, owner.id);

      // Hapus Habit yang bukan pemilik Timer.
      await habitProvider.deleteHabit(other.id, timerProvider);

      // Timer harus tetap tersimpan dan terhubung
      // dengan Habit pemiliknya.
      expect(timerProvider.hasTimer, true);
      expect(timerProvider.habitId, owner.id);

      timerProvider.dispose();
    });
  });
}
