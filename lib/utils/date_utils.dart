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