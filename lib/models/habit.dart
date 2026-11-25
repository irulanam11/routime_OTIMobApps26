
class Habit {
  final String id;
  String name;
  int colorValue;
  Set<String> doneDates;

  // Menentukan apakah habit menggunakan timer
  bool useTimer;

  Habit({
    required this.id,
    required this.name,
    required this.colorValue,
    Set<String>? doneDates,
    this.useTimer = false,
  }) : doneDates = doneDates ?? {};

  // Mengubah data Habit menjadi JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'doneDates': doneDates.toList(),
        'useTimer': useTimer,
      };

  // Mengubah JSON menjadi objek Habit
  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        colorValue: json['colorValue'],
        doneDates: Set<String>.from(json['doneDates'] ?? []),

        // Data lama yang belum memiliki useTimer
        // otomatis menggunakan nilai false
        useTimer: json['useTimer'] as bool? ?? false,
      );
}
