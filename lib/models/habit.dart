class Habit {
  final String id;
  String name;
  String description;
  int colorValue;
  Set<String> doneDates;
  bool useTimer;

  Habit({
    required this.id,
    required this.name,
    required this.colorValue,
    this.description = '',
    Set<String>? doneDates,
    this.useTimer = false,
  }) : doneDates = doneDates ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'colorValue': colorValue,
    'doneDates': doneDates.toList(),
    'useTimer': useTimer,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    name: json['name'],
    description: json['description'] as String? ?? '',
    colorValue: json['colorValue'],
    doneDates: Set<String>.from(json['doneDates'] ?? []),
    useTimer: json['useTimer'] as bool? ?? false,
  );
}
