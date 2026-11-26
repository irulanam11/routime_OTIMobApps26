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

  /// Memuat data Habit dari penyimpanan.
  Future<void> load() async {
    // Mencegah data terduplikasi jika load dipanggil kembali.
    _habits.clear();

    final stored = await _storage.loadHabits();

    if (stored == null) {
      _habits.addAll([
        Habit(
          id: '1',
          name: 'Minum 8 gelas air',
          colorValue: 0xFF2F7D4F,
        ),
        Habit(
          id: '2',
          name: 'Baca 15 menit',
          colorValue: 0xFF4A7FB5,
        ),
        Habit(
          id: '3',
          name: 'Belajar Flutter',
          colorValue: 0xFFF2A83B,
        ),
      ]);

      await _storage.saveHabits(_habits);
    } else {
      _habits.addAll(stored);
    }

    notifyListeners();
  }

  /// Menambahkan Habit baru.
  void addHabit(
    String name, {
    int colorValue = 0xFF2F7D4F,
    bool useTimer = false,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Memastikan ID tidak sama dengan Habit yang sudah ada.
    var id = timestamp.toString();

    while (_habits.any((habit) => habit.id == id)) {
      id = '${timestamp}_${_habits.length}';
    }

    _habits.add(
      Habit(
        id: id,
        name: name.trim(),
        colorValue: colorValue,
        useTimer: useTimer,
      ),
    );

    _commit();
  }

  /// Mengubah status penyelesaian Habit hari ini.
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

    if (timerProvider.hasTimer &&
        (timerProvider.habitId == id || !timerOwnerExists)) {
      await timerProvider.clear();
    }

    _habits.removeWhere((habit) => habit.id == id);

    await _storage.saveHabits(_habits);

    notifyListeners();
  }

  /// Menyimpan perubahan Habit.
  void _commit() {
    unawaited(_storage.saveHabits(_habits));
    notifyListeners();
  }
}
