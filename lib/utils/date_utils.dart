import '../models/habit.dart';

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

bool isDoneToday(Habit h) => h.doneDates.contains(dateKey(DateTime.now()));

int currentStreak(Habit h) {
  var day = DateTime.now();
  if (!h.doneDates.contains(dateKey(day))) {
    day = day.subtract(const Duration(days: 1));
  }
  var count = 0;
  while (h.doneDates.contains(dateKey(day))) {
    count++;
    day = day.subtract(const Duration(days: 1));
  }
  return count;
}

int longestStreak(Habit h) {
  if (h.doneDates.isEmpty) return 0;
  final dates = h.doneDates.map(DateTime.parse).toList()..sort();
  var longest = 1;
  var run = 1;
  for (var i = 1; i < dates.length; i++) {
    final gap = dates[i].difference(dates[i - 1]).inDays;
    if (gap == 1) {
      run++;
    } else {
      run = 1;
    }
    if (run > longest) longest = run;
  }
  return longest;
}

const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Daftar [n] tanggal terakhir, dari yang terlama sampai hari ini.
List<DateTime> lastDays(int n) {
  final now = DateTime.now();
  return [for (var i = n - 1; i >= 0; i--) now.subtract(Duration(days: i))];
}

/// Berapa hari kebiasaan ini selesai dalam [n] hari terakhir.
int doneInLastDays(Habit h, int n) =>
    lastDays(n).where((d) => h.doneDates.contains(dateKey(d))).length;

/// Sapaan sesuai jam.
String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'Selamat pagi!';
  if (hour < 15) return 'Selamat siang!';
  if (hour < 18) return 'Selamat sore!';
  return 'Selamat malam!';
}

const monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

/// Jumlah hari dalam bulan tertentu (otomatis benar untuk Februari/kabisat).
/// Trik: hari ke-0 bulan berikutnya = hari terakhir bulan ini.
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;