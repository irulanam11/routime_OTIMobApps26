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
import 'package:routime/utils/responsive.dart';
import 'package:routime/widgets/progress_ring.dart';

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

  Future<void> pumpHome(WidgetTester tester, {bool loadHabits = true}) async {
    await tester.binding.setSurfaceSize(
      Size((kWideBreakpoint - 1).toDouble(), 844),
    );

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    if (loadHabits) {
      await habitProvider.load();
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HabitProvider>.value(value: habitProvider),
          ChangeNotifierProvider<TimerProvider>.value(value: timerProvider),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('HomeScreen', () {
    testWidgets('Menampilkan sapaan dan progress hari ini', (tester) async {
      await pumpHome(tester);

      expect(find.text(greeting()), findsOneWidget);
      expect(find.text('Progress hari ini'), findsOneWidget);
      expect(find.byType(ProgressRing), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);
    });

    testWidgets('Menampilkan daftar Habit dari Provider', (tester) async {
      await pumpHome(tester);

      expect(find.text('Minum 8 gelas air'), findsOneWidget);
      expect(find.text('Baca 15 menit'), findsOneWidget);
      expect(find.text('Belajar Flutter'), findsOneWidget);
    });

    testWidgets('Menampilkan pesan ketika belum ada Habit', (tester) async {
      await pumpHome(tester, loadHabits: false);

      expect(
        find.text('Belum ada kebiasaan. Tekan + untuk menambah.'),
        findsOneWidget,
      );

      expect(find.text('Tambahkan kebiasaan pertamamu'), findsOneWidget);

      expect(find.byType(ProgressRing), findsOneWidget);
    });

    testWidgets('Menandai Habit selesai dan memperbarui progress', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(habitProvider.doneToday, 0);

      await tester.tap(find.byIcon(Icons.circle_outlined).first);

      await tester.pumpAndSettle();

      expect(habitProvider.doneToday, 1);

      expect(find.text('2 kebiasaan lagi untuk hari ini'), findsOneWidget);

      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('Membuka halaman detail Habit ketika dipilih', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.text('Belajar Flutter'));

      await tester.pumpAndSettle();

      expect(find.byType(HabitDetailScreen), findsOneWidget);

      expect(find.text('Belajar Flutter'), findsOneWidget);
      expect(find.text('Streak saat ini'), findsOneWidget);
      expect(find.text('Streak terpanjang'), findsOneWidget);
    });

    testWidgets('FAB membuka halaman tambah Habit', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byType(FloatingActionButton));

      await tester.pumpAndSettle();

      expect(find.byType(HabitFormScreen), findsOneWidget);
      expect(find.text('Kebiasaan Baru'), findsOneWidget);
      expect(find.text('Nama kebiasaan'), findsOneWidget);
      expect(find.text('Deskripsi'), findsOneWidget);
      expect(find.text('Warna'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('Menambahkan Habit baru melalui form', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byType(FloatingActionButton));

      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama kebiasaan'),
        'Olahraga pagi',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Deskripsi'),
        'Olahraga setiap pagi selama 15 menit',
      );

      await tester.tap(find.text('Gunakan Timer'));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));

      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      final addedHabit = habitProvider.habits.last;

      expect(addedHabit.name, 'Olahraga pagi');
      expect(addedHabit.description, 'Olahraga setiap pagi selama 15 menit');
      expect(addedHabit.useTimer, true);
      expect(find.text('Olahraga pagi'), findsOneWidget);
    });

    testWidgets('Validasi form mencegah nama Habit kosong', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byType(FloatingActionButton));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));

      await tester.pumpAndSettle();

      expect(find.byType(HabitFormScreen), findsOneWidget);
      expect(find.text('Nama tidak boleh kosong'), findsOneWidget);
      expect(habitProvider.habits.length, 3);
    });
  });
}
