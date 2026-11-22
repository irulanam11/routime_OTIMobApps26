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