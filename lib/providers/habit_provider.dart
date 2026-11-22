import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';

class HabitProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final List<Habit> _habits = [];

  List<Habit> get habits => List.unmodifiable(_habits);

  int get doneToday => _habits.where(isDoneToday).length;

  /// Dipanggil sekali saat aplikasi mulai.
  Future<void> load() async {
    final stored = await _storage.loadHabits();
    if (stored == null) {
      // Pertama kali dibuka: isi contoh data
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

  void addHabit(String name, {int colorValue = 0xFF2F7D4F}) {
    _habits.add(Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      colorValue: colorValue,
    ));
    _commit();
  }

  void toggleToday(String id) {
    final habit = _habits.firstWhere((h) => h.id == id);
    final key = dateKey(DateTime.now());
    if (habit.doneDates.contains(key)) {
      habit.doneDates.remove(key);
    } else {
      habit.doneDates.add(key);
    }
    _commit();
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    _commit();
  }

  // Satu pintu: simpan ke penyimpanan lalu beri tahu UI
  void _commit() {
    _storage.saveHabits(_habits);
    notifyListeners();
  }
}