import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../utils/date_utils.dart';

class HabitProvider extends ChangeNotifier {
  final List<Habit> _habits = [
    Habit(
      id: '1',
      name: 'Minum 8 gelas air',
      colorValue: 0xFF2F7D4F,
      doneDates: {
        for (var i = 0; i < 12; i++)
          dateKey(DateTime.now().subtract(Duration(days: i)))
      },
    ),
    Habit(id: '2', name: 'Baca 15 menit', colorValue: 0xFF2F7D4F),
    Habit(id: '3', name: 'Belajar Flutter', colorValue: 0xFF2F7D4F),
  ];

  List<Habit> get habits => List.unmodifiable(_habits);

  int get doneToday => _habits.where(isDoneToday).length;

  void addHabit(String name) {
    _habits.add(Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      colorValue: 0xFF2F7D4F,
    ));
    notifyListeners();
  }

  void toggleToday(String id) {
    final habit = _habits.firstWhere((h) => h.id == id);
    final key = dateKey(DateTime.now());
    if (habit.doneDates.contains(key)) {
      habit.doneDates.remove(key);
    } else {
      habit.doneDates.add(key);
    }
    notifyListeners();
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
  }
}