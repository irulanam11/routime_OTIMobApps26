import 'package:flutter_test/flutter_test.dart';
import 'package:routime/models/habit.dart';
import 'package:routime/utils/date_utils.dart';

Habit habitWith(Set<String> dates) =>
    Habit(id: 'h', name: 'H', colorValue: 0xFF2F7D4F, doneDates: dates);

String daysAgo(int n) =>
    dateKey(DateTime.now().subtract(Duration(days: n)));

void main() {
  group('dateKey & daysInMonth', () {
    test('dateKey memakai angka nol di depan', () {
      expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dateKey(DateTime(2026, 11, 26)), '2026-11-26');
    });

    test('daysInMonth benar termasuk Februari kabisat', () {
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2026, 11), 30);
      expect(daysInMonth(2026, 12), 31);
    });
  });

  group('currentStreak', () {
    test('0 jika belum pernah selesai', () {
      expect(currentStreak(habitWith({})), 0);
    });

    test('Menghitung hari beruntun sampai hari ini', () {
      final h = habitWith({daysAgo(0), daysAgo(1), daysAgo(2)});
      expect(currentStreak(h), 3);
    });

    test('Streak tetap hidup jika baru selesai sampai kemarin', () {
      final h = habitWith({daysAgo(1), daysAgo(2)});
      expect(currentStreak(h), 2);
    });

    test('Terputus jika ada hari kosong', () {
      final h = habitWith({daysAgo(0), daysAgo(2)});
      expect(currentStreak(h), 1);
    });
  });

  group('longestStreak', () {
    test('0 jika kosong', () {
      expect(longestStreak(habitWith({})), 0);
    });

    test('Mencari rangkaian terpanjang', () {
      final h = habitWith({
        '2026-11-01',
        '2026-11-02',
        '2026-11-03',
        '2026-11-10',
        '2026-11-11',
      });
      expect(longestStreak(h), 3);
    });
  });

  group('lastDays & doneInLastDays', () {
    test('lastDays berurutan dan berakhir hari ini', () {
      final days = lastDays(7);
      expect(days.length, 7);
      expect(dateKey(days.last), dateKey(DateTime.now()));
    });

    test('doneInLastDays hanya menghitung dalam rentang', () {
      final h = habitWith({daysAgo(0), daysAgo(3), daysAgo(20)});
      expect(doneInLastDays(h, 7), 2);
    });
  });
}
