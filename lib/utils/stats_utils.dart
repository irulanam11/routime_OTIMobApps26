import '../models/habit.dart';
import 'date_utils.dart';

/// Hasil perhitungan statistik untuk SATU bulan.
///
/// Semua angka dihitung sekali dalam satu kali lintasan data
/// (O(jumlah tanggal selesai)), lalu dipakai oleh banyak widget.
/// Logika ini sengaja dipisahkan dari widget agar mudah diuji.
class MonthStats {
  final int year;
  final int month;
  final int habitCount;

  /// Jumlah hari di bulan ini yang sudah berlalu (termasuk hari ini).
  final int elapsedDays;

  /// Total penyelesaian semua habit pada bulan ini.
  final int totalCompleted;

  /// Penyelesaian per habit (kunci = id habit).
  final Map<String, int> completedByHabit;

  /// Jumlah habit yang selesai per tanggal (kunci = 'yyyy-MM-dd').
  final Map<String, int> completedByDate;

  /// Jumlah penyelesaian per minggu: M1 = tgl 1-7, M2 = 8-14, dst.
  final List<int> weekly;

  const MonthStats._({
    required this.year,
    required this.month,
    required this.habitCount,
    required this.elapsedDays,
    required this.totalCompleted,
    required this.completedByHabit,
    required this.completedByDate,
    required this.weekly,
  });

  /// Jumlah tanggal berbeda yang punya minimal satu habit selesai.
  int get activeDays => completedByDate.length;

  /// Persentase 0.0 - 1.0 dari target (1 penyelesaian per habit per hari).
  double get completionRate {
    final possible = habitCount * elapsedDays;
    return possible == 0 ? 0.0 : totalCompleted / possible;
  }

  int completedOn(DateTime date) => completedByDate[dateKey(date)] ?? 0;

  int completedFor(Habit habit) => completedByHabit[habit.id] ?? 0;

  /// Habit diurutkan dari penyelesaian terbanyak pada bulan ini.
  List<Habit> rank(List<Habit> habits) {
    return [...habits]..sort((a, b) => completedFor(b).compareTo(completedFor(a)));
  }

  /// [now] dapat diisi saat pengujian agar hasilnya tetap.
  factory MonthStats.compute(
    List<Habit> habits,
    DateTime month, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final totalDays = daysInMonth(month.year, month.month);
    final weekCount = (totalDays + 6) ~/ 7;

    final elapsed = (month.year == today.year && month.month == today.month)
        ? today.day
        : totalDays;

    final byHabit = <String, int>{};
    final byDate = <String, int>{};
    final weekly = List<int>.filled(weekCount, 0);
    var total = 0;

    for (final habit in habits) {
      for (final key in habit.doneDates) {
        final date = DateTime.tryParse(key);
        if (date == null ||
            date.year != month.year ||
            date.month != month.month) {
          continue;
        }

        total++;
        byHabit[habit.id] = (byHabit[habit.id] ?? 0) + 1;
        byDate[key] = (byDate[key] ?? 0) + 1;
        weekly[(date.day - 1) ~/ 7]++;
      }
    }

    return MonthStats._(
      year: month.year,
      month: month.month,
      habitCount: habits.length,
      elapsedDays: elapsed,
      totalCompleted: total,
      completedByHabit: byHabit,
      completedByDate: byDate,
      weekly: weekly,
    );
  }
}
