import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class StorageService {
  static const _key = 'habits';

  /// Mengembalikan null jika belum pernah ada data tersimpan.
  Future<List<Habit>?> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Habit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}