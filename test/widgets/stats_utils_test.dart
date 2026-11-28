import 'package:flutter_test/flutter_test.dart';
import 'package:routime/models/habit.dart';
import 'package:routime/utils/stats_utils.dart';

void main() {
  final a = Habit(
    id: 'a',
    name: 'A',
    colorValue: 0xFF2F7D4F,
    doneDates: {'2026-11-01', '2026-11-02', '2026-11-26'},
  );
  final b = Habit(
    id: 'b',
    name: 'B',
    colorValue: 0xFF4A7FB5,
    doneDates: {'2026-11-02', '2026-10-31'},
  );

  final now = DateTime(2026, 11, 26);

  group('MonthStats', () {
    test('Menghitung total, hari aktif, dan hari berlalu bulan berjalan', () {
      final s = MonthStats.compute([a, b], DateTime(2026, 11), now: now);

      expect(s.totalCompleted, 4);
      expect(s.activeDays, 3);
      expect(s.elapsedDays, 26);
      expect(s.completionRate, closeTo(4 / (2 * 26), 1e-9));
      expect(s.completedFor(a), 3);
      expect(s.completedFor(b), 1);
    });

    test('Data mingguan membagi bulan per 7 hari', () {
      final s = MonthStats.compute([a, b], DateTime(2026, 11), now: now);

      // November 2026 punya 30 hari -> 5 minggu.
      expect(s.weekly, [3, 0, 0, 1, 0]);
    });

    test('Bulan lalu memakai seluruh hari dalam bulan', () {
      final s = MonthStats.compute([a, b], DateTime(2026, 10), now: now);

      expect(s.elapsedDays, 31);
      expect(s.totalCompleted, 1);
      expect(s.weekly, [0, 0, 0, 0, 1]);
    });

    test('completedOn menghitung habit selesai pada tanggal tertentu', () {
      final s = MonthStats.compute([a, b], DateTime(2026, 11), now: now);

      expect(s.completedOn(DateTime(2026, 11, 2)), 2);
      expect(s.completedOn(DateTime(2026, 11, 3)), 0);
    });

    test('rank mengurutkan dari penyelesaian terbanyak', () {
      final s = MonthStats.compute([b, a], DateTime(2026, 11), now: now);

      expect(s.rank([b, a]).map((h) => h.id).toList(), ['a', 'b']);
    });

    test('Tanpa habit, persentase 0 dan tidak error', () {
      final s = MonthStats.compute([], DateTime(2026, 11), now: now);

      expect(s.completionRate, 0);
      expect(s.activeDays, 0);
    });
  });
}
