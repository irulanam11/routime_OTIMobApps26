
import 'package:flutter_test/flutter_test.dart';
import 'package:routime/models/habit.dart';

void main() {
  group('Habit Model', () {
    test('Membuat Habit dengan nilai default', () {
      final habit = Habit(
        id: '1',
        name: 'Belajar Flutter',
        colorValue: 0xFF2F7D4F,
      );

      expect(habit.id, '1');
      expect(habit.name, 'Belajar Flutter');
      expect(habit.colorValue, 0xFF2F7D4F);
      expect(habit.doneDates, isEmpty);
      expect(habit.useTimer, false);
    });

    test('Membuat Habit dengan Timer aktif', () {
      final habit = Habit(
        id: '2',
        name: 'Belajar Flutter',
        colorValue: 0xFF2F7D4F,
        useTimer: true,
      );

      expect(habit.useTimer, true);
    });

    test('Mengubah Habit menjadi JSON', () {
      final habit = Habit(
        id: '3',
        name: 'Membaca Buku',
        colorValue: 0xFF4A7FB5,
        doneDates: {'2026-11-25'},
        useTimer: true,
      );

      final json = habit.toJson();

      expect(json['id'], '3');
      expect(json['name'], 'Membaca Buku');
      expect(json['colorValue'], 0xFF4A7FB5);
      expect(json['doneDates'], ['2026-11-25']);
      expect(json['useTimer'], true);
    });

    test('Mengubah JSON menjadi Habit', () {
      final json = {
        'id': '4',
        'name': 'Olahraga',
        'colorValue': 0xFFF2A83B,
        'doneDates': ['2026-11-25'],
        'useTimer': true,
      };

      final habit = Habit.fromJson(json);

      expect(habit.id, '4');
      expect(habit.name, 'Olahraga');
      expect(habit.colorValue, 0xFFF2A83B);
      expect(habit.doneDates, contains('2026-11-25'));
      expect(habit.useTimer, true);
    });

    test('Data lama tanpa useTimer menggunakan false', () {
      final json = {
        'id': '5',
        'name': 'Membaca',
        'colorValue': 0xFF2F7D4F,
        'doneDates': [],
      };

      final habit = Habit.fromJson(json);

      expect(habit.useTimer, false);
    });

    test('Habit dapat ditandai selesai pada beberapa tanggal', () {
      final habit = Habit(
        id: '6',
        name: 'Belajar',
        colorValue: 0xFF2F7D4F,
        doneDates: {
          '2026-11-24',
          '2026-11-25',
        },
      );

      expect(habit.doneDates.length, 2);
      expect(habit.doneDates, contains('2026-11-24'));
      expect(habit.doneDates, contains('2026-11-25'));
    });
  });
}
