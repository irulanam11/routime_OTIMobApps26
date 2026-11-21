class Habit {
  final String id;
  String name;
  int colorValue;
  Set<String> doneDates; // format 'yyyy-MM-dd'

  Habit({
    required this.id,
    required this.name,
    required this.colorValue,
    Set<String>? doneDates,
  }) : doneDates = doneDates ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'doneDates': doneDates.toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        colorValue: json['colorValue'],
        doneDates: Set<String>.from(json['doneDates']),
      );
}