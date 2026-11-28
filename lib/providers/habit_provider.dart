import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';
import 'timer_provider.dart';

class HabitProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final List<Habit> _habits = [];

  List<Habit> get habits => List.unmodifiable(_habits);

  int get doneToday => _habits.where(isDoneToday).length;

  Future<void> load() async {
    _habits.clear();

    final stored = await _storage.loadHabits();

    if (stored == null) {
      _habits.addAll([
        Habit(id: '1', name: 'Minum 8 gelas air', colorValue: 0xFF2F7D4F),
        Habit(id: '2', name: 'Baca 15 menit', colorValue: 0xFF4A7FB5),
        Habit(id: '3', name: 'Belajar Flutter', colorValue: 0xFFF2A83B),
      ]);

      await _storage.saveHabits(_habits);
    } else {
      _habits.addAll(stored);
    }

    notifyListeners();
  }

  void addHabit(
    String name, {
    String description = '',
    int colorValue = 0xFF2F7D4F,
    bool useTimer = false,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    var id = timestamp.toString();

    while (_habits.any((habit) => habit.id == id)) {
      id = '${timestamp}_${_habits.length}';
    }

    _habits.add(
      Habit(
        id: id,
        name: name.trim(),
        description: description.trim(),
        colorValue: colorValue,
        useTimer: useTimer,
      ),
    );

    _commit();
  }

  Future<void> updateHabit({
    required String id,
    required String name,
    required String description,
    required int colorValue,
    required bool useTimer,
    TimerProvider? timerProvider,
  }) async {
    final index = _habits.indexWhere((habit) => habit.id == id);

    if (index == -1) return;

    if (!useTimer &&
        timerProvider != null &&
        timerProvider.hasTimer &&
        timerProvider.habitId == id) {
      await timerProvider.clear();
    }

    final habit = _habits[index];

    habit.name = name.trim();
    habit.description = description.trim();
    habit.colorValue = colorValue;
    habit.useTimer = useTimer;

    _commit();
  }

  void toggleToday(String id) {
    final index = _habits.indexWhere((habit) => habit.id == id);

    if (index == -1) return;

    final habit = _habits[index];
    final key = dateKey(DateTime.now());

    if (habit.doneDates.contains(key)) {
      habit.doneDates.remove(key);
    } else {
      habit.doneDates.add(key);
    }

    _commit();
  }

  /// Menghapus Habit dan Timer yang dimilikinya.
  Future<void> deleteHabit(
    String id,
    TimerProvider timerProvider,
  ) async {
    final timerOwnerExists = _habits.any(
      (habit) => habit.id == timerProvider.habitId,
    );

    final shouldClearTimer = timerProvider.hasTimer &&
        (timerProvider.habitId == id || !timerOwnerExists);

    _habits.removeWhere((habit) => habit.id == id);
    notifyListeners();

    if (shouldClearTimer) {
      await timerProvider.clear();
    }

    await _storage.saveHabits(_habits);
  }

  void _commit() {
    unawaited(_storage.saveHabits(_habits));
    notifyListeners();
  }
}
